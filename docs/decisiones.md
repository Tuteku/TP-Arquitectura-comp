# Decisiones de diseño

Cada decisión tiene el contexto, las opciones que se consideraron, lo que se eligió y por qué. Las marcadas como **propuesta** se confirman al revisar el PR de M0; si alguna cambia, se edita acá y se anota la razón.

| # | Decisión | Elección | Issue | Estado |
|---|---|---|---|---|
| D1 | Tamaño y mapa de las memorias | IMEM y DMEM de 256 palabras (1 KiB) cada una, separadas | #2 | Propuesta |
| D2 | Implementación de las memorias | RAM distribuida inferida (lectura asíncrona) | #2 | Propuesta |
| D3 | Accesos desalineados | No soportados; el hardware ignora los bits bajos | #2 | Propuesta |
| D4 | Etapa donde se resuelven los saltos | EX para beq, bne, jal y jalr | #3 | Propuesta |
| D5 | Riesgos de control | Predecir no tomado + flush de 2 instrucciones | #3 | Propuesta |
| D6 | Riesgos de datos | Forwarding a EX + stall de load-use + bypass del banco | #4 | Propuesta |
| D7 | Control de ejecución | Clock enable global, sin gating | #7 | Propuesta |
| D8 | Reset y reprogramación | Reset de CPU por la Debug Unit + barrido de memorias | #7 | Propuesta |
| D9 | Instrucción HALT | `ebreak` (`0x00100073`) y cualquier instrucción ilegal | #8 | Propuesta |
| D10 | Programa sin HALT | IMEM limpia con ceros + watchdog | #8 | Propuesta |

---

## Memorias (#2)

### D1. Tamaño y mapa de memoria

**Contexto.** La consigna no fija tamaños. Los programas de prueba van a tener decenas de instrucciones y usar unas pocas palabras de datos.

**Decisión.**

| Memoria | Palabras | Bytes | Rango de direcciones | Índice de palabra |
|---|---|---|---|---|
| Instrucciones (IMEM) | 256 | 1 KiB | `0x000` a `0x3FF` | `pc[9:2]` |
| Datos (DMEM) | 256 | 1 KiB | `0x000` a `0x3FF` | `addr[9:2]` |

- Las dos memorias son independientes (arquitectura Harvard) y cada una arranca en la dirección 0. Eso evita el riesgo estructural entre IF y MEM.
- El PC arranca en `0x00000000`.
- Direccionamiento por byte y little-endian, como define RISC-V. Los bits `[1:0]` de una dirección eligen el byte dentro de la palabra.
- Los bits por encima del 9 se ignoran: una dirección fuera de rango se repite sobre la memoria (`0x400` es lo mismo que `0x000`). No se detecta como error.

**Justificación.** 256 instrucciones alcanzan con margen para cualquier programa de prueba razonable, y 1 KiB de datos permite probar arreglos chicos. El tamaño es un parámetro (`NB_ADDR = 8`), así que agrandarlo después es cambiar un número.

### D2. Implementación: RAM distribuida inferida

**Contexto.** En la Artix-7 hay dos opciones:

| | RAM distribuida (LUTRAM) | Block RAM (IP o inferida) |
|---|---|---|
| Lectura | Asíncrona, el dato sale en el mismo ciclo | Síncrona, el dato sale después del flanco |
| Encaje en el pipeline | Directo, como el datapath del libro | Hay que adelantar la dirección un ciclo |
| Costo para 2 × 1 KiB | Del orden de pocos cientos de LUTs de 20 800 | 1 bloque de 36 Kb por memoria |
| Puertos | 1 de escritura + varios de lectura | 2 puertos completos |

**Impacto de la BRAM en IF y MEM (lo que pide analizar la issue).** Con lectura síncrona, si la dirección de la IMEM es el PC, la instrucción recién sale un ciclo después: es como agregar una etapa. La solución es conectar a la dirección el *siguiente PC* (la salida del multiplexor que elige PC+4, destino de salto o PC congelado), de modo que el PC y la BRAM capturan la misma dirección en el mismo flanco y el registro de salida de la BRAM pasa a ser la mitad "instrucción" de IF/ID. Eso trae tres consecuencias:

- un stall ya no se resuelve solo congelando IF/ID: hay que volver a presentar la misma dirección o deshabilitar la BRAM,
- un flush no puede escribir una NOP en el registro interno de la BRAM, así que depende de un bit de válido,
- el camino del siguiente PC (que incluye la decisión de salto de EX) tiene que llegar a la BRAM antes del flanco, lo que probablemente lo vuelve crítico.

