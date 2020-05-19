/*
    //------------------------------------------------------------------------------------
    //      Тракт прохождения передаваемых данных Link-уровня SerialATA
    sata_link_tx_path
    #(
        .FPGAFAMILY         ()  // Семейство FPGA ("Arria V" | "Arria 10")
    )
    the_sata_link_tx_path
    (
        // Сброс и тактирование
        .reset              (), // i
        .clk                (), // i

        // Входной потоковый интерфейс
        .tx_dat             (), // i  [31 : 0]
        .tx_val             (), // i
        .tx_eop             (), // i
        .tx_rdy             (), // o

        // Интерфейс FIFO
        .fifo_data          (), // o  [31 : 0]
        .fifo_eop           (), // o
        .fifo_rdreq         (), // i
        .fifo_empty         (), // o
        .fifo_almostempty   ()  // o
    ); // the_sata_link_tx_path
*/

module sata_link_tx_path
#(
    parameter               FPGAFAMILY  = "Arria V"     // Семейство FPGA ("Arria V" | "Arria 10")
)
(
    // Сброс и тактирование
    input  logic            reset,
    input  logic            clk,

    // Входной потоковый интерфейс
    input  logic [31 : 0]   tx_dat,
    input  logic            tx_val,
    input  logic            tx_eop,
    output logic            tx_rdy,

    // Интерфейс FIFO
    output logic [31 : 0]   fifo_data,
    output logic            fifo_eop,
    input  logic            fifo_rdreq,
    output logic            fifo_empty,
    output logic            fifo_almostempty
);
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic [31 : 0]          crc_dat;
    logic                   crc_val;
    logic                   crc_eop;
    logic                   crc_rdy;
    //
    logic [31 : 0]          scram_dat;
    logic                   scram_val;
    logic                   scram_eop;
    logic                   scram_rdyn;

    //------------------------------------------------------------------------------------
    //      Генератор CRC для фреймов SerialATA
    sata_crc_generator
    sata_link_tx_crc_generator
    (
        // Сброс и тактирование
        .reset      (reset),    // i
        .clk        (clk),      // i

        // Входной потоковый интерфейс
        .i_dat      (tx_dat),   // i  [31 : 0]
        .i_val      (tx_val),   // i
        .i_eop      (tx_eop),   // i
        .i_rdy      (tx_rdy),   // o

        // Выходной потоковый интерфейс
        .o_dat      (crc_dat),  // o  [31 : 0]
        .o_val      (crc_val),  // o
        .o_eop      (crc_eop),  // o
        .o_rdy      (crc_rdy)   // i
    ); // sata_link_tx_crc_generator

    //------------------------------------------------------------------------------------
    //      Скремблер фреймов SerialATA
    sata_scrambler
    sata_link_tx_scrambler
    (
        // Сброс и тактирование
        .reset      (reset),        // i
        .clk        (clk),          // i

        // Входной потоковый интерфейс
        .i_dat      (crc_dat),      // i  [31 : 0]
        .i_val      (crc_val),      // i
        .i_eop      (crc_eop),      // i
        .i_rdy      (crc_rdy),      // o

        // Выходной потоковый интерфейс
        .o_dat      ( scram_dat),   // o  [31 : 0]
        .o_val      ( scram_val),   // o
        .o_eop      ( scram_eop),   // o
        .o_rdy      (~scram_rdyn)   // i
    ); // sata_link_tx_scrambler

    //------------------------------------------------------------------------------------
    //      FIFO тракта передачи Link-уровня SerialATA
    sata_link_fifo
    #(
        .FPGAFAMILY     (FPGAFAMILY),       // Семейство FPGA ("Arria V" | "Arria 10")
        .DIRECTION      ("TX")              // Направление тракта ("RX" | "TX")
    )
    sata_link_tx_fifo
    (
        // Сброс и тактирование
        .reset          (reset),            // i
        .clk            (clk),              // i

        // Интерфейс записи в FIFO
        .wr_data        (scram_dat),        // i  [31 : 0]
        .wr_eop         (scram_eop),        // i
        .wr_err         (1'b0),             // i
        .wr_req         (scram_val),        // i
        .wr_full        (scram_rdyn),       // o
        .wr_almostfull  (  ),               // o

        // Интерфейс чтения из FIFO
        .rd_data        (fifo_data),        // o  [31 : 0]
        .rd_eop         (fifo_eop),         // o
        .rd_err         (  ),               // o
        .rd_req         (fifo_rdreq),       // i
        .rd_empty       (fifo_empty),       // o
        .rd_almostempty (fifo_almostempty)  // o
    ); // sata_link_tx_fifo

endmodule: sata_link_tx_path