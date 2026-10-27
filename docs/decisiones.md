# Decisiones de diseño

Cada decisión tiene el contexto, las opciones que se consideraron, lo que se eligió y por qué. Las marcadas como **propuesta** se confirman al revisar el PR de M0; si alguna cambia, se edita acá y se anota la razón.

| # | Decisión | Elección | Issue | Estado |
|---|---|---|---|---|
| D1 | Tamaño y mapa de las memorias | IMEM y DMEM de 256 palabras (1 KiB) cada una, separadas | #2 | Propuesta |
| D2 | Implementación de las memorias | RAM distribuida inferida (lectura asíncrona); BRAM inferida, no IP, como alternativa | #2 | Propuesta |
| D3 | Accesos desalineados | No soportados ni detectados; el hardware ignora los bits bajos (datos y fetch) | #2 | Propuesta |
| D4 | Etapa donde se resuelven los saltos | EX para beq, bne, jal y jalr | #3 | Propuesta |
| D5 | Riesgos de control | Predecir no tomado + flush de 2 instrucciones | #3 | Propuesta |
| D6 | Riesgos de datos | Forwarding EX/MEM y MEM/WB a EX + stall de load-use + bypass del banco; x0 nunca se escribe ni se adelanta | #4 | Propuesta |
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
- Direccionamiento por byte y little-endian, como define RISC-V. Las memorias se organizan internamente en palabras de 32 bits: los bits `[9:2]` de la dirección eligen la palabra y los bits `[1:0]` el byte dentro de ella.
- Los bits por encima del 9 se ignoran: una dirección fuera de rango se repite sobre la memoria (`0x400` es lo mismo que `0x000`). No se detecta como error.

**Mapeo de una dirección de byte a la memoria:**

```
 31          10 9                2 1   0
+--------------+------------------+-----+
|  ignorados   | índice de palabra| byte|
+--------------+------------------+-----+
                  addr[9:2]        addr[1:0]
```

| Dirección | Palabra | Byte | Bits de la palabra que ocupa el byte |
|---|---|---|---|
| `0x000` | 0 | 0 | `[7:0]` |
| `0x001` | 0 | 1 | `[15:8]` |
| `0x002` | 0 | 2 | `[23:16]` |
| `0x003` | 0 | 3 | `[31:24]` |
| `0x00C` | 3 | 0 | `[7:0]` |
| `0x3FC` | 255 | 0 | `[7:0]` (última palabra) |
| `0x404` | 1 | 0 | `[7:0]` (se repite sobre la palabra 1) |

Por ser little-endian, `sw` de `0x11223344` en `0x000` deja `0x44` en el byte `0x000` y `0x11` en el `0x003`, y un `lbu` de `0x000` devuelve `0x44`.

**Justificación.** 256 instrucciones alcanzan con margen para cualquier programa de prueba razonable, y 1 KiB de datos permite probar arreglos chicos. El tamaño es un parámetro (`NB_ADDR = 8`), así que agrandarlo después es cambiar un número. Además encaja con el resto del diseño:

- el protocolo de carga acepta hasta `N = 256` palabras y el volcado de la DMEM manda como máximo 256 palabras (1231 bytes, unos 107 ms a 115200 baudios, ver [protocolo.md](protocolo.md)),
- las direcciones de la Debug Unit hacia las memorias (`i_imem_waddr`, `i_dbg_dmem_addr`, `o_dmem_waddr`) son de 8 bits, un índice de palabra, no de byte,
- las dos memorias entran en un solo bloque de BRAM de 36 Kb cada una si en algún momento se cambia la implementación (ver D2), y en LUTRAM ocupan poco.

### D2. Implementación: RAM distribuida inferida

**Contexto.** Hay dos preguntas separadas: qué recurso de la FPGA usar (RAM distribuida o Block RAM) y, si fuera BRAM, si instanciarla con el IP core *Block Memory Generator* o dejar que Vivado la infiera desde Verilog.

**Recurso de la Artix-7:**

