`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/05/2026 07:59:27 PM
// Design Name: 
// Module Name: tb_uart_rx
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



module tb_uart_rx;
    reg        clk = 0;
    reg        reset;
    reg        rx;
    reg        s_tick;
    reg  [7:0] data;
    wire [7:0] dout;
    wire       rx_done;

    uart_rx u_dut (
        .i_clk          (clk),
        .i_reset        (reset),
        .i_rx           (rx),
        .i_s_tick       (s_tick),
        .o_dout         (dout),
        .o_rx_done_tick (rx_done)
    );

    always #5 clk = ~clk;   // 100 MHz

    // tick cada 8 ciclos (en vez de 325, para que simule rapido)
    integer cnt = 0;
    always @(posedge clk) begin
        if (cnt == 7) begin
            cnt    <= 0;
            s_tick <= 1;
        end
        else begin
            cnt    <= cnt + 1;
            s_tick <= 0;
        end
    end

    // mantiene un valor en la linea durante 16 ticks
    task send_bit (input valor);
        integer k;
        begin
            @(negedge clk);
            rx = valor;
            k = 0;
            while (k < 16) begin
                @(posedge clk);
                if (s_tick) k = k + 1;
            end
        end
    endtask

    integer i;

    initial begin
        rx    = 1;
        reset = 1;
        data = 8'b01001011;
        repeat (5) @(posedge clk);
        reset = 0;
        repeat (5) @(posedge clk);

        // enviar 0x4B
        send_bit(0);                              // start
        for (i = 0; i < 8; i = i + 1)
            send_bit(data[i]);                   // datos, D0 primero
        send_bit(1);                              // stop

        repeat (20) @(posedge clk);
        $display("Enviado 0x4B, recibido 0x%02h", dout);
        $finish;
    end

endmodule
