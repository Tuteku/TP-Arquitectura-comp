# Trabajo Práctico N° 2: Comunicación UART

## Arquitectura de Computadoras

**Integrantes:** 
- De la Mata, Nicolás
- Quispe, Mateo

**Github**
- https://github.com/Tuteku/TP-Arquitectura-comp
---

## 1. Objetivo

Implementar un módulo UART sobre FPGA y usarlo para comunicar la ALU del trabajo anterior con una PC. La PC envía tres bytes por el puerto serie (operando A, operando B y opcode) y la placa responde con un byte con el resultado. El diseño debía ser parametrizable y cada módulo debía validarse con su propio test bench.

Se utilizó una **Digilent Basys3** (Artix-7 `xc7a35tcpg236-1`) y **Vivado 2025.2**.

---

## 2. Descripción general

El sistema se dividió en seis módulos:

- **baud_rate_generator**: genera un pulso (`tick`) a 16 veces la velocidad de transmisión.
- **uart_rx**: receptor. Detecta el bit de start, sobremuestrea cada bit y arma el byte.
- **uart_tx**: transmisor. Serializa un byte agregando los bits de start y stop.
- **uart_interface**: máquina de estados que guarda los tres bytes recibidos y ordena la transmisión del resultado.
- **alu**: la ALU del trabajo anterior, sin modificaciones.
- **top_level**: instancia y conecta los módulos anteriores.

![Diagrama de bloques](/assets/esquema_uart.png)

### 2.1 Formato de la trama y protocolo

Se usó el formato **8N1** (un bit de start en `0`, ocho bits de datos empezando por el LSB, sin paridad y un bit de stop en `1`) a **19200 baudios**, es decir unos 52 µs por bit.

```
 reposo  start  D0   D1   D2   D3   D4   D5   D6   D7   stop  reposo
 ‾‾‾‾‾‾\______/‾‾‾‾\____/‾‾‾‾\____/‾‾‾‾\____/‾‾‾‾\____/‾‾‾‾‾‾‾‾‾‾‾‾‾‾
```

| Orden | Sentido | Contenido |
|---|---|---|
| 1 | PC → FPGA | Operando A |
| 2 | PC → FPGA | Operando B |
| 3 | PC → FPGA | Opcode (6 bits menos significativos) |
| 4 | FPGA → PC | Resultado de la ALU |

## 3. Generador de baudios

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

Es un módulo contador `M` cuya salida `o_tick` vale `1` durante un ciclo cada vez que llega a `M-1`:

```verilog
localparam M        = (CLK_FREQ/(BAUD_RATE*16));
localparam NB_COUNT = $clog2(M);
```

Con 100 MHz y 19200 baudios resulta `M = 325` (325,52 truncado), lo que da una velocidad real de 19 230,8 baudios, un error de +0,16 %. Como el receptor muestrea en el centro de cada bit, tolera hasta medio bit de desfase acumulado en la trama, así que este error no afecta la comunicación.

## 4. Receptor (`uart_rx`)

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

El receptor usa 16 ticks por bit. Al detectar el flanco de bajada del start cuenta 8 ticks para ubicarse en el **centro del bit de start**, y desde ahí cuenta de a 16, de modo que cada muestra cae en el centro del bit siguiente.

| Estado | Acción | Transición |
|---|---|---|
| `IDLE` | Espera que la línea baje a `0` | A `START` cuando `i_rx = 0` |
| `START` | Cuenta 8 ticks | A `DATA` cuando `s_reg = 7` |
| `DATA` | Cada 16 ticks desplaza `i_rx` dentro de `b_reg` | A `STOP` después del bit `NB_DATA-1` |
| `STOP` | Espera 16 ticks | A `IDLE`, generando `o_rx_done_tick` |

`s_reg` cuenta ticks, `n_reg` cuenta bits y `b_reg` es el registro de desplazamiento. Como llega primero el LSB, cada bit entra por la izquierda y el registro se desplaza a la derecha:

```verilog
b_next = {i_rx, b_reg[NB_DATA-1:1]};
```

## 5. Transmisor (`uart_tx`)

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

| Estado | Línea | Transición |
|---|---|---|
| `IDLE` | `1` | A `START` con `i_tx_start`, cargando `i_data` en `b_reg` |
| `START` | `0` | A `DATA` después de 16 ticks |
| `DATA` | `b_reg[0]` | Cada 16 ticks desplaza `b_reg`; a `STOP` después del bit `NB_DATA-1` |
| `STOP` | `1` | A `IDLE` después de 16 ticks, generando `o_tx_done` |

El byte se copia en `b_reg` al recibir `i_tx_start`, así que `i_data` puede cambiar durante la transmisión. Siempre se transmite el bit 0 del registro, que se desplaza a la derecha después de cada bit:

```verilog
o_tx_next = b_reg[0];
...
b_next = {1'b0, b_reg[NB_DATA-1:1]};
```

## 6. Interfaz con la ALU (`uart_interface`)

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

Reemplaza a los registros con enable del `alu_top` del trabajo anterior: en lugar de los botones, cada pulso `i_rx_done` carga el byte recibido en el registro que corresponde según el orden de llegada.

