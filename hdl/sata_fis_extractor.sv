/*
    //------------------------------------------------------------------------------------
    //      Модуль выделения фрейма SerialATA из непрерывного потока принимаемых данных
    sata_fis_extractor
    the_sata_fis_extractor
    (
        // Сброс и тактирование
        .reset      (), // i
        .clk        (), // i
        
        // Входной поток принимаемых данных
        .rx_data    (), // i  [31 : 0]
        .rx_datak   (), // i
        
        // Выходной поток фреймов
        .fis_dat    (), // o  [31 : 0]
        .fis_val    (), // o
        .fis_eop    ()  // o
    ); // the_sata_fis_extractor
*/

`include "sata_defs.svh"

module sata_fis_extractor
(
    // Сброс и тактирование
    input  logic            reset,
    input  logic            clk,
    
    // Входной поток принимаемых данных
    input  logic [31 : 0]   rx_data,
    input  logic            rx_datak,
    
    // Выходной поток фреймов
    output logic [31 : 0]   fis_dat,
    output logic            fis_val,
    output logic            fis_eop
);
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic                   state_reg;
    //
    logic [31 : 0]          dat_reg;
    logic                   val_reg;
    //
    logic [31 : 0]          fis_dat_reg;
    logic                   fis_val_reg;
    logic                   fis_eop_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр текущего состояния
    always @(posedge reset, posedge clk)
        if (reset)
            state_reg <= '0;
        else if (state_reg)
            state_reg <= ~((rx_datak == `DWORD_IS_PRIM) & (rx_data == `EOF_PRIM));
        else
            state_reg <=  ((rx_datak == `DWORD_IS_PRIM) & (rx_data == `SOF_PRIM));
    
    //------------------------------------------------------------------------------------
    //      Регистр данных
    always @(posedge reset, posedge clk)
        if (reset)
            dat_reg <= '0;
        else if (state_reg & (rx_datak == `DWORD_IS_DATA))
            dat_reg <= rx_data;
        else
            dat_reg <= dat_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр признака достоверности
    always @(posedge reset, posedge clk)
        if (reset)
            val_reg <= '0;
        else if (val_reg)
            val_reg <= ~(state_reg & (rx_datak == `DWORD_IS_PRIM) & (rx_data == `EOF_PRIM));
        else
            val_reg <=  (state_reg & (rx_datak == `DWORD_IS_DATA));
    
    //------------------------------------------------------------------------------------
    //      Регистр данных фрейма
    always @(posedge reset, posedge clk)
        if (reset)
            fis_dat_reg <= '0;
        else if (val_reg & ((rx_datak == `DWORD_IS_DATA) | ((rx_datak == `DWORD_IS_PRIM) & (rx_data == `EOF_PRIM))))
            fis_dat_reg <= dat_reg;
        else
            fis_dat_reg <= fis_dat_reg;
    assign fis_dat = fis_dat_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр признака достоверности слова данных фрейма
    always @(posedge reset, posedge clk)
        if (reset)
            fis_val_reg <= '0;
        else
            fis_val_reg <= val_reg & ((rx_datak == `DWORD_IS_DATA) | ((rx_datak == `DWORD_IS_PRIM) & (rx_data == `EOF_PRIM)));
    assign fis_val = fis_val_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр признака конца фрейма
    always @(posedge reset, posedge clk)
        if (reset)
            fis_eop_reg <= '0;
        else
            fis_eop_reg <= val_reg & (rx_datak == `DWORD_IS_PRIM) & (rx_data == `EOF_PRIM);
    assign fis_eop = fis_eop_reg;
    
endmodule: sata_fis_extractor