| | RAM distribuida (LUTRAM) | Block RAM |
|---|---|---|
| Lectura | Asíncrona, el dato sale en el mismo ciclo | Síncrona, el dato sale después del flanco |
| Encaje en el pipeline | Directo, como el datapath del libro | Hay que adelantar la dirección un ciclo (ver abajo) |
| Costo para 2 × 1 KiB | Aprox. 128 LUTs por cada puerto de lectura de 256 × 32 (`RAM256X1S` usa 4 LUTs por bit); con los puertos de D2, unos 250 a 550 LUTs de 20 800 (de las 9600 que pueden ser memoria) | 1 bloque de 36 Kb por memoria, de 50 |
| Puertos | 1 de escritura + 1 o más de lectura (cada puerto de lectura extra replica la memoria) | 2 puertos completos (lectura y escritura cada uno) |
| Retardo de lectura | El de la LUT más los multiplexores F7/F8, unos 1,5 a 2 ns | Clock-to-out de la BRAM, unos 2 a 2,5 ns, pero empieza en el flanco |

Las cifras de LUTs son estimaciones; el número real sale del reporte de utilización cuando se sintetice la memoria en M1.

**IP core o memoria inferida (si se usara BRAM):**

| | IP core (Block Memory Generator) | Inferida desde Verilog |
|---|---|---|
| Fuente | Archivo `.xci` generado por Vivado | Un `.v` común en `rtl/core/` |
| Contenido inicial | Archivo `.coe` | `$readmemh` con el `.hex` del ensamblador |
| Simulación | Necesita las bibliotecas de Xilinx; no corre en Icarus | Cualquier simulador |
| Repositorio | Hay que versionar el `.xci` y regenerarlo en `crear_proyecto.tcl`; cambia entre versiones de Vivado | Nada especial |
| Control | Opciones de la GUI (registro de salida, ancho por puerto, byte enables) | Hay que respetar las plantillas de inferencia de Vivado (UG901) |

Para lo que necesitamos (un ancho, un reloj, escritura por byte) la inferencia da el mismo resultado que el IP sin sus inconvenientes. **Si en algún momento se pasa a BRAM, se infiere, no se usa el IP core.**

**Impacto de la lectura sincrónica de la BRAM en IF y MEM (lo que pide analizar la issue).**

*En IF.* Si la dirección de la IMEM es el PC, la instrucción recién sale un ciclo después de que el PC cambia: en la práctica agrega una etapa, y los saltos pasarían a descartar 3 instrucciones en lugar de 2. Para evitarlo hay que conectar a la dirección el *siguiente PC* (la salida del multiplexor que elige PC+4, destino de salto o PC congelado), de modo que el PC y la BRAM capturan la misma dirección en el mismo flanco y el registro de salida de la BRAM pasa a ser la mitad "instrucción" de IF/ID (`ifid_instr`). Eso trae cuatro consecuencias:

- un stall ya no se resuelve solo congelando IF/ID: hay que deshabilitar la BRAM (su pin de enable conectado a `i_enable && !stall`) para que mantenga la salida,
- un flush no puede escribir una NOP en el registro interno de la BRAM, así que depende de que el bit `ifid_valid` se ponga en 0 y de que ID ignore la instrucción cuando no es válida,
- el camino del siguiente PC, que incluye la decisión de salto de EX (forwarding, comparador, sumador del destino, multiplexor), tiene que llegar a la dirección de la BRAM antes del flanco y respetar su tiempo de setup, que es mayor que el de un flip-flop; ese camino ya es largo en este diseño y probablemente pase a ser el crítico,
- después del reset, el registro de salida de la BRAM no tiene la instrucción de la dirección 0 hasta el primer flanco con enable, así que el primer ciclo hay que tratarlo como una burbuja.

