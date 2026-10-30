`timescale 1ns / 1ps
`default_nettype none // Desactiva la creacion automatica de wire, usar un nombre no declarado es un error de compilacion
// ALU de RV32I: las 10 operaciones de tipo R y tipo I con el código interno
// alu_ctrl = {instr[30], funct3} (docs/datapath.md, control de la ALU).
// No tiene salida zero: la comparación de los branches la hace branch_unit (D4).

`include "riscv_defs.vh"

module alu #(
    parameter NB_DATA = 32,
    parameter NB_OP   = 4
)
(
    input  wire [NB_DATA-1:0]   i_a,
    input  wire [NB_DATA-1:0]   i_b,
    input  wire [NB_OP-1:0]     i_alu_ctrl,
    output reg  [NB_DATA-1:0]   o_alu_result
);

    localparam NB_SHIFT = $clog2(NB_DATA);

    // Solo se usan los bits bajos de b como cantidad de desplazamiento
    wire [NB_SHIFT-1:0] shamt = i_b[NB_SHIFT-1:0];

    // Los puertos son sin signo; $signed() solo donde la operación lo necesita
    always @(*)
    begin
        case (i_alu_ctrl)
            `ALU_ADD  : o_alu_result = i_a + i_b;
            `ALU_SUB  : o_alu_result = i_a - i_b;
            `ALU_SLL  : o_alu_result = i_a << shamt;
            `ALU_SLT  : o_alu_result = {{(NB_DATA-1){1'b0}}, ($signed(i_a) < $signed(i_b))};
            `ALU_SLTU : o_alu_result = {{(NB_DATA-1){1'b0}}, (i_a < i_b)};
            `ALU_XOR  : o_alu_result = i_a ^ i_b;
            `ALU_SRL  : o_alu_result = i_a >> shamt;
            `ALU_SRA  : o_alu_result = $signed(i_a) >>> shamt;
            `ALU_OR   : o_alu_result = i_a | i_b;
            `ALU_AND  : o_alu_result = i_a & i_b;
            default   : o_alu_result = {NB_DATA{1'b0}}; // Sin x, para no propagarlas por el pipeline
        endcase
    end

endmodule
