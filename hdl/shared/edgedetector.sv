/*
    //------------------------------------------------------------------------------------
    //      Модуль формирования одиночных импульсов индикаторов фронта входного сигнала
    edgedetector
    #(
        .INIT           ()  // Исходное значение регистра ('0 | '1)
    )
    the_edgedetector
    (
        // Сброс и тактирование
        .reset          (),
        .clk            (),
        
        // Входной сигнал
        .i_pulse        (),
        
        // Выходные импульсы индикаторы фронтов
        .o_rise         (),
        .o_fall         (),
        .o_either       ()
    ); // the_edgedetector
*/

module edgedetector
#(
    parameter logic         INIT = 1'b1     // Исходное значение регистра ('0 | '1)
)
(
    // Сброс и тактирование
    input  logic            reset,
    input  logic            clk,
    
    // Входной сигнал
    input  logic            i_pulse,
    
    // Выходные импульсы индикаторы фронтов
    output logic            o_rise,
    output logic            o_fall,
    output logic            o_either
);
    //------------------------------------------------------------------------------------
    //      Регистр входного сигнала
    logic pulse_reg;
    initial pulse_reg = INIT;
    always @(posedge reset, posedge clk)
        if (reset)
            pulse_reg <= INIT;
        else
            pulse_reg <= i_pulse;
    
    //------------------------------------------------------------------------------------
    //      Формирование выходных сигналов индикаторов
    assign o_rise = i_pulse & ~pulse_reg;
    assign o_fall = ~i_pulse & pulse_reg;
    assign o_either = i_pulse ^ pulse_reg;
    
endmodule // edgedetector