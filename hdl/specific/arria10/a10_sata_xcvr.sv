/*
    //------------------------------------------------------------------------------------
    //      Модуль высокоскоростного приемопередатчика Arria10, настроенного для
    //      работы с интерфейсом SerialATA
    a10_sata_xcvr
    #(
        .PLLTYPE            ()  // Тип используемой PLL ("fPLL" | "CMUPLL" | "ATXPLL")
    )
    the_a10_sata_xcvr
    (
        // Сброс и тактирование интерфейса реконфигурации
        .reconfig_reset     (), // i
        .reconfig_clk       (), // i

        // Сброс и тактирование высокоскоростных приемопередатчиков
        .gxb_reset          (), // i
        .gxb_refclk         (), // i

        // Интерфейс реконфигурации между поколениями SATA
        // (домен reconfig_clk)
        .recfg_request      (), // i
        .recfg_sata_gen     (), // i  [1 : 0]
        .recfg_ready        (), // o

        // Интерфейсные сигналы приемника
        .rx_clock           (), // o
        .rx_data            (), // o  [31 : 0]
        .rx_datak           (), // o  [3 : 0]
        .rx_is_lockedtodata (), // o
        .rx_is_lockedtoref  (), // o
        .rx_patterndetect   (), // o  [3 : 0]
        .rx_signaldetect    (), // o
        .rx_syncstatus      (), // o  [3 : 0]

        // Интерфейсные сигналы передатчика
        .tx_clock           (), // o
        .tx_data            (), // i  [31 : 0]
        .tx_datak           (), // i  [3 : 0]
        .tx_elecidle        (), // i

        // Статусные сигналы готовности
        // (домен gxb_refclk)
        .rx_ready           (), // o
        .tx_ready           (), // o

        // Высокоскоростные линии
        .gxb_rx             (), // i
        .gxb_tx             ()  // o
    ); // the_a10_sata_xcvr
*/

