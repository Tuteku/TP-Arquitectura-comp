# Trabajo Práctico N° 1: Unidad Aritmético Lógica (ALU)

## Arquitectura de Computadoras

**Integrantes:** 
- De la Mata, Nicolás
- Quispe, Mateo


---

## 1. Objetivo

El trabajo consistió en implementar una ALU sobre FPGA, parametrizable en el ancho del bus de datos para poder reutilizarla en el resto de trabajos de la materia, y validarla mediante un test bench con generación de entradas aleatorias y chequeo automático de resultados. Adicionalmente se pedía simular el diseño con las herramientas de Vivado, incluyendo el análisis de tiempo.

La placa utilizada fue una **Digilent Basys3**, con FPGA Xilinx Artix-7 (`xc7a35tcpg236-1`), y el entorno de desarrollo fue **Vivado 2025.2**.

---

## 2. Descripción general del diseño

El sistema se dividió en dos módulos:

- **alu**: la unidad aritmético-lógica propiamente dicha. Es un bloque combinacional que recibe dos operandos y un código de operación, y devuelve el resultado.
- **alu_top**: el nivel superior, que conecta la ALU con la placa física. Contiene tres registros que capturan los operandos y el opcode desde los switches, e instancia la ALU.


### 2.1 Diagrama de bloques
![alt text](image-1.png)

## 3. El módulo ALU

### 3.1 Interfaz

```verilog
module alu #(
    parameter NB_DATA = 8,
    parameter NB_OP   = 6
)
(
    input  wire signed [NB_DATA-1:0] i_a,
    input  wire signed [NB_DATA-1:0] i_b,
    input  wire        [NB_OP-1:0]   i_op,
    output reg  signed [NB_DATA-1:0] o_alu
);
```

El parámetro `NB_DATA` define el ancho del bus de datos. `NB_OP` se mantuvo en 6 debido a los códigos de operación provistos por la cátedra.

### 3.2 Operaciones implementadas

| Operación | Código | Descripción |
|---|---|---|
| ADD | `100000` | Suma |
| SUB | `100010` | Resta |
| AND | `100100` | AND bit a bit |
| OR  | `100101` | OR bit a bit |
| XOR | `100110` | XOR bit a bit |
| SRA | `000011` | Desplazamiento derecha aritmético |
| SRL | `000010` | Desplazamiento derecha lógico |
| NOR | `100111` | NOR bit a bit |

## 4. Decisiones de diseño

### 4.1 Puertos declarados como `signed`

Los operandos y la salida se declararon `signed`. El desplazamiento aritmético solo extiende el signo si el operando está declarado con `signed`. Sin esa declaración las operaciones SRA y SRL producirían resultados idénticos.

### 4.2 Cantidad de desplazamiento acotada

En las operaciones de shift se utilizan únicamente los bits menos significativos de `i_b`:

```verilog
localparam NB_SHIFT = $clog2(NB_DATA);
...
SRA : o_alu = i_a >>> i_b[NB_SHIFT-1:0];
SRL : o_alu = i_a >>  i_b[NB_SHIFT-1:0];
```
La justificación es que desplazar un dato de 8 bits en 8 o más posiciones produce siempre el mismo resultado, por eso se definió que el campo de desplazamiento son los NB_SHIFT bits bajos de i_b. El ahorro de logica que produce esta decisión se cuantifica en la sección 7.1.

### 4.3 Comportamiento ante un código de operación inválido

El `case` cubre 8 de los 64 códigos posibles. En el caso del `default` se optó por:

```verilog
default: o_alu = {NB_DATA{1'bx}};
```

El valor `x` cumple dos funciones. En simulación se propaga y hace visible de inmediato cualquier situación en la que se esté decodificando un opcode no previsto. En síntesis, `x` significa "no importa" y le da libertad al optimizador para elegir la implementación que menos lógica consuma.

### 4.4 Registros con enables independientes

Los tres registros del `alu_top` se cargan mediante tres sentencias `if` independientes.

```verilog
if (i_load_a) r_a  <= i_switches;
if (i_load_b) r_b  <= i_switches;
if (i_load_c) r_op <= i_switches[NB_OP-1:0];
```

Esto es debido a que en los `if`, cada señal de carga llega directamente con el positivo del clock. Si se activan dos a la vez, ambos registros se cargan con el mismo valor.

### 4.5 Reset síncrono

