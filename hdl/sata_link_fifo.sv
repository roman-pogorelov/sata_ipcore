/*
    //------------------------------------------------------------------------------------
    //      FIFO тракта приема/передачи Link-уровня SerialATA
    sata_link_fifo
    #(
        .FPGAFAMILY         (), // Семейство FPGA ("Arria V" | "Arria 10")
        .DIRECTION          ()  // Направление тракта ("RX" | "TX")
    )
    the_sata_link_fifo
    (
        // Сброс и тактирование
        .reset          (), // i
        .clk            (), // i
        
        // Интерфейс записи в FIFO
        .wr_data        (), // i  [31 : 0]
        .wr_eop         (), // i
        .wr_err         (), // i
        .wr_req         (), // i
        .wr_full        (), // o
        .wr_almostfull  (), // o
        
        // Интерфейс чтения из FIFO
        .rd_data        (), // o  [31 : 0]
        .rd_eop         (), // o
        .rd_err         (), // o
        .rd_req         (), // i
        .rd_empty       (), // o
        .rd_almostempty ()  // o
    ); // the_sata_link_fifo
*/

module sata_link_fifo
#(
    parameter               FPGAFAMILY  = "Arria V",    // Семейство FPGA ("Arria V" | "Arria 10")
    parameter               DIRECTION   = "TX"          // Направление тракта ("RX" | "TX")
)
(
    // Сброс и тактирование
    input  logic            reset,
    input  logic            clk,
    
    // Интерфейс записи в FIFO
    input  logic [31 : 0]   wr_data,
    input  logic            wr_eop,
    input  logic            wr_err,
    input  logic            wr_req,
    output logic            wr_full,
    output logic            wr_almostfull,
    
    // Интерфейс чтения из FIFO
    output logic [31 : 0]   rd_data,
    output logic            rd_eop,
    output logic            rd_err,
    input  logic            rd_req,
    output logic            rd_empty,
    output logic            rd_almostempty
);
    //------------------------------------------------------------------------------------
    //      Объявление констант
    localparam int unsigned         FIFO_LENGTH         = DIRECTION == "TX" ? 8 : 128;
    localparam int unsigned         FIFO_WITHU          = $clog2(FIFO_LENGTH);
    localparam int unsigned         FIFO_ALMOST_EMPTY   = 2;
    localparam int unsigned         FIFO_ALMOST_FULL    = FIFO_LENGTH / 2;
    
    //------------------------------------------------------------------------------------
    //      FIFO на ядре Altera
    scfifo
    #(
        .add_ram_output_register    ("OFF"),
        .almost_empty_value         (FIFO_ALMOST_EMPTY),
        .almost_full_value          (FIFO_ALMOST_FULL),
        .intended_device_family     (FPGAFAMILY),
        .lpm_numwords               (FIFO_LENGTH),
        .lpm_showahead              ("ON"),
        .lpm_type                   ("scfifo"),
        .lpm_width                  (34),
        .lpm_widthu                 (FIFO_WITHU),
        .overflow_checking          ("ON"),
        .underflow_checking         ("ON"),
        .use_eab                    ("ON")
    )
    sata_link_fifo_core
    (
        .aclr                       (reset),
        .clock                      (clk),
        .data                       ({wr_err, wr_eop, wr_data}),
        .rdreq                      (rd_req),
        .wrreq                      (wr_req),
        .almost_empty               (rd_almostempty),
        .empty                      (rd_empty),
        .full                       (wr_full),
        .q                          ({rd_err, rd_eop, rd_data}),
        .almost_full                (wr_almostfull),
        .sclr                       (1'b0),
        .usedw                      (  )
    ); // sata_link_fifo_core

endmodule: sata_link_fifo