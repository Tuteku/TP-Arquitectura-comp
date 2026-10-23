# Registros de segmentación (latches)

Issue: #6

Contenido exacto de IF/ID, ID/EX, EX/MEM y MEM/WB, con el ancho de cada campo, quién lo escribe y quién lo usa. Es el contrato entre el Verilog del procesador, la Debug Unit (que manda estos bits por UART) y la interfaz (que los decodifica para mostrarlos).

## Resumen

| Latch | Bits | Bytes en el volcado |
|---|---|---|
| IF/ID | 97 | 13 |
| ID/EX | 194 | 25 |
| EX/MEM | 112 | 14 |
| MEM/WB | 107 | 14 |
| **Total** | **510** | **66** |

## Reglas comunes

- Cada latch tiene un bit `valid`. Con `valid = 0` el contenido se ignora: la instrucción no escribe registros ni memoria, no salta, no genera forwarding ni HALT. Así se implementan las burbujas de stall y de flush (ver [decisiones.md, D5](decisiones.md#d5-predicción-no-tomado-y-flush)).
- El reset del procesador pone `valid = 0` en los cuatro latches. El resto de los campos queda en 0 también, para que el volcado sea limpio.
- Todos los latches se actualizan solo con `i_enable = 1`. IF/ID además mantiene su valor durante un stall.
- Las señales de control se generan una sola vez en ID. Cada latch lleva solamente las que usa alguna etapa posterior.

## Empaquetado para el volcado

Cada latch se concatena en un vector con el primer campo de la tabla en el bit 0:

```verilog
assign ifid_vec  = {ifid_instr, ifid_pc4, ifid_pc, ifid_valid};   // 97 bits
```

En el volcado se manda el vector completo de cada latch, rellenado con ceros hasta un número entero de bytes, empezando por el byte menos significativo (bits `[7:0]` primero). El orden de los latches y el resto de la trama están en [protocolo.md](protocolo.md).

Si se agrega o cambia un campo, hay que actualizar a la vez esta tabla, el Verilog y el decodificador de la interfaz. Para que los rangos de bits no se desalineen, conviene que la lista de campos viva en un solo lugar del software (por ejemplo `sw/interfaz/latches.py`) y que tanto la interfaz como un script que regenere esta tabla la lean de ahí.

## IF/ID

97 bits, se envían en 13 bytes (7 bits de relleno en 0).

| Bits | Campo | Ancho | Lo escribe | Lo usa | Nota |
|---|---|---|---|---|---|
| `[0]` | `ifid_valid` | 1 | IF | ID, Debug Unit | 0 = burbuja (flush, HALT pendiente o reset) |
| `[32:1]` | `ifid_pc` | 32 | IF | EX (destino de salto) | Dirección de la instrucción |
| `[64:33]` | `ifid_pc4` | 32 | IF | WB (link de jal/jalr) | PC + 4 |
| `[96:65]` | `ifid_instr` | 32 | IMEM | ID | Instrucción de 32 bits |

## ID/EX

194 bits, se envían en 25 bytes (6 bits de relleno en 0).

| Bits | Campo | Ancho | Lo escribe | Lo usa | Nota |
|---|---|---|---|---|---|
| `[0]` | `idex_valid` | 1 | ID | EX, forwarding, riesgos | 0 = burbuja |
| `[32:1]` | `idex_pc` | 32 | IF/ID | EX | Para PC + imm |
| `[64:33]` | `idex_pc4` | 32 | IF/ID | WB |  |
| `[96:65]` | `idex_rs1_data` | 32 | Banco | EX | Valor leído de rs1 (antes del forwarding) |
| `[128:97]` | `idex_rs2_data` | 32 | Banco | EX | Valor leído de rs2 (antes del forwarding) |
| `[160:129]` | `idex_imm` | 32 | Gen. inmediato | EX | Inmediato extendido a 32 bits |
| `[165:161]` | `idex_rs1` | 5 | Decodificador | Forwarding | 0 si la instrucción no usa rs1 |
| `[170:166]` | `idex_rs2` | 5 | Decodificador | Forwarding | 0 si la instrucción no usa rs2 |
| `[175:171]` | `idex_rd` | 5 | instr[11:7] | Riesgos, WB |  |
| `[178:176]` | `idex_funct3` | 3 | instr[14:12] | EX (beq/bne), MEM (tamaño) |  |
| `[182:179]` | `idex_alu_ctrl` | 4 | Control ALU | EX | Ver datapath.md |
| `[183]` | `idex_alu_src` | 1 | Control | EX | 0 = rs2, 1 = inmediato |
| `[184]` | `idex_branch` | 1 | Control | EX |  |
| `[185]` | `idex_jump` | 1 | Control | EX | jal |
| `[186]` | `idex_jalr` | 1 | Control | EX |  |
| `[187]` | `idex_mem_read` | 1 | Control | Riesgos, MEM | Es un load |
| `[188]` | `idex_mem_write` | 1 | Control | MEM |  |
| `[189]` | `idex_reg_write` | 1 | Control | Forwarding, WB |  |
| `[191:190]` | `idex_result_src` | 2 | Control | Forwarding, WB | 00 ALU, 01 MEM, 10 PC4 |
| `[192]` | `idex_halt` | 1 | Decodificador | MEM/WB | Instrucción de parada (ebreak o ilegal) |
| `[193]` | `idex_illegal` | 1 | Decodificador | Debug Unit | 1 si el HALT vino de una instrucción ilegal |

## EX/MEM

112 bits, se envían en 14 bytes (0 bits de relleno en 0).

| Bits | Campo | Ancho | Lo escribe | Lo usa | Nota |
|---|---|---|---|---|---|
| `[0]` | `exmem_valid` | 1 | EX | MEM, forwarding |  |
| `[32:1]` | `exmem_alu_result` | 32 | ALU | MEM (dirección), forwarding, WB |  |
| `[64:33]` | `exmem_store_data` | 32 | Mux ForwardB | MEM | Dato a guardar, ya adelantado |
| `[96:65]` | `exmem_pc4` | 32 | ID/EX | Forwarding, WB |  |
| `[101:97]` | `exmem_rd` | 5 | ID/EX | Forwarding, WB |  |
| `[104:102]` | `exmem_funct3` | 3 | ID/EX | MEM | Tamaño y signo del acceso |
| `[105]` | `exmem_mem_read` | 1 | ID/EX | MEM |  |
| `[106]` | `exmem_mem_write` | 1 | ID/EX | MEM |  |
| `[107]` | `exmem_reg_write` | 1 | ID/EX | Forwarding, WB |  |
| `[109:108]` | `exmem_result_src` | 2 | ID/EX | Forwarding, WB |  |
| `[110]` | `exmem_halt` | 1 | ID/EX | MEM/WB |  |
| `[111]` | `exmem_illegal` | 1 | ID/EX | MEM/WB |  |

## MEM/WB

107 bits, se envían en 14 bytes (5 bits de relleno en 0).

| Bits | Campo | Ancho | Lo escribe | Lo usa | Nota |
|---|---|---|---|---|---|
| `[0]` | `memwb_valid` | 1 | MEM | WB, forwarding, HALT |  |
| `[32:1]` | `memwb_alu_result` | 32 | EX/MEM | WB |  |
| `[64:33]` | `memwb_mem_data` | 32 | Alinear y extender | WB | Dato leído, ya extendido |
| `[96:65]` | `memwb_pc4` | 32 | EX/MEM | WB |  |
| `[101:97]` | `memwb_rd` | 5 | EX/MEM | WB, forwarding |  |
| `[102]` | `memwb_reg_write` | 1 | EX/MEM | WB, forwarding |  |
| `[104:103]` | `memwb_result_src` | 2 | EX/MEM | WB |  |
| `[105]` | `memwb_halt` | 1 | EX/MEM | Salida o_halt | o_halt = valid && halt |
| `[106]` | `memwb_illegal` | 1 | EX/MEM | Debug Unit |  |
## Ejemplo de lectura

Volcado del ejemplo de la guía, con `add x3, x1, x2` (`0x002081B3`) en la dirección `0x08` recién buscada, o sea en IF/ID:

| Campo | Valor |
|---|---|
| `ifid_valid` | 1 |
| `ifid_pc` | `0x00000008` |
| `ifid_pc4` | `0x0000000C` |
| `ifid_instr` | `0x002081B3` |

Vector de 97 bits = `{0x002081B3, 0x0000000C, 0x00000008, 1}`. Los primeros bytes enviados son `0x11 0x00 0x00 0x00` (el bit 0 es `valid` y los bits `[32:1]` son el PC, así que `0x08 << 1 | 1 = 0x11`).
