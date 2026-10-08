`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/26/2026 06:31:28 PM
// Design Name: 
// Module Name: interface
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


module uart_interface #(
    parameter NB_DATA = 8
)
(
    input  wire               i_clk,
    input  wire               i_reset,
    // lado UART
    input  wire [NB_DATA-1:0] i_rx_data,   // d_out del Rx
    input  wire               i_rx_done,
    input  wire               i_tx_done,
    output wire [NB_DATA-1:0] o_tx_data,   // d_in del Tx
    output wire               o_tx_start,
    // lado ALU
    output wire [NB_DATA-1:0] o_r_data,
    input  wire               i_rd,
    output wire               o_rx_empty,
    input  wire [NB_DATA-1:0] i_w_data,
    input  wire               i_wr,
    output wire               o_tx_full
);
    reg [NB_DATA-1:0] rx_buf, tx_buf;
    reg               rx_flag, tx_flag;

    always @(posedge i_clk) begin
        if (i_reset) begin
            rx_buf  <= {NB_DATA{1'b0}};
            tx_buf  <= {NB_DATA{1'b0}};
            rx_flag <= 1'b0;
            tx_flag <= 1'b0;
        end
        else begin
            // Buffer RX: se ll rd
            if (i_rx_done) begin
                rx_buf  <= i_rx_data;
                rx_flag <= 1'b1;
            end
            else if (i_rd) begin
                rx_flag <= 1'b0;            
            end
            // Buffer TX: se llena con wr, se vacía con tx_done
            if (i_wr && !tx_flag) begin
                tx_buf  <= i_w_data;
                tx_flag <= 1'b1;
            end
            else if (i_tx_done) begin
                tx_flag <= 1'b0;
            end    
        end
    end

    assign o_r_data   = rx_buf;
    assign o_rx_empty = ~rx_flag;
    assign o_tx_data  = tx_buf;
    assign o_tx_full  = tx_flag;
    assign o_tx_start = tx_flag;   // el Tx arranca cuando hay dato en el buffer
endmodule