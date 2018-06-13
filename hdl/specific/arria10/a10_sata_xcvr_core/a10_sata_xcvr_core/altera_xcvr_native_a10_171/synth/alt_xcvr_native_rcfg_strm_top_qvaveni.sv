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


//**********************************************************************************
// Top-level streamer, containing configuration rom and streamer control block
//**********************************************************************************

`timescale 1 ns / 1 ps


import alt_xcvr_native_rcfg_strm_functions::*;
import alt_xcvr_native_rcfg_strm_params_qvaveni::*;

module alt_xcvr_native_rcfg_strm_top_qvaveni #(
  parameter rcfg_rom_style        = "LOGIC",           //Type of inferred rom ("", "MLAB", or "M20K")
  parameter rcfg_profile_cnt      = 2,                //Number of configuration profiles
  parameter rom_data_width        = 26,               //ROM data width
  parameter addr_mode             = 1,                //0=word addressing, 1=byte addressing
  parameter xcvr_rcfg_if_type     = "channel",        //Reconfig interface type: "channel", "atx", "fpll", "cmu"
  parameter xcvr_rcfg_addr_width  = 10,               //XCVR RCFG address width
  parameter xcvr_rcfg_data_width  = 32,               //XCVR RCFG data width
  parameter xcvr_dprio_data_width = 8,                //XCVR DPRIO data width
  parameter xcvr_rcfg_interfaces  = 3,                //Number of reconfig interfaces in the xcvr 
  parameter xcvr_rcfg_shared      = 0                 //Reconfig interface is shared or independent
)(
  // Clock and reset
  input  wire clk,
  input  wire reset,

  // User interfce ports
  input  wire [xcvr_rcfg_interfaces*(altera_xcvr_native_a10_functions_h::clogb2_alt_xcvr_native_a10(rcfg_profile_cnt-1))-1:0]  cfg_sel,
  input  wire [xcvr_rcfg_interfaces-1:0]    bcast_en,  //Configure all channels simultaneously, works only with independent interface
  input  wire [xcvr_rcfg_interfaces-1:0]    cfg_load,
  output reg  [xcvr_rcfg_interfaces-1:0]    chan_sel = {{(xcvr_rcfg_interfaces-1){1'b0}},1'b1},
  output wire [xcvr_rcfg_interfaces-1:0]    stream_busy,

  // HSSI Reconfig Interface
  output wire [(xcvr_rcfg_shared ? 1 : xcvr_rcfg_interfaces)-1:0]                          xcvr_reconfig_write,
  output wire [(xcvr_rcfg_shared ? 1 : xcvr_rcfg_interfaces)-1:0]                          xcvr_reconfig_read,
  output wire [(xcvr_rcfg_shared ? (xcvr_rcfg_addr_width+altera_xcvr_native_a10_functions_h::clogb2_alt_xcvr_native_a10(xcvr_rcfg_interfaces-1)) : 
                                         (xcvr_rcfg_addr_width*xcvr_rcfg_interfaces))-1:0] xcvr_reconfig_address,
  output wire [(xcvr_rcfg_shared ? 1 : xcvr_rcfg_interfaces)*xcvr_rcfg_data_width-1:0]     xcvr_reconfig_writedata,
  input  wire [(xcvr_rcfg_shared ? 1 : xcvr_rcfg_interfaces)*xcvr_rcfg_data_width-1:0]     xcvr_reconfig_readdata,
  input  wire [(xcvr_rcfg_shared ? 1 : xcvr_rcfg_interfaces)-1:0]                          xcvr_reconfig_waitrequest

);

  localparam cfg_addr_width = altera_xcvr_native_a10_functions_h::clogb2_alt_xcvr_native_a10(get_max_value(rcfg_profile_cnt, rcfg_cfg_depths)-1); //Maximum ROM address width

  wire [cfg_addr_width-1:0]                   cfg_address;
  wire [rom_data_width-1:0]                   rom_readdata;
  reg  [(altera_xcvr_native_a10_functions_h::clogb2_alt_xcvr_native_a10(rcfg_profile_cnt-1))-1:0]     r_cfg_sel   = {(altera_xcvr_native_a10_functions_h::clogb2_alt_xcvr_native_a10(rcfg_profile_cnt-1)){1'b0}};
  reg                                         r_bcast_en  = 1'b0;
  reg                                         r_cfg_load  = 1'b0;
  reg  [31:0]                                 if_sel      = 32'b0; //Declared as 32-bit as altera_xcvr_native_a10_functions_h::clogb2_alt_xcvr_native_a10 returns integer. It is appropriately optimized by the synthesis tool.
  reg  [xcvr_rcfg_interfaces-1:0]             if_sel_mask = {xcvr_rcfg_interfaces{1'b0}};
  reg                                         if_sel_lock = 1'b0;
 
  reg  [xcvr_rcfg_interfaces-1:0]             if_sel_mask_tmp = {{(xcvr_rcfg_interfaces-1){1'b0}},1'b1};
  
  always @ (*) begin
   chan_sel         = {{(xcvr_rcfg_interfaces-1){1'b0}},1'b1} << if_sel; // Feedback to soft CSR (request from this channel is being serviced), used to reset corresponding cfg_load bit
   if_sel_mask_tmp  = (if_sel_mask | chan_sel); // Update the mask to keep track of which requests have recently been serviced and mask out repeated requests from the cfg_load bus
  end

  // Logic to generate if_sel
  always @ (posedge clk or posedge reset) begin
    if (reset) begin
      if_sel      <= 32'b0;
      if_sel_mask <= {xcvr_rcfg_interfaces{1'b0}};
      if_sel_lock <= 1'b0;
    end else begin
      if(~|stream_busy & |cfg_load & ~if_sel_lock) begin                                // Check if previous reconfig operation is complete and there are any other requests pending
        if((cfg_load & ~if_sel_mask_tmp) == {xcvr_rcfg_interfaces{1'b0}}) begin
          if_sel_mask <= {xcvr_rcfg_interfaces{1'b0}};                                  // Reset the mask if this round of reconfigurations is complete (all requests have been handled or there are only new requests to channels that have already been serviced)
          if_sel <= altera_xcvr_native_a10_functions_h::clogb2_alt_xcvr_native_a10(cfg_load) - {{(xcvr_rcfg_interfaces-1){1'b0}},1'b1}; // Reset if_sel to current cfg_load if this is not one of the pending transactions
        end else begin
          if_sel_mask <= if_sel_mask_tmp;
          if_sel <= altera_xcvr_native_a10_functions_h::clogb2_alt_xcvr_native_a10(cfg_load & ~if_sel_mask_tmp & ((~cfg_load | if_sel_mask_tmp) + 1)) - {{(xcvr_rcfg_interfaces-1){1'b0}},1'b1}; // Select the next request to service based on round-robin scheduling (less significant cfg_load bit = higher priority)
        end
        if_sel_lock <= 1'b1;                                                            // Lock to prevent if_sel changing again prematurely (after if_sel is set but before stream_busy goes high)
      end else if(|stream_busy & if_sel_lock) begin
        if_sel_lock <= 1'b0;                                                            // Reset the lock when stream busy goes high
      end
    end
  end

  // Register the control signals
   always @ (posedge clk or posedge reset) begin
    if (reset) begin
      r_cfg_sel  <= {(altera_xcvr_native_a10_functions_h::clogb2_alt_xcvr_native_a10(rcfg_profile_cnt-1)){1'b0}};
      r_bcast_en <= 1'b0;
      r_cfg_load <= 1'b0;
    end
    else begin
      if(cfg_load[if_sel] & ~stream_busy[if_sel]) begin
        r_cfg_sel  <= cfg_sel[(altera_xcvr_native_a10_functions_h::clogb2_alt_xcvr_native_a10(rcfg_profile_cnt-1))*if_sel +: (altera_xcvr_native_a10_functions_h::clogb2_alt_xcvr_native_a10(rcfg_profile_cnt-1))];
        r_bcast_en <= bcast_en[if_sel];
        r_cfg_load <= 1'b1;
      end else if(r_cfg_load)
        r_cfg_load <= 1'b0;
    end
  end

  // Rom to store the reconfiguration settings
  alt_xcvr_native_rcfg_strm_rom_qvaveni #(
    .rcfg_rom_style            (rcfg_rom_style           ),
    .rcfg_profile_cnt          (rcfg_profile_cnt         )
  )rom_inst(
    .clk                       (clk                      ),
    .cfg_sel                   (r_cfg_sel                ),
    .addr                      (cfg_address              ),
    .data                      (rom_readdata             )
  );

  // Streamer control block
  alt_xcvr_native_rcfg_strm_ctrl #(
    .cfg_addr_width            (cfg_addr_width           ),
    .rom_data_width            (rom_data_width           ),
    .addr_mode                 (addr_mode                ),
    .xcvr_rcfg_if_type         (xcvr_rcfg_if_type        ),
    .xcvr_rcfg_addr_width      (xcvr_rcfg_addr_width     ),
    .xcvr_rcfg_data_width      (xcvr_rcfg_data_width     ),
    .xcvr_dprio_data_width     (xcvr_dprio_data_width    ),
    .xcvr_rcfg_interfaces      (xcvr_rcfg_interfaces     ),
    .xcvr_rcfg_shared          (xcvr_rcfg_shared         )
  )ctrl_inst(
    .clk                       (clk                      ),
    .reset                     (reset                    ),
    .cfg_load                  (r_cfg_load               ),
    .stream_busy               (stream_busy              ),
    .if_sel                    (if_sel                   ),
    .bcast_en                  (r_bcast_en               ),
    .cfg_address               (cfg_address              ),
    .rom_readdata              (rom_readdata             ),
    .xcvr_reconfig_write       (xcvr_reconfig_write      ),
    .xcvr_reconfig_read        (xcvr_reconfig_read       ),
    .xcvr_reconfig_address     (xcvr_reconfig_address    ), 
    .xcvr_reconfig_writedata   (xcvr_reconfig_writedata  ),
    .xcvr_reconfig_readdata    (xcvr_reconfig_readdata   ),
    .xcvr_reconfig_waitrequest (xcvr_reconfig_waitrequest)
  );

endmodule

