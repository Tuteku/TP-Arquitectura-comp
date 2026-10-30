`timescale 1ns / 1ps
`default_nettype none // Desactiva la creacion automatica de wire, usar un nombre no declarado es un error de compilacion
// Unidad de control principal (ID): pasa la instrucción a señales de control
// con la tabla de docs/datapath.md. Pone en 0 rs1 y rs2 cuando la instrucción
// no los usa (D6), y detecta el HALT (ebreak) y las instrucciones ilegales (D9).
// Una ilegal es un HALT con o_illegal = 1 y todas las señales de escritura y
// de salto en 0.

`include "riscv_defs.vh"

module decoder
(
    input  wire [31:0]  i_instr,
    output reg          o_reg_write,
    output reg  [2:0]   o_imm_sel,
    output reg          o_alu_src,
    output reg  [1:0]   o_alu_op,
    output reg          o_mem_read,
    output reg          o_mem_write,
    output reg  [1:0]   o_result_src,
    output reg          o_branch,
    output reg          o_jump,
    output reg          o_jalr,
    output wire [4:0]   o_rs1,
    output wire [4:0]   o_rs2,
    output reg          o_use_rs1,
    output reg          o_use_rs2,
    output reg          o_halt,
    output reg          o_illegal
);

    wire [6:0] opcode = i_instr[6:0];
    wire [2:0] funct3 = i_instr[14:12];
    wire [6:0] funct7 = i_instr[31:25];

    // Combinaciones implementadas dentro de cada opcode válido
    wire rtype_ok = (funct7 == `F7_BASE) ||
                    (funct7 == `F7_ALT && (funct3 == `F3_ADD_SUB || funct3 == `F3_SRL_SRA));
    wire imm_ok   = (funct3 == `F3_SLL)     ? (funct7 == `F7_BASE) :
                    (funct3 == `F3_SRL_SRA) ? (funct7 == `F7_BASE || funct7 == `F7_ALT) :
                                              1'b1;
    wire load_ok  = (funct3 == `F3_LB)  || (funct3 == `F3_LH) || (funct3 == `F3_LW) ||
                    (funct3 == `F3_LBU) || (funct3 == `F3_LHU);
    wire store_ok = (funct3 == `F3_SB)  || (funct3 == `F3_SH) || (funct3 == `F3_SW);
    wire branch_ok = (funct3 == `F3_BEQ) || (funct3 == `F3_BNE);

    // Una instrucción que no usa un registro lo ve como x0: así forwarding y
    // detección de riesgos no encuentran dependencias falsas, y lui suma x0 + imm.
    assign o_rs1 = o_use_rs1 ? i_instr[19:15] : 5'd0;
    assign o_rs2 = o_use_rs2 ? i_instr[24:20] : 5'd0;

    always @(*)
    begin
        // Por defecto, la fila "HALT o ilegal" de la tabla: nada escribe ni salta
        o_reg_write  = 1'b0;
        o_imm_sel    = `IMM_I;
        o_alu_src    = 1'b0;
        o_alu_op     = `ALUOP_ADD;
        o_mem_read   = 1'b0;
        o_mem_write  = 1'b0;
        o_result_src = `RES_ALU;
        o_branch     = 1'b0;
        o_jump       = 1'b0;
        o_jalr       = 1'b0;
        o_use_rs1    = 1'b0;
        o_use_rs2    = 1'b0;
        o_halt       = 1'b0;
        o_illegal    = 1'b0;

        case (opcode)
            `OP_RTYPE:
                if (rtype_ok) begin
                    o_reg_write = 1'b1;
                    o_alu_op    = `ALUOP_RTYPE;
                    o_use_rs1   = 1'b1;
                    o_use_rs2   = 1'b1;
                end
                else
                    o_illegal = 1'b1;

            `OP_IMM:
                if (imm_ok) begin
                    o_reg_write = 1'b1;
                    o_imm_sel   = `IMM_I;
                    o_alu_src   = 1'b1;
                    o_alu_op    = `ALUOP_ITYPE;
                    o_use_rs1   = 1'b1;
                end
                else
                    o_illegal = 1'b1;

            `OP_LOAD:
                if (load_ok) begin
                    o_reg_write  = 1'b1;
                    o_imm_sel    = `IMM_I;
                    o_alu_src    = 1'b1;
                    o_mem_read   = 1'b1;
                    o_result_src = `RES_MEM;
                    o_use_rs1    = 1'b1;
                end
                else
                    o_illegal = 1'b1;

            `OP_STORE:
                if (store_ok) begin
                    o_imm_sel   = `IMM_S;
                    o_alu_src   = 1'b1;
                    o_mem_write = 1'b1;
                    o_use_rs1   = 1'b1;
                    o_use_rs2   = 1'b1;
                end
                else
                    o_illegal = 1'b1;

            `OP_BRANCH:
                if (branch_ok) begin
                    o_imm_sel = `IMM_B;
                    o_branch  = 1'b1;
                    o_use_rs1 = 1'b1;
                    o_use_rs2 = 1'b1;
                end
                else
                    o_illegal = 1'b1;

            `OP_JAL: begin
                o_reg_write  = 1'b1;
                o_imm_sel    = `IMM_J;
                o_result_src = `RES_PC4;
                o_jump       = 1'b1;
            end

            `OP_JALR: begin
                o_reg_write  = 1'b1;
                o_imm_sel    = `IMM_I;
                o_alu_src    = 1'b1;
                o_result_src = `RES_PC4;
                o_jalr       = 1'b1;
                o_use_rs1    = 1'b1;
            end

            `OP_LUI: begin
                o_reg_write = 1'b1;
                o_imm_sel   = `IMM_U;
                o_alu_src   = 1'b1;
            end

            // ebreak es el único SYSTEM reconocido; ecall y el resto son ilegales
            `OP_SYSTEM:
                if (i_instr != `INSTR_EBREAK)
                    o_illegal = 1'b1;

            // Opcode desconocido, incluidos 0x00000000, auipc y fence
            default:
                o_illegal = 1'b1;
        endcase

        // ebreak e ilegal se distinguen solo por o_illegal
        o_halt = o_illegal || (i_instr == `INSTR_EBREAK);
    end

endmodule
