`timescale 1ns / 1ps
// Test bench del banco de registros. Compara los tres puertos de lectura contra
// un arreglo de referencia: x0 fijo en 0, bypass, enable, reset y lecturas y
// escrituras aleatorias.

module tb_register_file;
    localparam NB_DATA = 32;
    localparam NB_ADDR = 5;
    localparam NUM_REGS = 2**NB_ADDR;
    localparam CANT = 300;

    reg                  i_clk;
    reg                  i_reset;
    reg                  i_enable;
    reg                  i_reg_write;
    reg  [NB_ADDR-1:0]   i_rd;
    reg  [NB_DATA-1:0]   i_wdata;
    reg  [NB_ADDR-1:0]   i_rs1;
    reg  [NB_ADDR-1:0]   i_rs2;
    reg  [NB_ADDR-1:0]   i_dbg_reg_addr;
    wire [NB_DATA-1:0]   o_rs1_data;
    wire [NB_DATA-1:0]   o_rs2_data;
    wire [NB_DATA-1:0]   o_dbg_reg_data;

    // Modelo de referencia: ref_regs[0] queda siempre en 0
    reg  [NB_DATA-1:0]   ref_regs [0:NUM_REGS-1];
    reg  [NB_DATA-1:0]   esp_rs1;
    reg  [NB_DATA-1:0]   esp_rs2;
    reg                  ref_w_en;

    integer errores;
    integer casos;
    integer escrituras;
    integer i;

    register_file #(
        .NB_DATA(NB_DATA),
        .NB_ADDR(NB_ADDR)
    ) u_01 (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_enable(i_enable),
        .i_reg_write(i_reg_write),
        .i_rd(i_rd),
        .i_wdata(i_wdata),
        .i_rs1(i_rs1),
        .i_rs2(i_rs2),
        .o_rs1_data(o_rs1_data),
        .o_rs2_data(o_rs2_data),
        .i_dbg_reg_addr(i_dbg_reg_addr),
        .o_dbg_reg_data(o_dbg_reg_data)
    );

    always #5 i_clk = ~i_clk;

    task check;
        input [8*24-1:0]    nombre;
        input [NB_DATA-1:0] obtenido;
        input [NB_DATA-1:0] esperado;
        begin
            casos = casos + 1;
            if (obtenido !== esperado) begin
                errores = errores + 1;
                $display("ERROR %0s t=%0t: obtenido=%h esperado=%h", nombre, $time, obtenido, esperado);
            end
        end
    endtask

    // Un ciclo completo: cambia las entradas en el flanco negativo, revisa los
    // tres puertos antes del flanco positivo (ahí se ve el bypass) y actualiza
    // el modelo cuando el banco escribe.
    task ciclo;
        input               en;
        input               we;
        input [NB_ADDR-1:0] rd;
        input [NB_DATA-1:0] wdata;
        input [NB_ADDR-1:0] rs1;
        input [NB_ADDR-1:0] rs2;
        input [NB_ADDR-1:0] dbg;
        begin
            @(negedge i_clk);
            i_enable       = en;
            i_reg_write    = we;
            i_rd           = rd;
            i_wdata        = wdata;
            i_rs1          = rs1;
            i_rs2          = rs2;
            i_dbg_reg_addr = dbg;
            #1;
            ref_w_en = en && we && (rd != 0);
            esp_rs1  = (ref_w_en && rs1 == rd && rs1 != 0) ? wdata : ref_regs[rs1];
            esp_rs2  = (ref_w_en && rs2 == rd && rs2 != 0) ? wdata : ref_regs[rs2];
            check("rs1", o_rs1_data, esp_rs1);
            check("rs2", o_rs2_data, esp_rs2);
            check("dbg", o_dbg_reg_data, ref_regs[dbg]);
            @(posedge i_clk);
            if (ref_w_en) begin
                ref_regs[rd] = wdata;
                escrituras = escrituras + 1;
            end
        end
    endtask

    // Ciclo de reset con el enable indicado; además pide una escritura para
    // comprobar que el reset tiene prioridad.
    task ciclo_reset;
        input en;
        begin
            @(negedge i_clk);
            i_reset     = 1'b1;
            i_enable    = en;
            i_reg_write = 1'b1;
            i_rd        = 5'd3;
            i_wdata     = 32'hBAD0_0003;
            @(posedge i_clk);
            for (i = 0; i < NUM_REGS; i = i + 1)
                ref_regs[i] = {NB_DATA{1'b0}};
            @(negedge i_clk);
            i_reset     = 1'b0;
            i_reg_write = 1'b0;
        end
    endtask

    // Recorre los 32 registros por el puerto de la Debug Unit sin escribir
    task verificar_todos;
        begin
            for (i = 0; i < NUM_REGS; i = i + 1)
                ciclo(1'b1, 1'b0, 5'd0, 32'd0, 5'd0, 5'd0, i);
        end
    endtask

    // Escribe un valor distinto en cada registro, de x1 a x31
    task llenar;
        input [NB_DATA-1:0] base;
        begin
            for (i = 1; i < NUM_REGS; i = i + 1)
                ciclo(1'b1, 1'b1, i, base + i, 5'd0, 5'd0, 5'd0);
        end
    endtask

initial
    begin
        errores        = 0;
        casos          = 0;
        escrituras     = 0;
        i_clk          = 1'b0;
        i_reset        = 1'b0;
        i_enable       = 1'b0;
        i_reg_write    = 1'b0;
        i_rd           = 0;
        i_wdata        = 0;
        i_rs1          = 0;
        i_rs2          = 0;
        i_dbg_reg_addr = 0;

        // Reset inicial con enable = 0
        ciclo_reset(1'b0);
        verificar_todos;

        // ---- El puerto de la Debug Unit lee cada registro ----
        llenar(32'hA000_0000);
        for (i = 0; i < NUM_REGS; i = i + 1) begin
            @(negedge i_clk);
            i_reg_write    = 1'b0;
            i_dbg_reg_addr = i;
            #1;
            check("dbg lee cada reg", o_dbg_reg_data, (i == 0) ? 32'd0 : 32'hA000_0000 + i);
        end

        // ---- El reset limpia todo, también con enable = 0 ----
        ciclo_reset(1'b0);
        for (i = 0; i < NUM_REGS; i = i + 1) begin
            @(negedge i_clk);
            i_dbg_reg_addr = i;
            #1;
            check("reset en=0", o_dbg_reg_data, 32'd0);
        end
        llenar(32'hB000_0000);
        ciclo_reset(1'b1);
        verificar_todos;

        // ---- x0: con reg_write = 1 y dato != 0 sigue leyendo 0 ----
        llenar(32'hC000_0000);
        @(negedge i_clk);
        i_enable       = 1'b1;
        i_reg_write    = 1'b1;
        i_rd           = 5'd0;
        i_wdata        = 32'hDEAD_BEEF;
        i_rs1          = 5'd0;
        i_rs2          = 5'd0;
        i_dbg_reg_addr = 5'd0;
        #1;     // ciclo de la escritura: el bypass no actúa con rd = 0
        check("x0 rs1 mismo ciclo", o_rs1_data, 32'd0);
        check("x0 rs2 mismo ciclo", o_rs2_data, 32'd0);
        check("x0 dbg mismo ciclo", o_dbg_reg_data, 32'd0);
        @(posedge i_clk);
        @(negedge i_clk);
        i_reg_write = 1'b0;
        #1;     // ciclo siguiente
        check("x0 rs1 despues", o_rs1_data, 32'd0);
        check("x0 rs2 despues", o_rs2_data, 32'd0);
        check("x0 dbg despues", o_dbg_reg_data, 32'd0);
        // Lo demás quedó igual
        verificar_todos;

        // ---- Bypass por rs1, por rs2 y por los dos a la vez ----
        // x5 tiene C000_0005; en el ciclo de la escritura se ve el dato nuevo
        @(negedge i_clk);
        i_enable       = 1'b1;
        i_reg_write    = 1'b1;
        i_rd           = 5'd5;
        i_wdata        = 32'h1111_1111;
        i_rs1          = 5'd5;
        i_rs2          = 5'd6;
        i_dbg_reg_addr = 5'd5;
        #1;
        check("bypass rs1", o_rs1_data, 32'h1111_1111);
        check("bypass rs1 otro rs2", o_rs2_data, 32'hC000_0006);
        check("dbg sin bypass", o_dbg_reg_data, 32'hC000_0005);
        @(posedge i_clk);
        ref_regs[5] = 32'h1111_1111;

        @(negedge i_clk);
        i_rd           = 5'd6;
        i_wdata        = 32'h2222_2222;
        i_rs1          = 5'd5;
        i_rs2          = 5'd6;
        i_dbg_reg_addr = 5'd6;
        #1;
        check("bypass rs2 otro rs1", o_rs1_data, 32'h1111_1111);
        check("bypass rs2", o_rs2_data, 32'h2222_2222);
        check("dbg sin bypass", o_dbg_reg_data, 32'hC000_0006);
        @(posedge i_clk);
        ref_regs[6] = 32'h2222_2222;

        @(negedge i_clk);
        i_rd           = 5'd31;
        i_wdata        = 32'h3333_3333;
        i_rs1          = 5'd31;
        i_rs2          = 5'd31;
        i_dbg_reg_addr = 5'd31;
        #1;
        check("bypass rs1 y rs2", o_rs1_data, 32'h3333_3333);
        check("bypass rs1 y rs2", o_rs2_data, 32'h3333_3333);
        check("dbg sin bypass", o_dbg_reg_data, 32'hC000_001F);
        @(posedge i_clk);
        ref_regs[31] = 32'h3333_3333;
        verificar_todos;

        // ---- Sin bypass con reg_write = 0 o enable = 0 ----
        @(negedge i_clk);
        i_enable       = 1'b1;
        i_reg_write    = 1'b0;
        i_rd           = 5'd7;
        i_wdata        = 32'h4444_4444;
        i_rs1          = 5'd7;
        i_rs2          = 5'd7;
        #1;
        check("we=0 rs1 viejo", o_rs1_data, 32'hC000_0007);
        check("we=0 rs2 viejo", o_rs2_data, 32'hC000_0007);
        @(posedge i_clk);

        @(negedge i_clk);
        i_enable       = 1'b0;
        i_reg_write    = 1'b1;
        #1;
        check("en=0 rs1 viejo", o_rs1_data, 32'hC000_0007);
        check("en=0 rs2 viejo", o_rs2_data, 32'hC000_0007);
        @(posedge i_clk);
        verificar_todos;

        // ---- Con enable = 0 no se escribe nada ----
        for (i = 1; i < NUM_REGS; i = i + 1)
            ciclo(1'b0, 1'b1, i, 32'hEEEE_0000 + i, i, NUM_REGS - i, i);
        for (i = 1; i < NUM_REGS; i = i + 1) begin
            @(negedge i_clk);
            i_reg_write    = 1'b0;
            i_dbg_reg_addr = i;
            #1;
            check("en=0 no escribe", o_dbg_reg_data, ref_regs[i]);
        end

        // ---- Escrituras y lecturas aleatorias contra el modelo ----
        escrituras = 0;
        for (i = 0; i < CANT; i = i + 1)
            ciclo(($random % 8) != 0, ($random % 4) != 0, $random, $random,
                  $random, $random, $random);
        verificar_todos;

        $display("=====================================");
        $display("  Casos ejecutados : %0d", casos);
        $display("  Escrit. aleat.   : %0d", escrituras);
        $display("  Errores          : %0d", errores);
        if (errores == 0 && escrituras >= 100)
            $display("  RESULTADO        : TEST PASSED");
        else
            $display("  RESULTADO        : TEST FAILED");
        $display("=====================================");
        $finish;
    end

endmodule
