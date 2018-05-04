/*
    //------------------------------------------------------------------------------------
    //      Модуль высокоскоростного приемопередатчика ArriaV, настроенного для
    //      работы с интерфейсом SerialATA
    av_sata_xcvr
    #(
        .GENERATION         ()  // Поколение ("SATA1" | "SATA2" | "SATA3")
    )
    the_av_sata_xcvr
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
        
        // Высокоскоростные линии
        .gxb_rx             (), // i
        .gxb_tx             ()  // o
    ); // the_av_sata_xcvr
*/

module av_sata_xcvr
#(
    parameter               GENERATION  = "SATA1"       // Поколение ("SATA1" | "SATA2" | "SATA3")
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
    
    // Высокоскоростные линии
    input  logic            gxb_rx,
    output logic            gxb_tx
);
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic [139 : 0]         reconfig_to_xcvr;
    logic [91 : 0]          reconfig_from_xcvr;
    //
    logic                   pll_powerdown;
    logic                   pll_clkout;
    logic                   pll_locked;
    //
    logic                   tx_analogreset;
    logic                   tx_digitalreset;
    logic                   tx_cal_busy;
    logic                   rx_analogreset;
    logic                   rx_digitalreset;
    logic                   rx_cal_busy;
    //
    logic [6 : 0]           recfg_addr;
    logic                   recfg_wreq;
    logic [31 : 0]          recfg_wdat;
    logic                   recfg_rreq;
    logic [31 : 0]          recfg_rdat;
    logic                   recfg_busy;
    
    //------------------------------------------------------------------------------------
    //      Ядро высокоскоростного приемопередатчика Serial ATA
    av_sata_xcvr_core
    the_av_sata_xcvr_core
    (
        .pll_powerdown              (pll_powerdown),                // i  [0:0]            pll_powerdown.pll_powerdown
        .tx_analogreset             (tx_analogreset),               // i  [0:0]           tx_analogreset.tx_analogreset
        .tx_digitalreset            (tx_digitalreset),              // i  [0:0]          tx_digitalreset.tx_digitalreset
        .tx_serial_data             (gxb_tx),                       // o  [0:0]           tx_serial_data.tx_serial_data
        .ext_pll_clk                (pll_clkout),                   // i  [0:0]              ext_pll_clk.ext_pll_clk
        .rx_analogreset             (rx_analogreset),               // i  [0:0]           rx_analogreset.rx_analogreset
        .rx_digitalreset            (rx_digitalreset),              // i  [0:0]          rx_digitalreset.rx_digitalreset
        .rx_cdr_refclk              (gxb_refclk),                   // i  [0:0]            rx_cdr_refclk.rx_cdr_refclk
        .rx_serial_data             (gxb_rx),                       // i  [0:0]           rx_serial_data.rx_serial_data
        .rx_is_lockedtoref          (rx_is_lockedtoref),            // o  [0:0]        rx_is_lockedtoref.rx_is_lockedtoref
        .rx_is_lockedtodata         (rx_is_lockedtodata),           // o  [0:0]       rx_is_lockedtodata.rx_is_lockedtodata
        .tx_std_coreclkin           (tx_clock),                     // i  [0:0]         tx_std_coreclkin.tx_std_coreclkin
        .rx_std_coreclkin           (rx_clock),                     // i  [0:0]         rx_std_coreclkin.rx_std_coreclkin
        .tx_std_clkout              (tx_clock),                     // o  [0:0]            tx_std_clkout.tx_std_clkout
        .rx_std_clkout              (rx_clock),                     // o  [0:0]            rx_std_clkout.rx_std_clkout
        .tx_std_elecidle            (tx_elecidle),                  // i  [0:0]          tx_std_elecidle.tx_std_elecidle
        .rx_std_signaldetect        (rx_signaldetect),              // o  [0:0]      rx_std_signaldetect.rx_std_signaldetect
        .tx_cal_busy                (tx_cal_busy),                  // o  [0:0]              tx_cal_busy.tx_cal_busy
        .rx_cal_busy                (rx_cal_busy),                  // o  [0:0]              rx_cal_busy.rx_cal_busy
        .reconfig_to_xcvr           (reconfig_to_xcvr[69 : 0]),     // i  [69:0]        reconfig_to_xcvr.reconfig_to_xcvr
        .reconfig_from_xcvr         (reconfig_from_xcvr[45 : 0]),   // o  [45:0]      reconfig_from_xcvr.reconfig_from_xcvr
        .tx_parallel_data           (tx_data),                      // i  [31:0]        tx_parallel_data.tx_parallel_data
        .tx_datak                   (tx_datak),                     // i  [3:0]                 tx_datak.tx_datak
        .unused_tx_parallel_data    ({8{1'b0}}),                    // i  [7:0]  unused_tx_parallel_data.unused_tx_parallel_data
        .rx_parallel_data           (rx_data),                      // o  [31:0]        rx_parallel_data.rx_parallel_data
        .rx_datak                   (rx_datak),                     // o  [3:0]                 rx_datak.rx_datak
        .rx_errdetect               (  ),                           // o  [3:0]             rx_errdetect.rx_errdetect
        .rx_disperr                 (  ),                           // o  [3:0]               rx_disperr.rx_disperr
        .rx_runningdisp             (  ),                           // o  [3:0]           rx_runningdisp.rx_runningdisp
        .rx_patterndetect           (rx_patterndetect),             // o  [3:0]         rx_patterndetect.rx_patterndetect
        .rx_syncstatus              (rx_syncstatus),                // o  [3:0]            rx_syncstatus.rx_syncstatus
        .unused_rx_parallel_data    (  )                            // o  [7:0]  unused_rx_parallel_data.unused_rx_parallel_data
    ); // the_av_sata_xcvr_core
    
    //------------------------------------------------------------------------------------
    //      Ядро PLL, тактирования передающей части высокоскоростного приемопередатчика
    av_sata_cmupll_core
    the_av_sata_cmupll_core
    (
        .pll_powerdown              (pll_powerdown),                // i              pll_powerdown.pll_powerdown
        .pll_refclk                 (gxb_refclk),                   // i  [0:0]          pll_refclk.pll_refclk
        .pll_fbclk                  (1'b0),                         // i                  pll_fbclk.pll_fbclk
        .pll_clkout                 (pll_clkout),                   // o                 pll_clkout.pll_clkout
        .pll_locked                 (pll_locked),                   // o                 pll_locked.pll_locked
        .fboutclk                   (  ),                           // o  [0:0]            fboutclk.fboutclk
        .hclk                       (  ),                           // o  [0:0]                hclk.hclk
        .reconfig_to_xcvr           (reconfig_to_xcvr[139 : 70]),   // i  [69:0]   reconfig_to_xcvr.reconfig_to_xcvr
        .reconfig_from_xcvr         (reconfig_from_xcvr[91 : 46])   // o  [45:0] reconfig_from_xcvr.reconfig_from_xcvr
    ); // the_av_sata_cmupll_core
    
    //------------------------------------------------------------------------------------
    //      Ядро модуля сброса высокоскоростного приемопередатчика
    av_sata_xcvr_rst_core
    the_av_sata_xcvr_rst_core
    (
        .clock                      (gxb_refclk),                   // i                     clock.clk
        .reset                      (gxb_reset),                    // i                     reset.reset
        .pll_powerdown              (pll_powerdown),                // o  [0:0]      pll_powerdown.pll_powerdown
        .tx_analogreset             (tx_analogreset),               // o  [0:0]     tx_analogreset.tx_analogreset
        .tx_digitalreset            (tx_digitalreset),              // o  [0:0]    tx_digitalreset.tx_digitalreset
        .tx_ready                   (  ),                           // o  [0:0]           tx_ready.tx_ready
        .pll_locked                 (pll_locked),                   // i  [0:0]         pll_locked.pll_locked
        .pll_select                 (1'b0),                         // i  [0:0]         pll_select.pll_select
        .tx_cal_busy                (tx_cal_busy),                  // i  [0:0]        tx_cal_busy.tx_cal_busy
        .rx_analogreset             (rx_analogreset),               // o  [0:0]     rx_analogreset.rx_analogreset
        .rx_digitalreset            (rx_digitalreset),              // o  [0:0]    rx_digitalreset.rx_digitalreset
        .rx_ready                   (  ),                           // o  [0:0]           rx_ready.rx_ready
        .rx_is_lockedtodata         (rx_is_lockedtodata),           // i  [0:0] rx_is_lockedtodata.rx_is_lockedtodata
        .rx_cal_busy                (rx_cal_busy)                   // i  [0:0]        rx_cal_busy.rx_cal_busy
    ); // the_av_sata_xcvr_rst_core
    
    //------------------------------------------------------------------------------------
    //      Ядро реконфигурации высокоскоростного приемопередатчика
    av_sata_reconf_core
    the_av_sata_reconf_core
    (
        .reconfig_busy                  (  ),                   // output wire              reconfig_busy.reconfig_busy
        .mgmt_clk_clk                   (reconfig_clk),         // input  wire               mgmt_clk_clk.clk
        .mgmt_rst_reset                 (reconfig_reset),       // input  wire             mgmt_rst_reset.reset
        .reconfig_mgmt_address          (recfg_addr),           // input  wire [6:0]        reconfig_mgmt.address
        .reconfig_mgmt_read             (recfg_rreq),           // input  wire                           .read
        .reconfig_mgmt_readdata         (recfg_rdat),           // output wire [31:0]                    .readdata
        .reconfig_mgmt_waitrequest      (recfg_busy),           // output wire                           .waitrequest
        .reconfig_mgmt_write            (recfg_wreq),           // input  wire                           .write
        .reconfig_mgmt_writedata        (recfg_wdat),           // input  wire [31:0]                    .writedata
        .reconfig_mif_address           (  ),                   // output wire [31:0]        reconfig_mif.address
        .reconfig_mif_read              (  ),                   // output wire                           .read
        .reconfig_mif_readdata          ({16{1'b0}}),           // input  wire [15:0]                    .readdata
        .reconfig_mif_waitrequest       (1'b0),                 // input  wire                           .waitrequest
        .reconfig_to_xcvr               (reconfig_to_xcvr),     // output wire [139:0]   reconfig_to_xcvr.reconfig_to_xcvr
        .reconfig_from_xcvr             (reconfig_from_xcvr)    // input  wire [91:0]  reconfig_from_xcvr.reconfig_from_xcvr
    ); // the_av_sata_reconf_core
    
    //------------------------------------------------------------------------------------
    //      Модуль реконфигурации высокоскоростного приемопередатчика Arria V на
    //      режимы работы стандартов SATA1, SATA2, SATA3
    av_sata_xcvr_reconf
    the_av_sata_xcvr_reconf
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
        .recfg_addr     (recfg_addr),       // o  [6 : 0]
        .recfg_wreq     (recfg_wreq),       // o
        .recfg_wdat     (recfg_wdat),       // o  [31 : 0]
        .recfg_rreq     (recfg_rreq),       // o
        .recfg_rdat     (recfg_rdat),       // i  [31 : 0]
        .recfg_busy     (recfg_busy)        // i
    ); // the_av_sata_xcvr_reconf
    
endmodule: av_sata_xcvr