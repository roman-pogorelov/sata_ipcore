/*
    // SATA host stack implementing stream interface to a
    // SATA device by using DMA commands
    sata_dma_stack
    #(
        .FPGAFAMILY             ()  // FPGA family ("Arria V" | "Stratix V" | "Arria 10")
    )
    the_sata_dma_stack
    (
        // General reset (for all clock domains)
        .reset                  (), // i

        // XCVR reference clock (it has to be 150MHz)
        .gxb_refclk             (), // i

        // XCVR reconfiguration interface clock
        .reconfig_clk           (), // i

        // XCVR lane
        .gxb_rx                 (), // i
        .gxb_tx                 (), // o

        // Link layer output clock with frequency depends on actual
        // SATA generation (I - 37.5 MHz, II - 75.0 MHz, III - 150.0 MHz)
        .sata_clkout            (), // o

        // User clock (may be arbitrary)
        .usr_clk                (), // i

        // User command interface (usr_clk clock domain)
        .cmd_valid              (), // i            command strobe
        .cmd_type               (), // i            command type: 0 - RD, 1 - WR
        .cmd_address            (), // i  [47 : 0]  start address of operation
        .cmd_size               (), // i  [47 : 0]  size of operation
        .cmd_ready              (), // o            ready to accept a command
        .cmd_fault              (), // o            fault occurring status

        // Inbound stream to write (usr_clk clock domain)
        .wr_dat                 (), // i  [31 : 0]
        .wr_val                 (), // i
        .wr_rdy                 (), // o

        // Outbound stream to read (usr_clk clock domain)
        .rd_dat                 (), // o  [31 : 0]
        .rd_val                 (), // o
        .rd_rdy                 (), // i

        // Link status (usr_clk clock domain)
        .stat_linkup            (), // o
        .stat_generation        (), // o  [1 : 0]

        // Device information (usr_clk clock domain)
        .info_valid             (), // o
        .info_max_lba_address   (), // o  [47 : 0]
        .info_sata_supported    ()  // o  [2 : 0]
    ); // the_sata_dma_stack
*/

