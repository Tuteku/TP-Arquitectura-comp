`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/15/2026 07:16:23 PM
// Design Name: 
// Module Name: baud_rate_generator
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


module baud_rate_generator #(
        parameter CLK_FREQ = 100000000,
        parameter BAUD_RATE = 19200
    )
    (
        input wire i_clk,
        input wire i_reset,
        output wire o_tick   
    );
    
    localparam M = (CLK_FREQ/(BAUD_RATE*16)); // Ciclos necesarios para contar un tick
    localparam NB_COUNT = $clog2(M);
   
    reg [NB_COUNT-1:0] count; 
    
    always @(posedge i_clk)
    begin
        if(i_reset)
        begin
            count <= {NB_COUNT{1'b0}};
        end
        else if(count == M-1)
        begin
            count <= {NB_COUNT{1'b0}};
        end
        else
        begin
            count <= count + 1;            
        end
    end
    
    assign o_tick = (count == M-1); // Vale 1 durante todo el ciclo de M = 324 y 0 el resto.
endmodule
