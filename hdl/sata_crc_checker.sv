/*
    //------------------------------------------------------------------------------------
    //      Модуль проверки CRC для фреймов SerialATA
    sata_crc_checker
    the_sata_crc_checker
    (
        // Сброс и тактирование
        .reset      (), // i
        .clk        (), // i

        // Входной потоковый интерфейс
        .i_dat      (), // i  [31 : 0]
        .i_val      (), // i
        .i_eop      (), // i
        .i_rdy      (), // o

        // Выходной потоковый интерфейс
        .o_dat      (), // o  [31 : 0]
        .o_val      (), // o
        .o_eop      (), // o
        .o_err      (), // o
        .o_rdy      ()  // i
    ); // the_sata_crc_checker
*/

`include "sata_defs.svh"

module sata_crc_checker
(
    // Сброс и тактирование
    input  logic                reset,
    input  logic                clk,

    // Входной потоковый интерфейс
    input  logic [31 : 0]       i_dat,
    input  logic                i_val,
    input  logic                i_eop,
    output logic                i_rdy,

    // Выходной потоковый интерфейс
    output logic [31 : 0]       o_dat,
    output logic                o_val,
    output logic                o_eop,
    output logic                o_err,
    input  logic                o_rdy
);
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic [31 : 0]              crc_reg;
    logic [31 : 0]              crc_new;
    logic [31 : 0]              dat_reg;
    logic                       val_reg;

    //------------------------------------------------------------------------------------
    //      Модуль вычисления значения значения контрольной суммы CRC
    crc_calculator
    #(
        .DATAWIDTH  (32),               // Разрядность данных
        .CRCWIDTH   (32),               // Разрядность CRC
        .POLYNOMIAL (`CRC_POLYNOMIAL)   // Порождающий полином
    )
    sata_crc_calculator
    (
        // Входные данные
        .i_dat      (i_dat),            // i  [DATAWIDTH - 1 : 0]

        // Входное (текущее) значение CRC
        .i_crc      (crc_reg),          // i  [CRCWIDTH - 1 : 0]

        // Выходное (расчитанное) значение CRC
        .o_crc      (crc_new)           // o  [CRCWIDTH - 1 : 0]
    ); // sata_crc_calculator

    //------------------------------------------------------------------------------------
    //      Регистр накопления значения CRC пакета
    initial crc_reg = `CRC_INITVALUE;
    always @(posedge reset, posedge clk)
        if (reset)
            crc_reg <= `CRC_INITVALUE;
        else if (i_val & i_rdy)
            if (i_eop)
                crc_reg <= `CRC_INITVALUE;
            else
                crc_reg <= crc_new;
        else
            crc_reg <= crc_reg;

    //------------------------------------------------------------------------------------
    //      Регистр буферизации очередного слова данных
    always @(posedge reset, posedge clk)
        if (reset)
            dat_reg <= '0;
        else if (i_val & i_rdy)
            dat_reg <= i_dat;
        else
            dat_reg <= dat_reg;

    //------------------------------------------------------------------------------------
    //      Регистр признака достоверности выходных данных
    always @(posedge reset, posedge clk)
        if (reset)
            val_reg <= '0;
        else if (val_reg)
            val_reg <= ~(i_val & i_eop & o_rdy);
        else
            val_reg <= i_val & ~i_eop;

    //------------------------------------------------------------------------------------
    //      Сигналы потоковых интерфейсов
    assign o_dat =  dat_reg;
    assign o_val =  val_reg & i_val;
    assign o_eop =  val_reg & i_eop;
    assign o_err =  val_reg & i_eop & (crc_new != 0);
    assign i_rdy = ~val_reg | o_rdy;

endmodule: sata_crc_checker