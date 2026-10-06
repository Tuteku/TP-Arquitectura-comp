# Trabajo Práctico N° 2: Comunicación UART

## Arquitectura de Computadoras

**Integrantes:** 
- De la Mata, Nicolás
- Quispe, Mateo

---

## 1. Objetivo

El trabajo consistió en implementar un módulo UART (Universal Asynchronous Receiver-Transmitter) sobre FPGA y utilizarlo para comunicar la ALU desarrollada en el trabajo anterior con una PC. En lugar de cargar los operandos y el código de operación desde los switches y leer el resultado en los LEDs, ahora la PC envía tres bytes por el puerto serie (operando A, operando B y opcode) y la placa responde con un byte que contiene el resultado de la operación.

Se pedía además que el diseño fuera parametrizable, que cada módulo se validara mediante su propio test bench y que la comunicación se verificara de punta a punta en simulación.

La placa utilizada fue nuevamente una **Digilent Basys3**, con FPGA Xilinx Artix-7 (`xc7a35tcpg236-1`), y el entorno de desarrollo fue **Vivado 2025.2**.

---

## 2. Descripción general del diseño

El sistema se dividió en seis módulos:

- **baud_rate_generator**: un contador que genera un pulso de un ciclo (`tick`) a 16 veces la velocidad de transmisión. Es la base de tiempo común del receptor y del transmisor.
- **uart_rx**: el receptor. Detecta el bit de start en la línea, sobremuestrea cada bit y arma el byte recibido.
- **uart_tx**: el transmisor. Serializa un byte agregándole los bits de start y de stop.
- **uart_interface**: la máquina de estados que hace de puente entre la UART y la ALU. Guarda los tres bytes recibidos y, una vez completos, ordena la transmisión del resultado.
- **alu**: la misma ALU del trabajo anterior, reutilizada sin modificaciones.
- **top_level**: el nivel superior, que instancia y conecta los cinco módulos anteriores.

### 2.1 Diagrama de bloques

![alt text](/assets/esquema_uart.png)

### 2.2 Formato de la trama

Se utilizó el formato más habitual, **8N1**: un bit de start en `0`, ocho bits de datos comenzando por el menos significativo, sin bit de paridad y un bit de stop en `1`. En reposo la línea se mantiene en `1`.

```
 reposo  start  D0   D1   D2   D3   D4   D5   D6   D7   stop  reposo
 ‾‾‾‾‾‾\______/‾‾‾‾\____/‾‾‾‾\____/‾‾‾‾\____/‾‾‾‾\____/‾‾‾‾‾‾‾‾‾‾‾‾‾‾
```

La velocidad elegida fue de **19200 baudios**, de modo que cada bit dura aproximadamente 52 µs y una trama completa de 10 bits unos 520 µs.

### 2.3 Protocolo con la PC

Una operación completa está formada por cuatro tramas:

| Orden | Sentido | Contenido |
|---|---|---|
| 1 | PC → FPGA | Operando A (8 bits) |
| 2 | PC → FPGA | Operando B (8 bits) |
| 3 | PC → FPGA | Opcode (los 6 bits menos significativos del byte) |
| 4 | FPGA → PC | Resultado de la ALU (8 bits) |

## 3. Generador de baudios

### 3.1 Interfaz

```verilog
module baud_rate_generator #(
        parameter CLK_FREQ  = 100000000,
        parameter BAUD_RATE = 19200
    )
    (
        input  wire i_clk,
        input  wire i_reset,
        output wire o_tick   
    );
```

### 3.2 Funcionamiento

El módulo es un contador módulo `M` que se reinicia al llegar a `M-1`, y la salida `o_tick` vale `1` únicamente durante ese ciclo. El valor de `M` y el ancho del contador se calculan a partir de los parámetros:

```verilog
localparam M        = (CLK_FREQ/(BAUD_RATE*16));
localparam NB_COUNT = $clog2(M);
```

Con un reloj de 100 MHz y 19200 baudios:

| Magnitud | Valor |
|---|---|
| `M` = 100 000 000 / (19200 × 16) | 325 (325,52 truncado) |
| `NB_COUNT` = `$clog2(325)` | 9 bits |
| Frecuencia de `tick` | 307 692 Hz |
| Velocidad real = 100 MHz / (325 × 16) | 19 230,8 baudios |
| Error respecto de 19200 | +0,16 % |

El truncamiento de la división entera introduce un error de 0,16 %, muy por debajo de la tolerancia del protocolo. Como el muestreo se hace en el centro de cada bit, el receptor admite un desfase acumulado de medio bit a lo largo de los 10 bits de la trama, lo que equivale a alrededor de un 5 % de diferencia entre las velocidades de ambos extremos.

