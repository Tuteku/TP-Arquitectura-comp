`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/05/2026 08:22:01 PM
// Design Name: 
// Module Name: tb_uart_tx
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

module tb_uart_tx;

    reg        clk = 0;
    reg        reset;
    reg        s_tick;
    reg        tx_start;
    reg  [7:0] dato = 8'h4B;
    wire       tx;
    wire       tx_done;

    uart_tx u_dut (
        .i_clk      (clk),
        .i_reset    (reset),
        .i_s_tick   (s_tick),
        .i_data     (dato),
        .i_tx_start (tx_start),
        .o_tx       (tx),
        .o_tx_done  (tx_done)
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

    task wait_ticks (input integer n);
        integer k;
        begin
            k = 0;
            while (k < n) begin
                @(posedge clk);
                if (s_tick) k = k + 1;
            end
        end
    endtask

    reg [7:0] recibido;
    integer   i;

    initial begin
        tx_start = 0;
        reset    = 1;
        repeat (5) @(posedge clk);
        reset = 0;
        repeat (5) @(posedge clk);

        // pulso de arranque de un ciclo
        @(negedge clk) tx_start = 1;
        @(negedge clk) tx_start = 0;

        // esperar el start bit
        wait (tx == 1'b0);

        // caer en el medio del start y despues muestrear cada bit
        wait_ticks(8);
        for (i = 0; i < 8; i = i + 1) begin
            wait_ticks(16);
            recibido[i] = tx;       // D0 sale primero
        end

        wait (tx_done == 1'b1);
        $display("Enviado 0x%02h, en la linea 0x%02h", dato, recibido);
        $finish;
    end

endmodule
