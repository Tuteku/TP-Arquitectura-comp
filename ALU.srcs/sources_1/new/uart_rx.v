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
    localparam [1:0] IDLE = 2'b00,
                     START = 2'b01,
                     DATA = 2'b10,
                     STOP = 2'b11;
                     
    localparam NB_N = $clog2(NB_DATA);
    
    reg [1:0] state_reg, state_next;
    reg [3 : 0] s_reg, s_next;
    reg [NB_N : 0] n_reg, n_next;
    reg [NB_DATA-1 : 0] b_reg, b_next;
        
    always@(posedge i_clk) begin
        if(i_reset) begin
            state_reg <= IDLE;
            s_reg <= {4{1'b0}};
            n_reg <= {NB_N{1'b0}};
            b_reg <= {NB_DATA{1'b0}};
        end
        else begin
            state_reg <= state_next;
            s_reg <= s_next;
            n_reg <= n_next;
            b_reg <= b_next;
        end
    end
endmodule