## 4. El receptor (`uart_rx`)

### 4.1 Interfaz

```verilog
module uart_rx #(
    parameter NB_DATA = 8,
    parameter SB_TICK = 16
)
(
    input  wire               i_s_tick,
    input  wire               i_clk,
    input  wire               i_reset,
    input  wire               i_rx,
    output wire [NB_DATA-1:0] o_dout,
    output wire               o_rx_done_tick       
);
```

### 4.2 Sobremuestreo

El receptor no conoce el reloj del transmisor, así que para ubicarse dentro de cada bit utiliza los ticks del generador de baudios, 16 por cada bit. Al detectar el flanco descendente del bit de start cuenta 8 ticks para posicionarse en el **centro del bit de start**, y a partir de ahí cuenta de a 16 ticks, con lo que cada muestra cae en el centro del bit siguiente. Muestrear en el centro es lo que da el margen frente a las diferencias de velocidad y a los flancos lentos de la línea.

### 4.3 Máquina de estados

El módulo se implementó como una FSMD con cuatro estados y tres registros de datos: `s_reg` cuenta los ticks dentro de un bit, `n_reg` cuenta los bits de datos recibidos y `b_reg` es el registro de desplazamiento donde se arma el byte.

| Estado | Acción | Transición |
|---|---|---|
| `IDLE` | Espera que la línea baje a `0` | A `START` cuando `i_rx = 0` |
| `START` | Cuenta 8 ticks hasta el centro del bit de start | A `DATA` cuando `s_reg = 7` |
| `DATA` | Cada 16 ticks desplaza `i_rx` dentro de `b_reg` | A `STOP` después del bit `NB_DATA-1` |
| `STOP` | Espera 16 ticks del bit de stop | A `IDLE`, generando `o_rx_done_tick` |

Como los datos llegan con el bit menos significativo primero, cada bit nuevo se ingresa por la izquierda y el registro se desplaza a la derecha. Después de ocho desplazamientos el primer bit recibido queda en la posición 0:

```verilog
b_next = {i_rx, b_reg[NB_DATA-1:1]};
```

La señal `o_rx_done_tick` dura un único ciclo de reloj y avisa a la interfaz que `o_dout` contiene un byte válido.

## 5. El transmisor (`uart_tx`)

### 5.1 Interfaz

```verilog
module uart_tx #(
    parameter NB_DATA = 8,
    parameter SB_TICK = 16
)
(
    input  wire [NB_DATA-1:0] i_data,
    input  wire               i_tx_start,
    input  wire               i_clk,
    input  wire               i_s_tick,
    input  wire               i_reset,   
    output wire               o_tx,
    output wire               o_tx_done      
);
```

### 5.2 Máquina de estados

El transmisor tiene la misma estructura que el receptor, con un registro adicional `o_tx_reg` que mantiene el nivel de la línea.

| Estado | Línea | Transición |
|---|---|---|
| `IDLE` | `1` | A `START` con `i_tx_start`, cargando `i_data` en `b_reg` |
| `START` | `0` | A `DATA` después de `SB_TICK` ticks |
| `DATA` | `b_reg[0]` | Cada `SB_TICK` ticks desplaza `b_reg`; a `STOP` después del bit `NB_DATA-1` |
| `STOP` | `1` | A `IDLE` después de `SB_TICK` ticks, generando `o_tx_done` |

En este caso no hace falta posicionarse en el centro de los bits, el transmisor simplemente mantiene cada nivel durante 16 ticks. El byte se copia en `b_reg` en el momento en que llega `i_tx_start`, por lo que la entrada `i_data` puede cambiar durante la transmisión sin afectar la trama en curso. Durante el estado `DATA` siempre se transmite el bit 0 del registro, que se desplaza a la derecha después de cada bit:

```verilog
o_tx_next = b_reg[0];
...
b_next = {1'b0, b_reg[NB_DATA-1:1]};
```

## 6. La interfaz con la ALU (`uart_interface`)

### 6.1 Interfaz

```verilog
module uart_interface #(
    parameter NB_DATA = 8,
    parameter NB_OP   = 6
)
(
    input  wire [NB_DATA-1:0] i_data,
    input  wire               i_rx_done,
    input  wire               i_clk,
    input  wire               i_tx_done,
    input  wire               i_reset,
    input  wire [NB_DATA-1:0] i_data_alu,
    output wire [NB_DATA-1:0] o_data_tx,
    output wire               o_tx_start,
    output wire [NB_DATA-1:0] o_alu_a,
    output wire [NB_DATA-1:0] o_alu_b,
    output wire [NB_OP-1:0]   o_alu_op
);
```

