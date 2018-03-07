`timescale  1ns / 1ps
module sata_crc_scramler_tb ();
    
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic               reset;
    logic               clk;
    //
    logic [31 : 0]      i_dat;
    logic               i_val;
    logic               i_eop;
    logic               i_rdy;
    //
    logic [31 : 0]      crc_gen_dat;
    logic               crc_gen_val;
    logic               crc_gen_eop;
    logic               crc_gen_rdy;
    //
    logic [31 : 0]      scram_dat;
    logic               scram_val;
    logic               scram_eop;
    logic               scram_rdy;
    //
    logic [31 : 0]      descram_dat;
    logic               descram_val;
    logic               descram_eop;
    logic               descram_rdy;
    //
    logic [31 : 0]      o_dat;
    logic               o_val;
    logic               o_eop;
    logic               o_err;
    logic               o_rdy;
    
    //------------------------------------------------------------------------------------
    //      Инициализация
    initial begin
        i_dat = 0;
        i_val = 0;
        i_eop = 0;
        o_rdy = 0;
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
    always  clk = #05 ~clk;
    
    //------------------------------------------------------------------------------------
    //      Случайная установка o_rdy
    always @(posedge reset, posedge clk)
        if (reset)
            o_rdy <= '0;
        else
            o_rdy <= $random;
    
    //------------------------------------------------------------------------------------
    //      Генератор CRC для фреймов SerialATA
    sata_crc_generator
    the_sata_crc_generator
    (
        // Сброс и тактирование
        .reset      (reset),        // i
        .clk        (clk),          // i
        
        // Входной потоковый интерфейс
        .i_dat      (i_dat),        // i  [31 : 0]
        .i_val      (i_val),        // i
        .i_eop      (i_eop),        // i
        .i_rdy      (i_rdy),        // o
        
        // Выходной потоковый интерфейс
        .o_dat      (crc_gen_dat),  // o  [31 : 0]
        .o_val      (crc_gen_val),  // o
        .o_eop      (crc_gen_eop),  // o
        .o_rdy      (crc_gen_rdy)   // i
    ); // the_sata_crc_generator
    
    //------------------------------------------------------------------------------------
    //      Скремблер фреймов SerialATA
    sata_scrambler
    scrambler
    (
        // Сброс и тактирование
        .reset      (reset),        // i
        .clk        (clk),          // i
        
        // Входной потоковый интерфейс
        .i_dat      (crc_gen_dat),  // i  [31 : 0]
        .i_val      (crc_gen_val),  // i
        .i_eop      (crc_gen_eop),  // i
        .i_rdy      (crc_gen_rdy),  // o
        
        // Выходной потоковый интерфейс
        .o_dat      (scram_dat),    // o  [31 : 0]
        .o_val      (scram_val),    // o
        .o_eop      (scram_eop),    // o
        .o_rdy      (scram_rdy)     // i
    ); //  scrambler
    
    //------------------------------------------------------------------------------------
    //      Скремблер фреймов SerialATA
    sata_scrambler
    descrambler
    (
        // Сброс и тактирование
        .reset      (reset),        // i
        .clk        (clk),          // i
        
        // Входной потоковый интерфейс
        .i_dat      (scram_dat),    // i  [31 : 0]
        .i_val      (scram_val),    // i
        .i_eop      (scram_eop),    // i
        .i_rdy      (scram_rdy),    // o
        
        // Выходной потоковый интерфейс
        .o_dat      (descram_dat),  // o  [31 : 0]
        .o_val      (descram_val),  // o
        .o_eop      (descram_eop),  // o
        .o_rdy      (descram_rdy)   // i
    ); //  descrambler
    
    //------------------------------------------------------------------------------------
    //      Модуль проверки CRC для фреймов SerialATA
    sata_crc_checker
    the_sata_crc_checker
    (
        // Сброс и тактирование
        .reset      (reset),        // i
        .clk        (clk),          // i
        
        // Входной потоковый интерфейс
        .i_dat      (descram_dat),  // i  [31 : 0]
        .i_val      (descram_val),  // i
        .i_eop      (descram_eop),  // i
        .i_rdy      (descram_rdy),  // o
        
        // Выходной потоковый интерфейс
        .o_dat      (o_dat),        // o  [31 : 0]
        .o_val      (o_val),        // o
        .o_eop      (o_eop),        // o
        .o_err      (o_err),        // o
        .o_rdy      (o_rdy)         // i
    ); // the_sata_crc_checker
    
endmodule: sata_crc_scramler_tb