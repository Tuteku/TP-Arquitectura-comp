`timescale 1ns / 1ps
`default_nettype none // Nombre de variable no declarado hace que el compilador lo tome como error y no defina un wire.
// Verifica imm_gen: casos dirigidos por formato (positivo, negativo, máximo y
// mínimo), los ejemplos de la guía, lui con la parte alta en 1, imm_sel no
// válido y 100 instrucciones aleatorias por formato contra ref_imm.

`include "riscv_defs.vh"

module tb_imm_gen;
    localparam CANT = 100;

    reg  [31:0] i_instr;
    reg  [2:0]  i_imm_sel;
    wire [31:0] o_imm;

    integer errores;
    integer i;
    integer sel;

    imm_gen u_imm_gen (
        .i_instr(i_instr),
        .i_imm_sel(i_imm_sel),
        .o_imm(o_imm)
    );

    // Modelo de referencia: arma el inmediato con desplazamientos en lugar de
    // concatenaciones, para no copiar la misma expresión del RTL.
    function [31:0] ref_imm(input [31:0] instr, input [2:0] imm_sel);
        reg [31:0] sgn;
        begin
            sgn = {32{instr[31]}};
            case (imm_sel)
                `IMM_I  : ref_imm = (sgn << 12) | instr[31:20];
                `IMM_S  : ref_imm = (sgn << 12) | (instr[31:25] << 5) | instr[11:7];
                `IMM_B  : ref_imm = (sgn << 12) | (instr[7] << 11) | (instr[30:25] << 5) | (instr[11:8] << 1);
                `IMM_U  : ref_imm = instr & 32'hFFFFF000;
                `IMM_J  : ref_imm = (sgn << 20) | (instr[19:12] << 12) | (instr[20] << 11) | (instr[30:21] << 1);
                default : ref_imm = 32'd0;
            endcase
        end
    endfunction

    task check(input [31:0] instr, input [2:0] imm_sel, input [31:0] esperado);
        begin
            i_instr   = instr;
            i_imm_sel = imm_sel;
            #1;
            if (o_imm !== esperado) begin // Un valor indefinido cuenta como distinto
                $display("  ERROR instr %h sel %b: obtenido %h, esperado %h", instr, imm_sel, o_imm, esperado);
                errores = errores + 1;
            end
        end
    endtask

    initial begin
        errores = 0;

        // I: positivo, negativo, máximo y mínimo
        check(32'h00510093, `IMM_I, 32'd5);          // addi x1, x2, 5
        check(32'hFFB10093, `IMM_I, -32'd5);         // addi x1, x2, -5
        check(32'h7FF10093, `IMM_I, 32'd2047);       // addi x1, x2, 2047
        check(32'h80010093, `IMM_I, -32'd2048);      // addi x1, x2, -2048

        // S
        check(32'h005122A3, `IMM_S, 32'd5);          // sw x5, 5(x2)
        check(32'hFE512DA3, `IMM_S, -32'd5);         // sw x5, -5(x2)
        check(32'h7E512FA3, `IMM_S, 32'd2047);       // sw x5, 2047(x2)
        check(32'h80512023, `IMM_S, -32'd2048);      // sw x5, -2048(x2)

        // B
        check(32'h00208463, `IMM_B, 32'd8);          // beq x1, x2, 8
        check(32'hFE208CE3, `IMM_B, -32'd8);         // beq x1, x2, -8
        check(32'h7E208FE3, `IMM_B, 32'd4094);       // beq x1, x2, 4094
        check(32'h80208063, `IMM_B, -32'd4096);      // beq x1, x2, -4096

        // U
        check(32'h123450B7, `IMM_U, 32'h12345000);   // lui x1, 0x12345
        check(32'h800010B7, `IMM_U, 32'h80001000);   // lui x1, 0x80001
        check(32'h7FFFF0B7, `IMM_U, 32'h7FFFF000);   // lui x1, 0x7FFFF
        check(32'h800000B7, `IMM_U, 32'h80000000);   // lui x1, 0x80000

        // J
        check(32'h010000EF, `IMM_J, 32'd16);         // jal x1, 16
        check(32'hFF1FF0EF, `IMM_J, -32'd16);        // jal x1, -16
        check(32'h7FFFF0EF, `IMM_J, 32'd1048574);    // jal x1, 1048574
        check(32'h800000EF, `IMM_J, -32'd1048576);   // jal x1, -1048576

        // Ejemplos de la guía y lui con la parte alta en 1
        check(32'hFE009CE3, `IMM_B, -32'd8);         // bne x1, x0, -8
        check(32'h010000EF, `IMM_J, 32'd16);         // jal x1, 16
        check(32'hFFFFF0B7, `IMM_U, 32'hFFFFF000);   // lui x1, 0xFFFFF

        // imm_sel no válido: 0 aunque la instrucción sea todo 1
        check(32'hFFFFFFFF, 3'b101, 32'd0);
        check(32'hFFFFFFFF, 3'b110, 32'd0);
        check(32'hFFFFFFFF, 3'b111, 32'd0);

        // Aleatorios: 100 por cada valor de imm_sel
        for (s  el = 0; sel < 8; sel = sel + 1)
            for (i = 0; i < CANT; i = i + 1) begin
                i_instr = $random;
                check(i_instr, sel, ref_imm(i_instr, sel));
            end

        if (errores == 0)
            $display("  RESULTADO        : TEST PASSED");
        else
            $display("  RESULTADO        : TEST FAILED (%0d errores)", errores);
        $finish;
    end
endmodule