*En MEM.* La situación es más simple. La dirección y el dato de un store ya están registrados en EX/MEM, así que la BRAM se direcciona con `exmem_alu_result` y la escritura no cambia (ya era síncrona). Para los loads el dato sale después del flanco que cierra MEM, o sea en WB: el registro de salida de la BRAM toma el lugar de `memwb_mem_data`. Las consecuencias son:

- la alineación y extensión de los loads (D3) se mueve de MEM a WB, y para eso `funct3` tiene que viajar en MEM/WB (`addr[1:0]` ya está en `memwb_alu_result`),
- el forwarding desde MEM/WB de un load sale del registro de la BRAM más la lógica de alineación, que queda en el camino hacia los multiplexores de EX,
- la BRAM también tiene que respetar `i_enable` para que el dato no cambie mientras el procesador está detenido,
- el stall de load-use (D6) sigue siendo de un ciclo, porque el dato llega a WB igual que con lectura asíncrona.

En resumen: en MEM la BRAM entra con cambios chicos; en IF obliga a rediseñar el PC, los stalls y el flush, y alarga el camino del salto.

**Decisión.** IMEM y DMEM como RAM distribuida inferida desde Verilog:

```verilog
always @(posedge i_clk) if (we) mem[waddr] <= wdata;  // escritura síncrona
assign rdata = mem[raddr];                             // lectura asíncrona
```

Para que Vivado no la convierta en BRAM ni en flip-flops, la lectura tiene que quedar asíncrona (sin registro) y el arreglo puede marcarse con `(* ram_style = "distributed" *)`.

**Justificación.** Se comporta exactamente como el datapath que diseñamos, así que el diagrama, el modelo de referencia y el hardware coinciden ciclo a ciclo, y el PC, los stalls y el flush quedan como en D4 a D6. El costo en LUTs es chico para este tamaño (menos del 3 % del chip). Si en M7 el análisis de tiempo muestra que la lectura de memoria es el camino crítico, el orden para pasar a BRAM es primero la DMEM (cambios chicos) y después, solo si hace falta, la IMEM.

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

**Desalineados.** Un acceso está alineado cuando la dirección es múltiplo de su tamaño. RISC-V permite que una implementación no soporte los desalineados (en ese caso deberían generar una excepción, pero este procesador no tiene excepciones). Decisión: **no se soportan y no se detectan**. El hardware ignora los bits que deberían ser cero, o sea que alinea hacia abajo sin avisar:

| Instrucción | Alineado si | Bits ignorados | Ejemplo desalineado | Qué hace el hardware |
|---|---|---|---|---|
| `lb`, `lbu`, `sb` | siempre | – | – | – |
| `lh`, `lhu` | `addr[0] = 0` | `addr[0]` | `lh` en `0x003` | Lee la media palabra alta de la palabra 0 (bytes `0x002`–`0x003`) |
| `sh` | `addr[0] = 0` | `addr[0]` | `sh` en `0x001` | Escribe los bytes `0x000`–`0x001` |
| `lw` | `addr[1:0] = 00` | `addr[1:0]` | `lw` en `0x006` | Lee la palabra 1 completa (bytes `0x004`–`0x007`) |
| `sw` | `addr[1:0] = 00` | `addr[1:0]` | `sw` en `0x00A` | Escribe la palabra 2 completa (bytes `0x008`–`0x00B`) |

Esto sale solo de las tablas de arriba: las máscaras de `sh` y `sw` y la selección de `lh`/`lhu`/`lw` no miran esos bits, así que no hace falta lógica adicional.

**Fetch desalineado.** La IMEM también ignora `pc[1:0]`. Con instrucciones de 4 bytes y sin la extensión C, el PC queda alineado siempre que los destinos de salto lo estén. No lo están si un `beq`, `bne` o `jal` tiene un desplazamiento que no es múltiplo de 4 (el formato admite múltiplos de 2) o si un `jalr` calcula una dirección con el bit 1 en 1 (el `& ~1` de D4 solo limpia el bit 0). En ese caso el procesador ejecuta la instrucción de la palabra `pc[9:2]` y el PC sigue desalineado (`PC + 4` mantiene `pc[1:0]`). El ensamblador (M4) genera desplazamientos múltiplos de 4 a partir de etiquetas, así que solo pasa con código armado a mano.

