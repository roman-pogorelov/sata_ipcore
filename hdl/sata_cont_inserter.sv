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
    //
    logic [31 : 0]              prev_data_reg;
    logic                       prev_datak_reg;
    logic [31 : 0]              curr_data_reg;
    logic                       curr_datak_reg;
    logic [31 : 0]              data_reg;
    logic                       datak_reg;
    //
    logic                       cont_cond_reg;
    logic                       rand_cond_reg;

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
    //      Регистры предыдущего слова потока
    always @(posedge reset, posedge clk)
        if (reset) begin
            prev_data_reg = '0;
            prev_datak_reg = `DWORD_IS_DATA;
        end
        else if (i_ready) begin
            prev_data_reg <= curr_data_reg;
            prev_datak_reg <= curr_datak_reg;
        end
        else begin
            prev_data_reg = '0;
            prev_datak_reg = `DWORD_IS_DATA;
        end

    //------------------------------------------------------------------------------------
    //      Регистры текущего слова входного потока
    always @(posedge reset, posedge clk)
        if (reset) begin
            curr_data_reg <= '0;
            curr_datak_reg <= `DWORD_IS_DATA;
        end
        else if (i_ready) begin
            curr_data_reg <= i_data;
            curr_datak_reg <= i_datak;
        end
        else begin
            curr_data_reg <= curr_data_reg;
            curr_datak_reg <= curr_datak_reg;
        end

    //------------------------------------------------------------------------------------
    //      Регистры слова выходного потока
    always @(posedge reset, posedge clk)
        if (reset) begin
            data_reg <= '0;
            datak_reg <= `DWORD_IS_DATA;
        end
        else if (i_ready) begin
            data_reg <= curr_data_reg;
            datak_reg <= curr_datak_reg;
        end
        else begin
            data_reg <= data_reg;
            datak_reg <= datak_reg;
        end

    //------------------------------------------------------------------------------------
    //      Регистр индикатор необходимости вставки примитива CONT
    always @(posedge reset, posedge clk)
        if (reset)
            cont_cond_reg <= '0;
        else if (i_ready)
            cont_cond_reg <= {
                (curr_data_reg == i_data) &
                (curr_data_reg == prev_data_reg) &
                (i_datak == `DWORD_IS_PRIM) &
                (curr_datak_reg == `DWORD_IS_PRIM) &
                (prev_datak_reg == `DWORD_IS_PRIM)
            };
        else
            cont_cond_reg <= '0;

    //------------------------------------------------------------------------------------
    //      Регист индикатор необходимости вставки случайного значения
    always @(posedge reset, posedge clk)
        if (reset)
            rand_cond_reg <= '0;
        else
            rand_cond_reg <= cont_cond_reg;

    //------------------------------------------------------------------------------------
    //      Логика формирования выходного потока
    always_comb begin
        if (cont_cond_reg) begin
            if (rand_cond_reg) begin
                o_data = randval;
                o_datak = `DWORD_IS_DATA;
            end
            else begin
                o_data = `CONT_PRIM;
                o_datak = `DWORD_IS_PRIM;
            end
        end
        else begin
            o_data = data_reg;
            o_datak = datak_reg;
        end
    end

endmodule: sata_cont_inserter