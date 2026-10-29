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
    integer casos;
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

    // Inversa: pone los bits de imm donde van según el formato y completa el
    // resto de la instrucción (opcode, rd, rs1, ...) con los bits de otros.
    function [31:0] encode(input [31:0] imm, input [2:0] imm_sel, input [31:0] otros);
        begin
            case (imm_sel)
                `IMM_I  : encode = {imm[11:0], otros[19:0]};
                `IMM_S  : encode = {imm[11:5], otros[24:12], imm[4:0], otros[6:0]};
                `IMM_B  : encode = {imm[12], imm[10:5], otros[24:12], imm[4:1], imm[11], otros[6:0]};
                `IMM_U  : encode = {imm[31:12], otros[11:0]};
                `IMM_J  : encode = {imm[20], imm[10:1], imm[11], imm[19:12], otros[11:0]};
                default : encode = otros;
            endcase
        end
    endfunction

    task check(input [31:0] instr, input [2:0] imm_sel, input [31:0] esperado);
        begin
            i_instr   = instr;
            i_imm_sel = imm_sel;
            #1;
            casos = casos + 1;
            if (o_imm !== esperado) begin // Un valor indefinido cuenta como distinto
                $display("  ERROR instr %h sel %b: obtenido %h, esperado %h", instr, imm_sel, o_imm, esperado);
                errores = errores + 1;
            end
        end
    endtask

    // Caso dirigido: el inmediato tiene que salir igual con el resto de la
    // instrucción en 0 y en 1.
    task check_imm(input [31:0] imm, input [2:0] imm_sel);
        begin
            check(encode(imm, imm_sel, 32'h00000000), imm_sel, imm);
            check(encode(imm, imm_sel, 32'hFFFFFFFF), imm_sel, imm);
        end
    endtask

    initial begin
        errores = 0;
        casos   = 0;

        // I y S: 12 bits con signo
        check_imm(32'd5,        `IMM_I);
        check_imm(-32'd5,       `IMM_I);
        check_imm(32'd2047,     `IMM_I);
        check_imm(-32'd2048,    `IMM_I);
        check_imm(32'd5,        `IMM_S);
        check_imm(-32'd5,       `IMM_S);
        check_imm(32'd2047,     `IMM_S);
        check_imm(-32'd2048,    `IMM_S);

        // B: 13 bits con signo, par
        check_imm(32'd8,        `IMM_B);
        check_imm(-32'd8,       `IMM_B);
        check_imm(32'd4094,     `IMM_B);
        check_imm(-32'd4096,    `IMM_B);

        // U: 20 bits altos, parte baja en 0
        check_imm(32'h12345000, `IMM_U);
        check_imm(32'h80001000, `IMM_U);
        check_imm(32'h7FFFF000, `IMM_U);
        check_imm(32'h80000000, `IMM_U);

        // J: 21 bits con signo, par
        check_imm(32'd16,       `IMM_J);
        check_imm(-32'd16,      `IMM_J);
        check_imm(32'd1048574,  `IMM_J);
        check_imm(-32'd1048576, `IMM_J);

        // Ejemplos de la guía
        check(32'hFE009CE3, `IMM_B, -32'd8);
        check(32'h010000EF, `IMM_J, 32'd16);

        // lui x1, 0xFFFFF
        check(32'hFFFFF0B7, `IMM_U, 32'hFFFFF000);

        // imm_sel no válido: 0 con la instrucción en 1
        for (sel = 5; sel < 8; sel = sel + 1)
            check(32'hFFFFFFFF, sel, 32'd0);

        // Aleatorios: todos los formatos y los imm_sel no válidos
        for (sel = 0; sel < 8; sel = sel + 1)
            for (i = 0; i < CANT; i = i + 1) begin
                i_instr = $random;
                check(i_instr, sel, ref_imm(i_instr, sel));
            end

        $display("  CASOS            : %0d", casos);
        if (errores == 0)
            $display("  RESULTADO        : TEST PASSED");
        else
            $display("  RESULTADO        : TEST FAILED (%0d errores)", errores);
        $finish;
    end
endmodule