**Justificación.** Soportarlos implicaría partir un acceso en dos ciclos o leer dos palabras, con un costo grande para un caso que los programas de prueba no necesitan, y detectarlos sin un mecanismo de excepciones solo serviría para frenar el procesador. Para que no pase desapercibido, el modelo de referencia en Python (M4) marca como error cualquier acceso a datos o fetch desalineado, así un test que lo provoque falla en simulación, y los programas de prueba usan solo accesos alineados.

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

La *distancia* es cuántas instrucciones separan al productor del consumidor: distancia 1 es la instrucción inmediatamente siguiente. Con 5 etapas, el resultado se escribe en el banco en WB, tres ciclos después de que el consumidor a distancia 1 lo leyó en ID. Por eso hacen falta mecanismos para las distancias 1, 2 y 3, y desde la 4 el valor ya está en el banco.

#### Caminos de forwarding

| Camino | Origen | Destino | ¿Se implementa? | Por qué |
|---|---|---|---|---|
| EX/MEM → EX | `exmem_alu_result` o `exmem_pc4` | Operandos A y B de EX | Sí | Distancia 1 entre instrucciones que no son loads |
| MEM/WB → EX | Salida del multiplexor de WB (ALU, dato leído o `PC + 4`) | Operandos A y B de EX | Sí | Distancia 2, y distancia 1 de un load después del stall |
| WB → ID | Dato de escritura del banco | Lectura de rs1 y rs2 en ID | Sí, como bypass dentro del banco | Distancia 3 |
| MEM/WB → MEM | Dato leído por un load | Dato a guardar de un store en MEM | No | Ahorraría el stall en `lw x1` / `sw x1`, un caso poco frecuente, a cambio de una unidad de forwarding más y un multiplexor en el camino de escritura de la DMEM. Se resuelve con el stall de load-use |
| EX/MEM → ID, MEM/WB → ID | Resultados | Comparador de branches en ID | No | Solo haría falta si los saltos se resolvieran en ID; por D4 se resuelven en EX y el forwarding a EX ya cubre sus operandos |

Los caminos que existen salen todos de latches (EX/MEM, MEM/WB) o del dato que se escribe en el banco, así que ninguno parte de la salida combinacional de la ALU o de la DMEM del mismo ciclo.

#### Tabla de casos

