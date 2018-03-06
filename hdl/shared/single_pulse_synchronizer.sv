/*
    //------------------------------------------------------------------------------------
    //      Модуль синхронизации передачи одиночных (длительностью 1 такт) импульсов
    //      между двумя асинхронными доменами. Работоспособность обеспечивается
    //      только для импульсов длительностью в один такт частоты источника и периодом
    //      следования не менее двух тактов частоты приемника
    single_pulse_synchronizer
    #(
        .EXTRA_STAGES   ()  // Количество дополнительных ступеней цепи синхронизации
    )
    the_single_pulse_synchronizer
    (
        // Сброс и тактирование домена источника
        .src_reset      (), // i
        .src_clk        (), // i
        
        // Сброс и тактирование домена приемника
        .dst_reset      (), // i
        .dst_clk        (), // i
        
        // Одиночный импульс домена источника
        .src_pulse      (), // i
        
        // Одиночный импульс домена приемника
        .dst_pulse      ()  // o
    ); // the_single_pulse_synchronizer
*/

module single_pulse_synchronizer
#(
    parameter int unsigned  EXTRA_STAGES = 0    // Количество дополнительных ступеней цепи синхронизации
)
(
    // Сброс и тактирование домена источника
    input  logic            src_reset,
    input  logic            src_clk,
    
    // Сброс и тактирование домена приемника
    input  logic            dst_reset,
    input  logic            dst_clk,
    
    // Одиночный импульс домена источника
    input  logic            src_pulse,
    
    // Одиночный импульс домена приемника
    output logic            dst_pulse
);
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic   src_tick_reg;
    logic   dst_tick;
    logic   dst_tick_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр домена источника
    initial src_tick_reg = 1'b0;
    always @(posedge src_reset, posedge src_clk)
        if (src_reset)
            src_tick_reg <= 1'b0;
        else
            src_tick_reg <= src_tick_reg ^ src_pulse;
    
    //------------------------------------------------------------------------------------
    //      Модуль синхронизации сигнала на последовательной триггерной цепочке
    ff_synchronizer
    #(
        .WIDTH          (1),            // Разрядность синхронизируемой шины
        .EXTRA_STAGES   (EXTRA_STAGES), // Количество дополнительных ступеней цепи синхронизации
        .RESET_VALUE    (1'b0)          // Значение по умолчанию для ступеней цепи синхронизации
    )
    the_ff_synchronizer
    (
        // Сброс и тактирование
        .reset          (dst_reset),    // i
        .clk            (dst_clk),      // i
        
        // Асинхронный входной сигнал
        .async_data     (src_tick_reg), // i  [WIDTH - 1 : 0]
        
        // Синхронный выходной сигнал
        .sync_data      (dst_tick)      // o  [WIDTH - 1 : 0]
    ); // the_ff_synchronizer
    
    //------------------------------------------------------------------------------------
    //      Регистр домена приемника
    initial dst_tick_reg = 1'b0;
    always @(posedge dst_reset, posedge dst_clk)
        if (dst_reset)
            dst_tick_reg <= 1'b0;
        else
            dst_tick_reg <= dst_tick;
    
    //------------------------------------------------------------------------------------
    //      Одиночный импульс домена приемника
    assign dst_pulse = dst_tick ^ dst_tick_reg;
    
endmodule: single_pulse_synchronizer