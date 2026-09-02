`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/01/2026 06:01:02 PM
// Design Name: 
// Module Name: tb_alu
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


module tb_alu;
    localparam NB_DATA = 8;
    localparam NB_OP = 6;
    localparam CANT = 100;
    localparam ADD = 6'b100000;
    localparam SUB = 6'b100010;
    localparam AND = 6'b100100;
    localparam OR = 6'b100101;
    localparam XOR = 6'b100110;
    localparam SRA = 6'b000011;
    localparam SRL = 6'b000010;
    localparam NOR = 6'b100111;
    
    reg signed [NB_DATA-1:0]    i_a;
    reg signed [NB_DATA-1:0]    i_b;
    reg        [NB_OP-1:0]      i_op;
    wire signed [NB_DATA-1:0]    o_alu;
    integer errores;
    integer casos;
    integer esperado;
    integer i;
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
        
        for(i = 0; i<CANT; i = i+1)
        begin// for
            i_a = $random;
            i_b = $random;
            i_op = ADD;
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
             
            i_a = $random;
            i_b = $random;
            i_op = SUB;
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
            
            i_a = $random; //and
            i_b = $random;
            i_op = AND;
            #1;
            esperado = i_a & i_b;
            resultado_esp = esperado;
            #1;
            if (o_alu !== resultado_esp)
            begin
                errores = errores + 1;
                $display("ERROR: op=%b a=%b b=%b -> obtenido=%b esperado=%b", i_op, i_a, i_b, o_alu, resultado_esp);
            end
            casos = casos + 1;
            
            i_a = $random; //or
            i_b = $random;
            i_op = OR;
            #1;
            esperado = i_a | i_b;
            resultado_esp = esperado;
            #1;
            if (o_alu !== resultado_esp)
            begin
                errores = errores + 1;
                $display("ERROR: op=%b a=%b b=%b -> obtenido=%b esperado=%b", i_op, i_a, i_b, o_alu, resultado_esp);
            end
            casos = casos + 1;
            
            i_a = $random; //XOR
            i_b = $random;
            i_op = XOR;
            #1;
            esperado = i_a ^ i_b;
            resultado_esp = esperado;
            #1;
            if (o_alu !== resultado_esp)
            begin
                errores = errores + 1;
                $display("ERROR: op=%b a=%b b=%b -> obtenido=%b esperado=%b", i_op, i_a, i_b, o_alu, resultado_esp);
            end
            casos = casos + 1;
            
            i_a = $random; //sra SIGNED
            i_b = $random;
            i_op = SRA;
            #1;
            esperado = i_a >>> i_b;
            resultado_esp = esperado;
            #1;
            if (o_alu !== resultado_esp)
            begin
                errores = errores + 1;
                $display("ERROR: op=%b a=%b b=%b -> obtenido=%b esperado=%b", i_op, i_a, i_b, o_alu, resultado_esp);
            end
            casos = casos + 1;
            
            i_a = $random; //srl
            i_b = $random;
            i_op = SRL;
            #1;
            esperado = i_a >> i_b;
            resultado_esp = esperado;
            #1;
            if (o_alu !== resultado_esp)
            begin
                errores = errores + 1;
                $display("ERROR: op=%b a=%b b=%b -> obtenido=%b esperado=%b", i_op, i_a, i_b, o_alu, resultado_esp);
            end
            casos = casos + 1;
            
            i_a = $random; //nor
            i_b = $random;
            i_op = NOR;
            #1;
            esperado = ~(i_a|i_b);
            resultado_esp = esperado;
            #1;
            if (o_alu !== resultado_esp)
            begin
                errores = errores + 1;
                $display("ERROR: op=%b a=%b b=%b -> obtenido=%b esperado=%b", i_op, i_a, i_b, o_alu, resultado_esp);
            end
            casos = casos + 1;
        end
        
        
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