| Caso | Ejemplo | Solución | Ciclos perdidos |
|---|---|---|---|
| ALU → ALU, distancia 1 | `add x1,..` / `sub x2,x1,..` | Forwarding desde EX/MEM | 0 |
| ALU → ALU, distancia 2 | `add x1,..` / otra / `sub x2,x1,..` | Forwarding desde MEM/WB | 0 |
| Cualquiera, distancia 3 | `add x1,..` / otra / otra / `sub x2,x1,..` | Bypass del banco | 0 |
| Load → uso, distancia 1 | `lw x1,0(x2)` / `add x3,x1,x4` | Stall de 1 ciclo + forwarding desde MEM/WB | 1 |
| Load → uso, distancia 2 | `lw x1,..` / otra / `add x3,x1,..` | Forwarding desde MEM/WB (dato leído) | 0 |
| Load → uso, distancia 3 | `lw x1,..` / otra / otra / `add x3,x1,..` | Bypass del banco | 0 |
| Doble dependencia del mismo registro | `add x1,..` / `addi x1,x1,1` / `sub x2,x1,..` | Forwarding desde EX/MEM, que tiene prioridad sobre MEM/WB por ser el valor más nuevo | 0 |
| Dos operandos de productores distintos | `add x1,..` / `add x2,..` / `sub x3,x1,x2` | Cada operando tiene su multiplexor: A desde MEM/WB, B desde EX/MEM | 0 |
| Dato de un store | `addi x5,..` / `sw x5,0(x2)` | Forwarding sobre el camino de rs2, que también es el dato a guardar | 0 |
| Base de un load o store | `addi x2,..` / `lw x1,0(x2)` | Forwarding sobre rs1, que va a la ALU para calcular la dirección | 0 |
| Load → store del mismo dato | `lw x1,..` / `sw x1,0(x2)` | Se trata como load-use: stall de 1 ciclo (no hay forwarding MEM/WB → MEM) | 1 |
| Load → base de otro acceso | `lw x2,..` / `lw x1,0(x2)` | Stall de 1 ciclo + forwarding desde MEM/WB | 1 |
| Operandos de un branch | `addi x1,..` / `bne x1,x0,..` | Forwarding a EX (el comparador usa los valores adelantados) | 0 |
| Load → branch | `lw x1,..` / `beq x1,x2,..` | Stall de 1 ciclo + forwarding desde MEM/WB | 1 |
| Base de `jalr` | `addi x1,..` / `jalr x0,0(x1)` | Forwarding a EX | 0 |
| `jal`/`jalr` como productor | `jal x1,f` / ... / `add x2,x1,..` | El valor adelantado es `PC + 4` (ver abajo) | 0 |
| `lui` como productor | `lui x1,0x12345` / `addi x1,x1,0x678` | Forwarding desde EX/MEM; el resultado de `lui` sale de la ALU (`x0 + imm`) | 0 |
| Instrucción que no lee el registro | `addi x1,..` / `jal x5,f` | Ninguna: el decodificador pone `rs1 = rs2 = 0` y no hay coincidencia | 0 |
| Productor anulado (burbuja o flush) | `beq` tomado que descarta un `add x1,..` | Ninguna: con `valid = 0` no se adelanta ni se escribe | 0 |
| Destino x0 | `addi x0,x0,5` / `add x1,x0,x0` | No se escribe ni se adelanta nunca | 0 |
| Load con destino x0 | `lw x0,0(x2)` / `add x1,x0,x0` | No hay stall (`idex_rd != 0` falla); la DMEM se lee pero el dato se descarta | 0 |
| `jal`/`jalr` con destino x0 | `jal x0,f` (`j f`) / `add x1,x0,..` | No se adelanta `PC + 4`; x0 sigue en 0 | 0 |
| Lectura de x0 mientras se "escribe" x0 | WB con `rd = 0` / ID lee x0 | El bypass también exige `rd != 0`, así que devuelve 0 | 0 |

#### El caso de x0

x0 vale siempre 0 aunque una instrucción lo tenga como destino. Eso se cuida en cuatro lugares: los tres primeros hacen falta para que el resultado sea correcto y el cuarto evita un stall innecesario.

| Lugar | Condición | Si faltara |
|---|---|---|
| Banco de registros | Escribe solo si `rd != 0`, y x0 no tiene registro: su lectura es la constante 0 | `addi x0,x0,5` dejaría un 5 en x0 |
| Bypass del banco | Solo si `rd != 0` | Una lectura de x0 en ID devolvería el dato que WB intenta escribir en x0 |
| Unidad de forwarding | `exmem_rd != 0`, `memwb_rd != 0` | `addi x0,x0,5` / `add x1,x0,x0` adelantaría el 5 y daría `x1 = 10` |
| Detección de load-use | `idex_rd != 0` | `lw x0,..` seguido de algo que lee x0 frenaría un ciclo sin necesidad (sería correcto pero más lento) |

Las instrucciones que no leen un registro tienen `rs = 0` (lo pone el decodificador), así que la condición `rd != 0` también evita que coincidan por accidente con un productor que escribe x0.

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
stall = ifid_valid && idex_valid && idex_mem_read && idex_rd != 0 &&
        ((id_use_rs1 && idex_rd == id_rs1) || (id_use_rs2 && idex_rd == id_rs2))
