`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2026 04:55:52 PM
// Design Name: 
// Module Name: alu_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_alu_top;
    
    localparam NB_DATA = 8;
    localparam NB_OP = 6;
    localparam PERIODO = 10; // 10ns -> 100MHz
    
    reg [NB_DATA-1:0] i_switches;
    reg i_load_a;
    reg i_load_b;
    reg i_load_c;
    reg i_clk;
    reg i_reset;
    wire [NB_DATA-1:0] o_leds;
    
    alu_top #(
        .NB_DATA(NB_DATA),
        .NB_OP(NB_OP)
    ) u_01(
        .i_switches(i_switches),
        .i_load_a(i_load_a),
        .i_load_b(i_load_b),
        .i_load_c(i_load_c),
        .i_clk(i_clk),
        .i_reset(i_reset),
        .o_leds(o_leds)
    );

    // Generador de clock: PERIODO ns -> 100 MHz
    always 
    begin
    #(PERIODO/2) 
    i_clk = ~i_clk;
    end

    initial
    begin
        #0
        i_clk = 1'b1;
        i_reset = 1'b0;
        i_switches = {NB_DATA{1'b0}};
        i_load_a = 1'b0;
        i_load_b = 1'b0;
        i_load_c = 1'b0;
        @(negedge i_clk);   // Cargar registro A
            i_switches = 8'd10;
            i_load_a = 1'b1;
        @(posedge i_clk);
            #1;
            $display("r_a = %d", u_01.r_a); 
        @(negedge i_clk);   // Cargar registro B
            i_load_a = 0;
            i_load_b = 1;
            i_switches = 8'd5;
        @(posedge i_clk);
            #1;
            $display("r_b = %d", u_01.r_b);
        @(negedge i_clk);   // Cargar registro OP
            i_load_b = 0;
            i_switches = 6'b100000;
            i_load_c = 1;
        @(posedge i_clk);
            #1;
            $display("r_op = %b", u_01.r_op);
            #1;
            $display("o_leds = %d", u_01.o_leds);
        
        @(negedge i_clk);
            i_load_c   = 1'b0;
            i_switches = 8'd99;
        @(posedge i_clk);
            #1;
            $display("Con todos los load en 0 y switches=99:");
            $display("  r_a=%0d r_b=%0d r_op=%b",u_01.r_a, u_01.r_b, u_01.r_op);

            #(PERIODO*10) $finish;
    end        
endmodule
