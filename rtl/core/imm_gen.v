`timescale 1ns / 1ps
`default_nettype none // Desactiva la creacion automatica de wire, usar un nombre no declarado es un error de compilacion
// Generador de inmediatos: arma el inmediato de 32 bits según imm_sel
// (I, S, B, U, J), con los formatos de docs/datapath.md. B y J tienen el
// bit 0 en 0. Un imm_sel no válido da 0.

`include "riscv_defs.vh"

module imm_gen
(
    input  wire [31:0]  i_instr,
    input  wire [2:0]   i_imm_sel,
    output reg  [31:0]  o_imm
);

    always @(*)
    begin
        case (i_imm_sel)
            `IMM_I  : o_imm = {{20{i_instr[31]}}, i_instr[31:20]};
            `IMM_S  : o_imm = {{20{i_instr[31]}}, i_instr[31:25], i_instr[11:7]};
            `IMM_B  : o_imm = {{19{i_instr[31]}}, i_instr[31], i_instr[7], i_instr[30:25], i_instr[11:8], 1'b0};
            `IMM_U  : o_imm = {i_instr[31:12], 12'b0};
            `IMM_J  : o_imm = {{11{i_instr[31]}}, i_instr[31], i_instr[19:12], i_instr[20], i_instr[30:21], 1'b0};
            default : o_imm = 32'd0; // 101-111
        endcase
    end

endmodule