| Estado | Acción | Transición |
|---|---|---|
| `RX_A` | Guarda el primer byte en `reg_a` | A `RX_B` con `i_rx_done` |
| `RX_B` | Guarda el segundo byte en `reg_b` | A `RX_OP` con `i_rx_done` |
| `RX_OP` | Guarda los 6 bits bajos del tercer byte en `reg_op` | A `TX_SEND` con `i_rx_done` |
| `TX_SEND` | Copia la salida de la ALU en `data_tx` y genera `tx_start` | A `TX_WAIT` |
| `TX_WAIT` | Espera el fin de la transmisión | A `RX_A` con `i_tx_done` |

El estado `TX_SEND` existe para darle un ciclo a la ALU: al salir de `RX_OP` el opcode recién se escribe en `reg_op`, por lo que el resultado correcto aparece en el ciclo siguiente. Sin este estado se transmitiría el resultado con el opcode anterior.

## 7. Módulo `top_level`

Solo conecta los módulos. Un único generador de baudios alimenta al receptor y al transmisor, la salida del receptor entra a la interfaz, la interfaz alimenta a la ALU y el resultado vuelve por el transmisor.

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

Todos los parámetros se propagan a los submódulos, así que la velocidad o el ancho de datos se cambian desde un único lugar.

## 8. Decisiones de diseño

- **FSM con dos bloques `always`**: un bloque secuencial con los registros y el reset, y uno combinacional (`always @(*)`) que calcula el estado siguiente. Al inicio del bloque combinacional se asignan valores por defecto a todas las señales `_next`, lo que evita la inferencia de latches.
- **El tick como habilitación, no como reloj**: todo el diseño trabaja con el reloj de 100 MHz y el tick se consulta con `if (i_s_tick)`. Así hay un único dominio de reloj y el análisis de tiempo cubre todo el diseño.
- **Un único generador de baudios** compartido por receptor y transmisor.
- **Salida del transmisor registrada**: `o_tx` sale de un flip-flop (`o_tx_reg`), lo que evita glitches que la PC podría interpretar como un bit de start. El reset la deja en `1`.
- **Pulsos de un ciclo**: `o_rx_done_tick`, `o_tx_done` y `o_tx_start` duran un ciclo, por lo que cada byte produce exactamente una transición en la interfaz y cada orden de transmisión una sola trama.
- **Reset síncrono** activo en alto.

## 9. Interfaz con la placa

La Basys3 incluye un conversor USB-UART (FTDI FT2232), así que la comunicación usa el mismo cable USB de programación.

| Puerto | Pin | Elemento físico |
|---|---|---|
| `i_rx` | B18 | RsRx (PC → FPGA) |
| `o_tx` | A18 | RsTx (FPGA → PC) |
| `i_reset` | T18 | BTNU |
| `i_clk` | W5 | Oscilador de 100 MHz |

## 10. Verificación

| Test bench | Módulo | Qué verifica |
|---|---|---|
| `tb_uart_rx` | `uart_rx` | Recepción y armado de un byte |
| `tb_uart_tx` | `uart_tx` | Serialización de un byte en la línea |
| `tb_interface` | `uart_interface` | Secuencia A → B → Op y orden de transmisión |
| `tb_top_level` | `top_level` | Una operación completa por la línea serie |

En `tb_uart_rx` y `tb_uart_tx` el tick se genera dentro del propio banco cada 8 ciclos de reloj (en lugar de 325) para acortar la simulación. Como los módulos solo cuentan ticks, el comportamiento es el mismo:

```verilog
integer cnt = 0;
always @(posedge clk) begin
    if (cnt == 7) begin
        cnt    <= 0;
        s_tick <= 1;
    end
    else begin
        cnt    <= cnt + 1;
        s_tick <= 0;
    end
end
```

### 10.1 Receptor

El banco hace de transmisor. La `task` `send_bit` mantiene un valor en la línea durante 16 ticks:

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

Con ella se envía la trama de `0x4B` (`01001011`) y luego se muestra `o_dout`:

```verilog
data = 8'b01001011;
...
send_bit(0);                              // start
for (i = 0; i < 8; i = i + 1)
    send_bit(data[i]);                    // datos, D0 primero
send_bit(1);                              // stop

#200;
$display("Enviado 0x4B, recibido 0x%02h", dout);
```

Se eligió `0x4B` porque no es simétrico: si el receptor invirtiera el orden de los bits se obtendría `0xD2`.

### 10.2 Transmisor

El banco hace de receptor. Se da un pulso de un ciclo en `i_tx_start` con el dato `0x4B`, se espera el bit de start, se avanzan 8 ticks hasta su centro y se toma una muestra cada 16 ticks, igual que el `uart_rx`:

```verilog
@(negedge clk) tx_start = 1;
@(negedge clk) tx_start = 0;

wait (tx == 1'b0);
wait_ticks(8);
for (i = 0; i < 8; i = i + 1) begin
    wait_ticks(16);
    recibido[i] = tx;       // D0 sale primero
end

wait (tx_done == 1'b1);
$display("Enviado 0x%02h, en la linea 0x%02h", dato, recibido);
```

