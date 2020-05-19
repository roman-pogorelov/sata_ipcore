/*
    //------------------------------------------------------------------------------------
    //      Модуль формирования фреймов данных SATA из потока данных
    sata_fis_data_shaper
    the_sata_fis_data_shaper
    (
        // Сброс и тактирование
        .reset      (), // i
        .clk        (), // i

        // Интерфейс управления
        .ctl_valid  (), // i
        .ctl_count  (), // i  [10 : 0]
        .ctl_ready  (), // o

        // Входной потоковый интерфейс
        .i_dat      (), // i  [31 : 0]
        .i_val      (), // i
        .i_rdy      (), // o

        // Выходной потоковый интерфейс
        .o_dat      (), // o  [31 : 0]
        .o_val      (), // o
        .o_eop      (), // o
        .o_rdy      ()  // i
    ); // the_sata_fis_data_shaper
*/

`include "sata_defs.svh"

module sata_fis_data_shaper
(
    // Сброс и тактирование
    input  logic            reset,
    input  logic            clk,

    // Интерфейс управления
    input  logic            ctl_valid,
    input  logic [10 : 0]   ctl_count,
    output logic            ctl_ready,

    // Входной потоковый интерфейс
    input  logic [31 : 0]   i_dat,
    input  logic            i_val,
    output logic            i_rdy,

    // Выходной потоковый интерфейс
    output logic [31 : 0]   o_dat,
    output logic            o_val,
    output logic            o_eop,
    input  logic            o_rdy
);
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic                   o_sop_reg;
    logic                   pass_reg;
    logic [10 : 0]          word_cnt;

    //------------------------------------------------------------------------------------
    //      Регистр признака начала выходного пакета
    initial o_sop_reg = '1;
    always @(posedge reset, posedge clk)
        if (reset)
            o_sop_reg <= '1;
        else if (o_val & o_rdy)
            o_sop_reg <= o_eop;
        else
            o_sop_reg <= o_sop_reg;

    //------------------------------------------------------------------------------------
    //      Регистр разрешения пропускания потока
    always @(posedge reset, posedge clk)
        if (reset)
            pass_reg <= '0;
        else if (pass_reg)
            pass_reg <= ~(i_val & i_rdy & (word_cnt == 1));
        else
            pass_reg <= ctl_valid;

    //------------------------------------------------------------------------------------
    //      Счетчик слов фрейма
    always @(posedge reset, posedge clk)
        if (reset)
            word_cnt <= '0;
        else if (pass_reg)
            if (i_val & i_rdy)
                word_cnt <= word_cnt - 1'b1;
            else
                word_cnt <= word_cnt;
        else
            word_cnt <= ctl_count;

    //------------------------------------------------------------------------------------
    //      Признак готовности интерфейса управления
    assign ctl_ready = ~pass_reg;

    //------------------------------------------------------------------------------------
    //      Входной признак готовности
    assign i_rdy = o_rdy & pass_reg & ~o_sop_reg;

    //------------------------------------------------------------------------------------
    //      Выходные данные
    assign o_dat = o_sop_reg ? {{24{1'b0}}, `DATA_FIS} : i_dat;

    //------------------------------------------------------------------------------------
    //      Выходной признак достоверности
    assign o_val = pass_reg & (i_val | o_sop_reg);

    //------------------------------------------------------------------------------------
    //      Выходной признак конца пакета
    assign o_eop = pass_reg & ~o_sop_reg & (word_cnt == 1);

endmodule: sata_fis_data_shaper