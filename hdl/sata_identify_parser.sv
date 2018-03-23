/*
    //------------------------------------------------------------------------------------
    //      Модуль разбора фрейма данных с идентификационной информацией
    sata_identify_parser
    the_sata_identify_parser
    (
        // Сброс и тактирование
        .reset              (), // i
        .clk                (), // i
        
        // Входной последовательный интерфейс принимаемого фрейма
        .i_dat              (), // i  [31 : 0]
        .i_val              (), // i
        .i_eop              (), // i
        .i_err              (), // i
        
        // Выходной параллельный интерфейс идентификационной информации
        .identify_done      (), // o
        .sata1_supported    (), // o
        .sata2_supported    (), // o
        .sata3_supported    (), // o
        .max_lba_address    (), // o  [47 : 0]
        .bad_checksum       ()  // o
    ); // the_sata_identify_parser
*/

`include "sata_defs.svh"

module sata_identify_parser
(
    // Сброс и тактирование
    input  logic                reset,
    input  logic                clk,
    
    // Входной последовательный интерфейс принимаемого фрейма
    input  logic [31 : 0]       i_dat,
    input  logic                i_val,
    input  logic                i_eop,
    input  logic                i_err,
    
    // Выходной параллельный интерфейс идентификационной информации
    output logic                identify_done,
    output logic                sata1_supported,
    output logic                sata2_supported,
    output logic                sata3_supported,
    output logic [47 : 0]       max_lba_address,
    output logic                bad_checksum
);
    //------------------------------------------------------------------------------------
    //      Объявление констант
    localparam int unsigned     FIS_LEN         = 129;
    localparam int unsigned     SATA_CAP_OFFSET = 38;
    localparam int unsigned     MAX_LBA_OFFSET  = 50;
    
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic                               sop_reg;
    logic [$clog2(FIS_LEN + 1) - 1 : 0] len_cnt;
    logic                               done_reg;
    logic [2 : 0]                       sata_supported_reg;
    logic [31 : 0]                      max_lba_low_reg;
    logic [15 : 0]                      max_lba_high_reg;
    logic                               bad_crc_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр признака начала пакета
    initial sop_reg = 1'b1;
    always @(posedge reset, posedge clk)
        if (reset)
            sop_reg <= 1'b1;
        else if (i_val)
            sop_reg <= i_eop;
        else
            sop_reg <= sop_reg;
    
    //------------------------------------------------------------------------------------
    //      Счетчик длины идентификационного фрейма данных
    always @(posedge reset, posedge clk)
        if (reset)
            len_cnt <= '0;
        else if (i_val)
            if (i_eop)
                len_cnt <= '0;
            else if (len_cnt == 0)
                len_cnt <= {len_cnt[$high(len_cnt) : 1], sop_reg & (i_dat[7 : 0] == `DATA_FIS)};
            else
                len_cnt <= len_cnt + (len_cnt != FIS_LEN);
        else
            len_cnt <= len_cnt;
    
    //------------------------------------------------------------------------------------
    //      Регистр окончания разбора идентификационного фрейма
    always @(posedge reset, posedge clk)
        if (reset)
            done_reg <= '0;
        else if (done_reg)
            done_reg <= ~(i_val & sop_reg & ~i_eop & (i_dat[7 : 0] == `DATA_FIS));
        else
            done_reg <= i_val & i_eop & (len_cnt == (FIS_LEN - 1));
    assign identify_done = done_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр признаков поддержки SATA1, SATA2, SATA3
    always @(posedge reset, posedge clk)
        if (reset)
            sata_supported_reg <= '0;
        else if (i_val & (len_cnt == SATA_CAP_OFFSET))
            sata_supported_reg <= i_dat[3 : 1];
        else
            sata_supported_reg <= sata_supported_reg;
    assign {sata3_supported, sata2_supported,  sata1_supported} = sata_supported_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр младшей части максимального LBA адреса
    always @(posedge reset, posedge clk)
        if (reset)
            max_lba_low_reg <= '0;
        else if (i_val & (len_cnt == MAX_LBA_OFFSET))
            max_lba_low_reg <= i_dat;
        else
            max_lba_low_reg <= max_lba_low_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр старшей части максимального LBA адреса
    always @(posedge reset, posedge clk)
        if (reset)
            max_lba_high_reg <= '0;
        else if (i_val & (len_cnt == (MAX_LBA_OFFSET + 1)))
            max_lba_high_reg <= i_dat[15 : 0];
        else
            max_lba_high_reg <= max_lba_high_reg;
    assign max_lba_address = {max_lba_high_reg, max_lba_low_reg};
    
    //------------------------------------------------------------------------------------
    //      Регистр признака некорректной контрольной суммы
    always @(posedge reset, posedge clk)
        if (reset)
            bad_crc_reg <= '0;
        else if (i_val)
            bad_crc_reg <= i_eop & i_err;
        else
            bad_crc_reg <= bad_crc_reg;
    assign bad_checksum = bad_crc_reg;
    
endmodule: sata_identify_parser