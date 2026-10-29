`timescale 1ns / 1ps
`default_nettype none // Nombre de variable no declarado hace que el compilador lo tome como error y no defina un wire.
// Verifica rtl/core/alu.v: casos dirigidos a los bordes (desbordes, comparación
// con y sin signo con el bit 31 en 1, desplazamientos por 0 y por 31, bits de b
// por encima del 4) y 100 casos aleatorios por operación contra el modelo.

`include "riscv_defs.vh"

module tb_alu;
    localparam NB_DATA  = 32;
    localparam NB_OP    = 4;
    localparam CANT     = 100;
    localparam NB_SHIFT = $clog2(NB_DATA);

    reg  [NB_DATA-1:0]  i_a;
    reg  [NB_DATA-1:0]  i_b;
    reg  [NB_OP-1:0]    i_alu_ctrl;
    wire [NB_DATA-1:0]  o_alu_result;

    reg  [NB_DATA-1:0]  esperado;
    integer errores;
    integer casos;
    integer i;
    integer op;

    // Las 10 operaciones, para recorrerlas en los casos aleatorios
    reg  [NB_OP-1:0]    ops [0:9];

    alu #(
        .NB_DATA(NB_DATA),
        .NB_OP(NB_OP)
    ) u_alu (
        .i_a(i_a),
        .i_b(i_b),
        .i_alu_ctrl(i_alu_ctrl),
        .o_alu_result(o_alu_result)
    );

    // Modelo de referencia, escrito con la tabla de docs/datapath.md
    function [NB_DATA-1:0] modelo;
        input [NB_DATA-1:0] a;
        input [NB_DATA-1:0] b;
        input [NB_OP-1:0]   ctrl;
        begin
            case (ctrl)
                `ALU_ADD  : modelo = a + b;
                `ALU_SUB  : modelo = a - b;
                `ALU_SLL  : modelo = a << b[NB_SHIFT-1:0];
                `ALU_SLT  : modelo = ($signed(a) < $signed(b)) ? 1 : 0;
                `ALU_SLTU : modelo = (a < b) ? 1 : 0;
                `ALU_XOR  : modelo = a ^ b;
                `ALU_SRL  : modelo = a >> b[NB_SHIFT-1:0];
                `ALU_SRA  : modelo = $signed(a) >>> b[NB_SHIFT-1:0];
                `ALU_OR   : modelo = a | b;
                `ALU_AND  : modelo = a & b;
                default   : modelo = {NB_DATA{1'b0}};
            endcase
        end
    endfunction

    // Compara contra un valor esperado escrito a mano (casos dirigidos)
    task check;
        input [NB_DATA-1:0] a;
        input [NB_DATA-1:0] b;
        input [NB_OP-1:0]   ctrl;
        input [NB_DATA-1:0] valor;
        begin
            i_a        = a;
            i_b        = b;
            i_alu_ctrl = ctrl;
            #1;
            casos = casos + 1;
            if (o_alu_result !== valor) begin // Un valor indefinido cuenta como distinto
                errores = errores + 1;
                $display("  ERROR caso %0d: ctrl=%b a=%h b=%h -> obtenido=%h esperado=%h",
                         casos, ctrl, a, b, o_alu_result, valor);
            end
        end
    endtask

    // Compara contra el modelo (casos aleatorios)
    task check_modelo;
        input [NB_DATA-1:0] a;
        input [NB_DATA-1:0] b;
        input [NB_OP-1:0]   ctrl;
        begin
            esperado = modelo(a, b, ctrl);
            check(a, b, ctrl, esperado);
        end
    endtask

    initial begin
        errores = 0;
        casos   = 0;

        ops[0] = `ALU_ADD;  ops[1] = `ALU_SUB;  ops[2] = `ALU_SLL;
        ops[3] = `ALU_SLT;  ops[4] = `ALU_SLTU; ops[5] = `ALU_XOR;
        ops[6] = `ALU_SRL;  ops[7] = `ALU_SRA;  ops[8] = `ALU_OR;
        ops[9] = `ALU_AND;

        // Desbordes: dan la vuelta sin aviso
        check(32'h7FFFFFFF, 32'h00000001, `ALU_ADD, 32'h80000000);
        check(32'hFFFFFFFF, 32'h00000001, `ALU_ADD, 32'h00000000);
        check(32'h80000000, 32'h00000001, `ALU_SUB, 32'h7FFFFFFF);
        check(32'h00000000, 32'h00000001, `ALU_SUB, 32'hFFFFFFFF);
        check(32'h0000000A, 32'h0000000A, `ALU_SUB, 32'h00000000);

        // SLT y SLTU con el bit 31 en 1 en un operando
        check(32'hFFFFFFFF, 32'h00000001, `ALU_SLT,  32'd1);   // -1 < 1
        check(32'hFFFFFFFF, 32'h00000001, `ALU_SLTU, 32'd0);   // 0xFFFFFFFF > 1
        check(32'h00000001, 32'hFFFFFFFF, `ALU_SLT,  32'd0);
        check(32'h00000001, 32'hFFFFFFFF, `ALU_SLTU, 32'd1);
        check(32'h7FFFFFFF, 32'h80000000, `ALU_SLT,  32'd0);   // máximo positivo contra mínimo negativo
        check(32'h7FFFFFFF, 32'h80000000, `ALU_SLTU, 32'd1);
        // En los dos operandos
        check(32'h80000000, 32'hFFFFFFFF, `ALU_SLT,  32'd1);   // -2^31 < -1
        check(32'h80000000, 32'hFFFFFFFF, `ALU_SLTU, 32'd1);
        check(32'hFFFFFFFF, 32'h80000000, `ALU_SLT,  32'd0);
        check(32'hFFFFFFFF, 32'h80000000, `ALU_SLTU, 32'd0);
        // Iguales
        check(32'hFFFFFFFF, 32'hFFFFFFFF, `ALU_SLT,  32'd0);
        check(32'hFFFFFFFF, 32'hFFFFFFFF, `ALU_SLTU, 32'd0);

        // Desplazamientos por 0 y por 31
        check(32'h80000001, 32'd0,  `ALU_SLL, 32'h80000001);
        check(32'h80000001, 32'd0,  `ALU_SRL, 32'h80000001);
        check(32'h80000001, 32'd0,  `ALU_SRA, 32'h80000001);
        check(32'h00000001, 32'd31, `ALU_SLL, 32'h80000000);
        check(32'h80000000, 32'd31, `ALU_SRL, 32'h00000001);
        check(32'h80000000, 32'd31, `ALU_SRA, 32'hFFFFFFFF);

        // Bits de b por encima del 4 en 1: se ignoran (0xFFFFFFE1 -> shamt = 1)
        check(32'h00000003, 32'hFFFFFFE1, `ALU_SLL, 32'h00000006);
        check(32'h80000000, 32'hFFFFFFE1, `ALU_SRL, 32'h40000000);
        check(32'h80000000, 32'hFFFFFFE1, `ALU_SRA, 32'hC0000000);
        check(32'h12345678, 32'h00000020, `ALU_SLL, 32'h12345678); // 32 -> shamt = 0

        // SRA y SRL sobre un valor negativo
        check(32'hF0000000, 32'd4, `ALU_SRL, 32'h0F000000);
        check(32'hF0000000, 32'd4, `ALU_SRA, 32'hFF000000);
        check(32'hFFFFFFF8, 32'd1, `ALU_SRL, 32'h7FFFFFFC);
        check(32'hFFFFFFF8, 32'd1, `ALU_SRA, 32'hFFFFFFFC);   // -8 >> 1 = -4

        // Lógicas
        check(32'hF0F0F0F0, 32'hFF00FF00, `ALU_AND, 32'hF000F000);
        check(32'hF0F0F0F0, 32'hFF00FF00, `ALU_OR,  32'hFFF0FFF0);
        check(32'hF0F0F0F0, 32'hFF00FF00, `ALU_XOR, 32'h0FF00FF0);

        // Códigos que no son ninguna operación: devuelven 0, no x
        check(32'h12345678, 32'h9ABCDEF0, 4'b1001, 32'h00000000);
        check(32'h12345678, 32'h9ABCDEF0, 4'b1111, 32'h00000000);
        check(32'h12345678, 32'h9ABCDEF0, 4'bxxxx, 32'h00000000);

        // Aleatorios: CANT por cada una de las 10 operaciones
        for (op = 0; op < 10; op = op + 1)
            for (i = 0; i < CANT; i = i + 1)
                check_modelo($random, $random, ops[op]);

        $display("=====================================");
        $display("  Casos ejecutados : %0d", casos);
        $display("  Errores          : %0d", errores);
        if (errores == 0)
            $display("  RESULTADO        : TEST PASSED");
        else
            $display("  RESULTADO        : TEST FAILED");
        $display("=====================================");
        $finish;
    end

endmodule