Se incorporó un reset síncrono activo en alto, con prioridad sobre las cargas:

```verilog
always @(posedge i_clk) begin
    if (i_reset) begin
        r_a  <= {NB_DATA{1'b0}};
        r_b  <= {NB_DATA{1'b0}};
        r_op <= {NB_OP{1'b0}};
    end
    else begin
        // cargas
    end
end
```
## 5. Interfaz con la placa

El módulo `alu_top` conecta el diseño con los periféricos físicos de la Basys3.

| Puerto | Pines | Elemento físico |
|---|---|---|
| `i_switches[7:0]` | V2, T3, T2, R3, W2, U1, T1, R2 | SW8 a SW15 |
| `o_leds[7:0]` | V13, V3, W3, U3, P3, N3, P1, L1 | LD8 a LD15 |
| `i_load_a` | U17 | BTND |
| `i_load_b` | T17 | BTNR |
| `i_load_c` | W19 | BTNL |
| `i_reset` | T18 | BTNU |
| `i_clk` | W5 | Oscilador de 100 MHz |

## 6. Verificación

Se desarrollaron dos test benches con propósitos distintos:

| Test bench | Módulo bajo prueba | Qué verifica |
|---|---|---|
| `tb_alu` | `alu` | Las ocho operaciones, con chequeo automático |
| `tb_alu_top` | `alu_top` | La carga de los registros y la integración |


### 6.1 Estructura del chequeo automático

El test bench de la ALU se organizó en torno a una `task` que encapsula todo el procedimiento de verificación:

```verilog
task alu_task;
    input signed [NB_DATA-1:0] a;
    input signed [NB_DATA-1:0] b;
    input        [NB_OP-1:0]   op;
    begin
        i_a = a;  i_b = b;  i_op = op;
        #1
        case (op)
            ADD : esperado = a + b;
            SUB : esperado = a - b;
            // ...
        endcase
        casos = casos + 1;
        if (o_alu !== esperado) begin
            errores = errores + 1;
            $display("ERROR caso %0d: ...", casos, ...);
        end
    end
endtask
```

### 6.2 Resultados
**tb_alu:**
![alt text](image-2.png)
**tb_alu_top:**

## 7. Síntesis e implementación

### 7.1 Impacto de la optimización del desplazador

Para cuantificar el efecto de acotar la cantidad de desplazamiento (sección 4.2), se sintetizó el módulo `alu` con y sin la máscara utilizando el sintetizador Yosys, que reporta el conteo en compuertas genéricas:

![alt text](<Pasted image-1.png>)

| Versión | Celdas |
|---|---|
| Sin máscara (`i_b` completo) | 316 |
| Con máscara (`i_b[NB_SHIFT-1:0]`) | **263** |
| Reducción | 53 celdas (**16,8 %**) |

La diferencia corresponde a las cinco etapas de cada desplazador de barril que la máscara elimina.

Además la reducción de etapas acorta el camino combinacional, lo que se traduce en un menor retardo de propagación.

### 7.2 Análisis de tiempo



## 8. Conclusiones

Se implementó y verificó una ALU combinacional de ocho operaciones, parametrizable
en el ancho del bus de datos, que queda disponible como bloque reutilizable para los
trabajos siguientes de la materia. La validación se hizo en dos etapas, primero por
simulación, con un test bench de estímulos aleatorios que compara la salida contra un
modelo de referencia sobre 804 casos, y despues sobre la Basys3, donde el
comportamiento observado en los LEDs coincidió con el de la simulación.

Más allá del resultado funcional, el trabajo dejó algunas conclusiones sobre las
decisiones de diseño:

- La declaración `signed` de los puertos es un detalle importante ya que es lo que separa
  SRA de SRL. Sin ella, ambas operaciones son iguales.
- Acotar la cantidad de desplazamiento a `$clog2(NB_DATA)` bits es una decisión de
  especificación que permite darle uso al desplazamiento. Como beneficio adicional, redujo un 16,8 % la cantidad
  de celdas del diseño.
- El valor `x` en la rama `default` cumple dos funciones opuestas según el contexto en el que se encuentre,
  en simulación muestra de inmediato un opcode no contemplado, y en síntesis le da
  libertad al optimizador para elegir la implementación más económica.
- Parametrizar desde el principio tuvo un costo bajo y es lo que permite llevar el
  módulo a 16 o 32 bits sin modificar la lógica, que es la condición para poder
  reutilizarlo más adelante.

