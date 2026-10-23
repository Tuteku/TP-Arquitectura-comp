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

    // Baud rate
    wire s_tick;

    // Rx/Tx <-> Interface
    wire [NB_DATA-1:0] d_out;
    wire rx_done;
    wire [NB_DATA-1:0] d_in;
    wire tx_start;
    wire tx_done;

    // Interface <-> ALU
    wire [NB_DATA-1:0] r_data;
    wire rd;
    wire rx_empty;
    wire [NB_DATA-1:0] w_data;
    wire wr;
    wire tx_full;

    baud_rate_generator  #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_baud_rate_generator (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .o_tick(s_tick)
    );

    uart_rx #(
        .NB_DATA (NB_DATA),
        .SB_TICK (SB_TICK)
    ) u_uart_rx (
        .i_s_tick (s_tick),
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
        .i_s_tick (s_tick),
        .i_clk (i_clk),
        .i_reset (i_reset),
        .i_data (d_in),
        .i_tx_start (tx_start),
        .o_tx (o_tx),
        .o_tx_done (tx_done)
    );

    uart_interface #(
        .NB_DATA (NB_DATA)
    ) u_uart_interface (
        .i_clk (i_clk),
        .i_reset (i_reset),
        // lado UART
        .i_rx_data (d_out),
        .i_rx_done (rx_done),
        .i_tx_done (tx_done),
        .o_tx_data (d_in),
        .o_tx_start (tx_start),
        // lado ALU
        .o_r_data (r_data),
        .i_rd (rd),
        .o_rx_empty (rx_empty),
        .i_w_data (w_data),
        .i_wr (wr),
        .o_tx_full (tx_full)
    );

    top_uart_alu #(
        .NB_DATA (NB_DATA),
        .NB_OP (NB_OP)
    ) u_top_uart_alu (
        .i_clk (i_clk),
        .i_reset (i_reset),
        .i_r_data (r_data),
        .i_rx_empty (rx_empty),
        .i_tx_full (tx_full),
        .o_rd (rd),
        .o_w_data (w_data),
        .o_wr (wr)
    );

endmodule