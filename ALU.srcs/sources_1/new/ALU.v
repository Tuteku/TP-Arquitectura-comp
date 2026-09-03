`timescale 1ns / 1ps
`default_nettype none // Desactiva la creacion automatica de wire, usar un nombre no declarado es un error de compilacion
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/26/2026 05:33:25 PM
// Design Name: 
// Module Name: ALU
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


module alu #(
    parameter NB_DATA = 8,
    parameter NB_OP = 6
)
(
    input wire signed [NB_DATA-1:0]    i_a,
    input wire signed [NB_DATA-1:0]    i_b,
    input wire        [NB_OP-1:0]      i_op,
    output reg signed [NB_DATA-1:0]    o_alu 
);

    localparam ADD = 6'b100000;
    localparam SUB = 6'b100010;
    localparam AND = 6'b100100;
    localparam OR = 6'b100101;
    localparam XOR = 6'b100110;
    localparam SRA = 6'b000011;
    localparam SRL = 6'b000010;
    localparam NOR = 6'b100111;
    localparam NB_SHIFT = $clog2(NB_DATA);
    always @(*)
    begin
        case(i_op)
            ADD : begin
                    o_alu = i_a + i_b;
                  end
            SUB : begin
                    o_alu = i_a + (~i_b+1);
                  end
            AND : begin
                    o_alu = i_a & i_b;
                  end
            OR : begin
                    o_alu = i_a | i_b;
                  end
            XOR : begin
                    o_alu = i_a ^ i_b;
                  end
            SRA : begin
                    o_alu = i_a >>> i_b;// [NB_SHIFT-1:0];
                  end
            SRL : begin
                    o_alu = i_a >> i_b;// [NB_SHIFT-1:0];
                  end
            NOR : begin
                    o_alu = ~(i_a|i_b); 
                  end
            default: o_alu = {NB_DATA{1'bx}};
        endcase
     end
   endmodule

module alu_top #(
    parameter NB_DATA = 8,
    parameter NB_OP = 6
)
(
    input wire [NB_DATA-1:0] i_switches,
    input wire i_load_a,
    input wire i_load_b,
    input wire i_load_c,
    input wire i_clk,
    output wire [NB_DATA-1:0] o_leds
);
    
    reg [NB_OP-1:0] r_op;
    reg [NB_DATA-1:0] r_a;
    reg [NB_DATA-1:0] r_b;
    
    initial
    begin
        r_op = {NB_OP{1'b0}};
        r_a = {NB_DATA{1'b0}};
        r_b = {NB_DATA{1'b0}};
    end
    
    always @(posedge i_clk)
    begin
        
        if (i_load_a == 1)
            r_a <= i_switches;
        if (i_load_b == 1)
            r_b <= i_switches; 
        if(i_load_c == 1)
            r_op <= i_switches; // Truncamiento de los ultimos dos bits mas significativos, usamos solo 6.
    end
    
    alu #(
        .NB_DATA (NB_DATA),
        .NB_OP (NB_OP)
    ) u_alu
    ( 
        .i_a (r_a),
        .i_b (r_b),
        .i_op (r_op),
        .o_alu (o_leds)
    );
    
    
endmodule