```

`id_use_rs1` e `id_use_rs2` salen del decodificador y valen 1 solo si la instrucción realmente lee ese registro. Así un `addi`, cuyos bits [24:20] son parte del inmediato, no provoca stalls falsos. `ifid_valid` evita frenar por una burbuja en ID, que no va a usar ningún dato.

| Instrucción | Usa rs1 | Usa rs2 |
|---|---|---|
| Tipo R | Sí | Sí |
| Tipo I aritméticas, loads, `jalr` | Sí | No |
| Stores, branches | Sí | Sí |
| `lui`, `jal`, HALT | No | No |

Cuando `stall = 1`: el PC y IF/ID no se actualizan y ID/EX recibe una burbuja (`idex_valid = 0`). EX/MEM y MEM/WB avanzan normalmente, así que en el ciclo siguiente el load está en MEM/WB y el consumidor, todavía en ID, pasa a EX y toma el dato con el forwarding desde MEM/WB.

Ciclo a ciclo, para `lw x1,0(x2)` / `add x3,x1,x4`:

| Ciclo | IF | ID | EX | MEM | WB |
|---|---|---|---|---|---|
| 1 | `lw` | | | | |
| 2 | `add` | `lw` | | | |
| 3 | sig. | `add` | `lw` → **stall** | | |
| 4 | sig. | `add` | burbuja | `lw` | |
| 5 | sig.+1 | sig. | `add` ← MEM/WB | burbuja | `lw` |

Un stall y un flush no pueden pedirse en el mismo ciclo: el stall exige un load en EX y el flush un salto tomado en EX.

#### Banco de registros: escritura y lectura en el mismo ciclo

En el ciclo en que una instrucción está en WB escribiendo `rd`, la instrucción que está en ID puede estar leyendo ese mismo registro (distancia 3). El libro lo resuelve escribiendo en la primera mitad del ciclo y leyendo en la segunda; en una FPGA eso obliga a usar el flanco negativo para la escritura, lo que parte el ciclo a la mitad para los caminos que pasan por el banco y complica el análisis de tiempo. Las opciones fueron:

| Opción | Cómo funciona | Problema |
|---|---|---|
| Escribir en el flanco negativo | El registro ya tiene el valor nuevo cuando ID lo lee | Dos flancos en el mismo diseño; los caminos de WB y de ID tienen medio ciclo cada uno |
| Forwarding desde WB a ID con un multiplexor afuera del banco | Igual que el bypass, pero en el datapath | Es lo mismo con más señales sueltas |
| Bypass dentro del banco | Lectura combinacional que devuelve el dato de escritura si las direcciones coinciden | Ninguno: es un comparador y un multiplexor por puerto de lectura |

Se eligió el bypass dentro del banco:

```verilog
assign w_en       = i_enable && i_reg_write && (i_rd != 0);
assign o_rs1_data = (i_rs1 == 0)                ? 32'd0   :
                    (w_en && i_rs1 == i_rd)     ? i_wdata :
                                                  regs[i_rs1];
