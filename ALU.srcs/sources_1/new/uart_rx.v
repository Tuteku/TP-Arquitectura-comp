`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/09/2026 06:11:11 PM
// Design Name: 
// Module Name: uart_rx
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


module uart_rx #(
    parameter NB_DATA = 8,
    parameter SB_TICK = 16
)
(
    input wire i_s_tick,
    input wire i_clk,
    input wire i_reset,
    input wire i_rx,
    output wire [NB_DATA-1:0] o_dout,
    output wire o_rx_done_tick       
);    
    localparam NB_N = $clog2(NB_DATA);
    
    reg [NB_DATA-1 : 0] rx_data;
    reg [3 : 0] s_reg;
    reg [NB_N : 0] n_reg;
    reg [NB_DATA-1 : 0] b_reg;
    
    always@(posedge i_clk)
    begin
        if(i_reset)
        begin
            s_reg <= {4{1'b0}};
        end
        if(i_s_tick)
        begin
            s <= s + 1;
        end
    end
endmodule
