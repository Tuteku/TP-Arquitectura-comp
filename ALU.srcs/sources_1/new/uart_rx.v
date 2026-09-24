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
    output reg [NB_DATA-1:0] o_dout,
    output wire o_rx_done_tick       
);    
    localparam [1:0] IDLE = 2'b00,
                     START = 2'b01,
                     DATA = 2'b10,
                     STOP = 2'b11;
                     
    localparam NB_N = $clog2(NB_DATA);
    
    reg [1:0] state_reg, state_next;
    reg [3 : 0] s_reg;
    reg [NB_N - 1: 0] n_reg;
    reg [NB_DATA-1 : 0] b_reg, b_reg_aux;
        
    always@(posedge i_clk) begin
        if(i_reset) begin
            state_reg <= IDLE;
            s_reg <= {4{1'b0}};
            n_reg <= {NB_N{1'b0}};
            b_reg <= {NB_DATA{1'b0}};
        end
        else begin
            case (state_reg) 
                IDLE : if (~i_rx) state_next = START;
                START :  begin
                             if(i_s_tick) begin
                                 if(s_reg == 7) begin
                                     state_next <= DATA;
                                     s_reg <= {4{1'b0}};
                                 end
                                 else begin
                                     s_reg <= s_reg + 1;
                                 end
                             end                            
                         end
                DATA : begin
                            if(i_s_tick) begin
                                if(n_reg == 7) begin
                                    state_next = STOP;
                                    n_reg <= {NB_N{1'b0}};
                                    b_reg <= b_reg_aux;
                                    b_reg_aux <= {NB_DATA{1'b0}};                                    
                                end
                                else if (s_reg == 15) begin
                                    n_reg <= n_reg + 1;
                                    s_reg <= {4{1'b0}};
                                    b_reg_aux <= (b_reg_aux << 1'b1) + i_rx; //push de datos.
                                end
                                else begin
                                    s_reg <= s_reg + 1;
                                end
                            end                                                                                                    
                        end                                               
                STOP :  begin
                            if(i_s_tick) begin
                                if(s_reg == 7) begin
                                    state_next <= IDLE;
                                    s_reg <= {4{1'b0}};
                                end
                                else begin
                                    s_reg <= s_reg + 1;
                                end
                            end                                                           
                        end
                default : state_next = IDLE;
            endcase                        
            
            o_dout <= b_reg;                              
        end
    end
endmodule