### 6.2 Máquina de estados

Este módulo reemplaza a los tres registros con enable del `alu_top` del trabajo anterior. Los botones de carga se sustituyeron por los pulsos `i_rx_done` del receptor, y el orden de llegada de cada byte es lo que decide en qué registro se guarda.

| Estado | Acción | Transición |
|---|---|---|
| `RX_A` | Espera el primer byte y lo guarda en `reg_a` | A `RX_B` con `i_rx_done` |
| `RX_B` | Espera el segundo byte y lo guarda en `reg_b` | A `RX_OP` con `i_rx_done` |
| `RX_OP` | Espera el tercer byte y guarda sus 6 bits bajos en `reg_op` | A `TX_SEND` con `i_rx_done` |
| `TX_SEND` | Copia la salida de la ALU en `data_tx` y genera `tx_start` | A `TX_WAIT` incondicionalmente |
| `TX_WAIT` | Espera que el transmisor termine la trama | A `RX_A` con `i_tx_done` |

![alt text](/assets/fsm_interface.png)

El estado `TX_SEND` dura un único ciclo y existe para darle tiempo a la ALU. Cuando se sale de `RX_OP`, el opcode recién se escribe en `reg_op` en ese flanco de reloj, así que el resultado correcto aparece en la salida de la ALU recién en el ciclo siguiente. En `TX_SEND` los tres registros ya tienen sus valores definitivos y la salida combinacional de la ALU es estable, por lo que se la puede capturar sin riesgo.

## 7. El módulo `top_level`

El nivel superior no contiene lógica propia, solamente conecta los módulos. El generador de baudios alimenta con la misma señal de tick al receptor y al transmisor, la salida del receptor entra a la interfaz, los registros de la interfaz alimentan a la ALU y el resultado vuelve a la interfaz para ser enviado por el transmisor.

```verilog
module top_level #(
    parameter CLK_FREQ  = 100000000,
    parameter BAUD_RATE = 19200,
    parameter NB_DATA   = 8,
    parameter SB_TICK   = 16,
    parameter NB_OP     = 6    
)
(
    input  wire i_rx,
    input  wire i_clk,
    input  wire i_reset,
    output wire o_tx
);
```

Todos los parámetros se propagan hacia los módulos instanciados, de modo que cambiar el ancho de datos o la velocidad de transmisión se hace desde un único lugar.

## 8. Decisiones de diseño

### 8.1 Máquinas de estado con dos bloques `always`

Las tres máquinas de estado (`uart_rx`, `uart_tx` y `uart_interface`) se escribieron separando la parte secuencial de la combinacional. Un `always @(posedge i_clk)` contiene únicamente los registros y el reset, y un `always @(*)` calcula el estado siguiente y las salidas:

```verilog
always @(*) begin
    state_next = state_reg;
    s_next     = s_reg;
    n_next     = n_reg;
    b_next     = b_reg;
    rx_done_tick = 1'b0;
    case (state_reg)
        // ...
    endcase
end

always @(posedge i_clk) begin
    if (i_reset) begin
        state_reg <= IDLE;
        // ...
    end
    else begin
        state_reg <= state_next;
        // ...
    end
end
```

Al comienzo del bloque combinacional se asignan valores por defecto a todas las señales `_next`. De esta forma cada rama del `case` solo tiene que escribir lo que cambia, y se garantiza que ninguna señal quede sin asignar en algún camino, que es lo que provoca que el sintetizador infiera latches.

### 8.2 El tick como habilitación y no como reloj

La salida del generador de baudios no se usa como reloj de los otros módulos. Todos los registros del diseño trabajan con el mismo reloj de 100 MHz y el tick funciona como una señal de habilitación que se consulta dentro de la lógica (`if (i_s_tick)`). Generar un reloj derivado a partir de lógica obligaría a rutearlo por recursos que no son los dedicados al reloj, con skew difícil de controlar, y crearía un segundo dominio de reloj entre la UART y la interfaz. Con un único reloj todo el diseño es sincrónico y el análisis de tiempo lo cubre completo.

### 8.3 Un único generador de baudios compartido

Receptor y transmisor usan la misma base de tiempo, por lo que se instanció un solo generador y su salida se conectó a ambos. Esto ahorra un contador y asegura que las dos direcciones trabajen exactamente a la misma velocidad.

### 8.4 Salida del transmisor registrada

