`timescale 1ns / 1ps
`default_nettype none
// Banco de 32 registros de 32 bits. x0 no se guarda y se lee siempre como 0.
// Escritura en el flanco positivo; los puertos rs1 y rs2 tienen bypass para que
// WB e ID puedan usar el mismo registro en el mismo ciclo. El puerto de la Debug
// Unit lee sin bypass (se usa con el procesador detenido).

module register_file #(
    parameter NB_DATA = 32,
    parameter NB_ADDR = 5
)
(
    input  wire                 i_clk,
    input  wire                 i_reset,
    input  wire                 i_enable,
    // Escritura desde WB (i_reg_write ya incluye memwb_valid)
    input  wire                 i_reg_write,
    input  wire [NB_ADDR-1:0]   i_rd,
    input  wire [NB_DATA-1:0]   i_wdata,
    // Lectura desde ID
    input  wire [NB_ADDR-1:0]   i_rs1,
    input  wire [NB_ADDR-1:0]   i_rs2,
    output wire [NB_DATA-1:0]   o_rs1_data,
    output wire [NB_DATA-1:0]   o_rs2_data,
    // Lectura desde la Debug Unit
    input  wire [NB_ADDR-1:0]   i_dbg_reg_addr,
    output wire [NB_DATA-1:0]   o_dbg_reg_data
);

    localparam NUM_REGS = 2**NB_ADDR;

    // Solo x1..x31: x0 no tiene registro
    reg [NB_DATA-1:0] regs [1:NUM_REGS-1];

    wire w_en = i_enable && i_reg_write && (i_rd != 0);

    integer i;

    // Reset síncrono con prioridad sobre el enable
    always @(posedge i_clk) begin
        if (i_reset) begin
            for (i = 1; i < NUM_REGS; i = i + 1)
                regs[i] <= {NB_DATA{1'b0}};
        end
        else if (w_en) begin
            regs[i_rd] <= i_wdata;
        end
    end

    // Lectura combinacional: x0 -> 0, coincidencia con la escritura -> bypass
    assign o_rs1_data = (i_rs1 == 0)            ? {NB_DATA{1'b0}} :
                        (w_en && i_rs1 == i_rd) ? i_wdata         :
                                                  regs[i_rs1];

    assign o_rs2_data = (i_rs2 == 0)            ? {NB_DATA{1'b0}} :
                        (w_en && i_rs2 == i_rd) ? i_wdata         :
                                                  regs[i_rs2];

    assign o_dbg_reg_data = (i_dbg_reg_addr == 0) ? {NB_DATA{1'b0}} :
                                                    regs[i_dbg_reg_addr];

endmodule

`default_nettype wire