module a10_sata_xcvr
#(
    parameter               PLLTYPE     = "fPLL"    // Тип используемой PLL ("fPLL" | "CMUPLL" | "ATXPLL")
)
(
    // Сброс и тактирование интерфейса реконфигурации
    input  logic            reconfig_reset,
    input  logic            reconfig_clk,

    // Сброс и тактирование высокоскоростных приемопередатчиков
    input  logic            gxb_reset,
    input  logic            gxb_refclk,

    // Интерфейс реконфигурации между поколениями SATA
    // (домен reconfig_clk)
    input  logic            recfg_request,
    input  logic [1 : 0]    recfg_sata_gen,
    output logic            recfg_ready,

    // Интерфейсные сигналы приемника
    output logic            rx_clock,
    output logic [31 : 0]   rx_data,
    output logic [3 : 0]    rx_datak,
    output logic            rx_is_lockedtodata,
    output logic            rx_is_lockedtoref,
    output logic [3 : 0]    rx_patterndetect,
    output logic            rx_signaldetect,
    output logic [3 : 0]    rx_syncstatus,

    // Интерфейсные сигналы передатчика
    output logic            tx_clock,
    input  logic [31 : 0]   tx_data,
    input  logic [3 : 0]    tx_datak,
    input  logic            tx_elecidle,

    // Статусные сигналы готовности
    // (домен gxb_refclk)
    output logic            rx_ready,
    output logic            tx_ready,

    // Высокоскоростные линии
    input  logic            gxb_rx,
    output logic            gxb_tx
);
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic                   rx_analogreset;
    logic                   rx_digitalreset;
    logic                   tx_analogreset;
    logic                   tx_digitalreset;
    logic                   tx_cal_busy;
    logic                   rx_cal_busy;
    logic                   tx_serial_clk;
    //
    logic                   pll_cal_busy;
    logic                   pll_locked;
    logic                   pll_powerdown;
    //
    logic [9 : 0]           recfg_addr;
    logic                   recfg_wreq;
    logic [31 : 0]          recfg_wdat;
    logic                   recfg_rreq;
    logic [31 : 0]          recfg_rdat;
    logic                   recfg_busy;

    //------------------------------------------------------------------------------------
    //      Ядро высокоскоростного приемопередатчика Serial ATA
    a10_sata_xcvr_core
    sata_a10_sata_xcvr_core
    (
        .reconfig_write             (recfg_wreq),           // input  wire [0:0]             reconfig_avmm.write
        .reconfig_read              (recfg_rreq),           // input  wire [0:0]                          .read
        .reconfig_address           (recfg_addr),           // input  wire [9:0]                          .address
        .reconfig_writedata         (recfg_wdat),           // input  wire [31:0]                         .writedata
        .reconfig_readdata          (recfg_rdat),           // output wire [31:0]                         .readdata
        .reconfig_waitrequest       (recfg_busy),           // output wire [0:0]                          .waitrequest
        .reconfig_clk               (reconfig_clk),         // input  wire [0:0]              reconfig_clk.clk
        .reconfig_reset             (reconfig_reset),       // input  wire [0:0]            reconfig_reset.reset
        .rx_analogreset             (rx_analogreset),       // input  wire [0:0]            rx_analogreset.rx_analogreset
        .rx_cal_busy                (rx_cal_busy),          // output wire [0:0]               rx_cal_busy.rx_cal_busy
        .rx_cdr_refclk0             (gxb_refclk),           // input  wire                  rx_cdr_refclk0.clk
        .rx_clkout                  (rx_clock),             // output wire [0:0]                 rx_clkout.clk
        .rx_coreclkin               (rx_clock),             // input  wire [0:0]              rx_coreclkin.clk
        .rx_datak                   (rx_datak),             // output wire [3:0]                  rx_datak.rx_datak
        .rx_digitalreset            (rx_digitalreset),      // input  wire [0:0]           rx_digitalreset.rx_digitalreset
        .rx_disperr                 (  ),                   // output wire [3:0]                rx_disperr.rx_disperr
        .rx_errdetect               (  ),                   // output wire [3:0]              rx_errdetect.rx_errdetect
        .rx_is_lockedtodata         (rx_is_lockedtodata),   // output wire [0:0]        rx_is_lockedtodata.rx_is_lockedtodata
        .rx_is_lockedtoref          (rx_is_lockedtoref),    // output wire [0:0]         rx_is_lockedtoref.rx_is_lockedtoref
        .rx_parallel_data           (rx_data),              // output wire [31:0]         rx_parallel_data.rx_parallel_data
        .rx_patterndetect           (rx_patterndetect),     // output wire [3:0]          rx_patterndetect.rx_patterndetect
        .rx_runningdisp             (  ),                   // output wire [3:0]            rx_runningdisp.rx_runningdisp
        .rx_serial_data             (gxb_rx),               // input  wire [0:0]            rx_serial_data.rx_serial_data
        .rx_std_signaldetect        (rx_signaldetect),      // output wire [0:0]       rx_std_signaldetect.rx_std_signaldetect
        .rx_std_wa_patternalign     (1'b0),                 // input  wire [0:0]    rx_std_wa_patternalign.rx_std_wa_patternalign
        .rx_syncstatus              (rx_syncstatus),        // output wire [3:0]             rx_syncstatus.rx_syncstatus
        .tx_analogreset             (tx_analogreset),       // input  wire [0:0]            tx_analogreset.tx_analogreset
        .tx_cal_busy                (tx_cal_busy),          // output wire [0:0]               tx_cal_busy.tx_cal_busy
        .tx_clkout                  (tx_clock),             // output wire [0:0]                 tx_clkout.clk
        .tx_coreclkin               (tx_clock),             // input  wire [0:0]              tx_coreclkin.clk
        .tx_datak                   (tx_datak),             // input  wire [3:0]                  tx_datak.tx_datak
        .tx_digitalreset            (tx_digitalreset),      // input  wire [0:0]           tx_digitalreset.tx_digitalreset
        .tx_parallel_data           (tx_data),              // input  wire [31:0]         tx_parallel_data.tx_parallel_data
        .tx_pma_elecidle            (tx_elecidle),          // input  wire [0:0]           tx_pma_elecidle.tx_pma_elecidle
        .tx_serial_clk0             (tx_serial_clk),        // input  wire [0:0]            tx_serial_clk0.clk
        .tx_serial_data             (gxb_tx),               // output wire [0:0]            tx_serial_data.tx_serial_data
        .unused_rx_parallel_data    (  ),                   // output wire [71:0]  unused_rx_parallel_data.unused_rx_parallel_data
        .unused_tx_parallel_data    ({92{1'b0}})            // input  wire [91:0]  unused_tx_parallel_data.unused_tx_parallel_data
    ); // sata_a10_sata_xcvr_core

    //------------------------------------------------------------------------------------
    //      Контроллер сброса
    a10_sata_xcvr_rst_core
    the_a10_sata_xcvr_rst_core
    (
        .clock                  (gxb_refclk),           // i                     clock.clk
        .pll_cal_busy           (pll_cal_busy),         // i  [0:0]       pll_cal_busy.pll_cal_busy
        .pll_locked             (pll_locked),           // i  [0:0]         pll_locked.pll_locked
        .pll_powerdown          (pll_powerdown),        // o  [0:0]      pll_powerdown.pll_powerdown
        .pll_select             (1'b0),                 // i  [0:0]         pll_select.pll_select
        .reset                  (gxb_reset),            // i                     reset.reset
        .rx_analogreset         (rx_analogreset),       // o  [0:0]     rx_analogreset.rx_analogreset
        .rx_cal_busy            (rx_cal_busy),          // i  [0:0]        rx_cal_busy.rx_cal_busy
        .rx_digitalreset        (rx_digitalreset),      // o  [0:0]    rx_digitalreset.rx_digitalreset
        .rx_is_lockedtodata     (rx_is_lockedtodata),   // i  [0:0] rx_is_lockedtodata.rx_is_lockedtodata
        .rx_ready               (rx_ready),             // o  [0:0]           rx_ready.rx_ready
        .tx_analogreset         (tx_analogreset),       // o  [0:0]     tx_analogreset.tx_analogreset
        .tx_cal_busy            (tx_cal_busy),          // i  [0:0]        tx_cal_busy.tx_cal_busy
        .tx_digitalreset        (tx_digitalreset),      // o  [0:0]    tx_digitalreset.tx_digitalreset
        .tx_ready               (tx_ready)              // o  [0:0]           tx_ready.tx_ready
    ); // the_a10_sata_xcvr_rst_core

    //------------------------------------------------------------------------------------
    //      Генерация необходимой PLL
    generate
        if (PLLTYPE == "ATXPLL") begin: atx_pll_implementation
            //------------------------------------------------------------------------------------
            //      ATXPLL для тактирования приемопередатчиков
            a10_sata_xcvr_atxpll_core
            the_a10_sata_xcvr_atxpll_core
            (
                .pll_cal_busy           (pll_cal_busy),             // o            pll_cal_busy.pll_cal_busy
                .pll_locked             (pll_locked),               // o              pll_locked.pll_locked
                .pll_powerdown          (pll_powerdown),            // i           pll_powerdown.pll_powerdown
                .pll_refclk0            (gxb_refclk),               // i             pll_refclk0.clk
                .tx_serial_clk          (tx_serial_clk)             // o           tx_serial_clk.clk
            ); // the_a10_sata_xcvr_atxpll_core
        end
        else if (PLLTYPE == "fPLL") begin: fpll_implementation
            //------------------------------------------------------------------------------------
            //      fPLL для тактирования приемопередатчиков
            a10_sata_xcvr_fpll_core
            the_a10_sata_xcvr_fpll_core
            (
                .pll_cal_busy           (pll_cal_busy),             // o            pll_cal_busy.pll_cal_busy
                .pll_locked             (pll_locked),               // o              pll_locked.pll_locked
                .pll_powerdown          (pll_powerdown),            // i           pll_powerdown.pll_powerdown
                .pll_refclk0            (gxb_refclk),               // i             pll_refclk0.clk
                .tx_serial_clk          (tx_serial_clk)             // o           tx_serial_clk.clk
            ); // the_a10_sata_xcvr_fpll_core
        end
        else begin: cmu_pll_implementation
            //------------------------------------------------------------------------------------
            //      CMUPLL для тактирования приемопередатчиков
            a10_sata_xcvr_cmupll_core
            the_a10_sata_xcvr_cmupll_core
            (
                .pll_cal_busy           (pll_cal_busy),             // o            pll_cal_busy.pll_cal_busy
                .pll_locked             (pll_locked),               // o              pll_locked.pll_locked
                .pll_powerdown          (pll_powerdown),            // i           pll_powerdown.pll_powerdown
                .pll_refclk0            (gxb_refclk),               // i             pll_refclk0.clk
                .tx_serial_clk          (tx_serial_clk)             // o           tx_serial_clk.clk
            ); // the_a10_sata_xcvr_cmupll_core
        end
    endgenerate

    //------------------------------------------------------------------------------------
    //      Модуль реконфигурации высокоскоростного приемопередатчика Arria 10 на
    //      режимы работы стандартов SATA1, SATA2, SATA3
    a10_sata_xcvr_reconf
    the_a10_sata_xcvr_reconf
    (
        // Сброс и тактирование
        .reset          (reconfig_reset),   // i
        .clk            (reconfig_clk),     // i

        // Интерфейс команд на ре-конфигурацию
        .cmd_reconfig   (recfg_request),    // i
        .cmd_sata_gen   (recfg_sata_gen),   // i  [1 : 0]
        .cmd_ready      (recfg_ready),      // o

        // Интерфейс доступа к адресному пространству
        // IP-ядра реконфигурации
        .recfg_addr     (recfg_addr),       // o  [9 : 0]
        .recfg_wreq     (recfg_wreq),       // o
        .recfg_wdat     (recfg_wdat),       // o  [31 : 0]
        .recfg_rreq     (recfg_rreq),       // o
        .recfg_rdat     (recfg_rdat),       // i  [31 : 0]
        .recfg_busy     (recfg_busy)        // i
    ); // the_a10_sata_xcvr_reconf

endmodule: a10_sata_xcvr