`timescale 1ns / 1ps
`default_nettype none // Nombre de variable no declarado hace que el compilador lo tome como error y no defina un wire.
// Verifica alu_control: las 10 operaciones de tipo R y las 9 de tipo I, addi
// e inmediatos negativos (bit 30 en 1) que no se convierten en SUB, srli/srai,
// y alu_op = 00 y 01 que dan ADD con cualquier funct3 y bit 30.

`include "riscv_defs.vh"

module tb_alu_control;

    reg  [1:0]  i_alu_op;
    reg  [2:0]  i_funct3;
    reg         i_instr30;
    wire [3:0]  o_alu_ctrl;

    integer errores;
    integer i;

    alu_control u_alu_control (
        .i_alu_op(i_alu_op),
        .i_funct3(i_funct3),
        .i_instr30(i_instr30),
        .o_alu_ctrl(o_alu_ctrl)
    );

    task check(input [1:0] alu_op, input [2:0] funct3, input instr30, input [3:0] esperado);
        begin
            i_alu_op  = alu_op;
            i_funct3  = funct3;
            i_instr30 = instr30;
            #1;
            if (o_alu_ctrl !== esperado) begin // Un valor indefinido cuenta como distinto
                $display("  ERROR alu_op %b funct3 %b instr30 %b: obtenido %b, esperado %b",
                         alu_op, funct3, instr30, o_alu_ctrl, esperado);
                errores = errores + 1;
            end
        end
    endtask

    initial begin
        errores = 0;

        // Tipo R: las 10 operaciones
        check(`ALUOP_RTYPE, `F3_ADD_SUB, 1'b0, `ALU_ADD);   // add
        check(`ALUOP_RTYPE, `F3_ADD_SUB, 1'b1, `ALU_SUB);   // sub
        check(`ALUOP_RTYPE, `F3_SLL,     1'b0, `ALU_SLL);   // sll
        check(`ALUOP_RTYPE, `F3_SLT,     1'b0, `ALU_SLT);   // slt
        check(`ALUOP_RTYPE, `F3_SLTU,    1'b0, `ALU_SLTU);  // sltu
        check(`ALUOP_RTYPE, `F3_XOR,     1'b0, `ALU_XOR);   // xor
        check(`ALUOP_RTYPE, `F3_SRL_SRA, 1'b0, `ALU_SRL);   // srl
        check(`ALUOP_RTYPE, `F3_SRL_SRA, 1'b1, `ALU_SRA);   // sra
        check(`ALUOP_RTYPE, `F3_OR,      1'b0, `ALU_OR);    // or
        check(`ALUOP_RTYPE, `F3_AND,     1'b0, `ALU_AND);   // and

        // Tipo I: las 9 operaciones
        check(`ALUOP_ITYPE, `F3_ADD_SUB, 1'b0, `ALU_ADD);   // addi
        check(`ALUOP_ITYPE, `F3_SLL,     1'b0, `ALU_SLL);   // slli
        check(`ALUOP_ITYPE, `F3_SLT,     1'b0, `ALU_SLT);   // slti
        check(`ALUOP_ITYPE, `F3_SLTU,    1'b0, `ALU_SLTU);  // sltiu
        check(`ALUOP_ITYPE, `F3_XOR,     1'b0, `ALU_XOR);   // xori
        check(`ALUOP_ITYPE, `F3_SRL_SRA, 1'b0, `ALU_SRL);   // srli
        check(`ALUOP_ITYPE, `F3_SRL_SRA, 1'b1, `ALU_SRA);   // srai
        check(`ALUOP_ITYPE, `F3_OR,      1'b0, `ALU_OR);    // ori
        check(`ALUOP_ITYPE, `F3_AND,     1'b0, `ALU_AND);   // andi

        // Tipo I con inmediato negativo (bit 30 en 1): el bit 30 no cambia la operación
        check(`ALUOP_ITYPE, `F3_ADD_SUB, 1'b1, `ALU_ADD);   // addi x1, x2, -5: ADD, no SUB
        check(`ALUOP_ITYPE, `F3_SLT,     1'b1, `ALU_SLT);   // slti
        check(`ALUOP_ITYPE, `F3_SLTU,    1'b1, `ALU_SLTU);  // sltiu
        check(`ALUOP_ITYPE, `F3_XOR,     1'b1, `ALU_XOR);   // xori
        check(`ALUOP_ITYPE, `F3_OR,      1'b1, `ALU_OR);    // ori
        check(`ALUOP_ITYPE, `F3_AND,     1'b1, `ALU_AND);   // andi

        // Loads, stores, jalr y lui (alu_op = 00) y alu_op = 01 (no usado):
        // ADD con cualquier funct3 y bit 30
        for (i = 0; i < 16; i = i + 1) begin
            check(`ALUOP_ADD, i[2:0], i[3], `ALU_ADD);
            check(2'b01,      i[2:0], i[3], `ALU_ADD);
        end

        if (errores == 0)
            $display("  RESULTADO        : TEST PASSED");
        else
            $display("  RESULTADO        : TEST FAILED (%0d errores)", errores);
        $finish;
    end
endmodule
