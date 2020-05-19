/*
    //------------------------------------------------------------------------------------
    //      Кодер OOB-последовательностей Serial ATA
    sata_oob_coder
    the_sata_oob_coder
    (
        // Сброс и тактирование
        .reset          (), // i
        .clk            (), // i

        // Индикатор готовности к приему команды
        .ready          (), // o

        // Окончание фазы генерации последовательностей
        .oobfinish      (), // i

        // Команды генерируемых  последовательностей
        .cominit        (), // i
        .comwake        (), // i

        // Управление переводом передатчика в неактивное состояние
        .txelecidle     ()  // o
    ); // the_sata_oob_coder
*/

module sata_oob_coder
(
    // Сброс и тактирование
    input  logic                reset,
    input  logic                clk,

    // Индикатор готовности к приему команды
    output logic                ready,

    // Окончание фазы генерации последовательностей
    input  logic                oobfinish,

    // Команды генерируемых  последовательностей
    input  logic                cominit,
    input  logic                comwake,

    // Управление переводом передатчика в неактивное состояние
    output logic                txelecidle
);
    //------------------------------------------------------------------------------------
    //      Описание констант
    localparam int unsigned     BURST       = 16;
    localparam int unsigned     GAPINIT     = 48;
    localparam int unsigned     GAPWAKE     = 16;
    localparam int unsigned     BURSTWIDTH  = $clog2(BURST);
    localparam int unsigned     GAPWIDTH    = $clog2(GAPINIT);
    localparam int unsigned     AMOUNT      = 6;

    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic [BURSTWIDTH - 1 : 0]      burst_len_cnt;
    logic [GAPWIDTH - 1 : 0]        gap_len_cnt;
    logic [$clog2(AMOUNT) - 1 : 0]  burst_cnt;
    logic                           txelecidle_reg;

    //------------------------------------------------------------------------------------
    //      Кодирование состояний конечного автомата
    enum logic [2 : 0] {
        st_ready        = 3'b000,
        st_init_burst   = 3'b101,
        st_init_idle    = 3'b001,
        st_wake_burst   = 3'b111,
        st_wake_idle    = 3'b011
    } state;
    wire [2 : 0] st;
    assign st = state;

    //------------------------------------------------------------------------------------
    //      Управляющие сигналы конечного автомата
    assign ready    = ~st[0];
    wire   comtype  =  st[1];
    wire   elstate  =  st[2];

    //------------------------------------------------------------------------------------
    //      Логика переходов конечного автомата
    always @(posedge reset, posedge clk)
        if (reset)
            state <= st_ready;
        else case (state)
            st_ready:
                if (cominit)
                    state <= st_init_burst;
                else if (comwake)
                    state <= st_wake_burst;
                else
                    state <= st_ready;

            st_init_burst:
                if (burst_len_cnt == (BURST - 1))
                    if (burst_cnt == (AMOUNT - 1))
                        state <= st_ready;
                    else
                        state <= st_init_idle;
                else
                    state <= st_init_burst;

            st_init_idle:
                if (gap_len_cnt == (GAPINIT - 1))
                    state <= st_init_burst;
                else
                    state <= st_init_idle;

            st_wake_burst:
                if (burst_len_cnt == (BURST - 1))
                    if (burst_cnt == (AMOUNT - 1))
                        state <= st_ready;
                    else
                        state <= st_wake_idle;
                else
                    state <= st_wake_burst;

            st_wake_idle:
                if (gap_len_cnt == (GAPWAKE - 1))
                    state <= st_wake_burst;
                else
                    state <= st_wake_idle;

            default:
                state <= st_ready;
        endcase

    //------------------------------------------------------------------------------------
    //      Счетчик длительности пачки активности
    always @(posedge reset, posedge clk)
        if (reset)
            burst_len_cnt <= '0;
        else if (~ready & elstate)
            burst_len_cnt <= burst_len_cnt + 1'b1;
        else
            burst_len_cnt <= '0;

    //------------------------------------------------------------------------------------
    //      Счетчик длительности циклов отсутствия активности
    always @(posedge reset, posedge clk)
        if (reset)
            gap_len_cnt <= '0;
        else if (~ready & ~elstate)
            gap_len_cnt <= gap_len_cnt + 1'b1;
        else
            gap_len_cnt <= '0;

    //------------------------------------------------------------------------------------
    //      Счетчик количества пачек активности
    always @(posedge reset, posedge clk)
        if (reset)
            burst_cnt <= '0;
        else if (~ready & elstate & (burst_len_cnt == (BURST - 1)))
            if (burst_cnt == (AMOUNT - 1))
                burst_cnt <= '0;
            else
                burst_cnt <= burst_cnt + 1'b1;
        else
            burst_cnt <= burst_cnt;

    //------------------------------------------------------------------------------------
    //      Регистр управление переводом передатчика в неактивное состояние
    initial txelecidle_reg = '1;
    always @(posedge reset, posedge clk)
        if (reset)
            txelecidle_reg <= '1;
        else
            txelecidle_reg <= ~(elstate | oobfinish);
    assign txelecidle = txelecidle_reg;

endmodule: sata_oob_coder