/*
    //------------------------------------------------------------------------------------
    //      Модуль синхронизации сигналов асинхронного сброса (предустановки)
    areset_synchronizer
    #(
        .EXTRA_STAGES   (), // Количество дополнительных ступеней цепи синхронизации
        .ACTIVE_LEVEL   ()  // Активный уровень сигнала сброса
    )
    the_areset_synchronizer
    (
        // Сигнал тактирования
        .clk            (), // i
        
        // Входной сброс (асинхронный 
        // относительно сигнала тактирования)
        .areset         (), // i
        
        // Выходной сброс (синхронный 
        // относительно сигнала тактирования)
        .sreset         ()  // o
    ); // the_areset_synchronizer
*/

module areset_synchronizer
#(
    parameter int unsigned  EXTRA_STAGES = 1,   // Количество дополнительных ступеней цепи синхронизации
    parameter logic         ACTIVE_LEVEL = 1'b1 // Активный уровень сигнала сброса
)
(
    // Сигнал тактирования
    input  logic            clk,
    
    // Входной сброс (асинхронный 
    // относительно сигнала тактирования)
    input  logic            areset,
    
    // Выходной сброс (синхронный 
    // относительно сигнала тактирования)
    output logic            sreset
);
    //------------------------------------------------------------------------------------
    //      Описание констант
    localparam int unsigned STAGES = 1 + EXTRA_STAGES;  // Общее количество ступеней цепи синхронизации 
    
    //------------------------------------------------------------------------------------
    //      Объявление сигналов с учетом требований синтеза и проверки Altera
    (* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON; -name SDC_STATEMENT \"set_false_path -through [get_pins -compatibility_mode {*areset_synchronizer*stage0|clrn}] -to [get_registers {*areset_synchronizer:*|stage0}]\" "} *) reg stage0;
    (* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON; -name SDC_STATEMENT \"set_false_path -through [get_pins -compatibility_mode {*areset_synchronizer*stage_chain[*]|clrn}] -to [get_registers {*areset_synchronizer:*|stage_chain[*]}]\" "} *) reg [STAGES - 1 : 0] stage_chain;
    
    //------------------------------------------------------------------------------------
    //      Входной асинхронный сброс с учетом различного активного уровня
    wire reset = ACTIVE_LEVEL ? areset : ~areset;
    
    //------------------------------------------------------------------------------------
    //      Первая ступень цепи синхронизации
    initial stage0 = ACTIVE_LEVEL;
    always @(posedge reset, posedge clk)
        if (reset)
            stage0 <= ACTIVE_LEVEL;
        else
            stage0 <= ~ACTIVE_LEVEL;
    
    //------------------------------------------------------------------------------------
    //      Остальные ступени цепи синхронизации
    initial stage_chain = {STAGES{ACTIVE_LEVEL}};
    always @(posedge reset, posedge clk)
        if (reset)
            stage_chain <= {STAGES{ACTIVE_LEVEL}};
        else if (STAGES > 1)
            stage_chain <= {stage_chain[STAGES - 2 : 0], stage0};
        else
            stage_chain <= stage0;
    assign sreset = stage_chain[STAGES - 1];
    
endmodule: areset_synchronizer