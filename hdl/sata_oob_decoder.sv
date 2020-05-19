/*
    //------------------------------------------------------------------------------------
    //      Декодер OOB-последовательностей Serial ATA
    sata_oob_decoder
    the_sata_oob_decoder
    (
        // Сброс и тактирование
        .reset          (), // i
        .clk            (), // i

        // Индикатор активности на линии приема
        .rxsignaldetect (), // i

        // Импульсы обнаруженных последовательностей
        .cominit        (), // o
        .comwake        (), // o

        // Признак окончания фазы отправки последовательностей
        .oobfinish      ()  // o
    ); // the_sata_oob_decoder
*/

module sata_oob_decoder
(
    // Сброс и тактирование
    input  logic                reset,
    input  logic                clk,

    // Индикатор активности на линии приема
    input  logic                rxsignaldetect,

    // Импульсы обнаруженных последовательностей
    output logic                cominit,
    output logic                comwake,

    // Признак окончания фазы отправки последовательностей
    output logic                oobfinish
);
    //------------------------------------------------------------------------------------
    //      Описание констант
    localparam int unsigned                 BURST_MIN   = 10;
    localparam int unsigned                 BURST_MAX   = 22;
    localparam int unsigned                 GAPINIT_MIN = 42;
    localparam int unsigned                 GAPINIT_MAX = 54;
    localparam int unsigned                 GAPWAKE_MIN = 10;
    localparam int unsigned                 GAPWAKE_MAX = 22;
    localparam int unsigned                 MAXCOUNT    = 80;
    localparam int unsigned                 AMOUNT      = 6;

    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic                                   sigdet;
    logic                                   sigdet_rise;
    logic                                   sigdet_fall;
    logic                                   sigdet_change;
    logic [$clog2(MAXCOUNT + 1) - 1 : 0]    cont_cnt;
    logic                                   burst_det_reg;
    logic                                   gapinit_det_reg;
    logic                                   gapwake_det_reg;
    logic                                   high_cont_reg;
    logic                                   low_cont_reg;
    logic [$clog2(AMOUNT) - 1 : 0]          burst_cnt;
    logic [$clog2(AMOUNT) - 1 : 0]          gapinit_cnt;
    logic [$clog2(AMOUNT) - 1 : 0]          gapwake_cnt;
    logic                                   cominit_reg;
    logic                                   comwake_reg;

    //------------------------------------------------------------------------------------
    //      Модуль синхронизации сигнала на последовательной триггерной цепочке
    ff_synchronizer
    #(
        .WIDTH          (1'b1),             // Разрядность синхронизируемой шины
        .EXTRA_STAGES   (1),                // Количество дополнительных ступеней цепи синхронизации
        .RESET_VALUE    (1'b0)              // Значение по умолчанию для ступеней цепи синхронизации
    )
    sigdet_synchronizer
    (
        // Сброс и тактирование
        .reset          (reset),            // i
        .clk            (clk),              // i

        // Асинхронный входной сигнал
        .async_data     (rxsignaldetect),   // i  [WIDTH - 1 : 0]

        // Синхронный выходной сигнал
        .sync_data      (sigdet)            // o  [WIDTH - 1 : 0]
    ); // sigdet_synchronizer

    //------------------------------------------------------------------------------------
    //      Модуль формирования одиночных импульсов индикаторов фронта входного сигнала
    edgedetector
    #(
        .INIT           (1'b0)  // Исходное значение регистра ('0 | '1)
    )
    sigdet_edgedetector
    (
        // Сброс и тактирование
        .reset          (reset),
        .clk            (clk),

        // Входной сигнал
        .i_pulse        (sigdet),

        // Выходные импульсы индикаторы фронтов
        .o_rise         (sigdet_rise),
        .o_fall         (sigdet_fall),
        .o_either       (sigdet_change)
    ); // sigdet_edgedetector

    //------------------------------------------------------------------------------------
    //      Счетчик длительности непрерывного уровня сигнала
    always @(posedge reset, posedge clk)
        if (reset)
            cont_cnt <= '0;
        else if (sigdet_change)
            cont_cnt <= {{$size(cont_cnt) - 1{1'b0}}, 1'b1};
        else if (cont_cnt < MAXCOUNT)
            cont_cnt <= cont_cnt + 1'b1;
        else
            cont_cnt <= cont_cnt;

    //------------------------------------------------------------------------------------
    //      Регистр признака обнаружения пачки ALIGN символов
    always @(posedge reset, posedge clk)
        if (reset)
            burst_det_reg <= '0;
        else
            burst_det_reg <= sigdet_fall & (cont_cnt >= BURST_MIN) & (cont_cnt <= BURST_MAX);

    //------------------------------------------------------------------------------------
    //      Регистр признака обнаружения паузы последовательности COMINIT
    always @(posedge reset, posedge clk)
        if (reset)
            gapinit_det_reg <= '0;
        else
            gapinit_det_reg <= sigdet_rise & (cont_cnt >= GAPINIT_MIN) & (cont_cnt <= GAPINIT_MAX);

    //------------------------------------------------------------------------------------
    //      Регистр признака обнаружения паузы последовательности COMWAKE
    always @(posedge reset, posedge clk)
        if (reset)
            gapwake_det_reg <= '0;
        else
            gapwake_det_reg <= sigdet_rise & (cont_cnt >= GAPWAKE_MIN) & (cont_cnt <= GAPWAKE_MAX);

    //------------------------------------------------------------------------------------
    //      Регистр признака продолжительного высокого уровня
    always @(posedge reset, posedge clk)
        if (reset)
            high_cont_reg <='0;
        else
            high_cont_reg <= (cont_cnt == MAXCOUNT) & sigdet & ~sigdet_change;

    //------------------------------------------------------------------------------------
    //      Регистр признака продолжительного низкого уровня
    always @(posedge reset, posedge clk)
        if (reset)
            low_cont_reg <='0;
        else
            low_cont_reg <= (cont_cnt == MAXCOUNT) & ~sigdet & ~sigdet_change;

    //------------------------------------------------------------------------------------
    //      Счетчик количества пачек ALIGN символов
    always @(posedge reset, posedge clk)
        if (reset)
            burst_cnt <= '0;
        else if (high_cont_reg | low_cont_reg)
            burst_cnt <= '0;
        else if (burst_det_reg)
            if (burst_cnt == (AMOUNT - 1))
                burst_cnt <= '0;
            else
                burst_cnt <= burst_cnt + 1'b1;
        else
            burst_cnt <= burst_cnt;

    //------------------------------------------------------------------------------------
    //      Счетчик количества пауз последовательности COMINIT
    always @(posedge reset, posedge clk)
        if (reset)
            gapinit_cnt <= '0;
        else if (high_cont_reg | low_cont_reg)
            gapinit_cnt <= '0;
        else if (gapinit_det_reg)
            if (gapinit_cnt == (AMOUNT - 1))
                gapinit_cnt <= '0;
            else
                gapinit_cnt <= gapinit_cnt + 1'b1;
        else
            gapinit_cnt <= gapinit_cnt;

    //------------------------------------------------------------------------------------
    //      Счетчик количества пауз последовательности COMWAKE
    always @(posedge reset, posedge clk)
        if (reset)
            gapwake_cnt <= '0;
        else if (high_cont_reg | low_cont_reg)
            gapwake_cnt <= '0;
        else if (gapwake_det_reg)
            if (gapwake_cnt == (AMOUNT - 1))
                gapwake_cnt <= '0;
            else
                gapwake_cnt <= gapwake_cnt + 1'b1;
        else
            gapwake_cnt <= gapwake_cnt;

    //------------------------------------------------------------------------------------
    //      Регистр индикатор декодирования последовательности COMINIT
    always @(posedge reset, posedge clk)
        if (reset)
            cominit_reg <= '0;
        else
            cominit_reg <= burst_det_reg & (burst_cnt == (AMOUNT - 1)) & (gapinit_cnt == (AMOUNT - 1));
    assign cominit = cominit_reg;

    //------------------------------------------------------------------------------------
    //      Регистр индикатор декодирования последовательности COMWAKE
    always @(posedge reset, posedge clk)
        if (reset)
            comwake_reg <= '0;
        else
            comwake_reg <= burst_det_reg & (burst_cnt == (AMOUNT - 1)) & (gapwake_cnt == (AMOUNT - 1));
    assign comwake = comwake_reg;

    //------------------------------------------------------------------------------------
    //      Индикатор обнаружения окончания OOB-последовательностей
    assign oobfinish = high_cont_reg;

endmodule: sata_oob_decoder