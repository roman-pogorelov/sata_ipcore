/*
    //------------------------------------------------------------------------------------
    //      Модуль отправки фреймов SATA Register FIS
    sata_reg_fis_sender
    the_sata_reg_fis_sender
    (
        // Сброс и тактирование
        .reset          (), // i
        .clk            (), // i
        
        // Входной параллельный интерфейс передаваемого фрейма
        .i_dat_type     (), // i  [7 : 0]
        .i_dat_command  (), // i  [7 : 0]
        .i_dat_address  (), // i  [47 : 0]
        .i_dat_scount   (), // i  [15 : 0]
        .i_val          (), // i
        .i_rdy          (), // o
        
        // Выходной последовательный интерфейс передаваемого фрейма
        .o_dat          (), // o  [31 : 0]
        .o_val          (), // o
        .o_eop          (), // o
        .o_rdy          ()  // i
    ); // the_sata_reg_fis_sender
*/

module sata_reg_fis_sender
(
    // Сброс и тактирование
    input  logic            reset,
    input  logic            clk,
    
    // Входной параллельный интерфейс передаваемого фрейма
    input  logic [7 : 0]    i_dat_type,
    input  logic [7 : 0]    i_dat_command,
    input  logic [47 : 0]   i_dat_address,
    input  logic [15 : 0]   i_dat_scount,
    input  logic            i_val,
    output logic            i_rdy,
    
    // Выходной последовательный интерфейс передаваемого фрейма
    output logic [31 : 0]   o_dat,
    output logic            o_val,
    output logic            o_eop,
    input  logic            o_rdy
);
    //------------------------------------------------------------------------------------
    //      Объявление констант
    localparam int unsigned FIS_LEN = 5;
    
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic [FIS_LEN - 1 : 0][31 : 0] fis_reg;
    logic                           rdy_reg;
    logic                           eop_reg;
    logic [$clog2(FIS_LEN) - 1 : 0] len_cnt;
    
    //------------------------------------------------------------------------------------
    //      Сдвиговый регистр для "выталкивания" фрейма
    always @(posedge reset, posedge clk)
        if (reset)
            fis_reg <= '0;
        else if (i_val & i_rdy)
            fis_reg <= {
                32'h00000000,
                16'h0000, i_dat_scount,
                8'h00, i_dat_address[47 : 24],
                8'hE0, i_dat_address[23 : 0],
                8'h00, i_dat_command, 8'h80, i_dat_type
            };
        else if (o_val & o_rdy)
            fis_reg <= {{32{1'b0}}, fis_reg[4 : 1]};
        else
            fis_reg <= fis_reg;
    assign o_dat = fis_reg[0];
    
    //------------------------------------------------------------------------------------
    //      Регистр готовности
    initial rdy_reg = 1'b1;
    always @(posedge reset, posedge clk)
        if (reset)
            rdy_reg <= 1'b1;
        else if (rdy_reg)
            rdy_reg <= ~i_val;
        else
            rdy_reg <= o_rdy & (len_cnt == (FIS_LEN - 1));
    assign i_rdy =  rdy_reg;
    assign o_val = ~rdy_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр признака последнего слова "выталкиваемого" фрейма
    always @(posedge reset, posedge clk)
        if (reset)
            eop_reg <= '0;
        else if (o_val & o_rdy)
            eop_reg <= (len_cnt == (FIS_LEN - 2));
        else
            eop_reg <= eop_reg;
    assign o_eop = eop_reg;
    
    //------------------------------------------------------------------------------------
    //      Счетчик длины "выталкиваемого" фрейма
    always @(posedge reset, posedge clk)
        if (reset)
            len_cnt <= '0;
        else if (o_val & o_rdy)
            if (len_cnt == (FIS_LEN - 1))
                len_cnt <= '0;
            else
                len_cnt <= len_cnt + 1'b1;
        else
            len_cnt <= len_cnt;
    
endmodule: sata_reg_fis_sender