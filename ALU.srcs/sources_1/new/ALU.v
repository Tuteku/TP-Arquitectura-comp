`timescale 1ns / 1ps
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
                    o_alu = i_a >>> i_b;
                  end
            SRL : begin
                    o_alu = i_a >> i_b;
                  end
            NOR : begin
                    o_alu = ~(i_a|i_b); 
                  end
            default: o_alu = {NB_DATA{1'bx}};
        endcase
     end
   endmodule

module load_register #(
    parameter NB_DATA = 8,
    parameter NB_OP = 6
)
(
    input wire [NB_DATA-1:0] i_bus_data,
    input wire i_a,
    input wire i_b,
    input wire i_c,
    output reg [NB_OP-1:0] o_op,
    output reg [NB_DATA-1:0] o_reg_a,
    output reg [NB_DATA-1:0] o_reg_b
);

    always @(i_a)
    begin
        o_reg_a = i_bus_data;
    end
    always @(i_b)
    begin
        o_reg_b = i_bus_data; 
    end
    always @(i_c)
    begin
        o_op = i_bus_data;
    end
    
endmodule