En MEM pasa lo mismo con la dirección que calcula la ALU.

**Decisión.** IMEM y DMEM como RAM distribuida inferida desde Verilog:

```verilog
always @(posedge i_clk) if (we) mem[waddr] <= wdata;  // escritura síncrona
assign rdata = mem[raddr];                             // lectura asíncrona
```

**Justificación.** Se comporta exactamente como el datapath que diseñamos, así que el diagrama, el modelo de referencia y el hardware coinciden ciclo a ciclo. El costo en LUTs es chico para este tamaño. Si en M7 el análisis de tiempo muestra que la lectura de memoria es el camino crítico, la BRAM queda como alternativa documentada.

**Puertos.**

| Memoria | Escritura | Lectura 1 | Lectura 2 |
|---|---|---|---|
| IMEM | Debug Unit (carga del programa, con el procesador detenido) | IF | Debug Unit (opcional, para verificar la carga) |
| DMEM | MEM cuando corre el procesador; Debug Unit cuando está detenido (limpieza) | MEM | Debug Unit (volcado) |

La RAM distribuida tiene un solo puerto de escritura, así que en la DMEM la dirección y el dato de escritura pasan por un multiplexor que elige entre la etapa MEM y la Debug Unit. Mientras el procesador está detenido, la escritura de MEM está deshabilitada por el enable, así que nunca compiten.

### D3. Accesos de distinto tamaño y desalineados

La DMEM se organiza como 4 bancos de 256 × 8 bits (un banco por byte de la palabra), lo que da escritura por byte con una máscara de 4 bits.

**Escritura (stores):**

| Instrucción | `funct3` | Máscara según `addr[1:0]` | Dato escrito |
|---|---|---|---|
| `sb` | `000` | `0001 << addr[1:0]` | `rs2[7:0]` replicado en los 4 bytes |
| `sh` | `001` | `0011 << {addr[1], 1'b0}` | `rs2[15:0]` replicado en las 2 mitades |
| `sw` | `010` | `1111` | `rs2` |

**Lectura (loads):** la memoria devuelve la palabra completa y un bloque de alineación elige el byte o la media palabra y la extiende:

| Instrucción | `funct3` | Toma | Extensión |
|---|---|---|---|
| `lb` | `000` | byte `addr[1:0]` | signo |
| `lh` | `001` | media palabra `addr[1]` | signo |
| `lw` | `010` | palabra completa | no hace falta |
| `lbu` | `100` | byte `addr[1:0]` | ceros |
| `lhu` | `101` | media palabra `addr[1]` | ceros |

**Desalineados.** RISC-V permite que una implementación no los soporte. Decisión: **no se soportan**. El hardware ignora los bits que deberían ser cero (`addr[1:0]` en `lw`/`sw`, `addr[0]` en `lh`/`lhu`/`sh`), o sea que alinea hacia abajo sin avisar.

**Justificación.** Soportarlos implicaría partir un acceso en dos ciclos o leer dos palabras, con un costo grande para un caso que los programas de prueba no necesitan. Para que no pase desapercibido, el modelo de referencia en Python (M4) marca como error cualquier acceso desalineado, así un test que lo provoque falla en simulación.

---

## Saltos y riesgos de control (#3)

### D4. Todos los saltos se resuelven en EX

**Contexto.** Hay que elegir en qué etapa se decide el siguiente PC para `beq`, `bne`, `jal` y `jalr`.

| Opción | Instrucciones descartadas si salta | Costo |
|---|---|---|
| Resolver en EX | 2 | Ninguno extra: la comparación y el destino se calculan con valores que ya llegan con forwarding a EX |
| Resolver en ID | 1 | Comparador de 32 bits y sumador PC+imm en ID, forwarding hacia ID, stalls nuevos y un camino crítico más largo en ID |

Resolver en ID agrega stalls cuando el branch depende de la instrucción anterior, que es el caso típico de un bucle:

```asm
addi x1, x1, -1
bne  x1, x0, loop    # con el salto en ID, x1 todavía se está calculando en EX: 1 stall
```

Si el productor es un `lw`, serían 2 stalls. Medido en el simulador con forwarding:

| Programa | Saltos en EX | Saltos en ID | Mínimo sin riesgos |
|---|---|---|---|
| Bucle con `addi` justo antes del `bne` | 21 ciclos | 22 ciclos | 17 |
| Mismo bucle con una instrucción entre el `addi` y el `bne` | 21 ciclos | 19 ciclos | 17 |

