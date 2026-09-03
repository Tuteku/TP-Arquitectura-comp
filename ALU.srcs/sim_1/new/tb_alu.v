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
    localparam NB_SHIFT = $clog2(NB_DATA);

    reg signed [NB_DATA-1:0]    i_a;
    reg signed [NB_DATA-1:0]    i_b;
    reg        [NB_OP-1:0]      i_op;
    wire signed [NB_DATA-1:0]    o_alu;
    integer errores;
    integer casos;
    reg signed [NB_DATA-1:0] esperado;
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
    
    task alu_task;
        input signed    [NB_DATA-1:0] a;
        input signed    [NB_DATA-1:0] b;
        input           [NB_OP-1:0] op;
        
        begin
            i_a  = a;
            i_b  = b;
            i_op = op;
        #1
            case (op)                    
                ADD : esperado = a + b;
                SUB : esperado = a - b;
                AND : esperado = a & b;
                OR  : esperado = a | b;
                XOR : esperado = a ^ b;
                SRA : esperado = a >>> b[NB_SHIFT-1:0];
                SRL : esperado = a >> b[NB_SHIFT-1:0];
                NOR : esperado = ~(a | b);
                default : esperado = {NB_DATA{1'bx}};
            endcase
            
            casos = casos + 1;
            if (o_alu !== esperado) 
            begin
                errores = errores + 1;
                $display("ERROR caso %0d: op=%b a=%b b=%b -> obtenido=%b esperado=%b", casos, op, a, b, o_alu, esperado);
            end
        end
    endtask 
initial 
    begin
        errores = 0;
        casos = 0;
        esperado = 0;
        alu_task(8'd127,  8'd1,  ADD);      // overflow
        alu_task(8'd10,   8'd10, SUB);      // debe dar 0
        alu_task(8'b10110010, 8'd0, SRL);   // shift por 0
        alu_task(8'd5,    8'd3,  6'b111111); // opcode invalido
        for (i = 0; i < CANT; i = i + 1) begin
            alu_task($random, $random, ADD);
            alu_task($random, $random, SUB);
            alu_task($random, $random, AND);
            alu_task($random, $random, OR);
            alu_task($random, $random, XOR);
            alu_task($random, $random, SRA);
            alu_task($random, $random, SRL);
            alu_task($random, $random, NOR);
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

