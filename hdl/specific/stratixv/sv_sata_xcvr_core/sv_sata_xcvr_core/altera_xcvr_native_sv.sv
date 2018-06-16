// (C) 2001-2017 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


`timescale 1 ps/1 ps

import altera_xcvr_functions::*;
import altera_xcvr_native_sv_functions_h::*;

module altera_xcvr_native_sv 
  #(
    //---------------------
    // Common parameters
    //---------------------
    parameter tx_enable = 1,                        // 0,1
    parameter rx_enable = 1,                        // 0,1  
    parameter enable_std = 0,                       // legal values 0, 1
    parameter enable_teng = 0,                      // legal values 0,1
    parameter data_path_select = "pma_direct",      // legal values "8G" "10G" "pma_direct"
    parameter channels = 1,                         // legal values 1+
    parameter bonded_mode = "xN",                   // (xN, fb_compensation, non_bonded)

    // TX PMA
    parameter data_rate       = "10000 Mbps",       // user entered data rate always in mbps
    parameter pma_width       = 80,                 // (8,10,16,20,32,40,64,80) PMA serialization/deserialization factor
    parameter tx_pma_clk_div  = 1,                  // (1,2,4,8) CGB clock divider value
    parameter tx_pma_txdetectrx_ctrl = 0,           // (0,1) 0=Enable tx_txdetectrx from PCS, 1=Enable tx_txdetectrx from PLD (used for QPI)
    
    // PLL specific parameters
    parameter pll_reconfig_enable = 0,              // (0,1) 0-Disable TX PLL reconfig, 1-Enable TX PLL reconfig
    parameter pll_external_enable = 0,              // (0,1) 0-Disable external TX PLL, 1-Enable external TX PLL
    parameter pll_data_rate = "0 Mbps",             // (PLL Rate) - must be (data_rate * 1,2,4,or8) in mbps    
    parameter pll_type = "AUTO",                    // PLL type for each PLL    
    parameter pll_network_select = "x1",            // selected PLL clock network ("x1","xN"). (List i.e. "x1,xN,x1,...") One per PLL. Required only for "xN" non-bonded
    parameter plls = 1,                             // no of plls, 1+   
    parameter pll_select = 0,                       // Selects the initial PLL
    parameter pll_refclk_cnt = 1,                   // Number of TX PLL reference clocks (per PLL)
    parameter pll_refclk_select = "0",              // Selects the initial reference clock for each TX PLL
    parameter pll_refclk_freq = "125 MHz",          // TX PLL reference clock frequency, this will go to TX PLL
    parameter pll_feedback_path = "internal"       ,// internal, external
    // CDR specific parameters
    parameter cdr_reconfig_enable = 0,              // (0,1) 0-Disable CDR reconfig, 1-Enable CDR reconfig
    parameter cdr_refclk_cnt = 1,                   // Number of RX CDR reference clocks
    parameter cdr_refclk_select = 0,                // Selects the initial reference clock for all RX CDR PLLs
    parameter cdr_refclk_freq = "125 MHz",          // RX CDR reference clock frequency, this will go to TX PLL and CDR PLL
    parameter rx_ppm_detect_threshold   = "1000",   //62,100,125,200,250,300,500,1000
    
    //-------------------------------
    // PMA Direct specific parameters
    //-------------------------------
    parameter rx_clkslip_enable         = 0,        // enables clkslip feature of the deserailizer
//  parameter rx_signaldetect_threshold = 16,       //(0,1,2...16) Signal Detect Threshold. 0->DATA_PULSE_4, 1->DATA_PULSE_6,....,16->FORCE_SD_ON    
 
    //-----------------------------
    // Standard (8G) PCS parameters
    //-----------------------------
    parameter std_protocol_hint                 = "basic",  // basic|cpri|gige|srio_2p1
    parameter std_pcs_pma_width                 = 10,       // 8G - 8|10|16|20
//  parameter std_pld_pcs_width                 = 10,       // 8G - 8|10|16|20|32|40
    // Low latency bypass
    parameter std_low_latency_bypass_enable     = 0,

    // Phase Compensation FIFO
    parameter std_tx_pcfifo_mode                = "low_latency",   //low_latency|register_fifo|normal_latency
    parameter std_rx_pcfifo_mode                = "low_latency",   //low_latency|register_fifo|normal_latency

    // Byte Ordering
    parameter std_rx_byte_order_enable          = 0,        // 0|1
    parameter std_rx_byte_order_mode            = "manual", // auto|manual
    parameter std_rx_byte_order_width           = 0,        // 8|9|10
    parameter std_rx_byte_order_symbol_count    = 1,        // 1|2
    parameter std_rx_byte_order_pattern         = "0",      // Byte order search pattern (hex string)
    parameter std_rx_byte_order_pad             = "0",      // Byte order pad pattern (hex string)

    // Byte serializer
    parameter std_tx_byte_ser_enable            = 0,
    parameter std_rx_byte_deser_enable          = 0,

    //8B/10B
    parameter std_tx_8b10b_enable               = 0,        // 0,1 
    parameter std_tx_8b10b_disp_ctrl_enable     = 0,        // 0,1
    parameter std_rx_8b10b_enable               = 0,        // 0,1

    //Rate match FIFO
    parameter std_rx_rmfifo_enable              = 0,
    parameter std_rx_rmfifo_pattern_p            = "000000000000000000000", 
    parameter std_rx_rmfifo_pattern_n            = "000000000000000000000",

    //Word aligner / Bit slip / Run Length
    parameter std_tx_bitslip_enable             = 0,              // 0,1
    parameter std_rx_word_aligner_mode          = "bit_slip",     //bit_slip|sync_sm|auto_align_pld_ctrl(manual)|deterministic_latency  
    parameter std_rx_word_aligner_pattern_len   = 7,              //7,8,10,16,20,32,40
    parameter std_rx_word_aligner_pattern       = "0000000000",
    parameter std_rx_word_aligner_rknumber      = 3,              //0-256
    parameter std_rx_word_aligner_renumber      = 3,              //0-256
    parameter std_rx_word_aligner_rgnumber      = 3,              //0-256
//  parameter std_rx_run_length_en              = 0,              // 0,1
    parameter std_rx_run_length_val             = 0,

    // Bit reversal/Polarity inversion
    parameter std_tx_bitrev_enable              = 0,
    parameter std_rx_bitrev_enable              = 0,
    parameter std_tx_byterev_enable             = 0,
    parameter std_rx_byterev_enable             = 0,
    parameter std_tx_polinv_enable              = 0,
    parameter std_rx_polinv_enable              = 0,
      
    // Test/Debug - PRBS
//  parameter std_tx_prbs_gen = "dis_prbs",  // dis_prbs|prbs_7_sw|prbs_7_dw|prbs_8|prbs_10|prbs_23_sw|prbs_23_dw|prbs_15|prbs_31|prbs_hf_sw|prbs_hf_dw|prbs_lf_sw|prbs_lf_dw|prbs_mf_sw|prbs_mf_dw
//  parameter std_rx_prbs_ver = "dis_prbs",  // dis_prbs|prbs_7_sw|prbs_7_dw|prbs_8|prbs_10|prbs_23_sw|prbs_23_dw|prbs_15|prbs_31|prbs_hf_sw|prbs_hf_dw|prbs_lf_sw|prbs_lf_dw|prbs_mf_sw|prbs_mf_dw
//  parameter std_rx_prbs_ver_clr_flag_enable = 0
    

    //----------------------
    // 10G PCS parameters
    //----------------------
    parameter teng_protocol_hint                = "basic",  // basic|interlaken|sfis|teng_baser|teng_sdi|teng_1588
    parameter teng_pcs_pma_width                = 40,       // 10G - 32|40|64
    parameter teng_pld_pcs_width                = 40,       // 10G - 10G-32|40|50|64|66|67
    // Tx FIFO
    parameter teng_txfifo_mode                  = "phase_comp", // phase_comp|register|clk_comp|generic|interlaken
    parameter teng_txfifo_full                  = 31,       // FIFO full threshold 0-31d (b)
    parameter teng_txfifo_empty                 = 0,        // FIFO empty threshold 00000-11111 (b)
    parameter teng_txfifo_pfull                 = 23,       // FIFO partially full threshold 00000-11111 (b)
    parameter teng_txfifo_pempty                = 7,        // FIFO partially empty threshold 00000-11111 (b)
 
    // Rx FIFO
    parameter teng_rxfifo_mode                  = "phase_comp", // phase_comp|register|clk_comp|generic|interlaken
    parameter teng_rxfifo_full                  = 31,       // FIFO full threshold 00000-11111 (b)
    parameter teng_rxfifo_empty                 = 0,        // FIFO empty threshold 00000-11111 (b)
    parameter teng_rxfifo_pfull                 = 23,       // FIFO partially full threshold 00000-11111 (b)
    parameter teng_rxfifo_pempty                = 7,        // FIFO partially empty threshold 00000-11111 (b)
    parameter teng_rxfifo_align_del             = 0,        // RX FIFO align enable flag, default value align_del_dis
    parameter teng_rxfifo_control_del           = 0,        // RX FIFO control_del, default to control_del_none


    // Frame Gen/Sync
    parameter teng_tx_frmgen_enable             = 0,            // 0,1
    parameter teng_tx_frmgen_user_length        = 2048,         // 0..8192
    parameter teng_tx_frmgen_burst_enable       = 0, // frmgen_burst_en|frmgen_burst_dis
    parameter teng_rx_frmsync_enable            = 0,            // 0,1a
    parameter teng_rx_frmsync_user_length       = 2048,         // 0..8192
    parameter teng_frmgensync_diag_word         = "6400000000000000", // 0000000000000000 - ffffffffffffffff (h) 
    parameter teng_frmgensync_scrm_word         = "2800000000000000", // 0000000000000000 - ffffffffffffffff (h)
    parameter teng_frmgensync_skip_word         = "1e1e1e1e1e1e1e1e", // 0000000000000000 - ffffffffffffffff (h)
    parameter teng_frmgensync_sync_word         = "78f678f678f678f6", // 0000000000000000 - ffffffffffffffff (h)
    //Sync header error
    parameter teng_tx_sh_err                    = 0,           //0, 1 // in 10GABSER this is sync header error insertion for 64b/66B encoder and for Interlaken this is sync header error insertion in frame generator
    
//  parameter teng_tx_frmgen_pipeln_enable      = 0, // frmgen_pipeln_dis|frmgen_pipeln_en
//  parameter teng_tx_frmgen_pyld_ins_enable    = 0, // frmgen_pyld_ins_dis|frmgen_pyld_ins_en
//  parameter teng_tx_frmgen_wordslip_enable    = 0, // frmgen_wordslip_dis|frmgen_wordslip_en, Engg mode feature so not enabled

//  parameter teng_tx_full_flag_type            = "full_rd_side", // full_rd_side|full_wr_side

    // CRC32 Gen/Chk
    parameter teng_tx_crcgen_enable             = 0,            // 0,1
    parameter teng_rx_crcchk_enable             = 0,            // 0,1

    // 64B/66B
    parameter teng_tx_64b66b_enable             = 0,            // 0,1
    parameter teng_rx_64b66b_enable             = 0,            // 0,1

    
    // Scambler
    parameter teng_tx_scram_enable              = 0,            // 0,1        
//  parameter teng_scram_seed_mode              = "min",               //min,max,user
    parameter teng_tx_scram_user_seed           = "000000000000000",  //hex
    parameter teng_rx_descram_enable            = 0,            // 0,1

    // Disparity Gen/Chk
    parameter teng_tx_dispgen_enable            = 0,            // 0,1
    parameter teng_rx_dispchk_enable            = 0,            // 0,1
    
    // Block Sync
    parameter teng_rx_blksync_enable            = 0,            // 0,1
//  parameter teng_rx_blksync_wait_user_cnt     = 7,            // 0-7
//  parameter teng_rx_blksync_wait_type         = "cnt"       // bitslip_match|bitslip_cnt

    // Gearbox
    //handle sync header through RBCs       
//  parameter teng_tx_synchdr_location          = "msb",        //msb|lsb
//  parameter teng_rx_synchdr_location          = "msb",        //msb|lsb
    // Polarity Inversion/Bit reversal
    //handle 10G Ctrl and data bit reversal through RBCs           
//  parameter teng_tx_ctrl_bitrev_enable        = 0,            // 0,1
//  parameter teng_tx_data_bitrev_enable        = 0,            // 0,1    
//  parameter teng_rx_ctrl_bitrev_enable        = 0,
//  parameter teng_rx_data_bitrev_enable        = 0,    
    parameter teng_tx_polinv_enable             = 0,
    parameter teng_tx_bitslip_enable            = 0,            // 0,1
    parameter teng_rx_polinv_enable             = 0,
    parameter teng_rx_bitslip_enable            = 0             // 0,1

    // BER
//  handle hiber enable through RBCs           
//    parameter teng_rx_hiber_enable              = 0            // 0,1

    // PRBS/Test for this needs in test mode
//    parameter teng_tx_test_mode                 = "test_off",   //test_off|pseudo_random|sq_wave|prbs_31|prbs_23|prbs_9|prbs_7
//    parameter teng_rx_test_mode                 = "test_off"   //test_off|pseudo_random|sq_wave|prbs_31|prbs_23|prbs_9|prbs_7

    ) ( 
    //------------------------
    // Common Ports
    //------------------------
    // Resets
    input   wire [channels-1:0]       tx_analogreset,   // TX PMA reset
    input   wire [((bonded_mode == "xN") ? 1 : channels)*plls-1:0] pll_powerdown, // TX PLL reset
    input   wire [channels-1:0]       tx_digitalreset,  // TX PCS reset
    input   wire [channels-1:0]       rx_analogreset,   // RX PMA reset
    input   wire [channels-1:0]       rx_digitalreset,  // RX PCS reset

    // Reconfig interface ports
    input   wire [get_native_reconfig_to_width  ("Stratix V",rx_enable,tx_enable,channels,((pll_external_enable == 1)? 0 : plls),"",bonded_mode)-1:0] reconfig_to_xcvr,
    output  wire [get_native_reconfig_from_width("Stratix V",rx_enable,tx_enable,channels,((pll_external_enable == 1)? 0 : plls),"",bonded_mode)-1:0] reconfig_from_xcvr, 
  
    output  wire [channels-1:0]       tx_cal_busy,      // TX calibration in progress
    output  wire [channels-1:0]       rx_cal_busy,      // RX calibration in progress
    
    //clk signals
    input   wire [pll_refclk_cnt-1:0] tx_pll_refclk,    // TX PLL reference clocks
    input   wire [cdr_refclk_cnt-1:0] rx_cdr_refclk,    // RX PLL reference clocks
    input   wire [(plls*channels)-1:0] ext_pll_clk,      // clkout from external PLL

    // TX and RX serial ports
    output  wire [channels-1:0]       tx_serial_data,   // TX serial data output to HSSI pin
    input   wire [channels-1:0]       rx_serial_data,   // RX serial data input from HSSI pin

    // control ports
    input   wire [channels-1:0]       rx_seriallpbken,  // Enable TX-to-RX loopback
    input   wire [channels-1:0]       rx_set_locktodata,// Set CDR to manual lock to data mode
    input   wire [channels-1:0]       rx_set_locktoref, // Set CDR to manual lock to reference mode

    //status
    output  wire [((bonded_mode=="xN")?1:channels)*plls-1:0] pll_locked,  // TX PLL is locked to reference clock
    output  wire [channels-1:0]       rx_is_lockedtoref,  // CDR is in lock to reference mode
    output  wire [channels-1:0]       rx_is_lockedtodata, // CDR is in lock to data mode
    output  wire [channels-1:0]       rx_signaldetect,    // RX PMA signal detect

    // QPI specific ports
    input wire  [channels-1:0]        rx_pma_qpipulldn, 
    input wire  [channels-1:0]        tx_pma_qpipulldn, 
    input wire  [channels-1:0]        tx_pma_qpipullup, 
    input wire  [channels-1:0]        tx_pma_txdetectrx, 
    output wire [channels-1:0]        tx_pma_rxfound,

    //parallel data ports
    input   wire [channels*64-1:0]    tx_parallel_data, // PCS TX parallel data interface
    output  wire [channels*64-1:0]    rx_parallel_data, // PCS TX parallel data interface
  
    //---------------------
    // PMA specific ports
    //---------------------
    output  wire  [channels-1:0]      tx_pma_clkout,  // TX Parallel clock output from PMA
    output  wire  [channels-1:0]      rx_pma_clkout,  // RX Parallel clock output from PMA
    output  wire  [channels-1:0]      tx_pma_pclk,    // TX Parallel clock output from PMA via pclk
    output  wire  [channels-1:0]      rx_pma_pclk,    // RX Parallel clock output from PMA via pclk

    // PMA parallel data ports
    input   wire [channels*80-1:0]    tx_pma_parallel_data, // PMA Direct TX parallel data interface
    output  wire [channels*80-1:0]    rx_pma_parallel_data, // PMA Direct RX parallel data interface

    input   wire  [channels-1:0]      rx_clkslip,
    
    //PPM detector clocks
    output  wire  [channels-1:0]      rx_clklow,    // RX Low freq recovered clock, PPM detecror specific
    output  wire  [channels-1:0]      rx_fref,      // RX PFD reference clock, PPM detecror specific

    //-------------------------
    // Standard PCS ports
    //------------------------- 
    // clock ports
    input   wire  [channels-1:0]      tx_std_coreclkin,   // 10G PCS PLD Tx parallel clock input
    input   wire  [channels-1:0]      rx_std_coreclkin,   // 10G PCS PLD Tx parallel clock input
    output  wire  [channels-1:0]      tx_std_clkout,      // TX Parallel clock output
    output  wire  [channels-1:0]      rx_std_clkout,      // RX parallel clock output

    //electrical idle
    input   wire  [channels-1:0]      tx_std_elecidle,

    //Phase compensation FIFOs
    output  wire  [channels-1:0]      tx_std_pcfifo_full,  //Phase comp. FIFO full   
    output  wire  [channels-1:0]      tx_std_pcfifo_empty, //Phase comp. FIFO empty
    output  wire  [channels-1:0]      rx_std_pcfifo_full,  //Phase comp. FIFO full
    output  wire  [channels-1:0]      rx_std_pcfifo_empty, //Phase comp. FIFO empty

    // Byte Ordering
    input   wire  [channels-1:0]      rx_std_byteorder_ena,    
    output  wire  [channels-1:0]      rx_std_byteorder_flag,

    // Bit reversal
    input   wire  [channels-1:0]      rx_std_bitrev_ena,

    // Byte (de)serializer 
    input   wire  [channels-1:0]      rx_std_byterev_ena,

    // Polarity inversion
    input   wire  [channels-1:0]      tx_std_polinv,
    input   wire  [channels-1:0]      rx_std_polinv,

    // Bit slip
    input   wire  [channels*5-1:0]    tx_std_bitslipboundarysel,
    output  wire  [channels*5-1:0]    rx_std_bitslipboundarysel,
    input   wire  [channels-1:0]      rx_std_bitslip,

    //Word align/Deterministic SM
    input   wire  [channels-1:0]      rx_std_wa_patternalign,
    input   wire  [channels-1:0]      rx_std_wa_a1a2size,

    //Rate Match FIFO
    output  wire  [channels-1:0]      rx_std_rmfifo_full,  //Rate Match FIFO full
    output  wire  [channels-1:0]      rx_std_rmfifo_empty, //Rate Match FIFO empty

    // Run length detector
    output  wire  [channels-1:0]      rx_std_runlength_err,    

    // PRBS
//  input   wire  [channels-1:0]      rx_std_prbs_cid_en,

    //signal detect for PCIE from 8G PCS
    output  wire  [channels-1:0]      rx_std_signaldetect,    

    //PRBS Signals for the 8G PCS
    output  wire  [channels-1:0]      rx_std_prbs_err,
    output  wire  [channels-1:0]      rx_std_prbs_done,

    //-------------------------
    // 10G PCS ports
    //-------------------------
    //clock ports
    input   wire  [channels-1:0]      tx_10g_coreclkin,   // 10G PCS PLD Tx parallel clock input
    input   wire  [channels-1:0]      rx_10g_coreclkin,   // 10G PCS PLD Tx parallel clock input
    output  wire  [channels-1:0]      tx_10g_clkout,      // TX Parallel clock output
    output  wire  [channels-1:0]      rx_10g_clkout,      // RX parallel clock output
    output  wire  [channels-1:0]      rx_10g_clk33out,    // RX parallel /33 clock output

    // data path/control
    input   wire  [channels*9-1:0]    tx_10g_control,
    output  wire  [channels*10-1:0]   rx_10g_control,

    // TxFIFO/RxFIFO
    input   wire  [channels-1:0]      tx_10g_data_valid,
    input   wire  [channels*2-1:0]    tx_10g_frame_diag_status,
//  input   wire  [channels-1:0]      tx_10g_wordslip, // Engg mode feature so not enabled
    output  wire  [channels-1:0]      tx_10g_fifo_full,
    output  wire  [channels-1:0]      tx_10g_fifo_pfull,
    output  wire  [channels-1:0]      tx_10g_fifo_empty,
    output  wire  [channels-1:0]      tx_10g_fifo_pempty,
    output  wire  [channels-1:0]      tx_10g_fifo_del,
    output  wire  [channels-1:0]      tx_10g_fifo_insert,
   
    input   wire  [channels-1:0]      rx_10g_fifo_rd_en, 
    output  wire  [channels-1:0]      rx_10g_data_valid,
    output  wire  [channels-1:0]      rx_10g_fifo_full,
    output  wire  [channels-1:0]      rx_10g_fifo_pfull,
    output  wire  [channels-1:0]      rx_10g_fifo_empty,
    output  wire  [channels-1:0]      rx_10g_fifo_pempty,
    output  wire  [channels-1:0]      rx_10g_fifo_del,
    output  wire  [channels-1:0]      rx_10g_fifo_insert,
    output  wire  [channels-1:0]      rx_10g_fifo_align_val,
    input   wire [channels-1:0]       rx_10g_fifo_align_clr, // Active high. User Align clear signal for RX FIFO when it's used as a deskew FIFO in Interlaken mode. When it asserts, FIFO is reset and it looks for new alignment pattern. It's don't care for non-Interlaken mode
    input   wire  [channels-1:0]      rx_10g_fifo_align_en, // User Align Enable signal for RX FIFO, when it's used as a deskew FIFO in Interlaken mode. It determines whether current channel is enabled for alignment. It's don't care for non-Interlaken mode


    // Bit slip
    input   wire  [channels*7-1:0]    tx_10g_bitslip,
    input   wire  [channels-1:0]      rx_10g_bitslip,

    // Block sync
    output  wire  [channels-1:0]      rx_10g_blk_lock,
    output  wire  [channels-1:0]      rx_10g_blk_sh_err,

    // Scrambler/de-scrambler
    output wire   [channels-1:0]      rx_10g_descram_err,

    // Frame generator/sync
    output  wire  [channels-1:0]      tx_10g_frame,
    output  wire  [channels-1:0]      rx_10g_frame,
    output  wire  [channels-1:0]      rx_10g_frame_lock,
    output  wire  [channels-1:0]      rx_10g_frame_mfrm_err,
    output  wire  [channels-1:0]      rx_10g_frame_sync_err,
    output  wire  [channels-1:0]      rx_10g_frame_skip_ins,
    output  wire  [channels-1:0]      rx_10g_frame_pyld_ins,
    output  wire  [channels-1:0]      rx_10g_frame_skip_err,
    output  wire  [channels-1:0]      rx_10g_frame_diag_err,
    output  wire  [channels*2-1:0]    rx_10g_frame_diag_status,

    input   wire  [channels-1:0]      tx_10g_frame_burst_en,

    // CRC chk
    output  wire  [channels-1:0]      rx_10g_crc32_err,

    // Disparity chk
//    input   wire  [channels-1:0]      rx_10g_disp_clr,  // Enginnering mode feature only


    // BER
    output  wire  [channels-1:0]      rx_10g_highber,
    input   wire  [channels-1:0]      rx_10g_highber_clr_cnt,

   //64B/66B specific 10GBASER signal
    input   wire  [channels-1:0]      rx_10g_clr_errblk_count,

    // PRBS - Only available in test mode and when prot_mode = test_prbs so no need to expose
    //PRBS Signals for the 10G PCS
    output  wire  [channels-1:0]      rx_10g_prbs_err,
    output  wire  [channels-1:0]      rx_10g_prbs_done,
    input   wire  [channels-1:0]      rx_10g_prbs_err_clr


    );

   import altera_xcvr_functions::*;
   import altera_xcvr_native_sv_functions_h::*;


   // Define all local parameters for internal use
   
   // bonding size for bonded channel instantiations
   // bonded_group_size = channels when bonded_mode is enabled (XN or fb_compensation) and equal to 1 when non_bonded
    localparam bonded_group_size = (bonded_mode == "non_bonded") ? 1 : channels;
   
   // Reconfig parameters
    localparam w_bundle_to_xcvr               = W_S5_RECONFIG_BUNDLE_TO_XCVR;
    localparam w_bundle_from_xcvr             = W_S5_RECONFIG_BUNDLE_FROM_XCVR;
    localparam reconfig_interfaces            = altera_xcvr_native_sv_functions_h::get_native_reconfig_interfaces("Stratix V",rx_enable,tx_enable,channels,(pll_external_enable ? 0 : plls),"",bonded_mode);
  
    localparam LCL_ENABLE_PMADIRECT           = (data_path_select == "pma_direct") ? 1 : 0;
    localparam LCL_RX_ENABLE                  = rx_enable; //set_rx_enable(operation_mode);
    localparam LCL_TX_ENABLE                  = tx_enable; //set_tx_enable(operation_mode);
    localparam LCL_ENABLE_PMA_DIRECT_TX       = set_lcl_enable_2lvl(LCL_TX_ENABLE,LCL_ENABLE_PMADIRECT); 
    localparam LCL_ENABLE_PMA_DIRECT_RX       = set_lcl_enable_2lvl(LCL_RX_ENABLE,LCL_ENABLE_PMADIRECT);
    localparam LCL_ENABLE_10G_RX              = set_lcl_enable_2lvl(LCL_RX_ENABLE,enable_teng);
    localparam LCL_ENABLE_10G_TX              = set_lcl_enable_2lvl(LCL_TX_ENABLE,enable_teng);
    localparam LCL_ENABLE_8G_RX               = set_lcl_enable_2lvl(LCL_RX_ENABLE,enable_std);
    localparam LCL_ENABLE_8G_TX               = set_lcl_enable_2lvl(LCL_TX_ENABLE,enable_std);

    localparam LCL_DATA_RATE                  = data_rate;
    localparam LCL_PLL_DATA_RATE              = pll_data_rate;      

   // Default base data rate to data rate if not specified
    localparam [MAX_STRS*MAX_CHARS*8-1:0] LCL_BASE_DATA_RATE_STR = (get_value_at_index(0,LCL_PLL_DATA_RATE) == "0 Mbps") ? LCL_DATA_RATE : LCL_PLL_DATA_RATE;   
   // local parameter for pma_bonding_type 
    localparam LCL_PMA_BONDING_TYPE                   = (bonded_mode == "fb_compensation")? "fb_compensation" : "default" ;
    localparam LCL_PLD_DATA_MAX_WIDTH                 = (LCL_ENABLE_PMADIRECT) ? 80 : 64;


    localparam LCL_PLD_PCS_IF_TESTBUS_SEL             = set_lcl_pld_pcs_if_testbus_sel(data_path_select);
   

    localparam LCL_PMA_PROT_MODE                      = set_pma_prot_mode(data_path_select,std_protocol_hint,teng_protocol_hint,std_rx_word_aligner_mode);
    localparam LCL_PMA_MODE                           = set_pma_mode(pma_width); 

    //-----------------------------
    // PMA direct paramaters
    //-----------------------------
    localparam LCL_COM_PCS_PMA_IF_PPMSEL              = set_ppm_thresh(rx_ppm_detect_threshold);
    localparam LCL_RX_PCS_PMA_IF_CLKSLIP_SEL          = set_pma_clkslip(std_protocol_hint);
    localparam LCL_DESER_ENABLE_BIT_SLIP              = set_lcl_true_false(rx_clkslip_enable);
    localparam LCL_SD_ON                              = 16;

    //-----------------------------
    // Standard PCS parameter mapping
    //-----------------------------
    //protocol mode, data width, PCS bypass 
    localparam LCL_PCS8G_TX_PROT_MODE                 = set_std_prot_mode(std_protocol_hint);
    localparam LCL_PCS8G_RX_PROT_MODE                 = set_std_prot_mode(std_protocol_hint);
    localparam LCL_PCS8G_TX_PMA_DW                    = set_std_pcs_pma_dw(std_pcs_pma_width);
    localparam LCL_PCS8G_RX_PMA_DW                    = set_std_pcs_pma_dw(std_pcs_pma_width);
    localparam LCL_PCS8G_TX_PCS_BYPASS                = set_lcl_enable_cond(std_low_latency_bypass_enable,"en_pcs_bypass","dis_pcs_bypass");
    localparam LCL_PCS8G_RX_PCS_BYPASS                = set_lcl_enable_cond(std_low_latency_bypass_enable,"en_pcs_bypass","dis_pcs_bypass");
    //8B10B 
    localparam LCL_PCS8G_TX_EIGHTB_TENB_ENCODER       = set_lcl_enable_cond(std_tx_8b10b_enable,"en_8b10b_ibm","dis_8b10b");
    localparam LCL_PCS8G_RX_EIGHTB_TENB_DECODER       = set_lcl_enable_cond(std_rx_8b10b_enable,"en_8b10b_ibm","dis_8b10b");
    localparam LCL_PCS8G_TX_EIGHTB_TENB_DISP_CTRL     = set_lcl_enable_cond(std_tx_8b10b_disp_ctrl_enable,"en_disp_ctrl","dis_disp_ctrl");
    //Phase Comp FIFO
    localparam LCL_PCS8G_RX_PHASE_COMPENSATION_FIFO   = std_rx_pcfifo_mode;
    localparam LCL_PCS8G_TX_PHASE_COMPENSATION_FIFO   = std_tx_pcfifo_mode;
    //Bit reversal & Polarity inversion
    localparam LCL_PCS8G_TX_BIT_REVERSAL              = set_lcl_enable_cond(std_tx_bitrev_enable,"en_bit_reversal","dis_bit_reversal");
    localparam LCL_PCS8G_RX_BIT_REVERSAL              = set_lcl_enable_cond(std_rx_bitrev_enable,"en_bit_reversal","dis_bit_reversal");
    localparam LCL_PCS8G_RX_SYMBOL_SWAP               = set_lcl_enable_cond(std_rx_byterev_enable,"en_symbol_swap","dis_symbol_swap");
    localparam LCL_PCS8G_TX_POLARITY_INVERSION        = set_lcl_enable_cond(std_tx_polinv_enable,"enable_polinv","dis_polinv");
    localparam LCL_PCS8G_RX_POLARITY_INVERSION        = set_lcl_enable_cond(std_rx_polinv_enable,"en_pol_inv","dis_pol_inv");
    localparam LCL_PCS8G_TX_SYMBOL_SWAP               = set_lcl_enable_cond(std_tx_byterev_enable,"en_symbol_swap","dis_symbol_swap");
    //Word aligner and bitslip
    localparam LCL_PCS8G_TX_TX_BITSLIP                = set_lcl_enable_cond(std_tx_bitslip_enable,"en_tx_bitslip","dis_tx_bitslip");
    localparam LCL_PCS8G_RX_WA_BOUNDARY_LOCK_CTRL     = set_std_wa_boundary_lock_ctrl(std_protocol_hint,std_rx_word_aligner_mode);
    localparam LCL_PCS8G_RX_WA_SYNC_SM_CTRL           = "<auto_any>";
    localparam [7:0] LCL_PCS8G_RX_WA_RKNUMBER_DATA    = std_rx_word_aligner_rknumber[7:0]; //number of pattern to aquire sync
    localparam [6:0] LCL_PCS8G_RX_WA_RENUMBER_DATA    = std_rx_word_aligner_renumber[6:0]; //number of error patterns to loose lock
    localparam [7:0] LCL_PCS8G_RX_WA_RGNUMBER_DATA    = std_rx_word_aligner_rgnumber[7:0]; //number of good patterns needed to decrement error count
    localparam [39:0] LCL_PCS8G_RX_WA_PD_DATA         = m_hex_to_bin(std_rx_word_aligner_pattern);
    localparam LCL_PCS8G_RX_WA_PD                     = set_wa_pd(std_rx_word_aligner_mode,std_rx_word_aligner_pattern_len,std_pcs_pma_width,std_protocol_hint);
    localparam LCL_PCS8G_RX_WA_DISP_ERR_FLAG          = set_lcl_enable_cond(std_rx_8b10b_enable,"en_disp_err_flag","dis_disp_err_flag");
    localparam LCL_PCS8G_RX_WA_CLK_SLIP_SPACING       = set_wa_cpri_auto(std_protocol_hint);
    localparam LCL_PCS8G_RX_WA_DET_LATENCY_SYNC_STATUS_BEH  = set_wa_cpri_auto(std_protocol_hint);
    //Run length detector
    localparam LCL_PCS8G_RX_RUNLENGTH_CHECK           = set_std_runlength(std_pcs_pma_width);
    localparam [5:0]  LCL_PCS8G_RX_RUNLENGTH_VAL      = std_rx_run_length_val;
    //Rate match FIFO
    localparam LCL_PCS8G_RX_RATE_MATCH                = set_std_rmfifo_mode(std_rx_rmfifo_enable,std_protocol_hint,std_pcs_pma_width);
    localparam [19:0] LCL_PCS8G_RX_CLKCMP_PATTERN_P   = m_hex_to_bin(std_rx_rmfifo_pattern_p);
    localparam [19:0] LCL_PCS8G_RX_CLKCMP_PATTERN_N   = m_hex_to_bin(std_rx_rmfifo_pattern_n);
    //Byte serializer/de-serializer
    localparam LCL_PCS8G_TX_BYTE_SERIALIZER           = set_lcl_enable_cond(std_tx_byte_ser_enable,"en_bs_by_2","dis_bs");
    localparam LCL_PCS8G_RX_BYTE_DESERIALIZER         = set_lcl_enable_cond(std_rx_byte_deser_enable,"en_bds_by_2","dis_bds");  
    //Byte ordering
    localparam LCL_PCS8G_RX_BYTE_ORDER                = set_rx_byte_order(std_rx_byte_order_enable,std_rx_byte_order_mode,std_rx_byte_order_width);
    localparam LCL_PCS8G_RX_DW_ONE_OR_TWO_SYMBOL_BO   = set_std_rx_dw_one_or_two_symbol_bo(std_rx_byte_order_enable,std_rx_byte_order_width,std_rx_byte_order_symbol_count,std_pcs_pma_width); 
    localparam [19:0] LCL_PCS8G_RX_BO_PATTERN         = m_hex_to_bin(std_rx_byte_order_pattern);
    localparam [9:0] LCL_PCS8G_RX_BO_PAD              = m_hex_to_bin(std_rx_byte_order_pad);

    //PRBS
//  localparam LCL_PCS8G_RX_PRBS_VER_CLR_FLAG         = set_lcl_enable_cond(std_rx_prbs_ver_flag_enable,"en_prbs_clr_flag","dis_prbs_clr_flag");
//  localparam LCL_PCS8G_TX_PRBS_VER                  = set_std_prbs_cond(std_tx_prbs_ver)
//  localparam LCL_PCS8G_RX_PRBS_VER                  = set_std_prbs_cond(std_rx_prbs_ver)     

    //-----------------------------
    // 10G PCS parameter mapping
    //-----------------------------
    //protocol mode 
    localparam LCL_PCS10G_TX_PROT_MODE                = set_10g_prot_mode(teng_protocol_hint);
    localparam LCL_PCS10G_RX_PROT_MODE                = set_10g_prot_mode(teng_protocol_hint);
    //Gearbox 
    localparam LCL_PCS10G_RX_GB_RX_IDWIDTH            = set_10g_gearbox_pma_width(teng_pcs_pma_width);
    localparam LCL_PCS10G_RX_GB_RX_ODWIDTH            = set_10g_gearbox_pld_width(teng_pld_pcs_width);
    localparam LCL_PCS10G_TX_GB_TX_IDWIDTH            = set_10g_gearbox_pld_width(teng_pld_pcs_width);
    localparam LCL_PCS10G_TX_GB_TX_ODWIDTH            = set_10g_gearbox_pma_width(teng_pcs_pma_width) ;
    //sync header error
    localparam LCL_PCS10G_TX_SH_ERR                   = set_lcl_enable_cond(teng_tx_sh_err,"sh_err_en","sh_err_dis");
   
    //Interface FIFOs
    localparam LCL_PCS10G_TX_TXFIFO_MODE              = set_10g_tx_fifo_mode(teng_txfifo_mode);
    localparam LCL_PCS10G_TX_TXFIFO_FULL              = teng_txfifo_full;
    localparam LCL_PCS10G_TX_TXFIFO_EMPTY             = teng_txfifo_empty;
    localparam LCL_PCS10G_TX_TXFIFO_PEMPTY            = teng_txfifo_pempty;
    localparam LCL_PCS10G_TX_TXFIFO_PFULL             = teng_txfifo_pfull;
    localparam LCL_PCS10G_RX_RXFIFO_MODE              = set_10g_rx_fifo_mode(teng_rxfifo_mode);
    localparam LCL_PCS10G_RX_RXFIFO_FULL              = teng_rxfifo_full;
    localparam LCL_PCS10G_RX_RXFIFO_EMPTY             = teng_rxfifo_empty;
    localparam LCL_PCS10G_RX_RXFIFO_PEMPTY            = teng_rxfifo_pempty;
    localparam LCL_PCS10G_RX_RXFIFO_PFULL             = teng_rxfifo_pfull;
    // DESKEW FIFO - valid only for Interlaken mode
    localparam LCL_PCS10G_RXFIFO_ALIGN_DEL            = set_lcl_enable_cond(teng_rxfifo_align_del,"align_del_en","align_del_dis");         
    // rx_control_del enables or disables the interlaken control word writing to RX FIFO , control_del_none will put all control words and control_del_all deletes all control words 
    // and only puts the paylod to RX FIFO
    localparam LCL_PCS10G_RXFIFO_CONTROL_DEL          = set_lcl_enable_cond(teng_rxfifo_control_del,"control_del_all","control_del_none"); 

    //64B/66B 
    localparam LCL_PCS10G_TX_ENC_64B66B_TXSM_BYPASS   = set_lcl_enable_cond(teng_tx_64b66b_enable,"enc_64b66b_txsm_bypass_dis","enc_64b66b_txsm_bypass_en"); 
    localparam LCL_PCS10G_RX_DEC_64B66B_RXSM_BYPASS   = set_lcl_enable_cond(teng_rx_64b66b_enable,"dec_64b66b_rxsm_bypass_dis","dec_64b66b_rxsm_bypass_en");

    // We will handle sync header through RBCs   
//  localparam LCL_PCS10G_TX_TX_SH_LOCATION           = teng_tx_synchdr_location;
//  localparam LCL_PCS10G_RX_RX_SH_LOCATION           = teng_rx_synchdr_location;
    //Bit reversal & Polarity inversion
    // We will handle CTRL and Data bit revsersal through RBCs
//  localparam LCL_PCS10G_TX_CTRL_BIT_REVERSE         = set_lcl_enable_cond(teng_tx_ctrl_bitrev_enable,"ctrl_bit_reverse_en","ctrl_bit_reverse_dis");
//  localparam LCL_PCS10G_TX_DATA_BIT_REVERSE         = set_lcl_enable_cond(teng_tx_data_bitrev_enable,"data_bit_reverse_en","data_bit_reverse_dis");   
//  localparam LCL_PCS10G_RX_CTRL_BIT_REVERSE         = set_lcl_enable_cond(teng_rx_ctrl_bitrev_enable,"ctrl_bit_reverse_en","ctrl_bit_reverse_dis");
//  localparam LCL_PCS10G_RX_DATA_BIT_REVERSE         = set_lcl_enable_cond(teng_rx_data_bitrev_enable,"data_bit_reverse_en","data_bit_reverse_dis");   
    localparam LCL_PCS10G_TX_TX_POLARITY_INV          = set_lcl_enable_cond(teng_tx_polinv_enable,"invert_enable","invert_disable");
    localparam LCL_PCS10G_RX_RX_POLARITY_INV          = set_lcl_enable_cond(teng_rx_polinv_enable,"invert_enable","invert_disable");
    //Block sync/Bitslip
    localparam LCL_PCS10G_TX_BITSLIP_EN               = set_lcl_enable_cond(teng_tx_bitslip_enable,"bitslip_en","bitslip_dis");
    localparam LCL_PCS10G_RX_BITSLIP_MODE             = set_lcl_enable_cond(teng_rx_bitslip_enable,"bitslip_en","bitslip_dis");
    localparam LCL_PCS10G_RX_BLKSYNC_BYPASS           = set_lcl_enable_cond(teng_rx_blksync_enable,"blksync_bypass_dis","blksync_bypass_en");
//  localparam LCL_PCS10G_RX_BLKSYNC_BITSLIP_WAIT_CNT = "wait_cnt_user";
//  localparam LCL_PCS10G_RX_BITSLIP_WAIT_CNT_USER    = teng_rx_blksync_wait_user_cnt;
//  localparam LCL_PCS10G_RX_BLKSYNC_BITSLIP_WAIT_TYPE= teng_rx_blksync_wait_type;
    //HI BER
   //handle HI BER through RBCs          
//  localparam LCL_PCS10G_RX_RX_SM_HIBER              = set_lcl_enable_cond(teng_rx_hiber_enable,"rx_sm_hiber_en","rx_sm_hiber_dis");
    //Scrambler
    localparam LCL_PCS10G_TX_SCRM_BYPASS              = set_lcl_enable_cond(teng_tx_scram_enable,"scrm_bypass_dis","scrm_bypass_en");
    localparam LCL_PCS10G_RX_DESCRM_BYPASS            = set_lcl_enable_cond(teng_rx_descram_enable,"descrm_bypass_dis","descrm_bypass_en");
//  localparam LCL_PCS10G_TX_SCRM_SEED                = set_10g_scrm_mode(teng_scram_seed_mode);

    localparam  [57:0]  LCL_PCS10G_TX_SCRM_SEED_USER_VAL  = altera_xcvr_functions::m_hex_to_bin(teng_tx_scram_user_seed);

    // Framegen/Frmesync parameters
    localparam  LCL_PCS10G_TX_FRMGEN_BYPASS = set_lcl_enable_cond(teng_tx_frmgen_enable, "frmgen_bypass_dis","frmgen_bypass_en");
    localparam  LCL_PCS10G_TX_FRMGEN_MFRM_LENGTH_USER = teng_tx_frmgen_user_length;
    localparam  LCL_PCS10G_RX_FRMSYNC_BYPASS = set_lcl_enable_cond(teng_rx_frmsync_enable, "frmsync_bypass_dis","frmsync_bypass_en");
    localparam  LCL_PCS10G_RX_FRMSYNC_MFRM_LENGTH_USER = teng_rx_frmsync_user_length;
    
    //Temporary hardcoded the values and will remove hardcoding after TCL takes care of string to bitvector conversion   
    localparam  [63:0]  LCL_PCS10G_FRMGENSYNC_SYNC_WORD = altera_xcvr_functions::m_hex_to_bin(teng_frmgensync_sync_word);
    localparam  [63:0]  LCL_PCS10G_FRMGENSYNC_SKIP_WORD = altera_xcvr_functions::m_hex_to_bin(teng_frmgensync_skip_word);
    localparam  [63:0]  LCL_PCS10G_FRMGENSYNC_SCRM_WORD = altera_xcvr_functions::m_hex_to_bin(teng_frmgensync_scrm_word);
    localparam  [63:0]  LCL_PCS10G_FRMGENSYNC_DIAG_WORD = altera_xcvr_functions::m_hex_to_bin(teng_frmgensync_diag_word);
    
    localparam LCL_PCS10G_TX_FRMGEN_BURST    = set_lcl_enable_cond(teng_tx_frmgen_burst_enable, "frmgen_burst_en","frmgen_burst_dis");

    // CRC32 Gen/chk
    localparam LCL_PCS10G_TX_CRCGEN_BYPASS = set_lcl_enable_cond(teng_tx_crcgen_enable, "crcgen_bypass_dis","crcgen_bypass_en");
    localparam LCL_PCS10G_RX_CRCCHK_BYPASS = set_lcl_enable_cond(teng_rx_crcchk_enable, "crcchk_bypass_dis","crcchk_bypass_en");

    // Disparity Gen/Checker
    localparam LCL_PCS10G_TX_DISPGEN_BYPASS = set_lcl_enable_cond(teng_tx_dispgen_enable, "dispgen_bypass_dis","dispgen_bypass_en");
    localparam LCL_PCS10G_RX_DISPCHK_BYPASS = set_lcl_enable_cond(teng_rx_dispchk_enable, "dispchk_bypass_dis","dispchk_bypass_en");
    
    // Common PCS-PMA interface parameter as this interface expects protocol mode as cpri_8g instead of cpri
    localparam LCL_RX_PCS_PMA_IF_PROT_MODE = (LCL_PCS8G_RX_PROT_MODE == "cpri")? "cpri_8g": "other_protocols";
    //PRBS/Test
//  localparam LCL_PCS10G_TX_TEST_MODE = teng_tx_test_mode;
//  localparam LCL_PCS10G_RX_TEST_MODE = teng_rx_test_mode;   

    //Width of the PCS Reserved Bus
    localparam LCL_PCS_RESERVED_WIDTH = 11;

    //The Sync SM enable control port needs to be enabled when user's select
    //sync SM mode for ther word aligner
    wire rx_std_sync_sm_en =  1'b1; //This signal is used in PIPE mode to force the sync SM to the LOSS_OF_LOCK state.    
   
   
   //wires for TX
   //PLD-PCS wires
   wire [(plls*channels) -1 : 0] pll_out_clk;
   wire [channels*LCL_PLD_DATA_MAX_WIDTH -1:0]       tx_datain_from_pld;
   wire [channels*LCL_PLD_DATA_MAX_WIDTH -1:0]       rx_dataout_to_pld;   
   wire [channels*LCL_PCS_RESERVED_WIDTH -1:0]       rx_10g_pld_reserved;

   
   
   //conduit
   
   // Declare local merged versions of reconfig buses 
   wire [(reconfig_interfaces*w_bundle_to_xcvr)  -1:0]  rcfg_to_xcvr;
   wire [(reconfig_interfaces*w_bundle_from_xcvr)-1:0]  rcfg_from_xcvr;

   genvar ig;  // Iterator for generated loops
   genvar jg;


   
   generate begin:gen_native_inst
/*      
      // One pll_locked output per logical PLL
      for (ig=0; ig<plls; ig=ig+1) begin:assign_tx_pll_locked
     assign  pll_locked[ig] = &pll_locked_xpos[ig];
      end
*/
      localparam num_bonded = bonded_group_size;
      
      
      for(ig=0; ig<channels; ig = ig + 1) begin: xcvr_native_insts
     
     localparam  [MAX_CHARS*8-1:0] LCL_FEEDBACK_PATH = (bonded_mode == "fb_compensation") ? "external" : 
                               pll_feedback_path;

     //extract the PRBS Done signal from bit zero of each channels' pcs_reserved_bus
     assign rx_10g_prbs_done[ig] = rx_10g_pld_reserved[LCL_PCS_RESERVED_WIDTH*ig];

/*
     // Transpose PLL locked from [channels][plls]->[plls][channels]
     for(jg=0; jg<plls; jg=jg+1) begin:gen_pll_locked_xpos
        assign  pll_locked_xpos[jg][ig] = pll_locked_wire[ig][jg];
     end
*/     
     if((ig % bonded_group_size) == 0 || (bonded_mode == "fb_compensation")) 
       begin:gen_bonded_group_plls   
        if(LCL_TX_ENABLE == 1) 
        begin:gen_tx_plls
          wire  [(plls*w_bundle_to_xcvr)-1:0]   pll_rcfg_to_xcvr;
          wire  [(plls*w_bundle_from_xcvr)-1:0] pll_rcfg_from_xcvr;

          wire  [plls-1:0]  tx_fbclk;
          assign tx_fbclk = (bonded_mode == "fb_compensation") ? tx_pma_clkout [ig] : tx_pma_clkout [ig / bonded_group_size] ;

          if(pll_external_enable) begin
            // Unused in external PLL mode (use pll_rcfg_from_xcvr for warning suppression)
            assign  pll_rcfg_to_xcvr  = {(plls*w_bundle_from_xcvr){&{1'b0,pll_rcfg_from_xcvr}}};
          end else begin
            // Connect rcfg_<to/from>_xcvr ports to PLL only when using internal PLL
            assign  pll_rcfg_to_xcvr  = rcfg_to_xcvr[(channels+(plls*ig))*w_bundle_to_xcvr+:plls*w_bundle_to_xcvr];
            assign  rcfg_from_xcvr[(channels+(plls*ig))*w_bundle_from_xcvr+:plls*w_bundle_from_xcvr] = pll_rcfg_from_xcvr;
          end

          sv_xcvr_plls 
          #(
            .plls                     (plls                  ),
            .pll_type                 (pll_type              ),
            .pll_reconfig             (pll_reconfig_enable   ),
            .pll_network_select       (pll_network_select    ),
            .pll_external             (pll_external_enable   ),
            .refclks                  (pll_refclk_cnt        ),
            .reference_clock_frequency(pll_refclk_freq       ),
            .reference_clock_select   (pll_refclk_select     ),
            .output_clock_datarate    (LCL_BASE_DATA_RATE_STR),
            .feedback_clk             (LCL_FEEDBACK_PATH     )
          ) tx_plls (
            // When using external PLLS, the refclk port is repurposed to provide the external PLL clock inputs
            .refclk     (pll_external_enable ? ext_pll_clk[ig*plls+:plls] : tx_pll_refclk ),
            .rst        (pll_powerdown[ig*plls+:plls] ),
            .fbclk      ({plls{tx_fbclk}}             ),
            .outclk     (pll_out_clk[ig*plls+:plls]   ),
//          .locked     (pll_locked_wire[ig]        ),
            .locked     (pll_locked[ig*plls+:plls]    ),                    
            .fboutclk   (/*unused*/                   ),
                  
            // avalon MM native reconfiguration interfaces
            .reconfig_to_xcvr   (pll_rcfg_to_xcvr   ),
            .reconfig_from_xcvr (pll_rcfg_from_xcvr )
          );
        end // block: gen_tx_plls
        else 
        begin:gen_no_tx  // TX disabled
           assign pll_out_clk[ig*plls+:plls]   = {plls{1'b0}};
           assign pll_locked[ig*plls+:plls]   = {plls{1'b0}};      
//           assign pll_locked_wire[ig]          = {plls{1'b0}};
        end
       end // block: gen_bonded_group_plls
     else begin: gen_pll_fanout
        assign pll_out_clk[ig*plls+:plls] = pll_out_clk[0+:plls]; // fanout for pll_out_clk for xN bonding 
//        assign pll_locked_wire[ig]        = pll_locked_wire[0]  ;
     end
     
     if ((ig % bonded_group_size) == 0) begin: gen_bonded_group_native
        localparam  [57:0]  LCL_PCS10G_TX_SCRM_SEED_USER  = set_10g_scrm_seed_user(teng_protocol_hint,LCL_PCS10G_TX_SCRM_SEED_USER_VAL,ig);

        // create native transceiver interface
        sv_xcvr_native 
          #(
        // SV PMA Parameters
        .rx_enable                            (LCL_RX_ENABLE),
        .tx_enable                            (LCL_TX_ENABLE),
        // Bonding parameters
        .pma_bonding_type                     (LCL_PMA_BONDING_TYPE),
        .plls                                 (plls),
        .pll_sel                              (pll_select),
        .pma_prot_mode                        (LCL_PMA_PROT_MODE),
        .pma_data_rate                        (LCL_DATA_RATE),
        // RX PMA Parameters
        .cdr_reference_clock_frequency        (cdr_refclk_freq),
        .cdr_refclk_cnt                       (cdr_refclk_cnt),
        .cdr_refclk_sel                       (cdr_refclk_select),
        .cdr_reconfig                         (cdr_reconfig_enable),
        .deser_enable_bit_slip                (LCL_DESER_ENABLE_BIT_SLIP),
        .tx_clk_div                           (tx_pma_clk_div),
        .sd_on                                (LCL_SD_ON),
        .enable_pma_direct_tx                 (LCL_ENABLE_PMA_DIRECT_TX),
        .enable_pma_direct_rx                 (LCL_ENABLE_PMA_DIRECT_RX),
        .qpi_enable                           (tx_pma_txdetectrx_ctrl),      

        // sv_pcs parameters
        .enable_10g_rx                        (LCL_ENABLE_10G_RX),
        .enable_10g_tx                        (LCL_ENABLE_10G_TX),
        .enable_8g_rx                         (LCL_ENABLE_8G_RX), 
        .enable_8g_tx                         (LCL_ENABLE_8G_TX),
        .enable_dyn_reconfig                  ("false"),
        .enable_gen12_pipe                    ("false"),
        .enable_gen3_pipe                     ("false"),
        .enable_gen3_rx                       ("false"),
        .enable_gen3_tx                       ("false"),

        // parameters for stratixv_hssi_8g_tx_pcs
        .pcs8g_tx_prot_mode                   (LCL_PCS8G_TX_PROT_MODE),
        .pcs8g_tx_eightb_tenb_disp_ctrl       (LCL_PCS8G_TX_EIGHTB_TENB_DISP_CTRL),
        .pcs8g_tx_eightb_tenb_encoder         (LCL_PCS8G_TX_EIGHTB_TENB_ENCODER),
        .pcs8g_tx_pcs_bypass                  (LCL_PCS8G_TX_PCS_BYPASS),
        .pcs8g_tx_phase_compensation_fifo     (LCL_PCS8G_TX_PHASE_COMPENSATION_FIFO),
        .pcs8g_tx_pma_dw                      (LCL_PCS8G_TX_PMA_DW),
        .pcs8g_tx_bit_reversal                (LCL_PCS8G_TX_BIT_REVERSAL),
        .pcs8g_tx_polarity_inversion          (LCL_PCS8G_TX_POLARITY_INVERSION),
        .pcs8g_tx_sup_mode                    ("user_mode"),
        .pcs8g_tx_tx_bitslip                  (LCL_PCS8G_TX_TX_BITSLIP),
        .pcs8g_tx_byte_serializer             (LCL_PCS8G_TX_BYTE_SERIALIZER),
        .pcs8g_tx_symbol_swap                 (LCL_PCS8G_TX_SYMBOL_SWAP),
//      .pcs8g_rx_prbs_ver                    (LCL_PCS8G_TX_PRBS_VER), // dis_prbs|prbs_7_sw|prbs_7_dw|prbs_8|prbs_10|prbs_23_sw|prbs_23_dw|prbs_15|prbs_31|prbs_hf_sw|prbs_hf_dw|prbs_lf_sw|prbs_lf_dw|prbs_mf_sw|prbs_mf_dw        
        // parameters for stratixv_hssi_8g_rx_pcs
        .pcs8g_rx_prot_mode                   (LCL_PCS8G_RX_PROT_MODE),
        .pcs8g_rx_eightb_tenb_decoder         (LCL_PCS8G_RX_EIGHTB_TENB_DECODER),
        .pcs8g_rx_pcs_bypass                  (LCL_PCS8G_TX_PCS_BYPASS),
        .pcs8g_rx_phase_compensation_fifo     (LCL_PCS8G_RX_PHASE_COMPENSATION_FIFO),
//      .pcs8g_rx_auto_deassert_pc_rst_cnt_data(5'b01000),
        .pcs8g_rx_auto_error_replacement      ("<auto_any>"),
        .pcs8g_rx_pma_dw                      (LCL_PCS8G_RX_PMA_DW),
        .pcs8g_rx_bit_reversal                (LCL_PCS8G_RX_BIT_REVERSAL),
        .pcs8g_rx_polarity_inversion          (LCL_PCS8G_RX_POLARITY_INVERSION),
        .pcs8g_rx_sup_mode                    ("user_mode"),
        .pcs8g_rx_byte_deserializer           (LCL_PCS8G_RX_BYTE_DESERIALIZER),
        .pcs8g_rx_byte_order                  (LCL_PCS8G_RX_BYTE_ORDER),
        .pcs8g_rx_dw_one_or_two_symbol_bo     (LCL_PCS8G_RX_DW_ONE_OR_TWO_SYMBOL_BO),
        .pcs8g_rx_bo_pad                      (LCL_PCS8G_RX_BO_PAD),
        .pcs8g_rx_bo_pattern                  (LCL_PCS8G_RX_BO_PATTERN),
        .pcs8g_rx_wa_boundary_lock_ctrl       (LCL_PCS8G_RX_WA_BOUNDARY_LOCK_CTRL),
        .pcs8g_rx_wa_sync_sm_ctrl             (LCL_PCS8G_RX_WA_SYNC_SM_CTRL),
        .pcs8g_rx_wa_disp_err_flag            (LCL_PCS8G_RX_WA_DISP_ERR_FLAG),
        .pcs8g_rx_err_flags_sel               ("<auto_any>"),
        .pcs8g_rx_wa_pd                       (LCL_PCS8G_RX_WA_PD),
        .pcs8g_rx_wa_pd_data                  (LCL_PCS8G_RX_WA_PD_DATA),
//      .pcs8g_rx_wa_pld_controlled           (LCL_PCS8G_RX_WA_PLD_CONTROLLED),
        .pcs8g_rx_wa_renumber_data            (LCL_PCS8G_RX_WA_RENUMBER_DATA),
        .pcs8g_rx_wa_rgnumber_data            (LCL_PCS8G_RX_WA_RGNUMBER_DATA),
        .pcs8g_rx_wa_rknumber_data            (LCL_PCS8G_RX_WA_RKNUMBER_DATA),
        .pcs8g_rx_wa_det_latency_sync_status_beh (LCL_PCS8G_RX_WA_DET_LATENCY_SYNC_STATUS_BEH),
        .pcs8g_rx_wa_clk_slip_spacing         (LCL_PCS8G_RX_WA_CLK_SLIP_SPACING),
        .pcs8g_rx_runlength_check             (LCL_PCS8G_RX_RUNLENGTH_CHECK),
        .pcs8g_rx_runlength_val               (LCL_PCS8G_RX_RUNLENGTH_VAL),
        .pcs8g_rx_rate_match                  (LCL_PCS8G_RX_RATE_MATCH),
        .pcs8g_rx_clkcmp_pattern_n            (LCL_PCS8G_RX_CLKCMP_PATTERN_N),
        .pcs8g_rx_clkcmp_pattern_p            (LCL_PCS8G_RX_CLKCMP_PATTERN_P),
        .pcs8g_rx_deskew_prog_pattern_only    ("dis_deskew_prog_pat_only"),
        .pcs8g_rx_symbol_swap                 (LCL_PCS8G_RX_SYMBOL_SWAP),
//      .pcs8g_rx_rx_rd_clk                   (LCL_PCS8G_RX_RX_RD_CLK),
//      .pcs8g_rx_rx_clk1                     (LCL_PCS8G_RX_RX_CLK1),
//      .pcs8g_rx_rx_clk2                     (LCL_PCS8G_RX_RX_CLK2),
        .pcs8g_rx_rx_rcvd_clk                 ("rcvd_clk_rcvd_clk"),

//      .pcs8g_rx_prbs_ver                  (LCL_PCS8G_RX_PRBS_VER), // dis_prbs|prbs_7_sw|prbs_7_dw|prbs_8|prbs_10|prbs_23_sw|prbs_23_dw|prbs_15|prbs_31|prbs_hf_sw|prbs_hf_dw|prbs_lf_sw|prbs_lf_dw|prbs_mf_sw|prbs_mf_dw
//      .pcs8g_rx_prbs_ver_clr_flag         (LCL_PCS8G_RX_PRBS_VER_CLR_FLAG), // dis_prbs_clr_flag|en_prbs_clr_flag
 
        // parameters for stratixv_hssi_10g_tx_pcs
        .pcs10g_tx_prot_mode                 (LCL_PCS10G_TX_PROT_MODE),
        .pcs10g_tx_gb_tx_idwidth             (LCL_PCS10G_TX_GB_TX_IDWIDTH),
        .pcs10g_tx_gb_tx_odwidth             (LCL_PCS10G_TX_GB_TX_ODWIDTH),
        .pcs10g_tx_gb_sel_mode               ("internal"),
        .pcs10g_tx_sup_mode                  ("user_mode"),
        .pcs10g_tx_sh_err                    (LCL_PCS10G_TX_SH_ERR),
        .pcs10g_tx_txfifo_mode               (LCL_PCS10G_TX_TXFIFO_MODE),
        .pcs10g_tx_txfifo_full               (LCL_PCS10G_TX_TXFIFO_FULL),
        .pcs10g_tx_txfifo_empty              (LCL_PCS10G_TX_TXFIFO_EMPTY),
        .pcs10g_tx_txfifo_pempty             (LCL_PCS10G_TX_TXFIFO_PEMPTY),
        .pcs10g_tx_txfifo_pfull              (LCL_PCS10G_TX_TXFIFO_PFULL),
//      .pcs10g_tx_tx_sh_location            (LCL_PCS10G_TX_TX_SH_LOCATION), //Handled by RBCs
        .pcs10g_tx_tx_polarity_inv           (LCL_PCS10G_TX_TX_POLARITY_INV),
//      .pcs10g_tx_ctrl_bit_reverse          (LCL_PCS10G_TX_CTRL_BIT_REVERSE), //Handled by RBCs
//      .pcs10g_tx_data_bit_reverse          (LCL_PCS10G_TX_DATA_BIT_REVERSE), //Handled by RBCs
        .pcs10g_tx_bitslip_en                (LCL_PCS10G_TX_BITSLIP_EN),
        .pcs10g_tx_enc_64b66b_txsm_bypass    (LCL_PCS10G_TX_ENC_64B66B_TXSM_BYPASS),
        .pcs10g_tx_scrm_bypass               (LCL_PCS10G_TX_SCRM_BYPASS),
//      .pcs10g_tx_scrm_seed                 (LCL_PCS10G_TX_SCRM_SEED),
        .pcs10g_tx_scrm_seed_user            (LCL_PCS10G_TX_SCRM_SEED_USER),
        .pcs10g_tx_test_mode                 ("test_off"),
        .pcs10g_tx_pseudo_random             ("all_0"),
        .pcs10g_tx_sq_wave                   ("sq_wave_4"),
        .pcs10g_tx_pmagate_en                ("pmagate_dis"),

        // Frame Gen
        .pcs10g_tx_frmgen_bypass             (LCL_PCS10G_TX_FRMGEN_BYPASS), // frmgen_bypass_dis|frmgen_bypass_en
        .pcs10g_tx_frmgen_mfrm_length("mfrm_user_length"),           
        .pcs10g_tx_frmgen_mfrm_length_user (LCL_PCS10G_TX_FRMGEN_MFRM_LENGTH_USER),

        .pcs10g_tx_frmgen_diag_word (LCL_PCS10G_FRMGENSYNC_DIAG_WORD    ),
        .pcs10g_tx_frmgen_scrm_word (LCL_PCS10G_FRMGENSYNC_SCRM_WORD    ),
        .pcs10g_tx_frmgen_skip_word    (LCL_PCS10G_FRMGENSYNC_SKIP_WORD    ),
        .pcs10g_tx_frmgen_sync_word    (LCL_PCS10G_FRMGENSYNC_SYNC_WORD    ),
        .pcs10g_tx_frmgen_burst(LCL_PCS10G_TX_FRMGEN_BURST),
//      .pcs10g_tx_frmgen_pipeln(LCL_PCS10G_TX_FRMGEN_PIPELN),
//      .pcs10g_tx_frmgen_pyld_ins(LCL_PCS10G_TX_FRMGEN_PYLD_INS),
//      .pcs10g_tx_frmgen_wordslip(LCL_PCS10G_TX_FRMGEN_WORDSLIP), //// Engg mode feature so not enabled

        // CRC32 Generator
        .pcs10g_tx_crcgen_bypass(LCL_PCS10G_TX_CRCGEN_BYPASS),
        // Disparity generator
        .pcs10g_tx_dispgen_bypass(LCL_PCS10G_TX_DISPGEN_BYPASS),

        // New in production    
//      .pcs10g_tx_full_flag_type(LCL_PCS10G_TX_FULL_FLAG_TYPE)

        .pcs10g_tx_tx_testbus_sel("<auto_any>"),
        .pcs10g_tx_bit_reverse("<auto_any>"),

        // parameters for stratixv_hssi_10g_rx_pcs
        .pcs10g_rx_prot_mode                 (LCL_PCS10G_RX_PROT_MODE),
        .pcs10g_rx_gb_rx_idwidth             (LCL_PCS10G_RX_GB_RX_IDWIDTH),
        .pcs10g_rx_gb_rx_odwidth             (LCL_PCS10G_RX_GB_RX_ODWIDTH),
        .pcs10g_rx_gb_sel_mode               ("internal"),
        .pcs10g_rx_sup_mode                  ("user_mode"),
        .pcs10g_rx_rxfifo_mode               (LCL_PCS10G_RX_RXFIFO_MODE),
        .pcs10g_rx_rxfifo_full               (LCL_PCS10G_RX_RXFIFO_FULL),
        .pcs10g_rx_rxfifo_empty              (LCL_PCS10G_RX_RXFIFO_EMPTY),
        .pcs10g_rx_rxfifo_pempty             (LCL_PCS10G_RX_RXFIFO_PEMPTY),
        .pcs10g_rx_rxfifo_pfull              (LCL_PCS10G_RX_RXFIFO_PFULL),
//      .pcs10g_rx_rx_sh_location            (LCL_PCS10G_RX_RX_SH_LOCATION), //Handled by RBCs
        .pcs10g_rx_dec_64b66b_rxsm_bypass    (LCL_PCS10G_RX_DEC_64B66B_RXSM_BYPASS),
//      .pcs10g_rx_ctrl_bit_reverse          (LCL_PCS10G_RX_CTRL_BIT_REVERSE), //Handled by RBCs
//      .pcs10g_rx_data_bit_reverse          (LCL_PCS10G_RX_DATA_BIT_REVERSE), //Handled by RBCs
        .pcs10g_rx_bitslip_mode              (LCL_PCS10G_RX_BITSLIP_MODE),
        .pcs10g_rx_rx_polarity_inv           (LCL_PCS10G_RX_RX_POLARITY_INV),
//      .pcs10g_rx_rx_sm_hiber               (LCL_PCS10G_RX_RX_SM_HIBER),     //Handled by RBCs
        .pcs10g_rx_blksync_bypass            (LCL_PCS10G_RX_BLKSYNC_BYPASS),   
//      .pcs10g_rx_blksync_bitslip_wait_cnt  (LCL_PCS10G_RX_BLKSYNC_BITSLIP_WAIT_CNT), 
//      .pcs10g_rx_blksync_bitslip_wait_type (LCL_PCS10G_RX_BLKSYNC_BITSLIP_WAIT_TYPE),
        .pcs10g_rx_blksync_knum_sh_cnt_prelock ("knum_sh_cnt_prelock_10g"),
        .pcs10g_rx_blksync_knum_sh_cnt_postlock ("knum_sh_cnt_postlock_10g"),
        .pcs10g_rx_blksync_enum_invalid_sh_cnt("enum_invalid_sh_cnt_10g"),
        .pcs10g_rx_blksync_bitslip_type      ("<auto_any>"), // bitslip_comb|bitslip_reg
        .pcs10g_rx_descrm_bypass             (LCL_PCS10G_RX_DESCRM_BYPASS), 
        .pcs10g_rx_align_del                 (LCL_PCS10G_RXFIFO_ALIGN_DEL), 
        .pcs10g_rx_control_del               (LCL_PCS10G_RXFIFO_CONTROL_DEL),
        .pcs10g_rx_test_mode                 ("test_off"),
        .pcs10g_rx_lpbk_mode                 ("lpbk_dis"),
        // CRC checker
        .pcs10g_rx_crcchk_bypass             (LCL_PCS10G_RX_CRCCHK_BYPASS),
        // Disparity checker
        .pcs10g_rx_dispchk_bypass            (LCL_PCS10G_RX_DISPCHK_BYPASS),
        // Frame synchronizer
        .pcs10g_rx_frmsync_bypass            (LCL_PCS10G_RX_FRMSYNC_BYPASS), // frmsync_bypass_dis|frmsync_bypass_en
        .pcs10g_rx_frmsync_mfrm_length       ("mfrm_user_length"),           
        .pcs10g_rx_frmsync_mfrm_length_user  (LCL_PCS10G_RX_FRMSYNC_MFRM_LENGTH_USER),  // 0..8191
        .pcs10g_rx_frmgen_diag_word (LCL_PCS10G_FRMGENSYNC_DIAG_WORD    ),
        .pcs10g_rx_frmgen_scrm_word (LCL_PCS10G_FRMGENSYNC_SCRM_WORD    ),
        .pcs10g_rx_frmgen_skip_word    (LCL_PCS10G_FRMGENSYNC_SKIP_WORD    ),
        .pcs10g_rx_frmgen_sync_word    (LCL_PCS10G_FRMGENSYNC_SYNC_WORD    ),
        .pcs10g_rx_rx_testbus_sel("<auto_any>"),
        .pcs10g_rx_rx_true_b2b("<auto_any>"),
        .pcs10g_rx_dis_signal_ok("<auto_any>"),
        .pcs10g_rx_ber_bit_err_total_cnt("bit_err_total_cnt_10g"),
        .pcs10g_rx_ber_xus_timer_window("<auto_any>"),
        .pcs10g_rx_bit_reverse                ("<auto_any>"),

   
        // Interface specific parameters
        .rx_pcs_pma_if_selectpcs(data_path_select == "10G" ? "ten_g_pcs" : "eight_g_pcs"),
        .rx_pld_pcs_if_selectpcs(data_path_select == "10G" ? "ten_g_pcs" : "eight_g_pcs"),
        .tx_pcs_pma_if_selectpcs(data_path_select == "10G" ? "ten_g_pcs" : "eight_g_pcs"),
        .rx_pcs_pma_if_prot_mode(LCL_RX_PCS_PMA_IF_PROT_MODE),
        .com_pcs_pma_if_func_mode(enable_teng           ? "teng_only" : 
                                  enable_std            ? "eightg_only_pld" : 
                                  LCL_ENABLE_PMADIRECT  ? "pma_direct" : "disable"),
        .com_pcs_pma_if_prot_mode             ("other_protocols"),
        .com_pcs_pma_if_sup_mode              ("user_mode"),
        .com_pcs_pma_if_force_freqdet         ("force_freqdet_dis"),
        .com_pcs_pma_if_ppmsel                (LCL_COM_PCS_PMA_IF_PPMSEL),
        .rx_pcs_pma_if_clkslip_sel            (LCL_RX_PCS_PMA_IF_CLKSLIP_SEL),  //selects type of clkslip
        .bonded_lanes                         (num_bonded),
        .pma_mode                             (LCL_PMA_MODE),
        .com_pld_pcs_if_testbus_sel           (LCL_PLD_PCS_IF_TESTBUS_SEL),
//      .rx_pld_pcs_if_is_8g_0ppm             (LCL_RX_PLD_PCS_IF_IS_8G_0PPM),
//      .tx_pld_pcs_if_is_8g_0ppm             (LCL_TX_PLD_PCS_IF_IS_8G_0PPM),
        .auto_negotiation                     ("false")
        ) 
        xcvr_native_inst 
          (
           .out_pld_clklow                (rx_clklow [ig +: num_bonded]),        // RX low frequency recovered clock
           .out_pld_fref                  (rx_fref[ig +: num_bonded]),            // rx PFD ref clock (rx_cdr_refclk after divider)
           
           // TX/RX ports
           .seriallpbken                  (rx_seriallpbken[ig +: num_bonded]),   // 1 = enable serial loopback                    
              
           // RX Ports                                                                 
           .rx_crurstn                    (~rx_analogreset[ig +: num_bonded]),
           .rx_datain                     (rx_serial_data[ig +: num_bonded]),      // RX serial data input                          
           .rx_cdr_ref_clk                ({num_bonded{rx_cdr_refclk}}), // Reference clock for CDR                       
           .rx_ltd                        (rx_set_locktodata[ig +: num_bonded]),         // Force lock-to-data stream
           .rx_clkdivrx                   (rx_pma_clkout[ig +: num_bonded]),
           .rx_is_lockedtoref             (rx_is_lockedtoref[ig +: num_bonded]),  // Indicates lock to reference clock
           .rx_is_lockedtodata            (rx_is_lockedtodata[ig +: num_bonded]),
           .rx_sd                         (rx_signaldetect[ig +: num_bonded]),            // Signal detect output from PMA
           .in_pld_ltr                    (rx_set_locktoref [ig +: num_bonded]  ),
           .in_pld_rxpma_rstb_in          (~rx_analogreset[ig +: num_bonded]),   // this drives the crurstn port of RX PMA
           .in_pld_rx_clk_slip_in         (rx_clkslip[ig +: num_bonded]),
           .in_pma_clkdiv33_lc_in           ({num_bonded{1'b0}}),
           .in_pma_rx_freq_tx_cmu_pll_lock_in({num_bonded{1'b0}}),
           .in_pma_tx_lc_pll_lock_in        ({num_bonded{1'b0}}),
           .in_pld_scan_mode_n            ({num_bonded{1'b1}} ),
           .out_pld_rx_data               (rx_parallel_data[64*ig +: num_bonded*64]),
           .out_pld_rx_pma_data           (rx_pma_parallel_data[80*ig +: num_bonded*80]),
           .out_pld_clkdiv33_txorrx       (rx_10g_clk33out[ig +: num_bonded]),           

           // TX Ports
           .tx_rxdetclk                   (1'b0),    // Clock for detection of downstream receiver
           .tx_dataout                    (tx_serial_data[ig +: num_bonded]),     // TX serial data output
           .tx_rstn                       (~tx_analogreset[ig +: num_bonded]),        
           .tx_clkdivtx                   (tx_pma_clkout  [ig +: num_bonded]), 
           .tx_ser_clk                    (pll_out_clk    [ig*plls +: (num_bonded*plls)]),     // High-speed serial clock from PLL              
           .tx_cal_busy                   (tx_cal_busy[ig +: num_bonded]  ),
           .rx_cal_busy                   (rx_cal_busy[ig +: num_bonded]  ),
           .in_pld_8g_txelecidle          (tx_std_elecidle[ig +: num_bonded]),
           .in_pld_tx_data                (tx_parallel_data[64*ig +: num_bonded*64]),         
           .in_pld_tx_pma_data            (tx_pma_parallel_data[80*ig +: num_bonded*80]),

            // QPI specific input ports
           .rxqpipulldn                   (rx_pma_qpipulldn[ig +: num_bonded]),
           .txqpipulldn                   (tx_pma_qpipulldn[ig +: num_bonded] ),
           .txqpipullup                   (tx_pma_qpipullup[ig +: num_bonded] ),
           .in_pld_txdetectrx             (tx_pma_txdetectrx[ig +: num_bonded]),
           // QPI specific output port
           .tx_rxfound                    (tx_pma_rxfound[ig +: num_bonded]),

           //Standard/8G input ports
           .in_pld_8g_pld_rx_clk          (rx_std_coreclkin[ig +: num_bonded]),
           .in_pld_8g_pld_tx_clk          (tx_std_coreclkin[ig +: num_bonded]),          
           .in_pld_8g_a1a2_size           (rx_std_wa_a1a2size[ig +: num_bonded]),
           .in_pld_8g_bitloc_rev_en       (rx_std_bitrev_ena[ig +: num_bonded]),
           .in_pld_8g_bitslip             (rx_std_bitslip[ig +: num_bonded]),
           .in_pld_8g_byte_rev_en         (rx_std_byterev_ena[ig +: num_bonded]),
           .in_pld_8g_bytordpld           (rx_std_byteorder_ena[ig +: num_bonded]),
           .in_pld_8g_encdt               (rx_std_wa_patternalign[ig +: num_bonded]),
           .in_pld_8g_polinv_rx           (rx_std_polinv[ig +: num_bonded]),
           .in_pld_8g_polinv_tx           (tx_std_polinv[ig +: num_bonded]),
           .in_pld_8g_prbs_cid_en         ({num_bonded{1'b0}}),
           .in_pld_8g_rddisable_tx        ({num_bonded{1'b0}}),
           .in_pld_8g_wrdisable_rx        ({num_bonded{1'b0}}),
           .in_pld_8g_wrenable_tx         ({num_bonded{1'b0}}),
           .in_pld_8g_rdenable_rmf        ({num_bonded{1'b0}}),
           .in_pld_8g_wrenable_rmf        ({num_bonded{1'b0}}),
           .in_pld_8g_rev_loopbk          ({num_bonded{1'b0}}),
           .in_pld_sync_sm_en             ({num_bonded{rx_std_sync_sm_en}}),
           .in_pld_8g_rxurstpcs_n         (~rx_digitalreset[ig +: num_bonded]),
           .in_pld_8g_tx_boundary_sel     (tx_std_bitslipboundarysel[(ig*5) +: (num_bonded*5)]),
           .in_pld_8g_tx_data_valid       ({num_bonded{4'b0000}}),
           .in_pld_8g_tx_sync_hdr         ({num_bonded{2'b00}}),
           .in_pld_8g_txurstpcs_n         (~tx_digitalreset      [ig +: num_bonded] ),

           //Standard/8G output ports
           .out_pld_8g_byteord_flag       (rx_std_byteorder_flag[ig +: num_bonded]),
           .out_pld_8g_empty_rmf          (rx_std_rmfifo_empty[ig +: num_bonded]),
           .out_pld_8g_empty_rx           (rx_std_pcfifo_empty[ig +: num_bonded]),
           .out_pld_8g_empty_tx           (tx_std_pcfifo_empty[ig +: num_bonded]),
           .out_pld_8g_full_rmf           (rx_std_rmfifo_full[ig +: num_bonded]),
           .out_pld_8g_full_rx            (rx_std_pcfifo_full[ig +: num_bonded]),
           .out_pld_8g_full_tx            (tx_std_pcfifo_full[ig +: num_bonded]),
           .out_pld_8g_rlv_lt             (rx_std_runlength_err[ig +: num_bonded]),
           .out_pld_8g_rx_clk_out         (rx_std_clkout[ig +: num_bonded]),
           .out_pld_8g_signal_detect_out  (rx_std_signaldetect[ig +: num_bonded]),
           .out_pld_8g_tx_clk_out         (tx_std_clkout[ig +: num_bonded]),
           .out_pld_8g_wa_boundary        (rx_std_bitslipboundarysel[5*ig +: 5*num_bonded]),
           .out_pld_8g_bistdone           (rx_std_prbs_done[ig +: num_bonded]),
           .out_pld_8g_bisterr            (rx_std_prbs_err[ig +: num_bonded]),

           //10g input ports
           .in_pld_10g_refclk_dig         ({num_bonded{1'b0}}),
           .in_pld_10g_rx_align_clr       (rx_10g_fifo_align_clr[ig +: num_bonded]), 
           .in_pld_10g_rx_align_en        (rx_10g_fifo_align_en[ig +: num_bonded]),  // only useful in interlaken mode
           .in_pld_10g_rx_bitslip         (rx_10g_bitslip[ig +: num_bonded]),
           .in_pld_10g_rx_clr_ber_count   (rx_10g_highber_clr_cnt[ig +: num_bonded]),
           .in_pld_10g_rx_clr_errblk_cnt  (rx_10g_clr_errblk_count),
//         .in_pld_10g_rx_disp_clr        (rx_10g_disp_clr[ig +: num_bonded]), // Enginnering mode feature only
           .in_pld_10g_rx_pld_clk         (rx_10g_coreclkin[ig +: num_bonded]),
           .in_pld_10g_rx_prbs_err_clr    (rx_10g_prbs_err_clr[ig +: num_bonded]),
           .in_pld_10g_rx_rd_en           (rx_10g_fifo_rd_en[ig +: num_bonded]),
           .in_pld_10g_rx_rst_n           (~rx_digitalreset[ig +: num_bonded]),
           .in_pld_10g_tx_bitslip         (tx_10g_bitslip[7*ig +: num_bonded*7]),
           .in_pld_10g_tx_burst_en        (tx_10g_frame_burst_en[ig +: num_bonded]),
           .in_pld_10g_tx_control         (tx_10g_control[lp_tx_control_max_width*ig +: num_bonded*lp_tx_control_max_width]),
           .in_pld_10g_tx_data_valid      (tx_10g_data_valid[ig +: num_bonded]),
           .in_pld_10g_tx_diag_status     (tx_10g_frame_diag_status[(ig*2) +: (num_bonded*2)]),
           .in_pld_10g_tx_pld_clk         (tx_10g_coreclkin[ig +: num_bonded]),
           .in_pld_10g_tx_rst_n           (~tx_digitalreset[ig +: num_bonded]),
//         .in_pld_10g_tx_wordslip        (tx_10g_wordslip[ig +: num_bonded]),  // Engg mode only

           //10g output ports
           .out_pld_10g_rx_align_val      (rx_10g_fifo_align_val[ig +: num_bonded]),
           .out_pld_10g_rx_blk_lock       (rx_10g_blk_lock[ig +: num_bonded]),
           .out_pld_10g_rx_clk_out        (rx_10g_clkout[ig +: num_bonded]),
           .out_pld_10g_rx_control        (rx_10g_control[lp_rx_control_max_width*ig +: num_bonded*lp_rx_control_max_width]),
           .out_pld_10g_rx_crc32_err      (rx_10g_crc32_err[ig +: num_bonded]),
           .out_pld_10g_rx_data_valid     (rx_10g_data_valid[ig +: num_bonded]),
           .out_pld_10g_rx_empty          (rx_10g_fifo_empty[ig +: num_bonded]),
           .out_pld_10g_rx_fifo_del       (rx_10g_fifo_del[ig +: num_bonded]),
           .out_pld_10g_rx_fifo_insert    (rx_10g_fifo_insert[ig +: num_bonded]),
           .out_pld_10g_rx_frame_lock     (rx_10g_frame_lock[ig +: num_bonded]),
           .out_pld_10g_rx_hi_ber         (rx_10g_highber[ig +: num_bonded]),
           .out_pld_10g_rx_mfrm_err       (rx_10g_frame_mfrm_err[ig +: num_bonded]),
           .out_pld_10g_rx_oflw_err       (rx_10g_fifo_full[ig +: num_bonded]),
           .out_pld_10g_rx_skip_ins       (rx_10g_frame_skip_ins[ig +: num_bonded]),
           .out_pld_10g_rx_skip_err       (rx_10g_frame_skip_err[ig +: num_bonded]),
           .out_pld_10g_rx_diag_err       (rx_10g_frame_diag_err[ig +: num_bonded]),
           .out_pld_10g_rx_pempty         (rx_10g_fifo_pempty[ig +: num_bonded]),
           .out_pld_10g_rx_pfull          (rx_10g_fifo_pfull[ig +: num_bonded]),
           .out_pld_10g_rx_prbs_err       (rx_10g_prbs_err[ig +: num_bonded]),
           .out_pld_10g_rx_pyld_ins       (rx_10g_frame_pyld_ins[ig +: num_bonded]),
           .out_pld_10g_rx_diag_status    (rx_10g_frame_diag_status[(ig*2) +: (num_bonded*2)]),
           .out_pld_10g_rx_rdneg_sts      (/*unused*/),
           .out_pld_10g_rx_rdpos_sts      (/*unused*/),
           .out_pld_10g_rx_rx_frame       (rx_10g_frame[ig +: num_bonded]),
           .out_pld_10g_rx_scrm_err       (rx_10g_descram_err[ig +: num_bonded]),
           .out_pld_10g_rx_sh_err         (rx_10g_blk_sh_err[ig +: num_bonded]),
           .out_pld_10g_rx_sync_err       (rx_10g_frame_sync_err[ig +: num_bonded]),
           .out_pld_10g_tx_clk_out        (tx_10g_clkout[ig +: num_bonded]),
           .out_pld_10g_tx_empty          (tx_10g_fifo_empty[ig +: num_bonded]),
           .out_pld_10g_tx_fifo_del       (tx_10g_fifo_del[ig +: num_bonded]),
           .out_pld_10g_tx_fifo_insert    (tx_10g_fifo_insert[ig +: num_bonded]),
           .out_pld_10g_tx_frame          (tx_10g_frame[ig +: num_bonded]),
           .out_pld_10g_tx_full           (tx_10g_fifo_full[ig +: num_bonded]),
           .out_pld_10g_tx_pempty         (tx_10g_fifo_pempty[ig +: num_bonded]),
           .out_pld_10g_tx_pfull          (tx_10g_fifo_pfull[ig +: num_bonded]),
           .out_pld_reserved_out          (rx_10g_pld_reserved[LCL_PCS_RESERVED_WIDTH*ig +: num_bonded*LCL_PCS_RESERVED_WIDTH]),

           // PMA clock outputs
           .out_pma_tx_clk_out            (tx_pma_pclk[ig+:num_bonded]),
           .out_pma_rx_clk_out            (rx_pma_pclk[ig+:num_bonded]),
 
           // Reconfig interface ports
           .reconfig_to_xcvr              (rcfg_to_xcvr   [ig*w_bundle_to_xcvr+:num_bonded*w_bundle_to_xcvr]    ),
           .reconfig_from_xcvr            (rcfg_from_xcvr [ig*w_bundle_from_xcvr+:num_bonded*w_bundle_from_xcvr]),

           .in_agg_test_so_to_pld_in(/*unused*/),
           .in_emsip_com_in(/*unused*/),
           .in_emsip_com_special_in(/*unused*/),
           .in_emsip_rx_clk_in(/*unused*/),
           .in_emsip_rx_in(/*unused*/),
           .in_emsip_rx_special_in(/*unused*/),
           .in_pld_10g_rx_disp_clr(/*unused*/),
//           .in_pld_10g_rx_prbs_err_clr(/*unused*/),
           .in_pld_8g_cmpfifourst_n(/*unused*/),
           .in_pld_8g_phfifourst_rx_n(/*unused*/),
           .in_pld_8g_powerdown(/*unused*/),
//           .in_pld_8g_prbs_cid_en(/*unused*/),
           .in_pld_8g_rdenable_rx(/*unused*/),
           .in_pld_8g_rxpolarity(/*unused*/),
           .in_pld_8g_txdeemph(/*unused*/),
           .in_pld_8g_txdetectrxloopback(/*unused*/),
           .in_pld_8g_txmargin(/*unused*/),
           .in_pld_8g_txswing(/*unused*/),
           .in_pld_gen3_rx_rstn(/*unused*/),
           .in_pld_pcs_pma_if_refclk_dig(/*unused*/),
           .in_pld_reserved_in(/*unused*/),
           .in_pld_scan_shift_n({num_bonded{1'b1}}),
           .in_pma_eye_monitor_in(/*unused*/),
           .in_pma_hclk(/*unused*/),
           .in_pma_reserved_in(/*unused*/),
           .pcs_rst_n(/*unused*/),
           .in_agg_align_status(/*unused*/),
           .in_agg_align_status_sync_0(/*unused*/),
           .in_agg_align_status_sync_0_top_or_bot(/*unused*/),
           .in_agg_align_status_top_or_bot(/*unused*/),
           .in_agg_cg_comp_rd_d_all(/*unused*/),
           .in_agg_cg_comp_rd_d_all_top_or_bot(/*unused*/),
           .in_agg_cg_comp_wr_all(/*unused*/),
           .in_agg_cg_comp_wr_all_top_or_bot(/*unused*/),
           .in_agg_del_cond_met_0(/*unused*/),
           .in_agg_del_cond_met_0_top_or_bot(/*unused*/),
           .in_agg_en_dskw_qd(/*unused*/),
           .in_agg_en_dskw_qd_top_or_bot(/*unused*/),
           .in_agg_en_dskw_rd_ptrs(/*unused*/),
           .in_agg_en_dskw_rd_ptrs_top_or_bot(/*unused*/),
           .in_agg_fifo_ovr_0(/*unused*/),
           .in_agg_fifo_ovr_0_top_or_bot(/*unused*/),
           .in_agg_fifo_rd_in_comp_0(/*unused*/),
           .in_agg_fifo_rd_in_comp_0_top_or_bot(/*unused*/),
           .in_agg_fifo_rst_rd_qd(/*unused*/),
           .in_agg_fifo_rst_rd_qd_top_or_bot(/*unused*/),
           .in_agg_insert_incomplete_0(/*unused*/),
           .in_agg_insert_incomplete_0_top_or_bot(/*unused*/),
           .in_agg_latency_comp_0(/*unused*/),
           .in_agg_latency_comp_0_top_or_bot(/*unused*/),
           .in_agg_rcvd_clk_agg(/*unused*/),
           .in_agg_rcvd_clk_agg_top_or_bot(/*unused*/),
           .in_agg_rx_control_rs(/*unused*/),
           .in_agg_rx_control_rs_top_or_bot(/*unused*/),
           .in_agg_rx_data_rs(/*unused*/),
           .in_agg_rx_data_rs_top_or_bot(/*unused*/),
           .in_agg_testbus(/*unused*/),
           .in_agg_tx_ctl_ts(/*unused*/),
           .in_agg_tx_ctl_ts_top_or_bot(/*unused*/),
           .in_agg_tx_data_ts(/*unused*/),
           .in_agg_tx_data_ts_top_or_bot(/*unused*/),
           .in_pld_8g_refclk_dig2(/*unused*/),
           .in_pld_8g_refclk_dig(/*unused*/),
           .in_pld_agg_refclk_dig(/*unused*/),
           .in_pld_partial_reconfig_in({num_bonded{1'b1}})
           
           );

       end // block: gen_bonded_group_native

     end // block: xcvr_native_insts
      
   end // block: gen_native_inst
   endgenerate
   
   // Merge critical reconfig signals
   sv_reconfig_bundle_merger 
     #(
       .reconfig_interfaces(reconfig_interfaces)
       ) sv_reconfig_bundle_merger_inst 
       (
    // Reconfig buses to/from reconfig controller
    .rcfg_reconfig_to_xcvr  (reconfig_to_xcvr   ),
    .rcfg_reconfig_from_xcvr(reconfig_from_xcvr ),
    
    // Reconfig buses to/from native xcvr
    .xcvr_reconfig_to_xcvr  (rcfg_to_xcvr   ),
    .xcvr_reconfig_from_xcvr(rcfg_from_xcvr )
    );
   
   
endmodule // altera_xcvr_native_sv






