`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2026 06:22:09 PM
// Design Name: 
// Module Name: top_uart_alu
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


module top_uart_alu #(
    parameter NB_DATA = 8,
    parameter NB_OP = 6
)
(
    input wire i_clk,
    input wire i_reset,
    input wire [NB_DATA-1:0] i_r_data,
    input wire i_rx_empty,
    input wire i_tx_full,
    output wire o_rd,
    output wire [NB_DATA-1:0] o_w_data,
    output wire o_wr
);
    localparam [1:0] RX_A    = 2'b00,
                     RX_B    = 2'b01,
                     RX_OP   = 2'b10,
                     TX_SEND = 2'b11;

    reg [1:0] state_reg, state_next;
    reg [NB_DATA-1:0] reg_a, reg_b, reg_a_next, reg_b_next;
    reg [NB_OP-1:0] reg_op, reg_op_next;
    reg rd, wr;

    always @(*) begin
            state_next  = state_reg;
            reg_a_next  = reg_a;
            reg_b_next  = reg_b;
            reg_op_next = reg_op;
            rd          = 1'b0;
            wr          = 1'b0;

        case (state_reg)
            RX_A : begin
                        if (!i_rx_empty) begin
                            reg_a_next = i_r_data;
                            rd = 1'b1;
                            state_next = RX_B;
                        end
                    end
            RX_B : begin
                        if (!i_rx_empty) begin
                            reg_b_next = i_r_data;
                            rd = 1'b1;
                            state_next = RX_OP;
                        end
                    end
            RX_OP : begin
                        if (!i_rx_empty) begin
                            reg_op_next = i_r_data[NB_OP-1:0];
                            rd = 1'b1;
                            state_next = TX_SEND;
                        end
                    end
            TX_SEND : begin
                        if (!i_tx_full) begin
                            wr = 1'b1;
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
        end
        else begin
        state_reg <= state_next;
        reg_a <= reg_a_next;
        reg_b <= reg_b_next;
        reg_op <= reg_op_next;
        end
    end

    // rd y wr son combinacionales: si se registraran, el flag de RX
    // bajaria un ciclo tarde y se leeria el mismo byte dos veces.
    assign o_rd = rd;
    assign o_wr = wr;

    alu #(
        .NB_DATA (NB_DATA),
        .NB_OP (NB_OP)
    ) u_alu
    (
        .i_a (reg_a),
        .i_b (reg_b),
        .i_op (reg_op),
        .o_alu (o_w_data)
    );

endmodule
