/*
    //------------------------------------------------------------------------------------
    //      Модуль вставки в поток передаваемых данных примитива CONT и следующей
    //      за ним псевдослучайной последовательности данных
    sata_cont_inserter
    the_sata_cont_inserter
    (
        // Сброс и тактирование
        .reset      (), // i
        .clk        (), // i
        
        // Входной поток
        .i_data     (), // i  [31 : 0]
        .i_datak    (), // i
        .i_ready    (), // o
        
        // Выходной поток
        .o_data     (), // o  [31 : 0]
        .o_datak    (), // o
        .o_ready    ()  // i
    ); // the_sata_cont_inserter
*/

`include "sata_defs.svh"

module sata_cont_inserter
(
    // Сброс и тактирование
    input  logic                reset,
    input  logic                clk,
    
    // Входной поток
    input  logic [31 : 0]       i_data,
    input  logic                i_datak,
    output logic                i_ready,
    
    // Выходной поток
    output logic [31 : 0]       o_data,
    output logic                o_datak,
    input  logic                o_ready
);
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic [47 : 0]              lfsrval;
    logic [31 : 0]              randval;
    logic [1 : 0][31 : 0]       data_reg;
    logic [1 : 0]               datak_reg;
    logic [2 : 0]               repeat_reg;
    
    //------------------------------------------------------------------------------------
    //      Сквозная трансляция признака готовности
    assign i_ready = o_ready;
    
    //------------------------------------------------------------------------------------
    //      Генератор псевдослучайной последовательности на сдвиговом линейном регистре
    //      с обратными связями
    lfsr_generator
    #(
        .POLYDEGREE     (16),               // Степень порождающего полинома
        .POLYNOMIAL     (`LFSR_POLYNOMIAL), // Значение порождающего полинома
        .REGWIDTH       (48),               // Разрядность сдвигового регистра (REGWIDTH >= POLYDEGREE)
        .STEPSIZE       (32),               // Количество одноразрядных сдвигов за такт (STEPSIZE > 0)
        .REGINITIAL     (`LFSR_INITVALUE)   // Начальное значение сдвигового регистра (REGINITIAL != 0)
    )
    sata_lfsr_generator
    (
        // Сброс и тактирование
        .reset          (reset),            // i
        .clk            (clk),              // i
        
        // Разрешение тактирования
        .clkena         (1'b1),             // i
        
        // Синхронный сброс (инициализация)
        .init           (1'b0),             // i
        
        // Выход
        .data           (lfsrval)           // o  [REGWIDTH - 1 : 0]
    ); // sata_lfsr_generator
    
    //------------------------------------------------------------------------------------
    //      Модуль реверса (зеркалирования) разрядов произвольной параллельной шины
    bitreverser
    #(
        .WIDTH      (32)                // Разрядность
    )
    lfsr_reverser
    (
        // Входные данные
        .i_dat      (lfsrval[47 : 16]), // i  [WIDTH - 1 : 0]
        
        // Выходные данные
        .o_dat      (randval)           // o  [WIDTH - 1 : 0]
    ); // lfsr_reverser
    
    //------------------------------------------------------------------------------------
    //      Регистровая линия задержки данных
    always @(posedge reset, posedge clk)
        if (reset)
            data_reg <= '0;
        else if (i_ready)
            data_reg <= {data_reg[0], i_data};
        else
            data_reg <= data_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистровая линия задержки признака примитива
    always @(posedge reset, posedge clk)
        if (reset)
            datak_reg <= '0;
        else if (i_ready)
            datak_reg <= {datak_reg[0], i_datak};
        else
            datak_reg <= datak_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистровая линия признака повторения примитива
    always @(posedge reset, posedge clk)
        if (reset)
            repeat_reg <= '0;
        else if (i_ready)
            repeat_reg <= {
                repeat_reg[1],
                datak_reg[0] & datak_reg[1] & (data_reg[0] == data_reg[1]) & repeat_reg[0],
                datak_reg[0] & datak_reg[1] & (data_reg[0] == data_reg[1])
            };
        else
            repeat_reg <= '0;
    
    //------------------------------------------------------------------------------------
    //      Логика формирования выходного потока
    always_comb begin
        case (repeat_reg[2 : 1])
            2'b01: begin
                o_data  = `CONT_PRIM;
                o_datak = `DWORD_IS_PRIM;
            end
            
            2'b11: begin
                o_data  = randval;
                o_datak = `DWORD_IS_DATA;
            end
            
            default: begin
                o_data  = data_reg[1];
                o_datak = datak_reg[1];
            end
        endcase
    end
    
endmodule: sata_cont_inserter