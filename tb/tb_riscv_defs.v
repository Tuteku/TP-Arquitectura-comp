`timescale 1ns / 1ps
`default_nettype none // Nombre de variable no declarado hace que el compilador lo tome como error y no defina un wire.
// Verifica rtl/core/riscv_defs.vh: que el archivo se pueda incluir dos veces
// (guarda contra doble inclusión) y que los códigos sean coherentes entre sí,
// en particular que alu_ctrl = {instr[30], funct3} como supone alu_control.

`include "riscv_defs.vh"
`include "riscv_defs.vh"

module tb_riscv_defs;
    localparam [31:0] EBREAK = `INSTR_EBREAK;

    integer errores;

    task check(input [31:0] obtenido, input [31:0] esperado, input [8*24-1:0] nombre);
        begin
            if (obtenido !== esperado) begin // Un valor indefinido cuenta como distinto
                $display("  ERROR %0s: obtenido %h, esperado %h", nombre, obtenido, esperado);
                errores = errores + 1;
            end
        end
    endtask

    initial begin
        errores = 0;

        // alu_ctrl sale directo de {bit 30, funct3}
        check(`ALU_ADD,  {1'b0, `F3_ADD_SUB}, "ALU_ADD");
        check(`ALU_SUB,  {1'b1, `F3_ADD_SUB}, "ALU_SUB");
        check(`ALU_SLL,  {1'b0, `F3_SLL},     "ALU_SLL");
        check(`ALU_SLT,  {1'b0, `F3_SLT},     "ALU_SLT");
        check(`ALU_SLTU, {1'b0, `F3_SLTU},    "ALU_SLTU");
        check(`ALU_XOR,  {1'b0, `F3_XOR},     "ALU_XOR");
        check(`ALU_SRL,  {1'b0, `F3_SRL_SRA}, "ALU_SRL");
        check(`ALU_SRA,  {1'b1, `F3_SRL_SRA}, "ALU_SRA");
        check(`ALU_OR,   {1'b0, `F3_OR},      "ALU_OR");
        check(`ALU_AND,  {1'b0, `F3_AND},     "ALU_AND");

        // El bit 30 de la instrucción es el bit 5 de funct7
        check(`F7_BASE, 7'b0000000, "F7_BASE");
        check(`F7_ALT,  7'b0100000, "F7_ALT");
        check(`F7_ALT >> 5, 1, "F7_ALT[5]");

        // ebreak: opcode SYSTEM, funct3 0, imm 1
        check(EBREAK[6:0],   `OP_SYSTEM, "EBREAK opcode");
        check(EBREAK[14:12], 3'b000,     "EBREAK funct3");
        check(EBREAK[31:20], 12'd1,      "EBREAK imm");

        // Los loads sin signo son los con signo con funct3[2] = 1
        check(`F3_LBU, `F3_LB | 3'b100, "F3_LBU");
        check(`F3_LHU, `F3_LH | 3'b100, "F3_LHU");

        // funct3[0] distingue beq de bne
        check(`F3_BEQ, 3'b000, "F3_BEQ");
        check(`F3_BNE, 3'b001, "F3_BNE");

        if (errores == 0)
            $display("  RESULTADO        : TEST PASSED");
        else
            $display("  RESULTADO        : TEST FAILED (%0d errores)", errores);
        $finish;
    end
endmodule
