/*
    //------------------------------------------------------------------------------------
    //      Тракт прохождения принимаемых данных Link-уровня SerialATA
    sata_link_rx_path
    #(
        .FPGAFAMILY         ()  // Семейство FPGA ("Arria V" | "Arria 10")
    )
    the_sata_link_rx_path
    (
        // Сброс и тактирование
        .reset              (), // i
        .clk                (), // i
        
        // Входной потоковый интерфейс
        .rx_dat             (), // i  [31 : 0]
        .rx_val             (), // i
        .rx_eop             (), // i
        
        // Интерфейс FIFO
        .fifo_data          (), // o  [31 : 0]
        .fifo_eop           (), // o
        .fifo_rdreq         (), // i
        .fifo_empty         (), // o
        .fifo_almostfull    (), // o
        
        // Интерфейс статусных сигналов
        .stat_good_crc      (), // o
        .stat_bad_crc       (), // o
        .stat_fifo_ovfl     ()  // o
    ); // the_sata_link_rx_path
*/

module sata_link_rx_path
#(
    parameter               FPGAFAMILY  = "Arria V"     // Семейство FPGA ("Arria V" | "Arria 10")
)
(
    // Сброс и тактирование
    input  logic            reset,
    input  logic            clk,
    
    // Входной потоковый интерфейс
    input  logic [31 : 0]   rx_dat,
    input  logic            rx_val,
    input  logic            rx_eop,
    
    // Интерфейс FIFO
    output logic [31 : 0]   fifo_data,
    output logic            fifo_eop,
    input  logic            fifo_rdreq,
    output logic            fifo_empty,
    output logic            fifo_almostfull,
    
    // Интерфейс статусных сигналов
    output logic            stat_good_crc,
    output logic            stat_bad_crc,
    output logic            stat_fifo_ovfl
);
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic [31 : 0]          descram_dat;
    logic                   descram_val;
    logic                   descram_eop;
    //
    logic [31 : 0]          crc_dat;
    logic                   crc_val;
    logic                   crc_eop;
    logic                   crc_err;
    //
    logic                   fifo_full;
    //
    logic                   good_crc_reg;
    logic                   bad_crc_reg;
    logic                   fifo_ovfl_reg;
    
    //------------------------------------------------------------------------------------
    //      Скремблер фреймов SerialATA
    sata_scrambler
    sata_link_rx_descrambler
    (
        // Сброс и тактирование
        .reset      (reset),        // i
        .clk        (clk),          // i
        
        // Входной потоковый интерфейс
        .i_dat      (rx_dat),       // i  [31 : 0]
        .i_val      (rx_val),       // i
        .i_eop      (rx_eop),       // i
        .i_rdy      (  ),           // o
        
        // Выходной потоковый интерфейс
        .o_dat      (descram_dat),  // o  [31 : 0]
        .o_val      (descram_val),  // o
        .o_eop      (descram_eop),  // o
        .o_rdy      (1'b1)          // i
    ); // sata_link_rx_descrambler
    
    //------------------------------------------------------------------------------------
    //      Модуль проверки CRC для фреймов SerialATA
    sata_crc_checker
    sata_link_rx_crc_checker
    (
        // Сброс и тактирование
        .reset      (reset),        // i
        .clk        (clk),          // i
        
        // Входной потоковый интерфейс
        .i_dat      (descram_dat),  // i  [31 : 0]
        .i_val      (descram_val),  // i
        .i_eop      (descram_eop),  // i
        .i_rdy      (  ),           // o
        
        // Выходной потоковый интерфейс
        .o_dat      (crc_dat),      // o  [31 : 0]
        .o_val      (crc_val),      // o
        .o_eop      (crc_eop),      // o
        .o_err      (crc_err),      // o
        .o_rdy      (1'b1)          // i
    ); // sata_link_rx_crc_checker
    
    //------------------------------------------------------------------------------------
    //      FIFO тракта приема/передачи Link-уровня SerialATA
    sata_link_fifo
    #(
        .FPGAFAMILY         (FPGAFAMILY),   // Семейство FPGA ("Arria V" | "Arria 10")
        .DIRECTION          ("RX")          // Направление тракта ("RX" | "TX")
    )
    the_sata_link_fifo
    (
        // Сброс и тактирование
        .reset          (reset),            // i
        .clk            (clk),              // i
        
        // Интерфейс записи в FIFO
        .wr_data        (crc_dat),          // i  [31 : 0]
        .wr_eop         (crc_eop),          // i
        .wr_req         (crc_val),          // i
        .wr_full        (fifo_full),        // o
        .wr_almostfull  (fifo_almostfull),  // o
        
        // Интерфейс чтения из FIFO
        .rd_data        (fifo_data),        // o  [31 : 0]
        .rd_eop         (fifo_eop),         // o
        .rd_req         (fifo_rdreq),       // i
        .rd_empty       (fifo_empty),       // o
        .rd_almostempty (  )                // o
    ); // the_sata_link_fifo
    
    //------------------------------------------------------------------------------------
    //      Регистр признака обнаружения корректной контрольной суммы CRC
    always @(posedge reset, posedge clk)
        if (reset)
            good_crc_reg <= '0;
        else
            good_crc_reg <= crc_val & crc_eop & (~crc_err);
    assign stat_good_crc = good_crc_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр признака обнаружения некорректной контрольной суммы CRC
    always @(posedge reset, posedge clk)
        if (reset)
            bad_crc_reg <= '0;
        else
            bad_crc_reg <= crc_val & crc_eop & crc_err;
    assign stat_bad_crc = bad_crc_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр признака обнаружения переполнения приемного FIFO
    always @(posedge reset, posedge clk)
        if (reset)
            fifo_ovfl_reg <= '0;
        else
            fifo_ovfl_reg <= crc_val & fifo_full;
    assign stat_fifo_ovfl = fifo_ovfl_reg;
    
    
endmodule: sata_link_rx_path