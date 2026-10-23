`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/06/2026 03:21:28 PM
// Design Name: 
// Module Name: tb_interface
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


module tb_interface;

    reg        clk = 0;
    reg        reset;
    reg  [7:0] rx_data;
    reg        rx_done;
    reg        tx_done;
    reg        rd;
    reg  [7:0] w_data;
    reg        wr;

    wire [7:0] tx_data;
    wire       tx_start;
    wire [7:0] r_data;
    wire       rx_empty;
    wire       tx_full;

    uart_interface u_dut (
        .i_clk      (clk),
        .i_reset    (reset),
        .i_rx_data  (rx_data),
        .i_rx_done  (rx_done),
        .i_tx_done  (tx_done),
        .o_tx_data  (tx_data),
        .o_tx_start (tx_start),
        .o_r_data   (r_data),
        .i_rd       (rd),
        .o_rx_empty (rx_empty),
        .i_w_data   (w_data),
        .i_wr       (wr),
        .o_tx_full  (tx_full)
    );

    always #5 clk = ~clk;   // 100 MHz

    initial begin
        rx_data = 8'h00;
        rx_done = 0;
        tx_done = 0;
        rd      = 0;
        w_data  = 8'h00;
        wr      = 0;
        reset   = 1;
        #50; reset = 0;
        #50;

        // RX: llega 0x4B del Rx
        @(negedge clk) begin rx_data = 8'h4B; rx_done = 1; end
        @(negedge clk) rx_done = 0;
        $display("RX lleno: r_data=0x%02h rx_empty=%b (esperado 0x4B, 0)", r_data, rx_empty);

        // la ALU lee el dato
        @(negedge clk) rd = 1;
        @(negedge clk) rd = 0;
        $display("RX leido: rx_empty=%b (esperado 1)", rx_empty);

        // TX: la ALU escribe 0x08
        @(negedge clk) begin w_data = 8'h08; wr = 1; end
        @(negedge clk) wr = 0;
        $display("TX lleno: tx_data=0x%02h tx_full=%b tx_start=%b (esperado 0x08, 1, 1)", tx_data, tx_full, tx_start);

        // el Tx termina de transmitir
        @(negedge clk) tx_done = 1;
        @(negedge clk) tx_done = 0;
        $display("TX libre: tx_full=%b tx_start=%b (esperado 0, 0)", tx_full, tx_start);

        #50;
        $finish;
    end

endmodule