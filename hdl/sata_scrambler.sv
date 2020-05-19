/*
    //------------------------------------------------------------------------------------
    //      Скремблер фреймов SerialATA
    sata_scrambler
    the_sata_scrambler
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
        .o_rdy      ()  // i
    ); // the_sata_scrambler
*/

`include "sata_defs.svh"

module sata_scrambler
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
    input  logic                o_rdy
);
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic [47 : 0]              lfsr;
    logic [31 : 0]              scram;
    logic [31 : 0]              dat_reg;
    logic                       val_reg;
    logic                       eop_reg;

    //------------------------------------------------------------------------------------
    //      Сквозная трансляция сигнала готовности
    assign i_rdy = o_rdy;

    //------------------------------------------------------------------------------------
    //      Генератор псевдослучайной последовательности на сдвиговом линейном регистре
    //      с обратными связями
    lfsr_generator
    #(
        .POLYDEGREE     (16),               // Степень порождающего полинома
        .POLYNOMIAL     (`LFSR_POLYNOMIAL), // Значение порождающего полинома
        .REGWIDTH       (48),               // Разрядность сдвигового регистра (REGWIDTH >= POLYDEGREE)
        .STEPSIZE       (32),               // Количество одноразрядных сдвигов за такт (STEPSIZE > 0)
        .REGINITIAL     (`LFSR_INITVALUE)   // Начальное значение сдвигового регистра (REGINITIAL != 0)
    )
    sata_lfsr_generator
    (
        // Сброс и тактирование
        .reset          (reset),            // i
        .clk            (clk),              // i

        // Разрешение тактирования
        .clkena         (i_val & i_rdy),    // i

        // Синхронный сброс (инициализация)
        .init           (i_eop),            // i

        // Выход
        .data           (lfsr)              // o  [REGWIDTH - 1 : 0]
    ); // sata_lfsr_generator

    //------------------------------------------------------------------------------------
    //      Модуль реверса (зеркалирования) разрядов произвольной параллельной шины
    bitreverser
    #(
        .WIDTH      (32)                // Разрядность
    )
    lfsr_reverser
    (
        // Входные данные
        .i_dat      (lfsr[47 : 16]),    // i  [WIDTH - 1 : 0]

        // Выходные данные
        .o_dat      (scram)             // o  [WIDTH - 1 : 0]
    ); // lfsr_reverser

    //------------------------------------------------------------------------------------
    //      Регистр данных
    always @(posedge reset, posedge clk)
        if (reset)
            dat_reg <= '0;
        else if (i_rdy)
            dat_reg <= i_dat ^ scram;
        else
            dat_reg <= dat_reg;
    assign o_dat = dat_reg;

    //------------------------------------------------------------------------------------
    //      Регистр признака достоверности
    always @(posedge reset, posedge clk)
        if (reset)
            val_reg <= '0;
        else if (i_rdy)
            val_reg <= i_val;
        else
            val_reg <= val_reg;
    assign o_val = val_reg;

    //------------------------------------------------------------------------------------
    //      Регистр признака конца пакета
    always @(posedge reset, posedge clk)
        if (reset)
            eop_reg <= '0;
        else if (i_rdy)
            eop_reg <= i_eop;
        else
            eop_reg <= eop_reg;
    assign o_eop = eop_reg;

endmodule: sata_scrambler