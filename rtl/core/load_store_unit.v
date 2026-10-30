`timescale 1ns / 1ps
`default_nettype none // Desactiva la creacion automatica de wire, usar un nombre no declarado es un error de compilacion
// Unidad de load/store de la etapa MEM (docs/decisiones.md, D3).
// Stores: arma la máscara de bytes y replica el dato en la palabra.
// Loads: toma el byte o la media palabra de la palabra leída y la extiende.
// Los desalineados no se detectan: sh/lh/lhu ignoran addr[0] y sw/lw
// ignoran addr[1:0]. Un funct3 no válido da máscara 0 y dato leído 0.

`include "riscv_defs.vh"

module load_store_unit
(
    input  wire [2:0]   i_funct3,
    input  wire [1:0]   i_addr,         // addr[1:0]: byte dentro de la palabra
    // Stores
    input  wire [31:0]  i_store_data,   // rs2
    output reg  [3:0]   o_wmask,
    output reg  [31:0]  o_wdata,
    // Loads
    input  wire [31:0]  i_rdata,        // palabra completa leída de la DMEM
    output reg  [31:0]  o_load_data
);

    // Byte y media palabra elegidos de la palabra leída
    wire [7:0]  byte_sel = i_rdata[8*i_addr +: 8];
    wire [15:0] half_sel = i_addr[1] ? i_rdata[31:16] : i_rdata[15:0];

    // Stores
    always @(*)
    begin
        o_wmask = 4'b0000;
        o_wdata = i_store_data;
        case (i_funct3)
            `F3_SB  : begin
                o_wmask = 4'b0001 << i_addr;
                o_wdata = {4{i_store_data[7:0]}};
            end
            `F3_SH  : begin
                o_wmask = 4'b0011 << {i_addr[1], 1'b0};
                o_wdata = {2{i_store_data[15:0]}};
            end
            `F3_SW  : o_wmask = 4'b1111;
            default : o_wmask = 4'b0000;
        endcase
    end

    // Loads
    always @(*)
    begin
        case (i_funct3)
            `F3_LB  : o_load_data = {{24{byte_sel[7]}}, byte_sel};
            `F3_LH  : o_load_data = {{16{half_sel[15]}}, half_sel};
            `F3_LW  : o_load_data = i_rdata;
            `F3_LBU : o_load_data = {24'd0, byte_sel};
            `F3_LHU : o_load_data = {16'd0, half_sel};
            default : o_load_data = 32'd0; // 011, 110, 111
        endcase
    end

endmodule
