/*
    //------------------------------------------------------------------------------------
    //      Модуль выравнивания порядка следования байт, приходящих от PCS-уровня
    //      высокоскоростного трансивера
    pcs_byte_aligner
    #(
        .BYTES      ()  // Количество байт (BYTES > 1)
    )
    the_pcs_byte_aligner
    (
        // Сброс и тактирование
        .reset      (), // i
        .clk        (), // i

        // Входной интерфейс
        .i_data     (), // i  [8 * BYTES - 1 : 0]
        .i_datak    (), // i  [BYTES - 1 : 0]
        .i_patdet   (), // i  [BYTES - 1 : 0]

        // Выходной интерфейс
        .o_data     (), // o  [8 * BYTES - 1 : 0]
        .o_datak    ()  // o  [BYTES - 1 : 0]
    ); // the_pcs_byte_aligner
*/

module pcs_byte_aligner
#(
    parameter int unsigned              BYTES = 4   // Количество байт (BYTES > 1)
)
(
    // Сброс и тактирование
    input  logic                        reset,
    input  logic                        clk,

    // Входной интерфейс
    input  logic [8 * BYTES - 1 : 0]    i_data,
    input  logic [BYTES - 1 : 0]        i_datak,
    input  logic [BYTES - 1 : 0]        i_patdet,

    // Выходной интерфейс
    output logic [8 * BYTES - 1 : 0]    o_data,
    output logic [BYTES - 1 : 0]        o_datak
);
    //------------------------------------------------------------------------------------
    //      Описание констант
    localparam int unsigned BWIDTH = $clog2(BYTES);


    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic [BWIDTH - 1 : 0]                      patdet_code;
    logic [BWIDTH - 1 : 0]                      patdet_code_reg;
    logic [8 * BYTES - 1 : 0]                   data_hold_reg;
    logic [BYTES - 1 : 0]                       datak_hold_reg;
    logic [BYTES - 1 : 0][8 * BYTES - 1 : 0]    data_cat;
    logic [BYTES - 1 : 0][BYTES - 1 : 0]        datak_cat;
    logic [8 * BYTES - 1 : 0]                   data_reg;
    logic [BYTES - 1 : 0]                       datak_reg;

    //------------------------------------------------------------------------------------
    //      Преобразователь позиционного кода в двоичный
    onehot2binary
    #(
        .WIDTH      (BYTES)         // Разрядность входа позиционного кода
    )
    patdet_coder
    (
        .onehot     (i_patdet),     // i  [WIDTH - 1 : 0]
        .binary     (patdet_code)   // o  [$clog2(WIDTH) - 1 : 0]
    ); // patdet_coder

    //------------------------------------------------------------------------------------
    //      Регистр хранения кода положения шаблона выравнивания
    initial patdet_code_reg = '0;
    always @(posedge reset, posedge clk)
        if (reset)
            patdet_code_reg <= '0;
        else if (|i_patdet)
            patdet_code_reg <= patdet_code;
        else
            patdet_code_reg <= patdet_code_reg;

    //------------------------------------------------------------------------------------
    //      Регист удерживания данных предыдущего такта
    always @(posedge reset, posedge clk)
        if (reset)
            data_hold_reg <= '0;
        else
            data_hold_reg <= i_data;

    //------------------------------------------------------------------------------------
    //      Регист удерживания признаков контрольных символов предыдущего такта
    always @(posedge reset, posedge clk)
        if (reset)
            datak_hold_reg <= '0;
        else
            datak_hold_reg <= i_datak;

    //------------------------------------------------------------------------------------
    //      Объединение байт текущего и предыдущего тактов
    generate
        genvar b;
        for (b = 0; b < BYTES; b++) begin: byte_concatenation
            if (b) begin
                assign data_cat[b][8 * BYTES - 1 : 0] = {i_data[b * 8 - 1 : 0], data_hold_reg[8 * BYTES - 1 : b * 8]};
                assign datak_cat[b][BYTES - 1 : 0] = {i_datak[b - 1 : 0], datak_hold_reg[BYTES - 1 : b]};
            end
            else begin
                assign data_cat[b][8 * BYTES - 1 : 0] = data_hold_reg;
                assign datak_cat[b][BYTES - 1 : 0] = datak_hold_reg;
            end
        end
    endgenerate

    //------------------------------------------------------------------------------------
    //      Регист выходных данных
    always @(posedge reset, posedge clk)
        if (reset)
            data_reg <= '0;
        else if (BYTES > 1)
            data_reg <= data_cat[patdet_code_reg][8 * BYTES - 1 : 0];
        else
            data_reg <= data_hold_reg;
    assign o_data = data_reg;

    //------------------------------------------------------------------------------------
    //      Регистр выходных признаков контрольных символов
    always @(posedge reset, posedge clk)
        if (reset)
            datak_reg <= '0;
        else if (BYTES > 1)
            datak_reg <= datak_cat[patdet_code_reg][BYTES - 1 : 0];
        else
            datak_reg <= datak_hold_reg;
    assign o_datak = datak_reg;

endmodule: pcs_byte_aligner