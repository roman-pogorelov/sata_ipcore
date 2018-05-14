/*
    //------------------------------------------------------------------------------------
    //      Буфер синхронизации потоковых интерфейсов между двумя доменами тактирования
    sata_dma_resync_buffer
    #(
        .DWIDTH     (), // Разрядность потока
        .DEPTH      (), // Глубина FIFO
        .RAMTYPE    ()  // Тип блоков встроенной памяти ("MLAB", "M20K", ...)
    )
    the_sata_dma_resync_buffer
    (
        // Сброс и тактирование
        .reset      (), // i
        .wr_clk     (), // i
        .rd_clk     (), // i
        
        // Входной потоковый интерфейс
        .wr_dat     (), // i  [DWIDTH - 1 : 0]
        .wr_val     (), // i
        .wr_rdy     (), // o
        
        // Выходной потоковый интерфейс
        .rd_dat     (), // o  [DWIDTH - 1 : 0]
        .rd_val     (), // o
        .rd_rdy     ()  // i
    ); // the_sata_dma_resync_buffer
*/

module sata_dma_resync_buffer
#(
    parameter                       DWIDTH  = 8,        // Разрядность потока
    parameter                       DEPTH   = 8,        // Глубина FIFO
    parameter                       RAMTYPE = "AUTO"    // Тип блоков встроенной памяти ("MLAB", "M20K", ...)
)
(
    // Сброс и тактирование
    input  logic                    reset,
    input  logic                    wr_clk,
    input  logic                    rd_clk,
    
    // Входной потоковый интерфейс
    input  logic [DWIDTH - 1 : 0]   wr_dat,
    input  logic                    wr_val,
    output logic                    wr_rdy,
    
    // Выходной потоковый интерфейс
    output logic [DWIDTH - 1 : 0]   rd_dat,
    output logic                    rd_val,
    input  logic                    rd_rdy
);
    //------------------------------------------------------------------------------------
    //      Описание сигналов
    logic                           fifo_rdempty;
    logic                           fifo_wrfull;
    
    //------------------------------------------------------------------------------------
    //      Двухклоковое FIFO на ядре от Altera
    dcfifo
    #(
        .lpm_hint               ({"RAM_BLOCK_TYPE=", RAMTYPE}),
        .lpm_numwords           (DEPTH),
        .lpm_showahead          ("ON"),
        .lpm_type               ("dcfifo"),
        .lpm_width              (DWIDTH),
        .lpm_widthu             ($clog2(DEPTH)),
        .overflow_checking      ("ON"),
        .rdsync_delaypipe       (4),
        .read_aclr_synch        ("ON"),
        .underflow_checking     ("ON"),
        .use_eab                ("ON"),
        .write_aclr_synch       ("ON"),
        .wrsync_delaypipe       (4)
    )
    the_dcfifo
    (
        .aclr                   (reset),
        .wrclk                  (wr_clk),
        .wrreq                  (wr_val & ~fifo_wrfull),
        .data                   (wr_dat),
        .wrfull                 (fifo_wrfull),
        .rdclk                  (rd_clk),
        .rdreq                  (rd_rdy & ~fifo_rdempty),
        .q                      (rd_dat),
        .rdempty                (fifo_rdempty),
        .rdfull                 (  ),
        .rdusedw                (  ),
        .wrempty                (  ),
        .wrusedw                (  )
    ); // the_dcfifo

    //------------------------------------------------------------------------------------
    //      Формирование сигналов wr_rdy и rd_val
    assign wr_rdy = ~fifo_wrfull;
    assign rd_val = ~fifo_rdempty;
    
endmodule: sata_dma_resync_buffer