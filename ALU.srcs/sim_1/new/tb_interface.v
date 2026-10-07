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
    reg  [7:0] data;
    reg        rx_done;
    reg        tx_done;

    wire [7:0] data_tx;
    wire       tx_start;
    wire [7:0] alu_a, alu_b;
    wire [5:0] alu_op;

    // ALU falsa: siempre suma
    wire [7:0] alu_result = alu_a + alu_b;

    uart_interface u_dut (
        .i_clk       (clk),
        .i_reset     (reset),
        .i_data      (data),
        .i_rx_done   (rx_done),
        .i_tx_done   (tx_done),
        .i_data_alu  (alu_result),
        .o_data_tx   (data_tx),
        .o_tx_start  (tx_start),
        .o_alu_a     (alu_a),
        .o_alu_b     (alu_b),
        .o_alu_op    (alu_op)
    );

    always #5 clk = ~clk;   // 100 MHz

    // simula un byte que llega del Rx
    task rx_byte (input [7:0] valor);
        begin
            @(negedge clk);
            data    = valor;
            rx_done = 1;
            @(negedge clk);
            rx_done = 0;
            #30;
        end
    endtask
    
    always @(posedge clk) begin
        if (tx_start)
            $display("A=0x%02h  B=0x%02h  Op=0b%06b  ->  data_tx=0x%02h", alu_a, alu_b, alu_op, data_tx);
    end
    
    initial begin
        rx_done = 0;
        tx_done = 0;
        data    = 8'h00;
        reset   = 1;
        #50; reset = 0;
        #50;

        rx_byte(8'h05);
        rx_byte(8'h03);
        rx_byte({2'b00, 6'b100000});

        #100;                       // simular que el Tx transmite
        @(negedge clk);
        tx_done = 1;

        #200;
        $finish;
    end

endmodule
