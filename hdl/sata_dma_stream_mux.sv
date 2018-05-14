/*
    //------------------------------------------------------------------------------------
    //      Модуль мультиплексирования потоковых интерфейсов
    sata_dma_stream_mux
    #(
        .INPUTS     (), // Количество входов
        .WIDTH      ()  // Разрядность потока
    )
    the_sata_dma_stream_mux
    (
        // Сигнал выбора
        .select     (), // i  [$clog2(INPUTS) - 1 : 0]
        
        // Входные потоковые интерфейсы
        .i_dat      (), // i  [INPUTS - 1 : 0][WIDTH - 1 : 0]
        .i_val      (), // i  [INPUTS - 1 : 0]
        .i_rdy      (), // o  [INPUTS - 1 : 0]
        
        // Выходной потоковый интерфейс
        .o_dat      (), // o  [WIDTH - 1 : 0]
        .o_val      (), // o
        .o_rdy      ()  // i
    ); // the_sata_dma_stream_mux
*/

module sata_dma_stream_mux
#(
    parameter int unsigned                          INPUTS  = 2,    // Количество входов
    parameter int unsigned                          WIDTH   = 8     // Разрядность потока
)
(
    // Сигнал выбора
    input  logic [$clog2(INPUTS) - 1 : 0]           select,
    
    // Входные потоковые интерфейсы
    input  logic [INPUTS - 1 : 0][WIDTH - 1 : 0]    i_dat,
    input  logic [INPUTS - 1 : 0]                   i_val,
    output logic [INPUTS - 1 : 0]                   i_rdy,
    
    // Выходной потоковый интерфейс
    output logic [WIDTH - 1 : 0]                    o_dat,
    output logic                                    o_val,
    input  logic                                    o_rdy
);
    //------------------------------------------------------------------------------------
    //      Позиционный код выбираемого канала
    logic [INPUTS - 1 : 0] select_pos;
    always_comb begin
        select_pos = {INPUTS{1'b0}};
        select_pos[select] = 1'b1;
    end
    
    //------------------------------------------------------------------------------------
    //      Логика мультиплексирования
    assign o_dat = i_dat[select];
    assign o_val = i_val[select];
    assign i_rdy = {INPUTS{o_rdy}} & select_pos;
    
endmodule: sata_dma_stream_mux