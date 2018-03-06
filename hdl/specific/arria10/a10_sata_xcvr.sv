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
    logic                   pll_recfg_write;
    logic                   pll_recfg_read;
    logic [9 : 0]           pll_recfg_address;
    logic [31 : 0]          pll_recfg_writedata;
    logic [31 : 0]          pll_recfg_readdata;
    logic                   pll_recfg_waitrequest;
    
    //------------------------------------------------------------------------------------
    //      Ядро высокоскоростного приемопередатчика Serial ATA
    a10_sata_xcvr_core
    sata_a10_sata_xcvr_core
    (
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
        .unused_tx_parallel_data    (  )                    // input  wire [91:0]  unused_tx_parallel_data.unused_tx_parallel_data
    ); // sata_a10_sata_xcvr_core
    
    //------------------------------------------------------------------------------------
    //      Контроллер сброса
    a10_sata_xcvr_rst_core
    the_a10_sata_xcvr_rst_core
    (
        .clock                  (reconfig_clk),                 // i                     clock.clk
        .pll_locked             (pll_locked),                   // i  [0:0]         pll_locked.pll_locked
        .pll_select             (1'b0),                         // i  [0:0]         pll_select.pll_select
        .reset                  (gxb_reset),                    // i                     reset.reset
        .rx_analogreset         (rx_analogreset),               // o  [0:0]     rx_analogreset.rx_analogreset
        .rx_cal_busy            (rx_cal_busy),                  // i  [0:0]        rx_cal_busy.rx_cal_busy
        .rx_digitalreset        (rx_digitalreset),              // o  [0:0]    rx_digitalreset.rx_digitalreset
        .rx_is_lockedtodata     (rx_is_lockedtodata),           // i  [0:0] rx_is_lockedtodata.rx_is_lockedtodata
        .rx_ready               (  ),                           // o  [0:0]           rx_ready.rx_ready
        .tx_analogreset         (tx_analogreset),               // o  [0:0]     tx_analogreset.tx_analogreset
        .tx_cal_busy            (tx_cal_busy | pll_cal_busy),   // i  [0:0]        tx_cal_busy.tx_cal_busy
        .tx_digitalreset        (tx_digitalreset),              // o  [0:0]    tx_digitalreset.tx_digitalreset
        .tx_ready               (  )                            // o  [0:0]           tx_ready.tx_ready
    ); // the_a10_sata_xcvr_rst_core
    
    //------------------------------------------------------------------------------------
    //      Модуль калибровки и сброса PLL тактирования высокоскоростных трансиверов
    a10_xcvr_pll_resetter
    #(
        .PLL_TYPE               ("fPLL"),                   // Тип PLL ("fPLL" | "CMUPLL" | "ATXPLL")
        .RST_DELAY              (200)                       // Длительность сброса PLL (в тактах clk)
    )
    the_a10_xcvr_pll_resetter
    (
        // Сброс и тактирование
        .reset                  (gxb_reset),                // i
        .clk                    (reconfig_clk),             // i
        
        // Интерфейс калибровки PLL
        .reconfig_address       (pll_recfg_address),        // o  [9 : 0]
        .reconfig_write         (pll_recfg_write),          // o
        .reconfig_writedata     (pll_recfg_writedata),      // o  [31 : 0]
        .reconfig_read          (pll_recfg_read),           // o
        .reconfig_readdata      (pll_recfg_readdata),       // i  [31 : 0]
        .reconfig_waitrequest   (pll_recfg_waitrequest),    // i
        
        // Интерфейс управления PLL
        .pll_powerdown          (pll_powerdown),            // o
        .pll_cal_busy           (pll_cal_busy)              // i
    ); // the_a10_xcvr_pll_resetter
    
    //------------------------------------------------------------------------------------
    //      Генерация необходимой PLL
    generate
        if (PLLTYPE == "ATXPLL") begin: atx_pll_implementation
            //------------------------------------------------------------------------------------
            //      ATXPLL для тактирования приемопередатчиков
            a10_sata_xcvr_atxpll_core
            the_a10_sata_xcvr_atxpll_core
            (
                .reconfig_write0        (pll_recfg_write),          // i          reconfig_avmm0.write
                .reconfig_read0         (pll_recfg_read),           // i                        .read
                .reconfig_address0      (pll_recfg_address),        // i  [9:0]                 .address
                .reconfig_writedata0    (pll_recfg_writedata),      // i  [31:0]                .writedata
                .reconfig_readdata0     (pll_recfg_readdata),       // o  [31:0]                .readdata
                .reconfig_waitrequest0  (pll_recfg_waitrequest),    // o                        .waitrequest
                .reconfig_clk0          (reconfig_clk),             // i           reconfig_clk0.clk
                .reconfig_reset0        (reconfig_reset),           // i         reconfig_reset0.reset
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
                .reconfig_write0        (pll_recfg_write),          // i          reconfig_avmm0.write
                .reconfig_read0         (pll_recfg_read),           // i                        .read
                .reconfig_address0      (pll_recfg_address),        // i  [9:0]                 .address
                .reconfig_writedata0    (pll_recfg_writedata),      // i  [31:0]                .writedata
                .reconfig_readdata0     (pll_recfg_readdata),       // o  [31:0]                .readdata
                .reconfig_waitrequest0  (pll_recfg_waitrequest),    // o                        .waitrequest
                .reconfig_clk0          (reconfig_clk),             // i           reconfig_clk0.clk
                .reconfig_reset0        (reconfig_reset),           // i         reconfig_reset0.reset
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
                .reconfig_write0        (pll_recfg_write),          // i          reconfig_avmm0.write
                .reconfig_read0         (pll_recfg_read),           // i                        .read
                .reconfig_address0      (pll_recfg_address),        // i  [9:0]                 .address
                .reconfig_writedata0    (pll_recfg_writedata),      // i  [31:0]                .writedata
                .reconfig_readdata0     (pll_recfg_readdata),       // o  [31:0]                .readdata
                .reconfig_waitrequest0  (pll_recfg_waitrequest),    // o                        .waitrequest
                .reconfig_clk0          (reconfig_clk),             // i           reconfig_clk0.clk
                .reconfig_reset0        (reconfig_reset),           // i         reconfig_reset0.reset
                .pll_cal_busy           (pll_cal_busy),             // o            pll_cal_busy.pll_cal_busy
                .pll_locked             (pll_locked),               // o              pll_locked.pll_locked
                .pll_powerdown          (pll_powerdown),            // i           pll_powerdown.pll_powerdown
                .pll_refclk0            (gxb_refclk),               // i             pll_refclk0.clk
                .tx_serial_clk          (tx_serial_clk)             // o           tx_serial_clk.clk
            ); // the_a10_sata_xcvr_cmupll_core
        end
    endgenerate
endmodule: a10_sata_xcvr