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
    reg [NB_N - 1: 0] n_reg, n_next;
    reg [NB_DATA-1 : 0] b_reg, b_next;
    reg rx_done_tick;
        
    always @(*) begin
            state_next   = state_reg;
            s_next       = s_reg;
            n_next       = n_reg;
            b_next       = b_reg;
            rx_done_tick = 1'b0;
    
        case (state_reg) 
            IDLE : if (~i_rx) begin
                        state_next = START;
                        s_next = 0;
                   end
            START :  begin
                         if(i_s_tick) begin
                             if(s_reg == 7) begin
                                 state_next = DATA;
                                 s_next = {4{1'b0}};
                                 n_next = {NB_N{1'b0}};
                             end
                             else begin
                                 s_next = s_reg + 1;
                             end
                         end                            
                     end
            DATA : begin
                        if(i_s_tick) begin
                            if(s_reg == 15) begin
                                s_next = {4{1'b0}};                               
                                b_next = (b_reg << 1'b1) + i_rx; //push de datos (ver si no esta al reves).
                                if(n_reg == NB_DATA-1) begin
                                    state_next = STOP;
                                end
                                else begin
                                    n_next = n_reg + 1;
                                end                                
                            end
                            else begin
                                s_next = s_reg + 1;
                            end
                        end                                                                                                    
                    end                                               
            STOP :  begin
                        if(i_s_tick) begin
                            if(s_reg == 15) begin
                                state_next = IDLE;
                                s_next = {4{1'b0}};
                                rx_done_tick = 1'b1; 
                            end
                            else begin
                                s_next = s_reg + 1;
                            end
                        end                                                           
                    end
            default : state_next = IDLE;
        endcase                                                                   
    end
            
    always @(posedge i_clk) begin
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
    
    assign o_dout = b_reg; 
    assign o_rx_done_tick = rx_done_tick;
    
endmodule
