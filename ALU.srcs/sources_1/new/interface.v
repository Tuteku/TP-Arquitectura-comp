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


module interface #(
    parameter NB_DATA = 8,
    parameter NB_OP = 6
)
(
    input wire [NB_DATA-1:0] i_data,
    input wire i_rx_done,
    input wire i_clk,
    input wire i_tx_done,
    input wire i_reset,
    input wire [NB_DATA-1:0] i_data_alu,
    output wire [NB_DATA-1:0] o_data_tx,
    output wire o_tx_start,
    output wire [NB_DATA-1:0] o_alu_a,
    output wire [NB_DATA-1:0] o_alu_b,
    output wire [NB_OP-1:0]   o_alu_op
);    
    localparam [2:0] RX_A = 3'b000,
                     RX_B = 3'b001,
                     RX_OP = 3'b010,
                     TX_SEND = 3'b011,
                     TX_WAIT = 3'b100;
                     
    reg [2:0] state_reg, state_next;  
    reg [NB_DATA-1:0] reg_a, reg_b, reg_a_next, reg_b_next;
    reg [NB_OP-1:0] reg_op, reg_op_next;  
    reg [NB_DATA-1:0] data_tx, data_tx_next;
    reg tx_start, tx_start_next;
        
    always @(*) begin
            state_next   = state_reg;
            reg_a_next    = reg_a;
            reg_b_next    = reg_b;
            reg_op_next   = reg_op;
            data_tx_next  = data_tx;
            tx_start_next = 1'b0;
    
        case (state_reg) 
            RX_A : begin                        
                        if (i_rx_done) begin
                            state_next = RX_B;                                                        
                            reg_a_next = i_data;    
                        end
                    end    
            RX_B :  begin                         
                         if(i_rx_done) begin                         
                            state_next = RX_OP;
                            reg_b_next = i_data;                           
                         end
                     end
            RX_OP : begin                         
                         if(i_rx_done) begin                         
                            state_next = TX_SEND;
                            reg_op_next = i_data[NB_OP-1:0];                           
                         end
                     end                                               
            TX_SEND : begin                                                                          
                        state_next = TX_WAIT;
                        data_tx_next = i_data_alu;
                        tx_start_next = {1'b1};                                                    
                     end
            TX_WAIT : begin                         
                         if(i_tx_done) begin                         
                            state_next = RX_A;                                                       
                         end
                     end                 
            default : state_next = RX_A; 
        endcase                                                                   
    end
            
    always @(posedge i_clk) begin
        if(i_reset) begin
            state_reg <= RX_A;
            reg_a <= {NB_DATA{1'b0}};
            reg_b <= {NB_DATA{1'b0}};
            reg_op <= {NB_OP{1'b0}};
            data_tx <= {NB_DATA{1'b0}};
            tx_start <= {1'b0};          
        end
        else begin
        state_reg <= state_next;
        reg_a <= reg_a_next;
        reg_b <= reg_b_next;
        reg_op <= reg_op_next;
        data_tx <= data_tx_next;
        tx_start <= tx_start_next;
        end
    end
    
    assign o_alu_a    = reg_a;
    assign o_alu_b    = reg_b;
    assign o_alu_op   = reg_op;
    assign o_data_tx  = data_tx;
    assign o_tx_start = tx_start;
        
endmodule

