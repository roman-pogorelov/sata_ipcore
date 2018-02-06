/*
    //------------------------------------------------------------------------------------
    //      Декодер OOB-последовательностей Serial ATA
    sata_oob_decoder
    #(
        .CLKFREQ        ()  // Частота тактирования clk, кГц
    )
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
#(
    parameter int unsigned      CLKFREQ = 100_000   // Частота тактирования clk, кГц
)
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
    localparam int unsigned     REFFREQ      = 1_500_000;
    localparam int unsigned     BURST_MIN    = (152 * CLKFREQ) / REFFREQ;
    localparam int unsigned     BURST_MAX    = (168 * CLKFREQ + (REFFREQ - 1)) / REFFREQ;
    localparam int unsigned     GAPINIT_MIN  = (456 * CLKFREQ) / REFFREQ;
    localparam int unsigned     GAPINIT_MAX  = (504 * CLKFREQ + (REFFREQ - 1)) / REFFREQ;
    localparam int unsigned     GAPWAKE_MIN  = (152 * CLKFREQ) / REFFREQ;
    localparam int unsigned     GAPWAKE_MAX  = (168 * CLKFREQ + (REFFREQ - 1)) / REFFREQ;
    localparam int unsigned     OOBFIN       = BURST_MAX * 5;
    localparam int unsigned     BURSTWIDTH   = $clog2(BURST_MAX + 2);
    localparam int unsigned     GAPINITWIDTH = $clog2(GAPINIT_MAX + 2);
    localparam int unsigned     GAPWAKEWIDTH = $clog2(GAPWAKE_MAX + 2);
    localparam int unsigned     OOBFINWIDTH  = $clog2(OOBFIN + 1);
    localparam int unsigned     AMOUNT       = 6;
    
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic                           sigdet;
    logic                           sigdet_rise;
    logic                           sigdet_fall;
    logic [BURSTWIDTH - 1 : 0]      burst_len_cnt;
    logic [GAPINITWIDTH - 1 : 0]    gapinit_len_cnt;
    logic [GAPWAKEWIDTH - 1 : 0]    gapwake_len_cnt;
    logic [OOBFINWIDTH - 1 : 0]     oobfin_len_cnt;
    logic [$clog2(AMOUNT) - 1 : 0]  burst_cnt;
    logic [$clog2(AMOUNT) - 1 : 0]  gapinit_cnt;
    logic [$clog2(AMOUNT) - 1 : 0]  gapwake_cnt;
    logic                           cominit_reg;
    logic                           comwake_reg;
    logic                           oobfin_reg;
    
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
        .o_either       (  )
    ); // sigdet_edgedetector
    
    //------------------------------------------------------------------------------------
    //      Счетчик длительности пачки ALIGN символов
    always @(posedge reset, posedge clk)
        if (reset)
            burst_len_cnt <= '0;
        else if (sigdet)
            if (burst_len_cnt == (BURST_MAX + 1))
                burst_len_cnt <= burst_len_cnt;
            else
                burst_len_cnt <= burst_len_cnt + 1'b1;
        else
            burst_len_cnt <= '0;
    
    //------------------------------------------------------------------------------------
    //      Счетчик длительности паузы последовательности COMINIT
    always @(posedge reset, posedge clk)
        if (reset)
            gapinit_len_cnt <= '0;
        else if (~sigdet)
            if (gapinit_len_cnt == (GAPINIT_MAX + 1))
                gapinit_len_cnt <= gapinit_len_cnt;
            else
                gapinit_len_cnt <= gapinit_len_cnt + 1'b1;
        else
            gapinit_len_cnt <= '0;
    
    //------------------------------------------------------------------------------------
    //      Счетчик длительности паузы последовательности COMWAKE
    always @(posedge reset, posedge clk)
        if (reset)
            gapwake_len_cnt <= '0;
        else if (~sigdet)
            if (gapwake_len_cnt == (GAPWAKE_MAX + 1))
                gapwake_len_cnt <= gapwake_len_cnt;
            else
                gapwake_len_cnt <= gapwake_len_cnt + 1'b1;
        else
            gapwake_len_cnt <= '0;
    
    //------------------------------------------------------------------------------------
    //      Счетчик тактов обнаружения окончания OOB-последовательностей
    always @(posedge reset, posedge clk)
        if (reset)
            oobfin_len_cnt <= '0;
        else if (sigdet)
            if (oobfin_len_cnt == OOBFIN)
                oobfin_len_cnt <= oobfin_len_cnt;
            else
                oobfin_len_cnt <= oobfin_len_cnt + 1'b1;
        else
            oobfin_len_cnt <= '0;
    
    //------------------------------------------------------------------------------------
    //      Счетчик количества пачек ALIGN символов
    always @(posedge reset, posedge clk)
        if (reset)
            burst_cnt <= '0;
        else if (sigdet_fall)
            if ((burst_len_cnt >= BURST_MIN) & (burst_len_cnt <= BURST_MAX))
                if (burst_cnt == (AMOUNT - 1))
                    burst_cnt <= '0;
                else
                    burst_cnt <= burst_cnt + 1'b1;
            else
                burst_cnt <= '0;
        else
            burst_cnt <= burst_cnt;
    
    //------------------------------------------------------------------------------------
    //      Счетчик количества пауз последовательности COMINIT
    always @(posedge reset, posedge clk)
        if (reset)
            gapinit_cnt <= '0;
        else if (sigdet_rise)
            if ((gapinit_len_cnt >= GAPINIT_MIN) & (gapinit_len_cnt <= GAPINIT_MAX))
                if (gapinit_cnt == (AMOUNT - 1))
                    gapinit_cnt <= '0;
                else
                    gapinit_cnt <= gapinit_cnt + 1'b1;
            else
                gapinit_cnt <= '0;
        else
            gapinit_cnt <= gapinit_cnt;
    
    //------------------------------------------------------------------------------------
    //      Счетчик количества пауз последовательности COMWAKE
    always @(posedge reset, posedge clk)
        if (reset)
            gapwake_cnt <= '0;
        else if (sigdet_rise)
            if ((gapwake_len_cnt >= GAPWAKE_MIN) & (gapwake_len_cnt <= GAPWAKE_MAX))
                if (gapwake_cnt == (AMOUNT - 1))
                    gapwake_cnt <= '0;
                else
                    gapwake_cnt <= gapwake_cnt + 1'b1;
            else
                gapwake_cnt <= '0;
        else
            gapwake_cnt <= gapwake_cnt;
    
    //------------------------------------------------------------------------------------
    //      Регистр индикатор декодирования последовательности COMINIT
    always @(posedge reset, posedge clk)
        if (reset)
            cominit_reg <= '0;
        else
            cominit_reg <= sigdet_fall & (burst_cnt == (AMOUNT - 1)) & (gapinit_cnt == (AMOUNT - 1));
    assign cominit = cominit_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр индикатор декодирования последовательности COMWAKE
    always @(posedge reset, posedge clk)
        if (reset)
            comwake_reg <= '0;
        else
            comwake_reg <= sigdet_fall & (burst_cnt == (AMOUNT - 1)) & (gapwake_cnt == (AMOUNT - 1));
    assign comwake = comwake_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр индикатор обнаружения окончания OOB-последовательностей
    always @(posedge reset, posedge clk)
        if (reset)
            oobfin_reg <= '0;
        else
            oobfin_reg <= (oobfin_len_cnt == OOBFIN);
    assign oobfinish = oobfin_reg;
    
endmodule: sata_oob_decoder