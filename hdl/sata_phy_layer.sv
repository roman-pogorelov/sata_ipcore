/*
    // SATA PHY layer block
    sata_phy_layer
    #(
        .FPGAFAMILY         ()  // FPGA generation ("Arria V" | "Stratix V" | "Arria 10")
    )
    the_sata_phy_layer
    (
        // General reset
        .reset              (), // i

        // Reconfiguration interface clock
        .reconfig_clk       (), // i

        // XCVR reference clock
        .gxb_refclk         (), // i

        // Output clock of link layer
        .link_clk           (), // o

        // Linkup status (link_clk clock domain)
        .linkup             (), // o

        // SATA generation status (link_clk clock domain)
        .sata_gen           (), // o  [1 : 0]

        // Receiver stream (link_clk clock domain)
        .rx_data            (), // o  [31 : 0]
        .rx_datak           (), // o

        // Transmitter stream (link_clk clock domain)
        .tx_data            (), // i  [31 : 0]
        .tx_datak           (), // i
        .tx_ready           (), // o

        // XCVR lane
        .gxb_rx             (), // i
        .gxb_tx             ()  // o
    ); // the_sata_phy_layer
*/


`include "sata_defs.svh"


module sata_phy_layer
#(
    parameter               FPGAFAMILY  = "Arria V"     // FPGA generation ("Arria V" | "Stratix V" | "Arria 10")
)
(
    // General reset
    input  logic            reset,

    // Reconfiguration interface clock
    input  logic            reconfig_clk,

    // XCVR reference clock
    input  logic            gxb_refclk,

    // Output clock of link layer
    output logic            link_clk,

    // Linkup status (link_clk clock domain)
    output logic            linkup,

    // SATA generation status (link_clk clock domain)
    output logic [1 : 0]    sata_gen,

    // Receiver stream (link_clk clock domain)
    output logic [31 : 0]   rx_data,
    output logic            rx_datak,

    // Transmitter stream (link_clk clock domain)
    input  logic [31 : 0]   tx_data,
    input  logic            tx_datak,
    output logic            tx_ready,

    // XCVR lane
    input  logic            gxb_rx,
    output logic            gxb_tx
);
    //------------------------------------------------------------------------------------
    //      Описание констант
    localparam int unsigned         TIMEOUT = (880 * 150);
    localparam int unsigned         TCWIDTH = $clog2(TIMEOUT);
    //
    localparam int unsigned         FIFOLEN = 10;
    localparam int unsigned         MAXUSED = 7;
    localparam int unsigned         MINUSED = 3;

    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic                           reconfig_reset;
    logic                           gxb_reset;
    //
    logic                           rx_reset;
    logic                           rx_clk;
    logic                           tx_reset;
    logic                           tx_clk;
    //
    logic                           rxtx_reset;
    logic                           rxtx_reset_reg;
    //
    logic                           gxb_rx_ready;
    logic                           gxb_tx_ready;
    //
    logic                           rx_is_lockedtodata;
    logic                           rx_is_lockedtodata_resync;
    logic                           rx_is_lockedtoref;
    logic                           rx_is_lockedtoref_resync;
    logic [3 : 0]                   rx_patterndetect;
    logic                           tx_elecidle;
    logic                           rx_signaldetect;
    logic                           rx_signaldetect_resync;
    logic [3 : 0]                   rx_syncstatus;
    logic [3 : 0]                   rx_syncstatus_resync;
    logic [3 : 0]                   rx_datak_resync;
    logic [31 : 0]                  rx_data_resync;
    logic [3 : 0]                   rx_datak_unalign;
    logic [31 : 0]                  rx_data_unalign;
    logic [3 : 0]                   rx_datak_align;
    logic [31 : 0]                  rx_data_align;
    //
    logic                           tx_cominit;
    logic                           tx_comwake;
    logic                           tx_oobfinish;
    logic                           tx_select;
    logic                           tx_select_reg;
    logic                           tx_select_resync;
    logic                           tx_oob_ready;
    //
    logic                           rx_cominit;
    logic                           rx_comwake;
    logic                           rx_oobfinish;
    //
    logic                           xcvr_set_max_rate;
    logic                           xcvr_change_rate;
    logic                           xcvr_reset;
    logic                           xcvr_reset_reg;
    //
    logic                           align_det_reg;
    logic                           sync_det_reg;
    logic                           link_fault_reg;
    //
    logic                           link_ready;
    logic                           link_ready_reg;
    logic                           link_ready_resync;
    logic                           timeout_inc;
    logic [TCWIDTH - 1 : 0]         timeout_cnt;
    logic                           timeout_reg;
    logic [7 : 0]                   align_cnt;
    logic                           align_reg;
    //
    logic [31 : 0]                  tx_data_reg;
    logic                           tx_datak_reg;
    //
    logic [$clog2(FIFOLEN) - 1 : 0] linkup_cnt;
    logic                           linkup_reg;
    //
    logic                           reset_rmfifo_reg;
    //
    logic                           recfg_request;
    logic                           recfg_request_resync;
    logic                           recfg_ready;
    logic                           recfg_ready_resync;
    logic [1 : 0]                   recfg_sata_gen_reg;
    logic [1 : 0]                   recfg_sata_gen_resync;
    //
    logic                           gxb_recfg_state_reg;
    logic                           gxb_recfg_request;
    logic                           gxb_recfg_ready;

    //------------------------------------------------------------------------------------
    //      Кодирование состояний конечного автомата
    (* syn_encoding = "gray" *) enum int unsigned {
        st_wait_for_xcvr,
        st_set_max_xcvr_rate,
        st_recfg_xcvr_rate,
        st_wait_for_set_xcvr_rate,
        st_reset_xcvr,
        st_wait_for_xcvr_after_reset,
        st_wait_for_lockedtodata,
        st_send_comreset,
        st_wait_for_comreset_finish,
        st_wait_for_cominit,
        st_send_comwake,
        st_wait_for_comwake_finish,
        st_wait_for_comwake,
        st_wait_for_align,
        st_change_xcvr_rate,
        st_wait_for_sync,
        st_link_ready
    } cstate, nstate;

    //------------------------------------------------------------------------------------
    //      Регистр текущего состояния конечного автомата и его регистровые выходы
    initial cstate = st_wait_for_xcvr;
    initial rxtx_reset_reg = '1;
    initial xcvr_reset_reg = '1;
    always @(posedge gxb_reset, posedge gxb_refclk)
        if (gxb_reset) begin
            cstate <= st_wait_for_xcvr;
            link_ready_reg <= '0;
            tx_select_reg <= '0;
            rxtx_reset_reg <= '1;
            xcvr_reset_reg <= '1;
        end
        else begin
            cstate <= nstate;
            link_ready_reg <= link_ready;
            tx_select_reg <= tx_select;
            rxtx_reset_reg <= rxtx_reset;
            xcvr_reset_reg <= xcvr_reset;
        end

    //------------------------------------------------------------------------------------
    //      Логика формирования следующего состояния конечного автомата и его выходов
    always_comb begin
        // Значения по умолчанию для выходов конечного автомата
        link_ready          = 1'b0;
        tx_select           = 1'b0;
        rxtx_reset          = 1'b0;
        xcvr_reset          = 1'b0;
        xcvr_set_max_rate   = 1'b0;
        xcvr_change_rate    = 1'b0;
        tx_cominit          = 1'b0;
        tx_comwake          = 1'b0;
        tx_oobfinish        = 1'b0;
        timeout_inc         = 1'b0;
        recfg_request       = 1'b0;

        // Выбор в зависимости от текущего состояния
        case (cstate)
            st_wait_for_xcvr: begin
                rxtx_reset = 1'b1;
                if (gxb_tx_ready & rx_is_lockedtoref_resync)
                    nstate = st_set_max_xcvr_rate;
                else
                    nstate = st_wait_for_xcvr;
            end

            st_set_max_xcvr_rate: begin
                xcvr_set_max_rate = 1'b1;
                nstate = st_recfg_xcvr_rate;
            end

            st_recfg_xcvr_rate: begin
                rxtx_reset = 1'b1;
                recfg_request = 1'b1;
                if (recfg_ready)
                    nstate = st_wait_for_set_xcvr_rate;
                else
                    nstate = st_recfg_xcvr_rate;
            end

            st_wait_for_set_xcvr_rate: begin
                rxtx_reset = 1'b1;
                if (recfg_ready) begin
                    xcvr_reset = 1'b1;
                    nstate = st_reset_xcvr;
                end
                else
                    nstate = st_wait_for_set_xcvr_rate;
            end

            st_reset_xcvr: begin
                rxtx_reset = 1'b1;
                nstate = st_wait_for_xcvr_after_reset;
            end

            st_wait_for_xcvr_after_reset: begin
                if (gxb_tx_ready & rx_is_lockedtoref_resync)
                    nstate = st_wait_for_lockedtodata;
                else begin
                    rxtx_reset = 1'b1;
                    nstate = st_wait_for_xcvr_after_reset;
                end
            end

            st_wait_for_lockedtodata: begin
                if (rx_is_lockedtodata_resync)
                    nstate = st_send_comreset;
                else
                    nstate = st_wait_for_lockedtodata;
            end

            st_send_comreset: begin
                tx_cominit = 1'b1;
                if (tx_oob_ready)
                    nstate = st_wait_for_comreset_finish;
                else
                    nstate = st_send_comreset;
            end

            st_wait_for_comreset_finish: begin
                if (tx_oob_ready)
                    nstate = st_wait_for_cominit;
                else
                    nstate = st_wait_for_comreset_finish;
            end

            st_wait_for_cominit: begin
                if (rx_cominit)
                    nstate = st_send_comwake;
                else if (timeout_reg)
                    nstate = st_send_comreset;
                else begin
                    timeout_inc = 1'b1;
                    nstate = st_wait_for_cominit;
                end
            end

            st_send_comwake: begin
                tx_comwake = 1'b1;
                if (tx_oob_ready)
                    nstate = st_wait_for_comwake_finish;
                else
                    nstate = st_send_comwake;
            end

            st_wait_for_comwake_finish: begin
                if (tx_oob_ready)
                    nstate = st_wait_for_comwake;
                else
                    nstate = st_wait_for_comwake_finish;
            end

            st_wait_for_comwake: begin
                if (rx_comwake) begin
                    tx_select = 1'b1;
                    nstate = st_wait_for_align;
                end
                else if (timeout_reg)
                    nstate = st_send_comreset;
                else begin
                    timeout_inc = 1'b1;
                    nstate = st_wait_for_comwake;
                end
            end

            st_wait_for_align: begin
                tx_oobfinish = 1'b1;
                if (align_det_reg)
                    nstate = st_wait_for_sync;
                else if (timeout_reg)
                    nstate = st_change_xcvr_rate;
                else begin
                    tx_select = 1'b1;
                    timeout_inc = 1'b1;
                    nstate = st_wait_for_align;
                end
            end

            st_change_xcvr_rate: begin
                xcvr_change_rate = 1'b1;
                nstate = st_recfg_xcvr_rate;
            end

            st_wait_for_sync: begin
                tx_oobfinish = 1'b1;
                if (sync_det_reg) begin
                    link_ready = 1'b1;
                    nstate = st_link_ready;
                end
                else if (timeout_reg)
                    nstate = st_send_comreset;
                else begin
                    timeout_inc = 1'b1;
                    nstate = st_wait_for_sync;
                end
            end

            st_link_ready: begin
                tx_oobfinish = 1'b1;
                if (link_fault_reg) begin
                    nstate = st_set_max_xcvr_rate;
                end
                else begin
                    link_ready = 1'b1;
                    nstate = st_link_ready;
                end
            end

            default: begin
                nstate = st_send_comreset;
            end
        endcase
    end

    //------------------------------------------------------------------------------------
    //      Модуль синхронизации сигналов асинхронного сброса (предустановки)
    areset_synchronizer
    #(
        .EXTRA_STAGES   (1),                // Количество дополнительных ступеней цепи синхронизации
        .ACTIVE_LEVEL   (1'b1)              // Активный уровень сигнала сброса
    )
    reconfig_reset_synchronizer
    (
        // Сигнал тактирования
        .clk            (reconfig_clk),     // i

        // Входной сброс (асинхронный
        // относительно сигнала тактирования)
        .areset         (reset),            // i

        // Выходной сброс (синхронный
        // относительно сигнала тактирования)
        .sreset         (reconfig_reset)    // o
    ); // reconfig_reset_synchronizer

    //------------------------------------------------------------------------------------
    //      Модуль синхронизации сигналов асинхронного сброса (предустановки)
    areset_synchronizer
    #(
        .EXTRA_STAGES   (1),                // Количество дополнительных ступеней цепи синхронизации
        .ACTIVE_LEVEL   (1'b1)              // Активный уровень сигнала сброса
    )
    gxb_reset_synchronizer
    (
        // Сигнал тактирования
        .clk            (gxb_refclk),       // i

        // Входной сброс (асинхронный
        // относительно сигнала тактирования)
        .areset         (reset),            // i

        // Выходной сброс (синхронный
        // относительно сигнала тактирования)
        .sreset         (gxb_reset)         // o
    ); // gxb_reset_synchronizer

    //------------------------------------------------------------------------------------
    //      Модуль синхронизации сигналов асинхронного сброса (предустановки)
    areset_synchronizer
    #(
        .EXTRA_STAGES   (1),                // Количество дополнительных ступеней цепи синхронизации
        .ACTIVE_LEVEL   (1'b1)              // Активный уровень сигнала сброса
    )
    rx_reset_synchronizer
    (
        // Сигнал тактирования
        .clk            (rx_clk),           // i

        // Входной сброс (асинхронный
        // относительно сигнала тактирования)
        .areset         (rxtx_reset_reg),   // i

        // Выходной сброс (синхронный
        // относительно сигнала тактирования)
        .sreset         (rx_reset)          // o
    ); // rx_reset_synchronizer

    //------------------------------------------------------------------------------------
    //      Модуль синхронизации сигналов асинхронного сброса (предустановки)
    areset_synchronizer
    #(
        .EXTRA_STAGES   (1),                // Количество дополнительных ступеней цепи синхронизации
        .ACTIVE_LEVEL   (1'b1)              // Активный уровень сигнала сброса
    )
    tx_reset_synchronizer
    (
        // Сигнал тактирования
        .clk            (tx_clk),           // i

        // Входной сброс (асинхронный
        // относительно сигнала тактирования)
        .areset         (rxtx_reset_reg),   // i

        // Выходной сброс (синхронный
        // относительно сигнала тактирования)
        .sreset         (tx_reset)          // o
    ); // tx_reset_synchronizer

    //------------------------------------------------------------------------------------
    //      Модуль синхронизации сигнала на последовательной триггерной цепочке
    ff_synchronizer
    #(
        .WIDTH          (43),           // Разрядность синхронизируемой шины
        .EXTRA_STAGES   (1),            // Количество дополнительных ступеней цепи синхронизации
        .RESET_VALUE    ({43{1'b0}})    // Значение по умолчанию для ступеней цепи синхронизации
    )
    rx2ref_ff_synchronizer
    (
        // Сброс и тактирование
        .reset          (gxb_reset),    // i
        .clk            (gxb_refclk),   // i

        // Асинхронный входной сигнал
        .async_data     ({              // i  [WIDTH - 1 : 0]
                            rx_signaldetect,
                            rx_is_lockedtoref,
                            rx_is_lockedtodata,
                            rx_syncstatus,
                            rx_datak_align,
                            rx_data_align
                        }),

        // Синхронный выходной сигнал
        .sync_data      ({              // o  [WIDTH - 1 : 0]
                            rx_signaldetect_resync,
                            rx_is_lockedtoref_resync,
                            rx_is_lockedtodata_resync,
                            rx_syncstatus_resync,
                            rx_datak_resync,
                            rx_data_resync
                        })
    ); // rx2ref_ff_synchronizer

    //------------------------------------------------------------------------------------
    //      Модуль синхронизации сигнала на последовательной триггерной цепочке
    ff_synchronizer
    #(
        .WIDTH          (4),            // Разрядность синхронизируемой шины
        .EXTRA_STAGES   (1),            // Количество дополнительных ступеней цепи синхронизации
        .RESET_VALUE    ({2{1'b0}})     // Значение по умолчанию для ступеней цепи синхронизации
    )
    ref2tx_ff_synchronizer
    (
        // Сброс и тактирование
        .reset          (tx_reset),     // i
        .clk            (tx_clk),       // i

        // Асинхронный входной сигнал
        .async_data     ({              // i  [WIDTH - 1 : 0]
                            tx_select_reg,
                            link_ready_reg,
                            recfg_sata_gen_reg
                        }),

        // Синхронный выходной сигнал
        .sync_data      ({              // o  [WIDTH - 1 : 0]
                            tx_select_resync,
                            link_ready_resync,
                            sata_gen
                        })
    ); // ref2tx_ff_synchronizer

    //------------------------------------------------------------------------------------
    //      Модуль синхронизации интерфейса DataStream между двумя доменами
    //      тактирования на основе механизма взаимного подтверждения
    ds_hs_synchronizer
    #(
        .WIDTH      (2),                        // Разрядность потока
        .ESTAGES    (1),                        // Количество дополнительных ступеней цепи синхронизации
        .HSTYPE     (2)                         // Схема взаимного подтверждения (2 - с двумя фазами 4 - с четырьмя фазами)
    )
    reconfig_synchronizer
    (
        // Сброс и тактирование входного потокового интерфейса
        .i_reset    (gxb_reset),                // i
        .i_clk      (gxb_refclk),               // i

        // Входной потоковый интерфейс
        .i_dat      (recfg_sata_gen_reg),       // i  [WIDTH - 1 : 0]
        .i_val      (recfg_request),            // i
        .i_rdy      (recfg_ready),              // o

        // Сброс и тактирование выходного потокового интерфейса
        .o_reset    (reconfig_reset),           // i
        .o_clk      (reconfig_clk),             // i

        // Выходной потоковый интерфейс
        .o_dat      (recfg_sata_gen_resync),    // o  [WIDTH - 1 : 0]
        .o_val      (recfg_request_resync),     // o
        .o_rdy      (recfg_ready_resync)        // i
    ); // reconfig_synchronizer

    //------------------------------------------------------------------------------------
    //      Кодер OOB-последовательностей Serial ATA
    sata_oob_coder
    the_sata_oob_coder
    (
        // Сброс и тактирование
        .reset          (gxb_reset),            // i
        .clk            (gxb_refclk),           // i

        // Индикатор готовности к приему команды
        .ready          (tx_oob_ready),         // o

        // Окончание фазы генерации последовательностей
        .oobfinish      (tx_oobfinish),         // i

        // Команды генерируемых  последовательностей
        .cominit        (tx_cominit),           // i
        .comwake        (tx_comwake),           // i

        // Управление переводом передатчика в неактивное состояние
        .txelecidle     (tx_elecidle)           // o
    ); // the_sata_oob_coder

    //------------------------------------------------------------------------------------
    //      Декодер OOB-последовательностей Serial ATA
    sata_oob_decoder
    the_sata_oob_decoder
    (
        // Сброс и тактирование
        .reset          (gxb_reset),        // i
        .clk            (gxb_refclk),       // i

        // Индикатор активности на линии приема
        .rxsignaldetect (rx_signaldetect),  // i

        // Импульсы обнаруженных последовательностей
        .cominit        (rx_cominit),       // o
        .comwake        (rx_comwake),       // o

        // Признак окончания фазы отправки последовательностей
        .oobfinish      (rx_oobfinish)      // o
    ); // the_sata_oob_decoder

    //------------------------------------------------------------------------------------
    //      Модуль выравнивания порядка следования байт, приходящих от PCS-уровня
    //      высокоскоростного трансивера
    pcs_byte_aligner
    #(
        .BYTES      (4)                 // Количество байт (BYTES > 1)
    )
    sata_pcs_byte_aligner
    (
        // Сброс и тактирование
        .reset      (rx_reset),         // i
        .clk        (rx_clk),           // i

        // Входной интерфейс
        .i_data     (rx_data_unalign),  // i  [8 * BYTES - 1 : 0]
        .i_datak    (rx_datak_unalign), // i  [BYTES - 1 : 0]
        .i_patdet   (rx_patterndetect), // i  [BYTES - 1 : 0]

        // Выходной интерфейс
        .o_data     (rx_data_align),    // o  [8 * BYTES - 1 : 0]
        .o_datak    (rx_datak_align)    // o  [BYTES - 1 : 0]
    ); // sata_pcs_byte_aligner

    //------------------------------------------------------------------------------------
    //      Модуль компенсации разности между восстановленной и опорной частотами
    //      PCS-уровня
    pcs_rate_match_fifo
    #(
        .BYTES          (4),                // Количество байт
        .DPATTERN       (`ALIGN_PRIM),      // Шаблон удаляемых/вставляемых данных
        .KPATTERN       (`DWORD_IS_PRIM),   // Шаблон удаляемых/вставляемых признаков контрольных символов
        .FIFOLEN        (FIFOLEN),          // Длина FIFO
        .MAXUSED        (MAXUSED),          // Максимальное количество слов в FIFO
        .MINUSED        (MINUSED),          // Минимальное количество слов в FIFO
        .RAMTYPE        ("AUTO")            // Тип блоков встроенной памяти ("MLAB" "M20K" ...)
    )
    the_pcs_rate_match_fifo
    (
        // Общий асинхронный сброс
        .reset          (reset_rmfifo_reg), // i

        // Восстановленная частота тактирования
        .rcv_clk        (rx_clk),           // i

        // Опорная частота тактирования
        .ref_clk        (tx_clk),           // i

        // Входной поток данных на восстановленной частоте
        .rcv_data       (rx_data_align),    // i  [8 * BYTES - 1 : 0]
        .rcv_datak      (rx_datak_align),   // i  [BYTES - 1 : 0]

        // Выходной поток данных на опорной частоте
        .ref_data       (rx_data),          // o  [8 * BYTES - 1 : 0]
        .ref_datak      (rx_datak),         // o  [BYTES - 1 : 0]

        // Статусные сигналы на восстановленной частоте
        .stat_rcv_del   (  ),               // o
        .stat_rcv_ovfl  (  ),               // o

        // Статусные сигналы на опорной частоте
        .stat_ref_ins   (  ),               // o
        .stat_ref_unfl  (  )                // o
    ); // the_pcs_rate_match_fifo

    //------------------------------------------------------------------------------------
    //      Генерация высокоскоростного приемопередатчика для конкретного семейства
    generate
        if (FPGAFAMILY == "Arria 10") begin: arria10_xcvr
            //------------------------------------------------------------------------------------
            //      Модуль высокоскоростного приемопередатчика Arria10, настроенного для
            //      работы с интерфейсом SerialATA
            a10_sata_xcvr
            #(
                .PLLTYPE            ("fPLL")                        // Тип используемой PLL ("fPLL" | "CMUPLL" | "ATXPLL")
            )
            the_a10_sata_xcvr
            (
                // Сброс и тактирование интерфейса реконфигурации
                .reconfig_reset     (reconfig_reset),               // i
                .reconfig_clk       (reconfig_clk),                 // i

                // Сброс и тактирование высокоскоростных приемопередатчиков
                .gxb_reset          (xcvr_reset_reg),               // i
                .gxb_refclk         (gxb_refclk),                   // i

                // Интерфейс реконфигурации между поколениями SATA
                // (домен reconfig_clk)
                .recfg_request      (gxb_recfg_request),            // i
                .recfg_sata_gen     (recfg_sata_gen_resync),        // i  [1 : 0]
                .recfg_ready        (gxb_recfg_ready),              // o

                // Интерфейсные сигналы приемника
                .rx_clock           (rx_clk),                       // o
                .rx_data            (rx_data_unalign),              // o  [31 : 0]
                .rx_datak           (rx_datak_unalign),             // o  [3 : 0]
                .rx_is_lockedtodata (rx_is_lockedtodata),           // o
                .rx_is_lockedtoref  (rx_is_lockedtoref),            // o
                .rx_patterndetect   (rx_patterndetect),             // o  [3 : 0]
                .rx_signaldetect    (rx_signaldetect),              // o
                .rx_syncstatus      (rx_syncstatus),                // o  [3 : 0]

                // Интерфейсные сигналы передатчика
                .tx_clock           (tx_clk),                       // o
                .tx_data            (tx_data_reg),                  // i  [31 : 0]
                .tx_datak           ({{3{1'b0}}, tx_datak_reg}),    // i  [3 : 0]
                .tx_elecidle        (tx_elecidle),                  // i

                // Статусные сигналы готовности
                // (домен gxb_refclk)
                .rx_ready           (gxb_rx_ready),                 // o
                .tx_ready           (gxb_tx_ready),                 // o

                // Высокоскоростные линии
                .gxb_rx             (gxb_rx),                       // i
                .gxb_tx             (gxb_tx)                        // o
            ); // the_a10_sata_xcvr
        end
        if (FPGAFAMILY == "Stratix V") begin: stratixv_xcvr
            //------------------------------------------------------------------------------------
            //      Модуль высокоскоростного приемопередатчика StratixV, настроенного для
            //      работы с интерфейсом SerialATA
            sv_sata_xcvr
            #(
                .PLLTYPE            ("CMUPLL")                      // Тип используемой PLL ("CMUPLL" | "ATXPLL")
            )
            the_sv_sata_xcvr
            (
                // Сброс и тактирование интерфейса реконфигурации
                .reconfig_reset     (reconfig_reset),               // i
                .reconfig_clk       (reconfig_clk),                 // i

                // Сброс и тактирование высокоскоростных приемопередатчиков
                .gxb_reset          (xcvr_reset_reg),               // i
                .gxb_refclk         (gxb_refclk),                   // i

                // Интерфейс реконфигурации между поколениями SATA
                // (домен reconfig_clk)
                .recfg_request      (gxb_recfg_request),            // i
                .recfg_sata_gen     (recfg_sata_gen_resync),        // i  [1 : 0]
                .recfg_ready        (gxb_recfg_ready),              // o

                // Интерфейсные сигналы приемника
                .rx_clock           (rx_clk),                       // o
                .rx_data            (rx_data_unalign),              // o  [31 : 0]
                .rx_datak           (rx_datak_unalign),             // o  [3 : 0]
                .rx_is_lockedtodata (rx_is_lockedtodata),           // o
                .rx_is_lockedtoref  (rx_is_lockedtoref),            // o
                .rx_patterndetect   (rx_patterndetect),             // o  [3 : 0]
                .rx_signaldetect    (rx_signaldetect),              // o
                .rx_syncstatus      (rx_syncstatus),                // o  [3 : 0]

                // Интерфейсные сигналы передатчика
                .tx_clock           (tx_clk),                       // o
                .tx_data            (tx_data_reg),                  // i  [31 : 0]
                .tx_datak           ({{3{1'b0}}, tx_datak_reg}),    // i  [3 : 0]
                .tx_elecidle        (tx_elecidle),                  // i

                // Статусные сигналы готовности
                // (домен gxb_refclk)
                .rx_ready           (gxb_rx_ready),                 // o
                .tx_ready           (gxb_tx_ready),                 // o

                // Высокоскоростные линии
                .gxb_rx             (gxb_rx),                       // i
                .gxb_tx             (gxb_tx)                        // o
            ); // the_sv_sata_xcvr
        end
        else begin: arriav_xcvr
            //------------------------------------------------------------------------------------
            //      Модуль высокоскоростного приемопередатчика ArriaV, настроенного для
            //      работы с интерфейсом SerialATA
            av_sata_xcvr
            the_av_sata_xcvr
            (
                // Сброс и тактирование интерфейса реконфигурации
                .reconfig_reset     (reconfig_reset),               // i
                .reconfig_clk       (reconfig_clk),                 // i

                // Сброс и тактирование высокоскоростных приемопередатчиков
                .gxb_reset          (xcvr_reset_reg),               // i
                .gxb_refclk         (gxb_refclk),                   // i

                // Интерфейс реконфигурации между поколениями SATA
                // (домен reconfig_clk)
                .recfg_request      (gxb_recfg_request),            // i
                .recfg_sata_gen     (recfg_sata_gen_resync),        // i  [1 : 0]
                .recfg_ready        (gxb_recfg_ready),              // o

                // Интерфейсные сигналы приемника
                .rx_clock           (rx_clk),                       // o
                .rx_data            (rx_data_unalign),              // o  [31 : 0]
                .rx_datak           (rx_datak_unalign),             // o  [3 : 0]
                .rx_is_lockedtodata (rx_is_lockedtodata),           // o
                .rx_is_lockedtoref  (rx_is_lockedtoref),            // o
                .rx_patterndetect   (rx_patterndetect),             // o  [3 : 0]
                .rx_signaldetect    (rx_signaldetect),              // o
                .rx_syncstatus      (rx_syncstatus),                // o  [3 : 0]

                // Интерфейсные сигналы передатчика
                .tx_clock           (tx_clk),                       // o
                .tx_data            (tx_data_reg),                  // i  [31 : 0]
                .tx_datak           ({{3{1'b0}}, tx_datak_reg}),    // i  [3 : 0]
                .tx_elecidle        (tx_elecidle),                  // i

                // Статусные сигналы готовности
                // (домен gxb_refclk)
                .rx_ready           (gxb_rx_ready),                 // o
                .tx_ready           (gxb_tx_ready),                 // o

                // Высокоскоростные линии
                .gxb_rx             (gxb_rx),                       // i
                .gxb_tx             (gxb_tx)                        // o
            ); // the_av_sata_xcvr
        end
    endgenerate

    //------------------------------------------------------------------------------------
    //      Регист признака обнаружения примитива ALIGN
    always @(posedge gxb_reset, posedge gxb_refclk)
        if (gxb_reset)
            align_det_reg <= '0;
        else
            align_det_reg <= (
                (rx_data_resync == `ALIGN_PRIM) &
                (rx_datak_resync == {{3{1'b0}}, `DWORD_IS_PRIM}) &
                (&rx_syncstatus_resync)
            );

    //------------------------------------------------------------------------------------
    //      Регист признака обнаружения примитива SYNC
    always @(posedge gxb_reset, posedge gxb_refclk)
        if (gxb_reset)
            sync_det_reg <= '0;
        else
            sync_det_reg <= (
                (rx_data_resync == `SYNC_PRIM) &
                (rx_datak_resync == {{3{1'b0}}, `DWORD_IS_PRIM}) &
                (&rx_syncstatus_resync)
            );

    //------------------------------------------------------------------------------------
    //      Регистр признака обрыва соединения
    initial link_fault_reg = 1'b1;
    always @(posedge gxb_reset, posedge gxb_refclk)
        if (gxb_reset)
            link_fault_reg <= 1'b1;
        else
            link_fault_reg <= ~(
                rx_signaldetect_resync &
                (&rx_syncstatus_resync)
            );

    //------------------------------------------------------------------------------------
    //      Счетчик тактов таймаута для прерывания операции
    always @(posedge gxb_reset, posedge gxb_refclk)
        if (gxb_reset)
            timeout_cnt <= '0;
        else if (timeout_inc)
            timeout_cnt <= timeout_cnt + 1'b1;
        else
            timeout_cnt <= '0;

    //------------------------------------------------------------------------------------
    //      Регистр индикатор прерывания ожидания по таймауту
    always @(posedge gxb_reset, posedge gxb_refclk)
        if (gxb_reset)
            timeout_reg <= '0;
        else
            timeout_reg <= timeout_inc & (timeout_cnt == (TIMEOUT - 1));

    //------------------------------------------------------------------------------------
    //      Счетчик тактов между примитивами выравнивания
    always @(posedge tx_reset, posedge tx_clk)
        if (tx_reset)
            align_cnt <= '0;
        else if (link_ready_resync)
            align_cnt <= align_cnt + 1'b1;
        else
            align_cnt <= '0;

    //------------------------------------------------------------------------------------
    //      Регист управления вставкой примитивов выравнивания
    always @(posedge tx_reset, posedge tx_clk)
        if (tx_reset)
            align_reg <= '0;
        else
            align_reg <= link_ready_resync & ((align_cnt == 0) | (align_cnt == 1));

    //------------------------------------------------------------------------------------
    //      Регистр данных для передачи
    always @(posedge tx_reset, posedge tx_clk)
        if (tx_reset)
            tx_data_reg <= '0;
        else if (tx_select_resync)
            tx_data_reg <= `DIAL_DATA;
        else if (link_ready_resync & ~align_reg)
            tx_data_reg <= tx_data;
        else
            tx_data_reg <= `ALIGN_PRIM;

    //------------------------------------------------------------------------------------
    //      Регистр признаков контрольных символов для передачи
    always @(posedge tx_reset, posedge tx_clk)
        if (tx_reset)
            tx_datak_reg <= '0;
        else if (tx_select_resync)
            tx_datak_reg <= `DWORD_IS_DATA;
        else if (link_ready_resync & ~align_reg)
            tx_datak_reg <= tx_datak;
        else
            tx_datak_reg <= `DWORD_IS_PRIM;

    //------------------------------------------------------------------------------------
    //      Счетчик тактов установленного соединения
    always @(posedge tx_reset, posedge tx_clk)
        if (tx_reset)
            linkup_cnt <= '0;
        else if (link_ready_resync)
            linkup_cnt <= linkup_cnt + (linkup_cnt != (FIFOLEN - 1));
        else
            linkup_cnt <= '0;

    //------------------------------------------------------------------------------------
    //      Регистр признака установки соединения
    always @(posedge tx_reset, posedge tx_clk)
        if (tx_reset)
            linkup_reg <= '0;
        else
            linkup_reg <= link_ready_resync & (linkup_cnt == (FIFOLEN - 1));

    //------------------------------------------------------------------------------------
    //      Регистр сброса Rate-Match FIFO
    initial reset_rmfifo_reg = '1;
    always @(posedge tx_reset, posedge tx_clk)
        if (tx_reset)
            reset_rmfifo_reg <= '1;
        else
            reset_rmfifo_reg <= ~link_ready_resync;

    //------------------------------------------------------------------------------------
    //      Регист текущей конфигурации SATA
    initial recfg_sata_gen_reg = `SATA_GEN3;
    always @(posedge gxb_reset, posedge gxb_refclk)
        if (gxb_reset)
            recfg_sata_gen_reg <= `SATA_GEN3;
        else if (xcvr_set_max_rate)
            recfg_sata_gen_reg <= `SATA_GEN3;
        else if (xcvr_change_rate)
            recfg_sata_gen_reg <= recfg_sata_gen_reg - (recfg_sata_gen_reg != `SATA_GEN1);
        else
            recfg_sata_gen_reg <= recfg_sata_gen_reg;

    //------------------------------------------------------------------------------------
    //      Регистр состояния интерфейса реконфигурации между поколениями SATA
    always @(posedge reconfig_reset, posedge reconfig_clk)
        if (reconfig_reset)
            gxb_recfg_state_reg <= '0;
        else if (gxb_recfg_state_reg)
            gxb_recfg_state_reg <= ~gxb_recfg_ready;
        else
            gxb_recfg_state_reg <= recfg_request_resync & gxb_recfg_ready;

    //------------------------------------------------------------------------------------
    //      Дополнительная логика в интерфейсе реконфигурации между поколениями SATA
    assign gxb_recfg_request  = ~gxb_recfg_state_reg & recfg_request_resync;
    assign recfg_ready_resync =  gxb_recfg_state_reg & gxb_recfg_ready;

    //------------------------------------------------------------------------------------
    //      Признак готовности интерфейса передатчика (не готов во время передачи
    //      примитивов выравнивания)
    assign tx_ready = ~align_reg;

    //------------------------------------------------------------------------------------
    //      Выходное тактирование интерфейса приемника и передатчика
    assign link_clk = tx_clk;

    //------------------------------------------------------------------------------------
    //      Индикатор установки соединения
    assign linkup = linkup_reg;

endmodule: sata_phy_layer