```

- 31 registros de 32 bits con flip-flops; `x0` no se guarda y su lectura devuelve siempre 0.
- Escritura en el flanco positivo si `enable && reg_write && rd != 0` (el `reg_write` que llega de WB ya incluye `memwb_valid`).
- Lectura combinacional con bypass: si la dirección leída coincide con la que se está escribiendo en ese ciclo y la escritura está habilitada (lo que incluye `rd != 0`), devuelve el dato de escritura.
- Tres puertos de lectura: rs1 y rs2 para ID, y uno para la Debug Unit. El de la Debug Unit no necesita bypass, porque se usa con el procesador detenido y entonces no hay escrituras.

**Justificación.** Es el esquema clásico del libro, con un solo stall posible (load-use) y sin forwarding hacia ID gracias a D4. El bypass del banco evita depender de escribir en la primera mitad del ciclo, que en FPGA obligaría a usar el flanco negativo.

---

## Control de ejecución sin intervenir el clock (#7)

### D7. Clock enable global

**Contexto.** La consigna prohíbe intervenir el reloj. Cortar el reloj con una compuerta (clock gating) agrega skew entre el procesador y la Debug Unit y puede generar glitches si la habilitación cambia con el reloj en alto.

**Decisión.** Un único reloj llega sin lógica a todos los flip-flops del diseño. La Debug Unit maneja una señal `cpu_enable` que entra al procesador como `i_enable` y habilita la carga de cada elemento de estado. Vivado la conecta al pin CE de los flip-flops (FDRE), así que no agrega lógica en el camino de datos.

**Módulos que reciben `i_enable`:**

| Elemento | Se actualiza cuando |
|---|---|
| PC | `enable && !stall` |
| IF/ID | `enable && !stall` (o burbuja si hay flush o HALT pendiente) |
| ID/EX | `enable` (burbuja si hay stall o flush) |
| EX/MEM | `enable` |
| MEM/WB | `enable` |
| Banco de registros | `enable && reg_write && rd != 0` |
| Memoria de datos | `enable && mem_write` |
| Flag de HALT pendiente | `enable` |

El banco y la DMEM también llevan el enable: así, con el procesador detenido, la instrucción que quedó en WB no reescribe su registro en cada ciclo y nada compite con las escrituras de la Debug Unit.

**Modos:**

| Modo | `cpu_enable` |
|---|---|
| Detenido | 0 |
| Continuo | 1 hasta que el procesador avisa HALT (`o_halt`) o vence el watchdog |
| Paso a paso | 1 durante exactamente un ciclo por cada comando de paso |

En paso a paso, la FSM de la Debug Unit tiene un estado que dura un ciclo en el que `cpu_enable = 1`, igual que `rd` y `wr` en el TP2. Después vuelve a 0 y manda el volcado.

La Debug Unit cuenta los ciclos con `cpu_enable = 1` (contador de 32 bits), que se informa en cada volcado.

### D8. Reset y escritura de la memoria de programa

**Resets.**

| Señal | Origen | Qué reinicia |
|---|---|---|
| `i_reset` | Botón BTNU de la placa, síncrono | Todo el diseño: UART, Debug Unit y procesador |
| `cpu_reset` | Debug Unit (comandos de carga y de reinicio) | Solo el procesador: PC = 0, `valid = 0` en los cuatro latches, banco de registros en 0, flag de HALT en 0, contador de ciclos en 0 |

El procesador recibe `i_reset | cpu_reset`. Todos los resets son síncronos y activos en alto, con prioridad sobre el enable.

Las memorias no se borran con reset (son RAM). La Debug Unit las limpia escribiendo ceros dirección por dirección, con el procesador detenido: 256 ciclos por memoria, unos 2,6 µs a 100 MHz.

**Escritura de la memoria de programa.** La IMEM tiene un puerto de escritura que solo maneja la Debug Unit. La FSM garantiza que solo escribe con `cpu_enable = 0`. La lectura de IF usa un puerto de lectura separado, así que no hay multiplexor en el camino de búsqueda.

**Secuencia del comando de carga:**

1. `cpu_enable = 0`.
2. `cpu_reset` durante un ciclo.
3. Limpiar IMEM y DMEM con ceros.
4. Recibir las N palabras y escribirlas en la IMEM desde la dirección 0.
5. Responder a la PC.

Esto responde las preguntas de la consigna sobre reprogramación:

| ¿Hay que vaciar...? | Respuesta |
|---|---|
| La memoria de datos | Sí. Si no, un programa que lee antes de escribir depende del programa anterior, y el volcado mostraría restos. |
| Los registros | Sí. Muchos programas asumen que arrancan en 0 (un acumulador, por ejemplo). Se hace con el reset en un ciclo. |
| El pipeline | Sí, es la más importante. Instrucciones viejas que queden en los latches terminarían su recorrido y escribirían el estado del programa nuevo. También hay que volver el PC a 0 y borrar el flag de HALT pendiente, o el programa nuevo nunca empieza. |
| La memoria de programa | No es necesario si el programa termina en HALT. Se limpia igual porque con D10 eso hace que un programa sin HALT se detenga solo. |

---

## Instrucción de parada (#8)

### D9. HALT

**Codificación.**

| Opción | Codificación | A favor | En contra |
|---|---|---|---|
| Opcode propio (`0xFFFFFFFF`) | Fuera de RV32I | Imposible de confundir | Un ensamblador estándar no lo genera |
| `ebreak` | `0x00100073` | Es la instrucción de RISC-V para devolverle el control a un depurador; el toolchain oficial la reconoce | Ninguno para este trabajo |

**Decisión.** HALT es `ebreak` (`0x00100073`). En el ensamblador se puede escribir `halt` o `ebreak`. Además, **cualquier instrucción que el decodificador no reconozca se trata como HALT**, incluida `0x00000000` (que RISC-V reserva como ilegal justamente para detectar ejecución de memoria vacía).

**Etapa de detección.** El decodificador la detecta en ID. Desde ese momento:

1. En el flanco siguiente se activa el flag `halt_pending`. Mientras está activo, el PC no avanza e IF/ID recibe burbujas: no entra ninguna instrucción nueva.
2. La instrucción HALT sigue avanzando con su bit `halt = 1` y todas sus señales de escritura en 0.
3. Cuando llega a MEM/WB, el procesador activa `o_halt = memwb_valid && memwb_halt`. En ese momento todas las instrucciones anteriores ya completaron WB y detrás solo hay burbujas: el pipeline está vacío.
4. La Debug Unit ve `o_halt`, deja `cpu_enable = 0` y manda el volcado.

| Instrucción | c1 | c2 | c3 | c4 | c5 | c6 | c7 |
|---|---|---|---|---|---|---|---|
| `add x3,x1,x2` | IF | ID | EX | MEM | WB | | |
| `sw x3,0(x0)` | | IF | ID | EX | MEM | WB | |
| `halt` | | | IF | ID | EX | MEM | WB → `o_halt` |
| siguiente (se anula) | | | | ~~IF~~ | | | |
| (burbujas) | | | | | ID | EX | MEM |

**HALT especulativo.** Si el HALT entra detrás de un salto que resulta tomado, el flush lo anula y también borra `halt_pending` (D5). Así un HALT que nunca debió ejecutarse no detiene el procesador. Ejemplo típico:

```asm
loop: ...
      bne x1, x0, loop
      halt              # se busca mientras el bne está en EX; si salta, se descarta
