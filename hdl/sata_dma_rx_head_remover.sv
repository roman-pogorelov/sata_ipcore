/*
    //------------------------------------------------------------------------------------
    //      Модуль удаления заголовка принимаемого фрейма данных SATA
    sata_dma_rx_head_remover
    the_sata_dma_rx_head_remover
    (
        // Сброс и тактирование
        .reset  (), // i
        .clk    (), // i
        
        // Входной потоковый интерфейс
        .i_dat  (), // i  [31 : 0]
        .i_val  (), // i
        .i_eop  (), // i
        .i_err  (), // i
        .i_rdy  (), // o
        
        // Выходной потоковый интерфейс
        .o_dat  (), // o  [31 : 0]
        .o_val  (), // o
        .o_eop  (), // o
        .o_err  (), // o
        .o_rdy  ()  // i
    ); // the_sata_dma_rx_head_remover
*/

module sata_dma_rx_head_remover
(
    // Сброс и тактирование
    input  logic            reset,
    input  logic            clk,
    
    // Входной потоковый интерфейс
    input  logic [31 : 0]   i_dat,
    input  logic            i_val,
    input  logic            i_eop,
    input  logic            i_err,
    output logic            i_rdy,
    
    // Выходной потоковый интерфейс
    output logic [31 : 0]   o_dat,
    output logic            o_val,
    output logic            o_eop,
    output logic            o_err,
    input  logic            o_rdy
);
    //------------------------------------------------------------------------------------
    //      Регистр признака начала пакета
    logic sop_reg;
    initial sop_reg = 1'b1;
    always @(posedge reset, posedge clk)
        if (reset)
            sop_reg <= 1'b1;
        else if (i_val & i_rdy)
            sop_reg <= i_eop;
        else
            sop_reg <= sop_reg;
    
    //------------------------------------------------------------------------------------
    //      Логика формирования выходных сигналов потоковых интерфейсов
    assign i_rdy = o_rdy |  sop_reg;
    assign o_dat = i_dat;
    assign o_val = i_val & ~sop_reg;
    assign o_eop = i_eop & ~sop_reg;
    assign o_err = i_err & ~sop_reg;
    
endmodule: sata_dma_rx_head_remover