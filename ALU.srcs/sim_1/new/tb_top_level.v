`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: tb_top_level
//////////////////////////////////////////////////////////////////////////////////

module tb_top_level;

    localparam CLK_FREQ  = 100_000_000;
    localparam BAUD_SIM  = 2_000_000;

    // mismo calculo que hace el baud_rate_generator (division entera)
    localparam M         = CLK_FREQ / (BAUD_SIM * 16);
    localparam BIT_NS    = M * 16 * 10;     // duracion de un bit, en ns

    reg  clk = 0;
    reg  reset;
    reg  rx;
    wire tx;

    top_level #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_SIM)
    ) u_dut (
        .i_clk   (clk),
        .i_reset (reset),
        .i_rx    (rx),
        .o_tx    (tx)
    );

    always #5 clk = ~clk;   // 100 MHz

    // manda una trama por la linea
    task send_byte (input [7:0] dato);
        integer i;
        begin
            rx = 1'b0;                      // start
            #BIT_NS;
            for (i = 0; i < 8; i = i + 1) begin
                rx = dato[i];               // D0 primero
                #BIT_NS;
            end
            rx = 1'b1;                      // stop
            #BIT_NS;
        end
    endtask

    // lee una trama de la linea
    task recv_byte (output [7:0] dato);
        integer i;
        begin
            @(negedge tx);                  // start bit
            #(BIT_NS + BIT_NS/2);           // caer en el medio de D0
            for (i = 0; i < 8; i = i + 1) begin
                dato[i] = tx;
                #BIT_NS;
            end
        end
    endtask

    reg [7:0] resultado;

    // escucha la respuesta desde el instante cero, en paralelo
    initial begin
        recv_byte(resultado);
        $display("A=0x05  B=0x03  ->  respuesta=0x%02h (esperado 0x08)", resultado);
    end

    // manda los tres bytes
    initial begin
        rx    = 1'b1;
        reset = 1'b1;
        #100;
        reset = 1'b0;
        #100;

        send_byte(8'h05);
        #(BIT_NS*2);
        send_byte(8'h03);
        #(BIT_NS*2);
        send_byte({2'b00, 6'b100000});

        #(BIT_NS*6);
        $finish;
    end

endmodule