`timescale  1ns / 1ps
module sata_oob_coder_decoder_tb ();

    //------------------------------------------------------------------------------------
    //      Описание констант
    localparam int unsigned     CLKFREQ = 100_000;  // Частота тактирования clk, кГц
    
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic                       reset;
    logic                       clk;
    //
    logic                       txready;
    logic                       txcominit;
    logic                       txcomwake;
    //
    logic                       elecidle;
    //
    logic                       rxcominit;
    logic                       rxcomwake;
    
    //------------------------------------------------------------------------------------
    //      Инициализация
    initial begin
        txcominit = 0;
        txcomwake = 0;
    end
    
    //------------------------------------------------------------------------------------
    //      Сброс
    initial begin
        #00 reset = 1;
        #15 reset = 0;
    end
    
    //------------------------------------------------------------------------------------
    //      Тактирование
    initial clk = 1;
    always  clk = #5 ~clk;
    
    //------------------------------------------------------------------------------------
    //      Кодер OOB-последовательностей Serial ATA
    sata_oob_coder
    #(
        .CLKFREQ        (CLKFREQ)       // Частота тактирования clk, кГц
    )
    the_sata_oob_coder
    (
        // Сброс и тактирование
        .reset          (reset),        // i
        .clk            (clk),          // i
        
        // Индикатор готовности к приему команды
        .ready          (txready),      // o
        
        // Команды генерируемых  последовательностей
        .cominit        (txcominit),    // i
        .comwake        (txcomwake),    // i
        
        // Управление переводом передатчика в неактивное состояние
        .txelecidle     (elecidle)      // o
    ); // the_sata_oob_coder
    
    //------------------------------------------------------------------------------------
    //      Декодер OOB-последовательностей Serial ATA
    sata_oob_decoder
    #(
        .CLKFREQ        (CLKFREQ)       // Частота тактирования clk, кГц
    )
    the_sata_oob_decoder
    (
        // Сброс и тактирование
        .reset          (reset),        // i
        .clk            (clk),          // i
        
        // Индикатор активности на линии приема
        .rxsignaldetect (~elecidle),    // i
        
        // Импульсы обнаруженных последовательностей
        .cominit        (rxcominit),    // o
        .comwake        (rxcomwake)     // o
    ); // the_sata_oob_decoder
    
endmodule: sata_oob_coder_decoder_tb