**Decisión.** `beq`, `bne`, `jal` y `jalr` se resuelven en EX:

| Instrucción | Condición | Destino | Calculado con |
|---|---|---|---|
| `beq` | `rs1 == rs2` | `PC + imm` | Comparador de igualdad sobre los operandos ya adelantados + sumador de destino |
| `bne` | `rs1 != rs2` | `PC + imm` | Ídem |
| `jal` | Siempre | `PC + imm` | Sumador de destino |
| `jalr` | Siempre | `(rs1 + imm) & ~1` | ALU (suma con `ALUSrc = 1`), bit 0 forzado a 0 |

`jal` y `jalr` escriben `PC + 4` en `rd`. Ese valor se calcula en IF (el mismo sumador que avanza el PC) y viaja por los latches hasta WB.

**Justificación.**

- Un único lugar donde se decide el siguiente PC y un único caso de flush (siempre las mismas dos etapas).
- No hace falta forwarding hacia ID ni stalls especiales para branches.
- No alarga ID, que ya tiene la lectura del banco de registros.
- La comparación de igualdad se hace con un comparador dedicado en lugar de mirar si la resta de la ALU dio cero, así la ALU no necesita una salida `zero` y la decisión de salto no espera a la cadena de acarreo.

**A futuro.** `jal` no lee registros, así que se podría resolver en ID sin stalls (1 instrucción descartada en vez de 2). Queda como mejora opcional para M3 si sobra tiempo; no cambia nada más del diseño.

### D5. Predicción "no tomado" y flush

**Decisión.** IF siempre busca `PC + 4`. Cuando una instrucción en EX resulta ser un salto tomado, en ese mismo flanco:

| Qué | Valor que toma |
|---|---|
| PC | Destino del salto |
| IF/ID | Burbuja (`valid = 0`) |
| ID/EX | Burbuja (`valid = 0`, señales de control en 0) |
| Flag de HALT pendiente | 0 (ver D9) |

El salto en EX sigue su camino normal hacia MEM y WB (`jal`/`jalr` todavía tienen que escribir `rd`).

Diagrama temporal de un `beq` tomado:

| Instrucción | c1 | c2 | c3 | c4 | c5 | c6 | c7 | c8 |
|---|---|---|---|---|---|---|---|---|
| `beq` (salta) | IF | ID | **EX** | MEM | WB | | | |
| PC + 4 | | IF | ~~ID~~ | | | | | |
| PC + 8 | | | ~~IF~~ | | | | | |
| destino | | | | IF | ID | EX | MEM | WB |

Penalización: 2 ciclos por salto tomado, 0 si no se toma.

**Burbujas con bit de válido.** Cada latch tiene un bit `valid`. Una instrucción con `valid = 0` no escribe registros ni memoria, no salta y no genera forwarding ni HALT, aunque los demás campos tengan cualquier valor. Se eligió esto en vez de cargar la instrucción NOP (`0x00000013`) porque:

- distingue una burbuja de un `addi x0, x0, 0` que el programa tenía de verdad, lo que la interfaz necesita para mostrar el pipeline,
- un solo bit por latch alcanza para anular la instrucción completa, sin tener que poner en cero cada señal de control.

**Prioridades cuando coinciden eventos en el mismo ciclo:**

1. Reset.
2. Flush por salto tomado en EX (anula lo que haya en IF y en ID, aunque esté frenado).
3. Stall por load-use (ver D6).
4. Avance normal.

**¿Hace falta forwarding hacia ID?** No con esta decisión: ID no compara registros. Haría falta solamente si en el futuro se mueve la decisión de branches a ID.

---

## Riesgos de datos (#4)

### D6. Forwarding hacia EX, stall de load-use y bypass del banco

**Decisión.** Tres mecanismos, cada uno para un caso:

| Mecanismo | Dónde | Qué resuelve |
|---|---|---|
| Forwarding desde EX/MEM y MEM/WB | Multiplexores a la entrada de EX | Dependencias a distancia 1 y 2 |
| Bypass interno del banco de registros | Lectura en ID | Dependencia a distancia 3 (escritura y lectura en el mismo ciclo) |
| Stall de un ciclo | Unidad de detección en ID | Load seguido de una instrucción que usa el dato |

#### Tabla de casos

