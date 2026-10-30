`timescale 1ns / 1ps
`default_nettype none // Nombre de variable no declarado hace que el compilador lo tome como error y no defina un wire.
// Verifica load_store_unit contra ref_store y ref_load: todos los funct3 en
// las 4 posiciones de byte con datos que prueban la posición y la extensión
// (bit alto en 1 y en 0), los desalineados de la tabla de D3 y combinaciones
// aleatorias de funct3, addr[1:0] y dato.

`include "riscv_defs.vh"

module tb_load_store_unit;
    localparam CANT = 200;

    reg  [2:0]  i_funct3;
    reg  [1:0]  i_addr;
    reg  [31:0] i_store_data;
    reg  [31:0] i_rdata;
    wire [3:0]  o_wmask;
    wire [31:0] o_wdata;
    wire [31:0] o_load_data;

    integer errores;
    integer i;

    load_store_unit u_load_store_unit (
        .i_funct3(i_funct3),
        .i_addr(i_addr),
        .i_store_data(i_store_data),
        .o_wmask(o_wmask),
        .o_wdata(o_wdata),
        .i_rdata(i_rdata),
        .o_load_data(o_load_data)
    );

    // Modelos de referencia: usan desplazamientos y multiplicaciones en lugar
    // de las concatenaciones del RTL, para no copiar la misma expresión.

    // Devuelve {máscara, dato escrito}
    function [35:0] ref_store(input [2:0] funct3, input [1:0] addr, input [31:0] data);
        case (funct3)
            `F3_SB  : ref_store = {4'd1 << addr,           data[7:0]  * 32'h01010101};
            `F3_SH  : ref_store = {4'd3 << (addr & 2'b10), data[15:0] * 32'h00010001};
            `F3_SW  : ref_store = {4'hF, data};
            default : ref_store = {4'h0, data};
        endcase
    endfunction

    // Extensión de signo con (x ^ bit_alto) - bit_alto
    function [31:0] ref_load(input [2:0] funct3, input [1:0] addr, input [31:0] rdata);
        case (funct3)
            `F3_LB  : ref_load = (((rdata >> (8 * addr)) & 32'hFF) ^ 32'h80) - 32'h80;
            `F3_LBU : ref_load =   (rdata >> (8 * addr)) & 32'hFF;
            `F3_LH  : ref_load = (((rdata >> (8 * (addr & 2'b10))) & 32'hFFFF) ^ 32'h8000) - 32'h8000;
            `F3_LHU : ref_load =   (rdata >> (8 * (addr & 2'b10))) & 32'hFFFF;
            `F3_LW  : ref_load = rdata;
            default : ref_load = 32'd0;
        endcase
    endfunction

    // Aplica las entradas y compara las tres salidas con los modelos
    task check(input [2:0] funct3, input [1:0] addr, input [31:0] store_data, input [31:0] rdata);
        begin
            i_funct3     = funct3;
            i_addr       = addr;
            i_store_data = store_data;
            i_rdata      = rdata;
            #1;
            if ({o_wmask, o_wdata} !== ref_store(funct3, addr, store_data) ||
                o_load_data        !== ref_load(funct3, addr, rdata)) begin // Un valor indefinido cuenta como distinto
                $display("  ERROR f3 %b addr %b: store %b/%h (esperado %h), load %h (esperado %h)",
                         funct3, addr, o_wmask, o_wdata, ref_store(funct3, addr, store_data),
                         o_load_data, ref_load(funct3, addr, rdata));
                errores = errores + 1;
            end
        end
    endtask

    // Los 8 funct3 (y los no válidos) en las 4 posiciones con el mismo dato
    task probar_todo(input [31:0] dato);
        integer f3;
        integer a;
        begin
            for (f3 = 0; f3 < 8; f3 = f3 + 1)
                for (a = 0; a < 4; a = a + 1)
                    check(f3, a, dato, dato);
        end
    endtask

    initial begin
        errores = 0;

        // Posición: un byte distinto en cada lugar
        probar_todo(32'h44332211);

        // Extensión con el bit alto en 1 y en 0
        probar_todo(32'h80808080);
        probar_todo(32'h7F7F7F7F);
        probar_todo(32'h80008000);
        probar_todo(32'h7FFF7FFF);

        // Desalineados de la tabla de D3
        check(`F3_LH, 2'b11, 32'd0,        32'hAABBCCDD);  // lh en 0x003
        check(`F3_SH, 2'b01, 32'h0000BEEF, 32'd0);         // sh en 0x001
        check(`F3_LW, 2'b10, 32'd0,        32'hCAFEF00D);  // lw en 0x006
        check(`F3_SW, 2'b10, 32'hDEADBEEF, 32'd0);         // sw en 0x00A

        // Aleatorios
        for (i = 0; i < CANT; i = i + 1)
            check($random, $random, $random, $random);

        if (errores == 0)
            $display("  RESULTADO        : TEST PASSED");
        else
            $display("  RESULTADO        : TEST FAILED (%0d errores)", errores);
        $finish;
    end
endmodule
