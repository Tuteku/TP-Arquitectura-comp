`timescale 1ns / 1ps
`default_nettype none // Nombre de variable no declarado hace que el compilador lo tome como error y no defina un wire.
// Verifica decoder: una instrucción de cada una de las 32 del subconjunto
// contra la tabla de control de docs/datapath.md, ebreak, las ilegales de D9
// y un addi con bits [24:20] distintos de 0 (no debe mostrar rs2).

`include "riscv_defs.vh"

module tb_decoder;
    // Filas de la tabla de control
    localparam T_R      = 0;
    localparam T_IMM    = 1;
    localparam T_LOAD   = 2;
    localparam T_STORE  = 3;
    localparam T_BRANCH = 4;
    localparam T_JAL    = 5;
    localparam T_JALR   = 6;
    localparam T_LUI    = 7;
    localparam T_EBREAK = 8;
    localparam T_ILEGAL = 9;

    localparam NB_CTRL = 28;

    reg  [31:0] i_instr;
    wire        o_reg_write;
    wire [2:0]  o_imm_sel;
    wire        o_alu_src;
    wire [1:0]  o_alu_op;
    wire        o_mem_read;
    wire        o_mem_write;
    wire [1:0]  o_result_src;
    wire        o_branch;
    wire        o_jump;
    wire        o_jalr;
    wire [4:0]  o_rs1;
    wire [4:0]  o_rs2;
    wire        o_use_rs1;
    wire        o_use_rs2;
    wire        o_halt;
    wire        o_illegal;

    integer errores;

    decoder u_decoder (
        .i_instr(i_instr),
        .o_reg_write(o_reg_write),
        .o_imm_sel(o_imm_sel),
        .o_alu_src(o_alu_src),
        .o_alu_op(o_alu_op),
        .o_mem_read(o_mem_read),
        .o_mem_write(o_mem_write),
        .o_result_src(o_result_src),
        .o_branch(o_branch),
        .o_jump(o_jump),
        .o_jalr(o_jalr),
        .o_rs1(o_rs1),
        .o_rs2(o_rs2),
        .o_use_rs1(o_use_rs1),
        .o_use_rs2(o_use_rs2),
        .o_halt(o_halt),
        .o_illegal(o_illegal)
    );

    // Todas las salidas en un vector, en el orden de las columnas de la tabla
    wire [NB_CTRL-1:0] obtenido = {o_reg_write, o_imm_sel, o_alu_src, o_alu_op,
                                   o_mem_read, o_mem_write, o_result_src,
                                   o_branch, o_jump, o_jalr,
                                   o_rs1, o_rs2, o_use_rs1, o_use_rs2,
                                   o_halt, o_illegal};

    // La tabla de docs/datapath.md fila por fila. Las celdas "–" van en x y no
    // se comparan. rs1 y rs2 salen de la instrucción solo si la fila los usa.
    function [NB_CTRL-1:0] esperado(input integer tipo, input [31:0] instr);
        reg [4:0] rs1;
        reg [4:0] rs2;
        begin
            rs1 = instr[19:15];
            rs2 = instr[24:20];
            case (tipo)
                //                     rw  imm_sel  src   alu_op  mr    mw    res_src  br    j     jalr  rs1    rs2    u1    u2    halt  ileg
                T_R      : esperado = {1'b1, 3'bxxx, 1'b0, 2'b10, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, rs1,  rs2,  1'b1, 1'b1, 1'b0, 1'b0};
                T_IMM    : esperado = {1'b1, 3'b000, 1'b1, 2'b11, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, rs1,  5'd0, 1'b1, 1'b0, 1'b0, 1'b0};
                T_LOAD   : esperado = {1'b1, 3'b000, 1'b1, 2'b00, 1'b1, 1'b0, 2'b01, 1'b0, 1'b0, 1'b0, rs1,  5'd0, 1'b1, 1'b0, 1'b0, 1'b0};
                T_STORE  : esperado = {1'b0, 3'b001, 1'b1, 2'b00, 1'b0, 1'b1, 2'bxx, 1'b0, 1'b0, 1'b0, rs1,  rs2,  1'b1, 1'b1, 1'b0, 1'b0};
                T_BRANCH : esperado = {1'b0, 3'b010, 1'bx, 2'bxx, 1'b0, 1'b0, 2'bxx, 1'b1, 1'b0, 1'b0, rs1,  rs2,  1'b1, 1'b1, 1'b0, 1'b0};
                T_JAL    : esperado = {1'b1, 3'b100, 1'bx, 2'bxx, 1'b0, 1'b0, 2'b10, 1'b0, 1'b1, 1'b0, 5'd0, 5'd0, 1'b0, 1'b0, 1'b0, 1'b0};
                T_JALR   : esperado = {1'b1, 3'b000, 1'b1, 2'b00, 1'b0, 1'b0, 2'b10, 1'b0, 1'b0, 1'b1, rs1,  5'd0, 1'b1, 1'b0, 1'b0, 1'b0};
                T_LUI    : esperado = {1'b1, 3'b011, 1'b1, 2'b00, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 5'd0, 5'd0, 1'b0, 1'b0, 1'b0, 1'b0};
                T_EBREAK : esperado = {1'b0, 3'bxxx, 1'bx, 2'bxx, 1'b0, 1'b0, 2'bxx, 1'b0, 1'b0, 1'b0, 5'd0, 5'd0, 1'b0, 1'b0, 1'b1, 1'b0};
                default  : esperado = {1'b0, 3'bxxx, 1'bx, 2'bxx, 1'b0, 1'b0, 2'bxx, 1'b0, 1'b0, 1'b0, 5'd0, 5'd0, 1'b0, 1'b0, 1'b1, 1'b1};
            endcase
        end
    endfunction

    task check(input [31:0] instr, input integer tipo, input [8*24-1:0] nombre);
        reg [NB_CTRL-1:0] esp;
        integer k;
        reg     falla;
        begin
            i_instr = instr;
            esp     = esperado(tipo, instr);
            #1;
            falla = 1'b0;
            for (k = 0; k < NB_CTRL; k = k + 1)
                if (esp[k] !== 1'bx && obtenido[k] !== esp[k]) // Un valor indefinido en la salida cuenta como distinto
                    falla = 1'b1;
            if (falla) begin
                $display("  ERROR %0s (%h): obtenido %b, esperado %b", nombre, instr, obtenido, esp);
                errores = errores + 1;
            end
        end
    endtask

    initial begin
        errores = 0;

        // Tipo R
        check(32'h002081B3, T_R, "add x3, x1, x2");
        check(32'h402081B3, T_R, "sub x3, x1, x2");
        check(32'h002091B3, T_R, "sll x3, x1, x2");
        check(32'h0020A1B3, T_R, "slt x3, x1, x2");
        check(32'h0020B1B3, T_R, "sltu x3, x1, x2");
        check(32'h0020C1B3, T_R, "xor x3, x1, x2");
        check(32'h0020D1B3, T_R, "srl x3, x1, x2");
        check(32'h4020D1B3, T_R, "sra x3, x1, x2");
        check(32'h0020E1B3, T_R, "or x3, x1, x2");
        check(32'h0020F1B3, T_R, "and x3, x1, x2");

        // Tipo I aritméticas
        check(32'hFFB30293, T_IMM, "addi x5, x6, -5");
        check(32'h00732293, T_IMM, "slti x5, x6, 7");
        check(32'h00733293, T_IMM, "sltiu x5, x6, 7");
        check(32'hFFF34293, T_IMM, "xori x5, x6, -1");
        check(32'h05536293, T_IMM, "ori x5, x6, 85");
        check(32'h0FF37293, T_IMM, "andi x5, x6, 255");
        check(32'h00331293, T_IMM, "slli x5, x6, 3");
        check(32'h00335293, T_IMM, "srli x5, x6, 3");
        check(32'h40335293, T_IMM, "srai x5, x6, 3");

        // Loads
        check(32'h00850483, T_LOAD, "lb x9, 8(x10)");
        check(32'h00851483, T_LOAD, "lh x9, 8(x10)");
        check(32'h00852483, T_LOAD, "lw x9, 8(x10)");
        check(32'h00854483, T_LOAD, "lbu x9, 8(x10)");
        check(32'h00855483, T_LOAD, "lhu x9, 8(x10)");

        // Stores
        check(32'hFEC58E23, T_STORE, "sb x12, -4(x11)");
        check(32'hFEC59E23, T_STORE, "sh x12, -4(x11)");
        check(32'hFEC5AE23, T_STORE, "sw x12, -4(x11)");

        // Branches, saltos y lui
        check(32'hFE008CE3, T_BRANCH, "beq x1, x0, -8");
        check(32'h00E69863, T_BRANCH, "bne x13, x14, 16");
        check(32'h010000EF, T_JAL,    "jal x1, 16");
        check(32'h00408067, T_JALR,   "jalr x0, 4(x1)");
        check(32'hFFFFF3B7, T_LUI,    "lui x7, 0xFFFFF");      // bits [19:15] = 11111, o_rs1 = 0

        // HALT
        check(`INSTR_EBREAK, T_EBREAK, "ebreak");

        // addi con bits [24:20] = 11111: no debe aparecer como rs2
        check(32'h7FF30293, T_IMM, "addi x5, x6, 2047");

        // Ilegales: opcode desconocido
        check(32'h00000000, T_ILEGAL, "0x00000000");
        check(32'h0000007F, T_ILEGAL, "opcode 1111111");
        check(32'h12345397, T_ILEGAL, "auipc x7, 0x12345");
        check(32'h0FF0000F, T_ILEGAL, "fence");
        check(32'h00000073, T_ILEGAL, "ecall");
        check(32'h00200073, T_ILEGAL, "SYSTEM distinto de ebreak");

        // Ilegales: funct3 no implementado
        check(32'h00853483, T_ILEGAL, "load funct3 011");
        check(32'h00856483, T_ILEGAL, "load funct3 110");
        check(32'h00857483, T_ILEGAL, "load funct3 111");
        check(32'h00C5B223, T_ILEGAL, "store funct3 011");
        check(32'h0020C463, T_ILEGAL, "blt x1, x2, 8");
        check(32'h0020D463, T_ILEGAL, "bge x1, x2, 8");
        check(32'h0020E463, T_ILEGAL, "bltu x1, x2, 8");
        check(32'h0020F463, T_ILEGAL, "bgeu x1, x2, 8");

        // Ilegales: funct7 inválido
        check(32'h022081B3, T_ILEGAL, "mul (funct7 0000001)");
        check(32'h4020C1B3, T_ILEGAL, "xor con funct7 0100000");
        check(32'h40331293, T_ILEGAL, "slli con funct7 0100000");
        check(32'h02335293, T_ILEGAL, "srli con funct7 0000001");

        if (errores == 0)
            $display("  RESULTADO        : TEST PASSED");
        else
            $display("  RESULTADO        : TEST FAILED (%0d errores)", errores);
        $finish;
    end
endmodule
