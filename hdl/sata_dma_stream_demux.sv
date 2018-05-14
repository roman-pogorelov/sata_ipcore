/*
    //------------------------------------------------------------------------------------
    //      Модуль демультиплексирования потоковых интерфейсов
    sata_dma_stream_demux
    #(
        .OUTPUTS    (), // Количество выходов
        .WIDTH      ()  // Разрядность потока
    )
    the_sata_dma_stream_demux
    (
        // Сигнал выбора
        .select     (), // i  [$clog2(OUTPUTS) - 1 : 0]
        
        // Входной потоковый интерфейс
        .i_dat      (), // i  [WIDTH - 1 : 0]
        .i_val      (), // i
        .i_rdy      (), // o
        
        // Выходные потоковые интерфейсы
        .o_dat      (), // o  [OUTPUTS - 1 : 0][WIDTH - 1 : 0]
        .o_val      (), // o  [OUTPUTS - 1 : 0]
        .o_rdy      ()  // i  [OUTPUTS - 1 : 0]
    ); // the_sata_dma_stream_demux
*/

module sata_dma_stream_demux
#(
    parameter int unsigned                          OUTPUTS = 2,    // Количество выходов
    parameter int unsigned                          WIDTH   = 8     // Разрядность потока
)
(
    // Сигнал выбора
    input  logic [$clog2(OUTPUTS) - 1 : 0]          select,
    
    // Входные потоковые интерфейсы
    input  logic [WIDTH - 1 : 0]                    i_dat,
    input  logic                                    i_val,
    output logic                                    i_rdy,
    
    // Выходной потоковый интерфейс
    output logic [OUTPUTS - 1 : 0][WIDTH - 1 : 0]   o_dat,
    output logic [OUTPUTS - 1 : 0]                  o_val,
    input  logic [OUTPUTS - 1 : 0]                  o_rdy
);
    //------------------------------------------------------------------------------------
    //      Позиционный код выбираемого канала
    logic [OUTPUTS - 1 : 0] select_pos;
    always_comb begin
        select_pos = {OUTPUTS{1'b0}};
        select_pos[select] = 1'b1;
    end
    
    //------------------------------------------------------------------------------------
    //      Логика демультиплексирования
    assign o_dat = {OUTPUTS{i_dat}};
    assign o_val = {OUTPUTS{i_val}} & select_pos;
    assign i_rdy = o_rdy[select];
    
endmodule: sata_dma_stream_demux