module sata_dma_stack
#(
    parameter               FPGAFAMILY  = "Arria V"     // FPGA family ("Arria V" | "Stratix V" | "Arria 10")
)
(
    // General reset (for all clock domains)
    input  logic            reset,

    // XCVR reference clock (it has to be 150MHz)
    input  logic            gxb_refclk,

    // XCVR reconfiguration interface clock
    input  logic            reconfig_clk,

    // XCVR lane
    input  logic            gxb_rx,
    output logic            gxb_tx,

    // Link layer output clock with frequency depends on actual
    // SATA generation (I - 37.5 MHz, II - 75.0 MHz, III - 150.0 MHz)
    output logic            sata_clkout,

    // User clock (may be arbitrary)
    input  logic            usr_clk,

    // User command interface (usr_clk clock domain)
    input  logic            cmd_valid,      // command strobe
    input  logic            cmd_type,       // command type: 0 - RD, 1 - WR
    input  logic [47 : 0]   cmd_address,    // start address of operation
    input  logic [47 : 0]   cmd_size,       // size of operation
    output logic            cmd_ready,      // ready to accept a command
    output logic            cmd_fault,      // fault occurring status

    // Inbound stream to write (usr_clk clock domain)
    input  logic [31 : 0]   wr_dat,
    input  logic            wr_val,
    output logic            wr_rdy,

    // Outbound stream to read (usr_clk clock domain)
    output logic [31 : 0]   rd_dat,
    output logic            rd_val,
    input  logic            rd_rdy,

    // Link status (usr_clk clock domain)
    output logic            stat_linkup,
    output logic [1 : 0]    stat_generation,

    // Device information (usr_clk clock domain)
    output logic            info_valid,
    output logic [47 : 0]   info_max_lba_address,
    output logic [2 : 0]    info_sata_supported
);
    // Signals declaration
    logic                   sata_reset;
    logic                   usr_reset;
    //
    logic                   sata_linkup;
    logic [1 : 0]           sata_generation;
    //
    logic [31 : 0]          phy_tx_data;
    logic                   phy_tx_datak;
    logic                   phy_tx_ready;
    //
    logic [31 : 0]          phy_rx_data;
    logic                   phy_rx_datak;
    //
    logic                   link_layer_busy;
    logic [2 : 0]           link_layer_result;
    //
    logic [31 : 0]          tx_fis_dat;
    logic                   tx_fis_val;
    logic                   tx_fis_eop;
    logic                   tx_fis_rdy;
    //
    logic [31 : 0]          rx_fis_dat;
    logic                   rx_fis_val;
    logic                   rx_fis_eop;
    logic                   rx_fis_err;
    logic                   rx_fis_rdy;


    // Asynchronous reset/preset synchronizer
    areset_synchronizer
    #(
        .EXTRA_STAGES   (1),            // The number of extra sync stages
        .ACTIVE_LEVEL   (1'b1)          // Active level of a reset/preset signal
    )
    sata_reset_synchronizer
    (
        // Clock
        .clk            (sata_clkout),  // i

        // Asynchronous reset/preset signal
        .areset         (
                            reset |
                            ~sata_linkup
                        ), // i

        // Synchronous reset/preset signal
        .sreset         (sata_reset)    // o
    ); // sata_reset_synchronizer


    // Asynchronous reset/preset synchronizer
    areset_synchronizer
    #(
        .EXTRA_STAGES   (1),            // The number of extra sync stages
        .ACTIVE_LEVEL   (1'b1)          // Active level of a reset/preset signal
    )
    usr_reset_synchronizer
    (
        // Clock
        .clk            (usr_clk),      // i

        // Asynchronous reset/preset signal
        .areset         (
                            reset |
                            ~sata_linkup
                        ), // i

        // Synchronous reset/preset signal
        .sreset         (usr_reset)     // o
    ); // usr_reset_synchronizer


    // FlipFlop synchronizer
    ff_synchronizer
    #(
        .WIDTH          (3),            // Synchronized bus width
        .EXTRA_STAGES   (1),            // The number of extra stages
        .RESET_VALUE    ({3{1'b0}})     // The sync stages default value
    )
    sata2usr_synchronizer
    (
        // Reset and clock
        .reset          (usr_reset),    // i
        .clk            (usr_clk),      // i

        // Asynchronous input
        .async_data     ({
                            sata_generation,
                            sata_linkup
                        }), // i  [WIDTH - 1 : 0]

        // Synchronous output
        .sync_data      ({
                            stat_generation,
                            stat_linkup
                        })  // o  [WIDTH - 1 : 0]
    ); // sata2usr_synchronizer


    // DMA implementation of the SATA transport layer
    sata_dma_engine
    the_sata_dma_engine
    (
        // General reset
        .reset                      (usr_reset),            // i

        // User clock
        .usr_clk                    (usr_clk),              // i

        // SATA link layer clock
        .sata_clk                   (sata_clkout),          // i

        // User command interface (usr_clk clock domain)
        .usr_cmd_valid              (cmd_valid),            // i
        .usr_cmd_type               (cmd_type),             // i
        .usr_cmd_address            (cmd_address),          // i  [47 : 0]
        .usr_cmd_size               (cmd_size),             // i  [47 : 0]
        .usr_cmd_ready              (cmd_ready),            // o
        .usr_cmd_fault              (cmd_fault),            // o

        // Device information (usr_clk clock domain)
        .usr_info_valid             (info_valid),           // o
        .usr_info_max_lba_address   (info_max_lba_address), // o  [47 : 0]
        .usr_info_sata_supported    (info_sata_supported),  // o  [2 : 0]

        // Inbound stream to write (usr_clk clock domain)
        .usr_wr_dat                 (wr_dat),               // i  [31 : 0]
        .usr_wr_val                 (wr_val),               // i
        .usr_wr_rdy                 (wr_rdy),               // o

        // Outbound stream to read (usr_clk clock domain)
        .usr_rd_dat                 (rd_dat),               // o  [31 : 0]
        .usr_rd_val                 (rd_val),               // o
        .usr_rd_eop                 (  ),                   // o
        .usr_rd_err                 (  ),                   // o
        .usr_rd_rdy                 (rd_rdy),               // i

        // Outbound stream of SATA FIS (sata_clk clock domain)
        .sata_tx_dat                (tx_fis_dat),           // o  [31 : 0]
        .sata_tx_val                (tx_fis_val),           // o
        .sata_tx_eop                (tx_fis_eop),           // o
        .sata_tx_rdy                (tx_fis_rdy),           // i

        // Inbound stream of SATA FIS (sata_clk clock domain)
        .sata_rx_dat                (rx_fis_dat),           // i  [31 : 0]
        .sata_rx_val                (rx_fis_val),           // i
        .sata_rx_eop                (rx_fis_eop),           // i
        .sata_rx_err                (rx_fis_err),           // i
        .sata_rx_rdy                (rx_fis_rdy),           // o

        // SATA link status  (sata_clk clock domain)
        .sata_link_busy             (link_layer_busy),      // i
        .sata_link_result           (link_layer_result)     // i  [2 : 0]
    ); // the_sata_dma_engine


    // SATA link layer block
    sata_link_layer
    #(
        .FPGAFAMILY         (FPGAFAMILY)            // FPGA family ("Arria V" | "Arria 10")
    )
    the_sata_link_layer
    (
        // Reset and clock
        .reset              (sata_reset),           // i
        .clk                (sata_clkout),          // i

        // Inbound stream from transport layer
        .tx_fis_dat         (tx_fis_dat),           // i  [31 : 0]
        .tx_fis_val         (tx_fis_val),           // i
        .tx_fis_eop         (tx_fis_eop),           // i
        .tx_fis_rdy         (tx_fis_rdy),           // o

        // Outbound stream to transport layer
        .rx_fis_dat         (rx_fis_dat),           // o  [31 : 0]
        .rx_fis_val         (rx_fis_val),           // o
        .rx_fis_eop         (rx_fis_eop),           // o
        .rx_fis_err         (rx_fis_err),           // o
        .rx_fis_rdy         (rx_fis_rdy),           // i

        // Interface to ask the transport layer for
        // the status of a received frame
        .trans_req          (  ),                   // o
        .trans_ack          (1'b1),                 // i
        .trans_err          (1'b0),                 // i

        // Outbound stream to PHY layer
        .phy_tx_data        (phy_tx_data),          // o  [31 : 0]
        .phy_tx_datak       (phy_tx_datak),         // o
        .phy_tx_ready       (phy_tx_ready),         // i

        // Inbound stream from PHY layer
        .phy_rx_data        (phy_rx_data),          // i  [31 : 0]
        .phy_rx_datak       (phy_rx_datak),         // i

        // Status signals
        .stat_fsm_code      (  ),                   // o  [4 : 0]
        .stat_link_busy     (link_layer_busy),      // o
        .stat_link_result   (link_layer_result),    // o  [2 : 0]
        .stat_rx_fifo_ovfl  (  )                    // o
    ); // the_sata_link_layer


    // SATA PHY layer block
    sata_phy_layer
    #(
        .FPGAFAMILY         (FPGAFAMILY)        // FPGA generation ("Arria V" | "Stratix V" | "Arria 10")
    )
    the_sata_phy_layer
    (
        // General reset
        .reset              (reset),            // i

        // Reconfiguration interface clock
        .reconfig_clk       (reconfig_clk),     // i

        // XCVR reference clock
        .gxb_refclk         (gxb_refclk),       // i

        // Output clock of link layer
        .link_clk           (sata_clkout),      // o

        // Linkup status (link_clk clock domain)
        .linkup             (sata_linkup),      // o

        // SATA generation status (link_clk clock domain)
        .sata_gen           (sata_generation),  // o  [1 : 0]

        // Receiver stream (link_clk clock domain)
        .rx_data            (phy_rx_data),      // o  [31 : 0]
        .rx_datak           (phy_rx_datak),     // o

        // Transmitter stream (link_clk clock domain)
        .tx_data            (phy_tx_data),      // i  [31 : 0]
        .tx_datak           (phy_tx_datak),     // i
        .tx_ready           (phy_tx_ready),     // o

        // XCVR lane
        .gxb_rx             (gxb_rx),           // i
        .gxb_tx             (gxb_tx)            // o
    ); // the_sata_phy_layer


endmodule: sata_dma_stack