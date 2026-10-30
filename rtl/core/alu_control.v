`timescale 1ns / 1ps
`default_nettype none // Desactiva la creacion automatica de wire, usar un nombre no declarado es un error de compilacion
// Control de la ALU: arma alu_ctrl a partir de alu_op, funct3 y el bit 30 de
// la instrucción (docs/datapath.md). En tipo I el bit 30 solo cuenta en
// srli/srai; en addi es parte del inmediato. alu_op = 01 no se usa y da ADD.

`include "riscv_defs.vh"

module alu_control
(
    input  wire [1:0]   i_alu_op,
    input  wire [2:0]   i_funct3,
    input  wire         i_instr30,
    output reg  [3:0]   o_alu_ctrl
);

    always @(*)
    begin
        case (i_alu_op)
            `ALUOP_RTYPE : o_alu_ctrl = {i_instr30, i_funct3};
            `ALUOP_ITYPE : o_alu_ctrl = (i_funct3 == `F3_SRL_SRA) ? {i_instr30, i_funct3}
                                                                  : {1'b0, i_funct3};
            default      : o_alu_ctrl = `ALU_ADD; // 00 y 01
        endcase
    end

endmodule