La línea `o_tx` sale directamente de un flip-flop (`o_tx_reg`) y no de lógica combinacional. Si la salida se calculara a partir del estado actual, en los cambios de estado podrían aparecer glitches que el receptor de la PC interpretaría como un flanco de start. Además el reset carga ese registro en `1`, de modo que la línea arranca en reposo.

### 8.5 Señales de control de un ciclo

`o_rx_done_tick`, `o_tx_done` y `o_tx_start` son pulsos de un solo ciclo de reloj. De este modo cada byte recibido produce exactamente una transición en la interfaz, y cada orden de transmisión produce exactamente una trama, sin necesidad de un protocolo adicional para bajar las señales.

### 8.6 Reutilización de la ALU

La ALU se instanció sin cambios, pasándole los mismos parámetros `NB_DATA` y `NB_OP` del nivel superior. Haberla parametrizado en el trabajo anterior es lo que permitió integrarla directamente.

### 8.7 Reset síncrono

Igual que en el trabajo anterior, todos los registros se reinician de forma sincrónica con una señal activa en alto. El reset lleva a las máquinas a su estado inicial (`IDLE` en la UART y `RX_A` en la interfaz), con la línea de transmisión en reposo.

## 9. Interfaz con la placa

La Basys3 incluye un conversor USB-UART (FTDI FT2232) conectado a la FPGA, por lo que la comunicación con la PC se hace a través del mismo cable USB que se usa para programarla.

| Puerto | Pin | Elemento físico |
|---|---|---|
| `i_rx` | B18 | RsRx (USB-UART, PC → FPGA) |
| `o_tx` | A18 | RsTx (USB-UART, FPGA → PC) |
| `i_reset` | T18 | BTNU |
| `i_clk` | W5 | Oscilador de 100 MHz |

## 10. Verificación

Se desarrolló un test bench para cada módulo con lógica propia y uno para el sistema completo:

| Test bench | Módulo bajo prueba | Qué verifica |
|---|---|---|
| `tb_uart_rx` | `uart_rx` | La recepción y el armado de un byte |
| `tb_uart_tx` | `uart_tx` | La serialización de un byte en la línea |
| `tb_interface` | `uart_interface` | La secuencia de carga A → B → Op y la orden de transmisión |
| `tb_top_level` | `top_level` | Una operación completa de punta a punta por la línea serie |

En los tres test benches de módulo el tick se genera dentro del propio banco cada 8 ciclos de reloj, en lugar de los 325 reales, para que la simulación sea más corta. Como el receptor y el transmisor solo cuentan ticks, el comportamiento es el mismo y únicamente cambia la escala de tiempo.

### 10.1 Test bench del receptor

El banco hace las veces del transmisor de la PC. Una `task` mantiene un valor en la línea durante 16 ticks, que es la duración de un bit:

```verilog
task send_bit (input valor);
    integer k;
    begin
        @(negedge clk);
        rx = valor;
        k = 0;
        while (k < 16) begin
            @(posedge clk);
            if (s_tick) k = k + 1;
        end
    end
endtask
```

Con esa `task` se arma la trama completa del byte `0x4B` (`01001011`): un bit de start, los ocho bits de datos empezando por `D0` y el bit de stop. Al terminar se imprime el contenido de `o_dout`. Se eligió `0x4B` porque no es simétrico, si el receptor ordenara los bits al revés se obtendría `0xD2`, por lo que el caso también verifica el orden de los bits.

### 10.2 Test bench del transmisor

En este caso el banco hace de receptor. Se aplica un pulso de un ciclo en `i_tx_start` con el dato `0x4B`, se espera la bajada de la línea que marca el bit de start y se avanzan 8 ticks para quedar en su centro. A partir de ahí se toma una muestra cada 16 ticks, que es exactamente el mismo procedimiento que sigue el `uart_rx`:

```verilog
wait (tx == 1'b0);
wait_ticks(8);
for (i = 0; i < 8; i = i + 1) begin
    wait_ticks(16);
    recibido[i] = tx;
end
wait (tx_done == 1'b1);
```

Por último se espera `o_tx_done` y se imprime el byte enviado junto al reconstruido a partir de la línea.

### 10.3 Test bench de la interfaz

Para aislar la máquina de estados se reemplazaron el receptor y el transmisor por estímulos directos, y la ALU por una suma combinacional (`alu_result = alu_a + alu_b`). Una `task` simula la llegada de un byte poniendo el dato en `i_data` y generando un pulso de un ciclo en `i_rx_done`:

