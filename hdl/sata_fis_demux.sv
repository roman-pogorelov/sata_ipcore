/*
    //------------------------------------------------------------------------------------
    //      Модуль демультиплексирования потоковых интерфейсов фреймов SATA
    sata_fis_demux
    the_sata_fis_demux
    (
        // Сброс и тактирование
        .reset      (), // i
        .clk        (), // i

        // Выбор выходного интерфейса
        .select     (), // i

        // Входной потоковый интерфейс фреймов SATA
        .i_dat      (), // i  [31 : 0]
        .i_val      (), // i
        .i_eop      (), // i
        .i_err      (), // i
        .i_rdy      (), // o

        // Выходной потоковый интерфейс #1 фреймов SATA
        .o1_dat     (), // o  [31 : 0]
        .o1_val     (), // o
        .o1_eop     (), // o
        .o1_err     (), // o
        .o1_rdy     (), // i

        // Выходной потоковый интерфейс #2 фреймов SATA
        .o2_dat     (), // o  [31 : 0]
        .o2_val     (), // o
        .o2_eop     (), // o
        .o2_err     (), // o
        .o2_rdy     ()  // i
    ); // the_sata_fis_demux
*/

module sata_fis_demux
(
    // Сброс и тактирование
    input  logic            reset,
    input  logic            clk,

    // Выбор выходного интерфейса
    input  logic            select,

    // Входной потоковый интерфейс фреймов SATA
    input  logic [31 : 0]   i_dat,
    input  logic            i_val,
    input  logic            i_eop,
    input  logic            i_err,
    output logic            i_rdy,

    // Выходной потоковый интерфейс #1 фреймов SATA
    output logic [31 : 0]   o1_dat,
    output logic            o1_val,
    output logic            o1_eop,
    output logic            o1_err,
    input  logic            o1_rdy,

    // Выходной потоковый интерфейс #2 фреймов SATA
    output logic [31 : 0]   o2_dat,
    output logic            o2_val,
    output logic            o2_eop,
    output logic            o2_err,
    input  logic            o2_rdy
);
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic                   sop_reg;
    logic                   selected_reg;
    logic                   selected;

    //------------------------------------------------------------------------------------
    //      Регистр признака начала фрейма входного потокового интерфейса
    initial sop_reg = 1'b1;
    always @(posedge reset, posedge clk)
        if (reset)
            sop_reg <= 1'b1;
        else if (i_val & i_rdy)
            sop_reg <= i_eop;
        else
            sop_reg <= sop_reg;

    //------------------------------------------------------------------------------------
    //      Регистр удержания выбранного выходного интерфейса
    always @(posedge reset, posedge clk)
        if (reset)
            selected_reg <= '0;
        else if (i_val & i_rdy & sop_reg)
            selected_reg <= select;
        else
            selected_reg <= selected_reg;

    //------------------------------------------------------------------------------------
    //      Сигнал выбора на время прохождения всего фрейма
    assign selected = sop_reg ? select : selected_reg;

    //------------------------------------------------------------------------------------
    //      Разветвление данных на оба выхода
    assign o1_dat = i_dat;
    assign o2_dat = i_dat;

    //------------------------------------------------------------------------------------
    //      Стробирование признака достоверности
    assign o1_val = i_val & ~selected;
    assign o2_val = i_val &  selected;

    //------------------------------------------------------------------------------------
    //      Стробирование признака конца фрейма
    assign o1_eop = i_eop & ~selected;
    assign o2_eop = i_eop &  selected;

    //------------------------------------------------------------------------------------
    //      Стробирование признака ошибки фрейма
    assign o1_err = i_err & ~selected;
    assign o2_err = i_err &  selected;

    //------------------------------------------------------------------------------------
    //      Коммутация признака готовности
    assign i_rdy = selected ? o2_rdy : o1_rdy;

endmodule: sata_fis_demux