```

**Paso a paso después del HALT.** Si llega un comando de paso o de correr con el programa ya terminado, la Debug Unit no habilita el procesador y responde con el volcado y el estado "terminado" (ver [protocolo.md](protocolo.md)).

### D10. ¿Qué pasa si la memoria no tiene instrucción de parada?

**Sin protección,** el PC sigue avanzando más allá del programa y ejecuta lo que haya en la IMEM: restos de un programa anterior o ceros. Como el índice usa solo 8 bits, al pasar la última palabra vuelve a la dirección 0 y el programa se repite indefinidamente. En modo continuo la Debug Unit nunca vería el final y la PC esperaría el volcado para siempre.

**Con las decisiones de este diseño:**

1. El comando de carga limpia la IMEM con ceros (D8), y `0x00000000` se trata como HALT (D9). Un programa sin HALT se detiene en la primera palabra después de su última instrucción, con el pipeline vaciado igual que con un HALT normal.
2. Un **watchdog** en la Debug Unit cubre el caso que lo anterior no detecta: un bucle infinito dentro del propio programa. Si en modo continuo se superan `WATCHDOG_CYCLES` ciclos (parámetro, por defecto 2^20 ≈ 1 millón, unos 10 ms a 100 MHz), la Debug Unit detiene el procesador y manda el volcado con el estado "watchdog".

El volcado indica por qué terminó la ejecución (HALT, instrucción ilegal o watchdog), así la interfaz puede avisar que el programa no tenía instrucción de parada.
