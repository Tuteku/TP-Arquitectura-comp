`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/28/2026 04:55:08 PM
// Design Name: 
// Module Name: top_level
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


module top_level #(
    parameter CLK_FREQ = 100000000,
    parameter BAUD_RATE = 19200,
    parameter NB_DATA = 8,
    parameter SB_TICK = 16,
    parameter NB_OP = 6    
)
(
    input wire i_rx,
    input wire i_clk,
    input wire i_reset,
    output wire o_tx
);

    wire i_s_tick;
    wire [NB_DATA-1:0] d_out;
    wire rx_done;
    wire [NB_DATA-1:0] d_in;
    wire tx_start;
    wire tx_done;
    wire [NB_DATA-1:0] w_data;
    wire [NB_DATA-1:0] r_a, r_b;
    wire [NB_OP-1:0] r_op;

    baud_rate_generator  #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_baud_rate_generator (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .o_tick(i_s_tick)
    );
    
    uart_rx #(
        .NB_DATA (NB_DATA),
        .SB_TICK (SB_TICK)
    ) u_uart_rx (
        .i_s_tick (i_s_tick),
        .i_clk (i_clk),
        .i_reset (i_reset),
        .i_rx (i_rx),
        .o_dout (d_out),
        .o_rx_done_tick (rx_done)
    );
    
    uart_tx #(
        .NB_DATA (NB_DATA),
        .SB_TICK (SB_TICK)
    ) u_uart_tx (
        .i_s_tick (i_s_tick),
        .i_clk (i_clk),
        .i_reset (i_reset),
        .i_data (d_in),
        .i_tx_start (tx_start),
        .o_tx (o_tx),
        .o_tx_done (tx_done)
    );
    
    uart_interface #(
        .NB_DATA (NB_DATA),
        .NB_OP (NB_OP)
    ) u_uart_interface (
        .i_data (d_out),
        .i_rx_done (rx_done),
        .i_clk (i_clk),
        .i_tx_done (tx_done),
        .i_reset (i_reset),
        .i_data_alu (w_data),
        .o_data_tx (d_in),
        .o_tx_start (tx_start),
        .o_alu_a (r_a),
        .o_alu_b (r_b),
        .o_alu_op (r_op)     
    );
    
    alu #(
        .NB_DATA (NB_DATA),
        .NB_OP (NB_OP)
    ) u_alu
    ( 
        .i_a (r_a),
        .i_b (r_b),
        .i_op (r_op),
        .o_alu (w_data)
    );    
        
endmodule
