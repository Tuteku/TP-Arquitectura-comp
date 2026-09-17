module alu_top #(
    parameter NB_DATA = 8,
    parameter NB_OP = 6
)
(
    input wire [NB_DATA-1:0] i_switches,
    input wire i_load_a,
    input wire i_load_b,
    input wire i_load_c,
    input wire i_clk,
    output wire [NB_DATA-1:0] o_leds,
    input  wire  i_reset
);
    
    reg [NB_OP-1:0] r_op;
    reg [NB_DATA-1:0] r_a;
    reg [NB_DATA-1:0] r_b;
    
     always @(posedge i_clk) begin
        if (i_reset) 
        begin
            r_a  <= {NB_DATA{1'b0}};
            r_b  <= {NB_DATA{1'b0}};
            r_op <= {NB_OP{1'b0}};
        end
        else
        begin
            if (i_load_a) r_a  <= i_switches;
            if (i_load_b) r_b  <= i_switches;
            if (i_load_c) r_op <= i_switches[NB_OP-1:0];
        end
    end
    alu #(
        .NB_DATA (NB_DATA),
        .NB_OP (NB_OP)
    ) u_alu
    ( 
        .i_a (r_a),
        .i_b (r_b),
        .i_op (r_op),
        .o_alu (o_leds)
    );
    
    
endmodule