| Caso | Ejemplo | Solución | Ciclos perdidos |
|---|---|---|---|
| ALU → ALU, distancia 1 | `add x1,..` / `sub x2,x1,..` | Forwarding desde EX/MEM | 0 |
| ALU → ALU, distancia 2 | `add x1,..` / otra / `sub x2,x1,..` | Forwarding desde MEM/WB | 0 |
| Cualquiera, distancia 3 | `add x1,..` / otra / otra / `sub x2,x1,..` | Bypass del banco | 0 |
| Load → uso, distancia 1 | `lw x1,0(x2)` / `add x3,x1,x4` | Stall de 1 ciclo + forwarding desde MEM/WB | 1 |
| Load → uso, distancia 2 | `lw x1,..` / otra / `add x3,x1,..` | Forwarding desde MEM/WB (dato leído) | 0 |
| Dato de un store | `addi x5,..` / `sw x5,0(x2)` | Forwarding sobre el camino de rs2, que también es el dato a guardar | 0 |
| Load → store del mismo dato | `lw x1,..` / `sw x1,0(x2)` | Se trata como load-use: stall de 1 ciclo | 1 |
| Operandos de un branch | `addi x1,..` / `bne x1,x0,..` | Forwarding a EX (el comparador usa los valores adelantados) | 0 |
| Base de `jalr` | `addi x1,..` / `jalr x0,0(x1)` | Forwarding a EX | 0 |
| `jal`/`jalr` como productor | `jal x1,f` / ... / `add x2,x1,..` | El valor adelantado es `PC + 4` (ver abajo) | 0 |
| Destino x0 | `addi x0,x0,5` / `add x1,x0,x0` | No se escribe ni se adelanta nunca | 0 |

#### Unidad de forwarding (en EX)

Para el operando A (con rs1). El operando B es igual con rs2:

```
si   exmem_valid && exmem_reg_write && exmem_rd != 0 && exmem_rd == idex_rs1  -> forward_a = 2'b10 (desde EX/MEM)
sino memwb_valid && memwb_reg_write && memwb_rd != 0 && memwb_rd == idex_rs1  -> forward_a = 2'b01 (desde MEM/WB)
sino                                                                          -> forward_a = 2'b00 (valor leído en ID)
```

- EX/MEM tiene prioridad porque es el valor más reciente.
- El valor que se adelanta desde EX/MEM es `exmem_pc4` si la instrucción es `jal`/`jalr` (`result_src = PC4`) y `exmem_alu_result` en cualquier otro caso. Un load en EX/MEM nunca llega a adelantarse porque el stall de load-use lo impide.
- El valor que se adelanta desde MEM/WB es la salida del multiplexor de WB, o sea exactamente lo que se va a escribir en el registro.
- La salida del multiplexor de B alimenta tanto al multiplexor `ALUSrc` como al dato que se guarda en un store y al comparador de branches.

#### Unidad de detección de riesgos (en ID)

```
stall = idex_valid && idex_mem_read && idex_rd != 0 &&
        ((id_use_rs1 && idex_rd == id_rs1) || (id_use_rs2 && idex_rd == id_rs2))
```

`id_use_rs1` e `id_use_rs2` salen del decodificador y valen 1 solo si la instrucción realmente lee ese registro. Así un `addi`, cuyos bits [24:20] son parte del inmediato, no provoca stalls falsos.

| Instrucción | Usa rs1 | Usa rs2 |
|---|---|---|
| Tipo R | Sí | Sí |
| Tipo I aritméticas, loads, `jalr` | Sí | No |
| Stores, branches | Sí | Sí |
| `lui`, `jal`, HALT | No | No |

Cuando `stall = 1`: el PC y IF/ID no se actualizan y ID/EX recibe una burbuja.

#### Banco de registros

- 31 registros de 32 bits con flip-flops; `x0` no se guarda y su lectura devuelve siempre 0.
- Escritura en el flanco positivo si `enable && reg_write && rd != 0`.
- Lectura combinacional con bypass: si la dirección leída coincide con la que se está escribiendo en ese ciclo (y la escritura está habilitada), devuelve el dato de escritura.
- Tres puertos de lectura: rs1 y rs2 para ID, y uno para la Debug Unit.

**Justificación.** Es el esquema clásico del libro, con un solo stall posible (load-use) y sin forwarding hacia ID gracias a D4. El bypass del banco evita depender de escribir en la primera mitad del ciclo, que en FPGA obligaría a usar el flanco negativo.

