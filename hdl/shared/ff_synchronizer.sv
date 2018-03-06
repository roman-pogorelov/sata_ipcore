/*
    //------------------------------------------------------------------------------------
    //      Модуль синхронизации сигнала на последовательной триггерной цепочке
    ff_synchronizer
    #(
        .WIDTH          (), // Разрядность синхронизируемой шины
        .EXTRA_STAGES   (), // Количество дополнительных ступеней цепи синхронизации
        .RESET_VALUE    ()  // Значение по умолчанию для ступеней цепи синхронизации
    )
    the_ff_synchronizer
    (
        // Сброс и тактирование
        .reset          (), // i
        .clk            (), // i
        
        // Асинхронный входной сигнал
        .async_data     (), // i  [WIDTH - 1 : 0]
        
        // Синхронный выходной сигнал
        .sync_data      ()  // o  [WIDTH - 1 : 0]
    ); // the_ff_synchronizer
*/

module ff_synchronizer
#(
    parameter int unsigned          WIDTH        = 1,   // Разрядность синхронизируемой шины
    parameter int unsigned          EXTRA_STAGES = 0,   // Количество дополнительных ступеней цепи синхронизации
    parameter logic [WIDTH - 1 : 0] RESET_VALUE  = 0    // Значение по умолчанию для ступеней цепи синхронизации
)
(
    // Сброс и тактирование
    input  logic                    reset,
    input  logic                    clk,
    
    // Асинхронный входной сигнал
    input  logic [WIDTH - 1 : 0]    async_data,
    
    // Синхронный выходной сигнал
    output logic [WIDTH - 1 : 0]    sync_data
);
    //------------------------------------------------------------------------------------
    //      Описание констант
    localparam int unsigned STAGES = 1 + EXTRA_STAGES;  // Общее количество ступеней цепи синхронизации 
    
    //------------------------------------------------------------------------------------
    //      Объявление сигналов с учетом требований синтеза и проверки Altera
    (* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON; -name SDC_STATEMENT \"set_false_path -to [get_keepers {*ff_synchronizer:*|stage0[*]}]\" "} *) reg [WIDTH - 1 : 0] stage0;
    (* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON"} *) reg [STAGES - 1 : 0][WIDTH - 1 : 0] stage_chain;
    
    //------------------------------------------------------------------------------------
    //      Первая ступень цепи синхронизации
    initial stage0 = RESET_VALUE;
    always @(posedge reset, posedge clk)
        if (reset)
            stage0 <= RESET_VALUE;
        else
            stage0 <= async_data;
    
    //------------------------------------------------------------------------------------
    //      Остальные ступени цепи синхронизации
    initial stage_chain = {STAGES{RESET_VALUE}};
    always @(posedge reset, posedge clk)
        if (reset)
            stage_chain <= {STAGES{RESET_VALUE}};
        else if (STAGES > 1)
            stage_chain <= {stage_chain[STAGES - 2 : 0], stage0};
        else
            stage_chain <= stage0;
    assign sync_data = stage_chain[STAGES - 1];
    
endmodule: ff_synchronizer