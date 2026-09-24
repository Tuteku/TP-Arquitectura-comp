`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/24/2026 07:01:52 PM
// Design Name: 
// Module Name: uart_tx
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


module uart_tx #(
    parameter NB_DATA = 8,
    parameter SB_TICK = 16
)
(
    input wire [NB_DATA-1:0] i_data,
    input wire i_tx_start,
    input wire i_clk,
    input wire i_s_tick,
    input wire i_reset,   
    output wire o_tx,
    output wire o_tx_done      
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
    reg o_tx_reg, o_tx_next;
    reg tx_done_tick;
    
        
    always @(*) begin
            state_next   = state_reg;
            s_next       = s_reg;
            n_next       = n_reg;
            b_next       = b_reg;
            o_tx_next    = o_tx_reg;
            tx_done_tick = 1'b0;
    
        case (state_reg) 
            IDLE : begin
                        o_tx_next = {1'b1};
                        if (i_tx_start) begin
                            state_next = START;
                            s_next = {4{1'b0}};
                            b_next = i_data;
                            o_tx_next = {1'b0};
                        end
                    end    
            START :  begin
                         o_tx_next = {1'b1};
                         if(i_s_tick) begin                         
                             if(s_reg == 15) begin
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
                    o_tx_next = b_reg[0];               
                        if(i_s_tick) begin
                            if(s_reg == 15) begin
                                s_next = {4{1'b0}}; 
                                if(n_reg == NB_DATA-1) begin
                                    state_next = STOP;
                                end
                                else begin
                                    n_next = n_reg + 1;
                                    b_next = {1'b0, b_reg[NB_DATA-1:1]}; //concatenacion de datos.
                                end                                
                            end
                            else begin
                                s_next = s_reg + 1;
                            end
                        end                                                                                                    
                    end                                               
            STOP :  begin
                        o_tx_next = 1'b0;                    
                        if(i_s_tick) begin
                            if(s_reg == 15) begin
                                state_next = IDLE;
                                s_next = {4{1'b0}};
                                tx_done_tick = 1'b1; 
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
            o_tx_reg <= {1'b1};
        end
        else begin
        state_reg <= state_next;
        s_reg <= s_next;
        n_reg <= n_next;
        b_reg <= b_next;
        o_tx_reg <= o_tx_next;
        end
    end
    
    assign o_tx = o_tx_reg; 
    assign o_tx_done = tx_done_tick;
    
endmodule
