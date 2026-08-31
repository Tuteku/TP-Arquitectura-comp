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
    
    reg [NB_DATA-1:0] i_switches;
    reg i_load_a;
    reg i_load_b;
    reg i_load_c;
    reg i_clk;
    integer i = 0;
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
        .o_leds(o_leds)
    );
    
    initial
    begin
        #0
        i_clk = 1'b1;
        i_switches = {NB_DATA{1'b0}};
        i_load_a = 1'b0;
        i_load_b = 1'b0;
        i_load_c = 1'b0;
        @(negedge i_clk);
        i_switches = 8'd10;
        i_load_a = 1'b1;
        @(posedge i_clk);
        #1;
        $display("r_a = %d", u_01.r_a); 
        @(negedge i_clk);
        i_load_a = 0;
        i_load_b = 1;
        i_switches = 8'd5;
        @(posedge i_clk);
        #1;
        $display("r_b = %d", u_01.r_b);
        @(negedge i_clk);
        i_load_b = 0;
        i_switches = 6'b100000;
        i_load_c = 1;
        @(posedge i_clk);
        #1;
        $display("r_op = %b", u_01.r_op);
        #1;
        $display("o_leds = %d", u_01.o_leds);
        #250 $finish;
    end
    
/*    initial
    begin
        #201
        $display("Clock cambio %d", i);
        #250 $finish;
    end
*/    
    always
    begin
        #5
        i_clk = ~i_clk;
        //i = i + 1;
    end
   
endmodule

module tb_alu;
    localparam NB_DATA = 8;
    localparam NB_OP = 6;
    
    reg signed [NB_DATA-1:0]    i_a;
    reg signed [NB_DATA-1:0]    i_b;
    reg        [NB_OP-1:0]      i_op;
    wire signed [NB_DATA-1:0]    o_alu;
    integer errores;
    integer casos;
    integer esperado;
    reg signed [NB_DATA-1:0] resultado_esp; 
    
    alu #(
        .NB_DATA(NB_DATA),
        .NB_OP(NB_OP)
    ) u_01 (
      .i_a(i_a),
      .i_b(i_b),
      .i_op(i_op),
      .o_alu(o_alu)
    );
    
    initial
    begin
        errores = 0;
        casos = 0;
        esperado = 0;
        i_a = 8'd10;
        i_b = 8'd5;
        i_op = 6'b100000;
        #1;
        esperado = i_a + i_b;
        resultado_esp = esperado;
        #1;
        if (o_alu !== resultado_esp)
        begin
            errores = errores + 1;
            $display("ERROR: op=%b a=%b b=%b -> obtenido=%b esperado=%b", i_op, i_a, i_b, o_alu, resultado_esp);
        end
        casos = casos + 1;
        
        i_a = 8'd10;
        i_b = 8'd5;
        i_op = 6'b100000;
        #1;
        esperado = i_a - i_b;
        resultado_esp = esperado;
        #1;
        if (o_alu !== resultado_esp)
        begin
            errores = errores + 1;
            $display("ERROR: op=%b a=%b b=%b -> obtenido=%b esperado=%b", i_op, i_a, i_b, o_alu, resultado_esp);
        end
        casos = casos + 1;
        
        i_a = 8'd10;
        i_b = 8'd5;
        i_op = 6'b100010;
        #1;
        esperado = i_a - i_b;
        resultado_esp = esperado;
        #1;
        if (o_alu !== resultado_esp)
        begin
            errores = errores + 1;
            $display("ERROR: op=%b a=%b b=%b -> obtenido=%b esperado=%b", i_op, i_a, i_b, o_alu, resultado_esp);
        end
        casos = casos + 1;
        
        i_a = 8'd127;
        i_b = 8'd1;
        i_op = 6'b100000;
        #1;
        esperado = i_a + i_b;
        resultado_esp = esperado;
        #1;
        if (o_alu !== resultado_esp)
        begin
            errores = errores + 1;
            $display("ERROR: op=%b a=%b b=%b -> obtenido=%b esperado=%b", i_op, i_a, i_b, o_alu, resultado_esp);
        end
        casos = casos + 1;
        
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
