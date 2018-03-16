/*
    //------------------------------------------------------------------------------------
    //      Модуль извлечения из потока принимаемых данных примитива CONT и следующей
    //      за ним псевдослучайной последовательности данных
    sata_cont_extractor
    the_sata_cont_extractor
    (
        // Сброс и тактирование
        .reset      (), // i
        .clk        (), // i
        
        // Входной поток
        .i_data     (), // i  [31 : 0]
        .i_datak    (), // i
        
        // Выходной поток
        .o_data     (), // o  [31 : 0]
        .o_datak    ()  // o
    ); // the_sata_cont_extractor
*/

`include "sata_defs.svh"

module sata_cont_extractor
(
    // Сброс и тактирование
    input  logic                reset,
    input  logic                clk,
    
    // Входной поток
    input  logic [31 : 0]       i_data,
    input  logic                i_datak,
    
    // Выходной поток
    output logic [31 : 0]       o_data,
    output logic                o_datak
);
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic                       state_reg;
    logic [31 : 0]              curr_data_reg;
    logic                       curr_datak_reg;
    logic [31 : 0]              next_data_reg;
    logic                       next_datak_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр текущего состояния
    always @(posedge reset, posedge clk)
        if (reset)
            state_reg <= 1'b0;
        else if (state_reg)
            state_reg <= ~(i_datak & (i_data != `CONT_PRIM));
        else
            state_reg <=  (i_datak & (i_data == `CONT_PRIM));
    
    //------------------------------------------------------------------------------------
    //      Регистр текущего значения данных
    always @(posedge reset, posedge clk)
        if (reset)
            curr_data_reg <= '0;
        else if (state_reg)
            curr_data_reg <= curr_data_reg;
        else
            curr_data_reg <= next_data_reg;
    assign o_data = curr_data_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр текущего значения признака примитива
    always @(posedge reset, posedge clk)
        if (reset)
            curr_datak_reg <= '0;
        else if (state_reg)
            curr_datak_reg <= curr_datak_reg;
        else
            curr_datak_reg <= next_datak_reg;
    assign o_datak = curr_datak_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр следующего значения данных
    always @(posedge reset, posedge clk)
        if (reset)
            next_data_reg <= '0;
        else
            next_data_reg <= i_data;
    
    //------------------------------------------------------------------------------------
    //      Регистр следующего значения признака примитива
    always @(posedge reset, posedge clk)
        if (reset)
            next_datak_reg <= '0;
        else
            next_datak_reg <= i_datak;
    
endmodule: sata_cont_extractor