```verilog
task rx_byte (input [7:0] valor);
    begin
        @(negedge clk);
        data    = valor;
        rx_done = 1;
        @(negedge clk);
        rx_done = 0;
        repeat (3) @(negedge clk);
    end
endtask
```

Se ejecutan dos operaciones consecutivas. En la primera se envían `0x05`, `0x03` y el opcode de la suma, se espera `o_tx_start` y se verifica que `o_data_tx` valga `0x08`. Luego se simula el fin de la transmisión con un pulso en `i_tx_done` y se repite con `0x10` y `0x20`, esperando `0x30`. La segunda operación es la que comprueba que la máquina vuelve correctamente a `RX_A` después de `TX_WAIT` y que puede procesar operaciones de forma continua.

### 10.4 Test bench del sistema completo

El último banco prueba el `top_level` exactamente como lo vería la PC, solo a través de las líneas `i_rx` y `o_tx`. Para acortar la simulación se instanció con una velocidad de 2 Mbaudios. El banco repite el mismo cálculo que hace el generador de baudios para obtener la duración real de un bit:

```verilog
localparam M      = CLK_FREQ / (BAUD_SIM * 16);   // 3
localparam BIT_NS = M * 16 * 10;                  // 480 ns
```

Calcularlo de esta forma, y no como `1/BAUD_SIM`, hace que el banco tenga en cuenta el truncamiento de la división entera. Si se usara el valor ideal de 500 ns, a esta velocidad el error de redondeo sería del 4 % y el banco quedaría desfasado del diseño.

Las tramas se envían y se leen con dos `task`, `send_byte` y `recv_byte`, que trabajan con retardos de `BIT_NS` en lugar de contar ticks. La lectura de la respuesta se lanza en paralelo con el envío mediante un `fork ... join`, para que el banco ya esté esperando el bit de start cuando el transmisor arranca:

```verilog
fork
    recv_byte(resultado);
    begin
        send_byte(8'h05);                  // A
        #(BIT_NS*2);
        send_byte(8'h03);                  // B
        #(BIT_NS*2);
        send_byte({2'b00, 6'b100000});     // Op (ADD)
    end
join
```

El valor esperado de la respuesta es `0x08`.

### 10.5 Resultados

En el `tb_uart_rx` el byte armado por el receptor coincide con el enviado:

![alt text](/assets/tb_uart_rx.png)

En el `tb_uart_tx` el byte reconstruido a partir de la línea coincide con el dato de entrada:

![alt text](/assets/tb_uart_tx.png)

En el `tb_interface` las dos operaciones devuelven `0x08` y `0x30`, confirmando la secuencia de carga y el regreso al estado inicial:

![alt text](/assets/tb_interface.png)

En el `tb_top_level` la respuesta obtenida en la línea `o_tx` es `0x08`, el resultado de 5 + 3:

![alt text](/assets/tb_top_level.png)

## 11. Conclusiones

Se implementó una UART completa, receptor, transmisor y generador de baudios, y se la utilizó para controlar la ALU del trabajo anterior desde una PC. La validación se hizo por módulos, aislando cada máquina de estados con su propio test bench, y finalmente sobre el sistema completo, interactuando con el diseño únicamente a través de la línea serie.

Del trabajo se desprenden algunas conclusiones sobre las decisiones de diseño:

- El sobremuestreo a 16 veces la velocidad de transmisión, junto con el muestreo en el centro de cada bit, es lo que permite recibir datos de un transmisor cuyo reloj no se conoce, tolerando diferencias de velocidad de varios puntos porcentuales.
- Usar el tick como habilitación y no como reloj mantiene todo el diseño en un único dominio de reloj, lo que simplifica tanto la síntesis como el análisis de tiempo.
- Separar las máquinas de estado en dos bloques `always`, con valores por defecto en la parte combinacional, hace que el código sea más fácil de leer y evita la inferencia de latches.
- El estado `TX_SEND` de la interfaz muestra la importancia de tener en cuenta en qué ciclo se actualiza cada registro, sin él se capturaría la salida de la ALU con el opcode anterior.
- La parametrización del trabajo anterior permitió reutilizar la ALU sin modificaciones, y la de este trabajo permite cambiar la velocidad de transmisión o el ancho de datos desde el `top_level`. Esto mismo se aprovechó en el test bench del sistema completo, que simula a 2 Mbaudios cambiando un único parámetro.

Como mejoras quedan pendientes agregar un sincronizador de dos flip-flops en la entrada `i_rx`, que llega de forma asincrónica respecto del reloj de la FPGA, y verificar en el receptor que el bit de stop efectivamente valga `1`, para poder detectar errores de trama.
