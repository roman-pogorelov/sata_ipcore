/*
    //------------------------------------------------------------------------------------
    //      Модуль высокоскоростного приемопередатчика ArriaV, настроенного для
    //      работы с интерфейсом SerialATA
    av_sata_xcvr
    the_av_sata_xcvr
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
    ); // the_av_sata_xcvr
*/

module av_sata_xcvr
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
    logic [139 : 0]         reconfig_to_xcvr;
    logic [91 : 0]          reconfig_from_xcvr;
    
    //------------------------------------------------------------------------------------
    //      Ядро высокоскоростного приемопередатчика Serial ATA
    av_sata_xcvr_core
    the_av_sata_xcvr_core
    (
        .phy_mgmt_clk                   (reconfig_clk),         // input  wire                        phy_mgmt_clk.clk
        .phy_mgmt_clk_reset             (reconfig_reset),       // input  wire                  phy_mgmt_clk_reset.reset
        .phy_mgmt_address               ({9{1'b0}}),            // input  wire [8:0]                      phy_mgmt.address
        .phy_mgmt_read                  (1'b0),                 // input  wire                                    .read
        .phy_mgmt_readdata              (  ),                   // output wire [31:0]                             .readdata
        .phy_mgmt_waitrequest           (  ),                   // output wire                                    .waitrequest
        .phy_mgmt_write                 (1'b0),                 // input  wire                                    .write
        .phy_mgmt_writedata             ({32{1'b0}}),           // input  wire [31:0]                             .writedata
        .tx_ready                       (  ),                   // output wire                            tx_ready.export
        .rx_ready                       (  ),                   // output wire                            rx_ready.export
        .pll_ref_clk                    (gxb_refclk),           // input  wire [0:0]                   pll_ref_clk.clk
        .tx_serial_data                 (gxb_tx),               // output wire [0:0]                tx_serial_data.export
        .tx_forceelecidle               (tx_elecidle),          // input  wire [0:0]              tx_forceelecidle.export
        .pll_locked                     (  ),                   // output wire [0:0]                    pll_locked.export
        .rx_serial_data                 (gxb_rx),               // input  wire [0:0]                rx_serial_data.export
        .rx_runningdisp                 (  ),                   // output wire [3:0]                rx_runningdisp.export
        .rx_is_lockedtoref              (rx_is_lockedtoref),    // output wire [0:0]             rx_is_lockedtoref.export
        .rx_is_lockedtodata             (rx_is_lockedtodata),   // output wire [0:0]            rx_is_lockedtodata.export
        .rx_signaldetect                (rx_signaldetect),      // output wire [0:0]               rx_signaldetect.export
        .rx_patterndetect               (rx_patterndetect),     // output wire [3:0]              rx_patterndetect.export
        .rx_syncstatus                  (rx_syncstatus),        // output wire [3:0]                 rx_syncstatus.export
        .rx_bitslipboundaryselectout    (  ),                   // output wire [4:0]   rx_bitslipboundaryselectout.export
        .tx_clkout                      (tx_clock),             // output wire [0:0]                     tx_clkout.export
        .rx_clkout                      (rx_clock),             // output wire [0:0]                     rx_clkout.export
        .tx_parallel_data               (tx_data),              // input  wire [31:0]             tx_parallel_data.export
        .tx_datak                       (tx_datak),             // input  wire [3:0]                      tx_datak.export
        .rx_parallel_data               (rx_data),              // output wire [31:0]             rx_parallel_data.export
        .rx_datak                       (rx_datak),             // output wire [3:0]                      rx_datak.export
        .reconfig_from_xcvr             (reconfig_from_xcvr),   // output wire [91:0]           reconfig_from_xcvr.reconfig_from_xcvr
        .reconfig_to_xcvr               (reconfig_to_xcvr)      // input  wire [139:0]            reconfig_to_xcvr.reconfig_to_xcvr
    ); // the_av_sata_xcvr_core
    
    //------------------------------------------------------------------------------------
    //      Ядро реконфигурации высокоскоростного приемопередатчика
    av_sata_reconf_core
    the_av_sata_reconf_core
    (
        .reconfig_busy                  (  ),                   // output wire              reconfig_busy.reconfig_busy
        .mgmt_clk_clk                   (reconfig_clk),         // input  wire               mgmt_clk_clk.clk
        .mgmt_rst_reset                 (reconfig_reset),       // input  wire             mgmt_rst_reset.reset
        .reconfig_mgmt_address          ({7{1'b0}}),            // input  wire [6:0]        reconfig_mgmt.address
        .reconfig_mgmt_read             (1'b0),                 // input  wire                           .read
        .reconfig_mgmt_readdata         (  ),                   // output wire [31:0]                    .readdata
        .reconfig_mgmt_waitrequest      (  ),                   // output wire                           .waitrequest
        .reconfig_mgmt_write            (1'b0),                 // input  wire                           .write
        .reconfig_mgmt_writedata        ({32{1'b0}}),           // input  wire [31:0]                    .writedata
        .reconfig_to_xcvr               (reconfig_to_xcvr),     // output wire [139:0]   reconfig_to_xcvr.reconfig_to_xcvr
        .reconfig_from_xcvr             (reconfig_from_xcvr)    // input  wire [91:0]  reconfig_from_xcvr.reconfig_from_xcvr
    ); // the_av_sata_reconf_core
    
endmodule: av_sata_xcvr