### 10.3 Interfaz

El receptor y el transmisor se reemplazan por estímulos directos y la ALU por una suma (`alu_result = alu_a + alu_b`). La `task` `rx_byte` simula la llegada de un byte con un pulso de un ciclo en `i_rx_done`:

```verilog
task rx_byte (input [7:0] valor);
    begin
        @(negedge clk);
        data    = valor;
        rx_done = 1;
        @(negedge clk);
        rx_done = 0;
        #30;
    end
endtask
```

Para mostrar el resultado un bloque `always`vigila `o_tx_start` e imprime los registros cada vez que se genera el pulso:

```verilog
always @(posedge clk) begin
    if (tx_start)
        $display("A=0x%02h  B=0x%02h  Op=0b%06b  ->  data_tx=0x%02h", alu_a, alu_b, alu_op, data_tx);
end
```

Se ejecutan dos operaciones seguidas, `0x05 + 0x03` y `0x10 + 0x20`. Entre ambas se simula el fin de la transmisión con un pulso de un ciclo en `i_tx_done`:

```verilog
rx_byte(8'h05);
rx_byte(8'h03);
rx_byte({2'b00, 6'b100000});

#100;                       // simular que el Tx transmite
@(negedge clk);
tx_done = 1;
```

La segunda operación comprueba que la máquina vuelve a `RX_A` después de `TX_WAIT`.

### 10.4 Sistema completo

El `top_level` se prueba solo a través de `i_rx` y `o_tx`, a 2 Mbaudios para acortar la simulación. La duración de un bit se calcula igual que en el generador de baudios, para tener en cuenta el truncamiento de la división:

```verilog
localparam M      = CLK_FREQ / (BAUD_SIM * 16);   // 3
localparam BIT_NS = M * 16 * 10;                  // 480 ns
```

Las `task` `send_byte` y `recv_byte` arman y leen las tramas con retardos de `BIT_NS`. `recv_byte` espera el flanco de bajada del start y avanza un bit y medio para muestrear en el centro de `D0`:

```verilog
task send_byte (input [7:0] dato);
    integer i;
    begin
        rx = 1'b0;                      // start
        #BIT_NS;
        for (i = 0; i < 8; i = i + 1) begin
            rx = dato[i];               // D0 primero
            #BIT_NS;
        end
        rx = 1'b1;                      // stop
        #BIT_NS;
    end
endtask

task recv_byte (output [7:0] dato);
    integer i;
    begin
        @(negedge tx);                  // start bit
        #(BIT_NS + BIT_NS/2);           // caer en el medio de D0
        for (i = 0; i < 8; i = i + 1) begin
            dato[i] = tx;
            #BIT_NS;
        end
    end
endtask
```

El envío y la recepción se lanzan en paralelo con un `fork ... join`:

```verilog
fork
    // escucha la respuesta desde antes de que llegue
    recv_byte(resultado);

    // manda los tres bytes
    begin
        send_byte(8'h05);
        #(BIT_NS*2);
        send_byte(8'h03);
        #(BIT_NS*2);
        send_byte({2'b00, 6'b100000});
    end
join

$display("A=0x05  B=0x03  ->  respuesta=0x%02h (esperado 0x08)", resultado);
```

Esto es necesario porque el receptor genera `o_rx_done_tick` en la mitad del bit de stop, y el transmisor empieza a responder antes de que termine `send_byte`. Si `recv_byte` se llamara después del envío, se perdería el flanco de bajada del start.

### 10.5 Resultados

`tb_uart_rx`: el byte recibido coincide con el enviado.

![tb_uart_rx](/assets/tb_uart_rx.png)

`tb_uart_tx`: el byte reconstruido desde la línea coincide con el dato de entrada.

![tb_uart_tx](/assets/tb_uart_tx.png)

`tb_interface`: la operacion devuelve `0x08`, lo que confirma la secuencia de carga.

![tb_interface](/assets/tb_interface.png)

`tb_top_level`: la respuesta en `o_tx` es `0x08`, el resultado de 5 + 3.

![tb_top_level](/assets/tb_top_level.png)

## 11. Conclusiones

Se implementó una UART completa (receptor, transmisor y generador de baudios) y se la usó para controlar la ALU del trabajo anterior desde una PC. Se validó cada módulo por separado y luego el sistema completo a través de la línea serie.

- El sobremuestreo x16 con muestreo en el centro de cada bit permite recibir datos de un transmisor con un reloj desconocido, tolerando diferencias de velocidad de varios puntos porcentuales.
- Usar el tick como habilitación mantiene todo el diseño en un único dominio de reloj.
- Separar las FSM en dos bloques `always` con valores por defecto hace el código más claro y evita latches.
- El estado `TX_SEND` muestra la importancia de saber en qué ciclo se actualiza cada registro.
- La parametrización permitió reutilizar la ALU sin cambios y simular el sistema completo a 2 Mbaudios modificando un solo parámetro.
