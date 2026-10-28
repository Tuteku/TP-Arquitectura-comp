// Constantes del procesador RISC-V: opcodes, funct3, funct7 y códigos de las
// señales de control. Cada código se define una sola vez acá (convenciones.md);
// las tablas de donde salen están en docs/datapath.md.
//
// Forma elegida: macros `define, con guarda contra doble inclusión.
//
// La alternativa era un include de localparam que va adentro de cada módulo,
// pero no se puede combinar con la guarda: los `define son globales a toda la
// unidad de compilación (xvlog y la síntesis de Vivado procesan todos los
// archivos juntos), así que el primer módulo que incluyera el archivo
// definiría RISCV_DEFS_VH y los siguientes se quedarían sin las constantes.
// Con macros, la guarda funciona y el archivo se puede incluir en cualquier
// lugar y cualquier cantidad de veces.
//
// Uso:
//     `include "riscv_defs.vh"      (rtl/core está en include_dirs)
//     case (opcode)
//         `OP_RTYPE: ...
//
// Todas las macros llevan el ancho explícito, así se pueden usar en
// concatenaciones y comparaciones sin extensiones inesperadas.

`ifndef RISCV_DEFS_VH
`define RISCV_DEFS_VH

// ---------------------------------------------------------------------------
// Opcodes (instr[6:0])
// ---------------------------------------------------------------------------
`define OP_RTYPE        7'b0110011
`define OP_IMM          7'b0010011
`define OP_LOAD         7'b0000011
`define OP_STORE        7'b0100011
`define OP_BRANCH       7'b1100011
`define OP_JAL          7'b1101111
`define OP_JALR         7'b1100111
`define OP_LUI          7'b0110111
`define OP_SYSTEM       7'b1110011

// HALT: ebreak, la única instrucción de OP_SYSTEM que se reconoce
`define INSTR_EBREAK    32'h00100073

// ---------------------------------------------------------------------------
// funct3 (instr[14:12])
// ---------------------------------------------------------------------------
// Loads
`define F3_LB           3'b000
`define F3_LH           3'b001
`define F3_LW           3'b010
`define F3_LBU          3'b100
`define F3_LHU          3'b101

// Stores
`define F3_SB           3'b000
`define F3_SH           3'b001
`define F3_SW           3'b010

// Branches: funct3[0] distingue beq (0) de bne (1)
`define F3_BEQ          3'b000
`define F3_BNE          3'b001

// Operaciones aritméticas, comunes a tipo R y tipo I. add/sub y srl/sra
// comparten funct3 y se distinguen por funct7 (instr[30]).
`define F3_ADD_SUB      3'b000
`define F3_SLL          3'b001
`define F3_SLT          3'b010
`define F3_SLTU         3'b011
`define F3_XOR          3'b100
`define F3_SRL_SRA      3'b101
`define F3_OR           3'b110
`define F3_AND          3'b111

// ---------------------------------------------------------------------------
// funct7 (instr[31:25])
// ---------------------------------------------------------------------------
`define F7_BASE         7'b0000000      // add, srl, srli y el resto
`define F7_ALT          7'b0100000      // sub, sra, srai

// ---------------------------------------------------------------------------
// alu_ctrl: {instr[30], funct3}
// ---------------------------------------------------------------------------
`define ALU_ADD         4'b0000
`define ALU_SUB         4'b1000
`define ALU_SLL         4'b0001
`define ALU_SLT         4'b0010
`define ALU_SLTU        4'b0011
`define ALU_XOR         4'b0100
`define ALU_SRL         4'b0101
`define ALU_SRA         4'b1101
`define ALU_OR          4'b0110
`define ALU_AND         4'b0111

// ---------------------------------------------------------------------------
// alu_op: del decoder a alu_control
// ---------------------------------------------------------------------------
`define ALUOP_ADD       2'b00           // loads, stores, jalr, lui
`define ALUOP_RTYPE     2'b10
`define ALUOP_ITYPE     2'b11

// ---------------------------------------------------------------------------
// imm_sel: formato del inmediato en imm_gen
// ---------------------------------------------------------------------------
`define IMM_I           3'b000
`define IMM_S           3'b001
`define IMM_B           3'b010
`define IMM_U           3'b011
`define IMM_J           3'b100

// ---------------------------------------------------------------------------
// result_src: qué se escribe en rd en WB
// ---------------------------------------------------------------------------
`define RES_ALU         2'b00
`define RES_MEM         2'b01
`define RES_PC4         2'b10

`endif // RISCV_DEFS_VH
