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


//***********************************************************************************************
// Reconfig ROM parser 
// Parses the ROM contents 
// Generates DPRIO address and control signals for a single xcvr interface
//   - Performs writes for incoming direct XCVR offsets/data/mask
//   - Performs RMW for incoming direct XCVR offsets/data/mask
//   - Performs RMW for handling logical refclk select and logical PLL (CGB) select
//***********************************************************************************************

`timescale 1 ns / 1 ps

import alt_xcvr_native_rcfg_strm_functions::*;


module alt_xcvr_native_rcfg_strm_ctrl #(
  parameter cfg_addr_width        = 16,        // Address width within a single configuration in the rom
  parameter rom_data_width        = 26,        // Width of the ROM
  parameter addr_mode             = 1,         // 0=word addressing, 1=byte addressing
  parameter xcvr_rcfg_if_type     = "channel", // Reconfig interface type: "channel", "atx", "fpll", "cmu"
  parameter xcvr_rcfg_addr_width  = 10,        // XCVR RCFG address width
  parameter xcvr_rcfg_data_width  = 32,        // XCVR RCFG data width
  parameter xcvr_dprio_data_width = 8,         // XCVR DPRIO data width
  parameter xcvr_rcfg_interfaces  = 1,         // Number of reconfig interfaces in the xcvr 
  parameter xcvr_rcfg_shared      = 0          // Reconfig interface is shared or independent
) (
  input wire clk,
  input wire reset,
  
  //--------------------------------------
  // User Interface
  //--------------------------------------
  input  wire [altera_xcvr_native_a10_functions_h::clogb2_alt_xcvr_native_a10(xcvr_rcfg_interfaces-1) -1:0]               if_sel,      //Select one of the interfaces
  input  wire                                                     bcast_en,    //Configure all channels simultaneously
  input  wire                                                     cfg_load,
  output wire [(xcvr_rcfg_shared ? 1 : xcvr_rcfg_interfaces)-1:0] stream_busy,  
 
  //input wire [1:0] if_type,
  //--------------------------------------
  // Config ROM Interface
  //--------------------------------------
  output reg  [cfg_addr_width-1:0] cfg_address,   
  input  wire [rom_data_width-1:0] rom_readdata,
   
  //------------------------------------------------
  // HSSI Reconfig Interface
  // Multiple interfaces
  //------------------------------------------------
  output wire [(xcvr_rcfg_shared ? 1 : xcvr_rcfg_interfaces)-1:0]                           xcvr_reconfig_write,
  output wire [(xcvr_rcfg_shared ? 1 : xcvr_rcfg_interfaces)-1:0]                           xcvr_reconfig_read,
  output wire [(xcvr_rcfg_shared ? (xcvr_rcfg_addr_width+altera_xcvr_native_a10_functions_h::clogb2_alt_xcvr_native_a10(xcvr_rcfg_interfaces-1)) : 
                                         (xcvr_rcfg_addr_width*xcvr_rcfg_interfaces))-1:0]  xcvr_reconfig_address, 
  output wire [(xcvr_rcfg_shared ? 1 : xcvr_rcfg_interfaces)*xcvr_rcfg_data_width-1:0]      xcvr_reconfig_writedata,
  input  wire [(xcvr_rcfg_shared ? 1 : xcvr_rcfg_interfaces)*xcvr_rcfg_data_width-1:0]      xcvr_reconfig_readdata,
  input  wire [(xcvr_rcfg_shared ? 1 : xcvr_rcfg_interfaces)-1:0]                           xcvr_reconfig_waitrequest

);


  //End of MIF
  localparam [rom_data_width-1:0] EOM = {rom_data_width{1'b1}};

  // Parser states
  localparam [2:0] IDLE       = 3'h0;
  localparam [2:0] ROM_READ   = 3'h1;
  localparam [2:0] XCVR_READ  = 3'h2;
  localparam [2:0] XCVR_WRITE = 3'h3;

  //Interface types
  localparam [1:0] CHANNEL    = 2'd0;
  localparam [1:0] ATX_PLL    = 2'd1;
  localparam [1:0] FPLL       = 2'd2;

  localparam total_dprio_data_width = (xcvr_rcfg_shared ? 1 : xcvr_rcfg_interfaces)*xcvr_dprio_data_width;
  localparam total_dprio_addr_width = (xcvr_rcfg_shared ? 1 : xcvr_rcfg_interfaces)*xcvr_rcfg_addr_width;

  reg busy;

  // state machine declarations
  reg [2:0]  next_state;
  reg [2:0]  state;

  wire [1:0] addr_incr;

  wire rom_data_valid;
  reg  rom_read;
  reg  rom_read_r;

  wire  [xcvr_dprio_data_width-1:0] writedata_from_rom;
  wire  [xcvr_dprio_data_width-1:0] datamask_from_rom;
  wire [total_dprio_data_width-1:0] extended_writedata_from_rom;
  wire [total_dprio_data_width-1:0] extended_datamask_from_rom;

  reg  [total_dprio_data_width-1:0] saved_readdata;
  wire [total_dprio_data_width-1:0] modify_data;
  wire [total_dprio_data_width-1:0] reconfig_writedata;
  wire [total_dprio_data_width-1:0] reduced_reconfig_readdata;

  reg                               reconfig_write;
  reg                               reconfig_read;
  wire [xcvr_rcfg_addr_width-1:0]   reconfig_address;
  wire                              reconfig_waitrequest;
 
  assign reconfig_address            = rom_readdata[(xcvr_rcfg_addr_width+2*xcvr_dprio_data_width-1):(2*xcvr_dprio_data_width)];
  assign writedata_from_rom          = rom_readdata[xcvr_dprio_data_width-1:0];
  assign datamask_from_rom           = rom_readdata[xcvr_dprio_data_width +: xcvr_dprio_data_width];
  assign extended_writedata_from_rom = {(xcvr_rcfg_shared ? 1 : xcvr_rcfg_interfaces){writedata_from_rom}};
  assign extended_datamask_from_rom  = {(xcvr_rcfg_shared ? 1 : xcvr_rcfg_interfaces){datamask_from_rom}};
  assign reconfig_writedata          = (~&datamask_from_rom) ? modify_data : {(xcvr_rcfg_shared ? 1 : xcvr_rcfg_interfaces){writedata_from_rom}};

  genvar ig;
  generate
    if (xcvr_rcfg_shared) begin
      assign xcvr_reconfig_write   = reconfig_write;
      assign xcvr_reconfig_read    = reconfig_read;
      assign xcvr_reconfig_address = {if_sel,reconfig_address};
      assign reconfig_waitrequest  = xcvr_reconfig_waitrequest;
      assign xcvr_reconfig_writedata = {24'b0,reconfig_writedata};
      assign reduced_reconfig_readdata = xcvr_reconfig_readdata[7:0];
		assign stream_busy           = busy;
    end else begin 
      for(ig=0;ig<xcvr_rcfg_interfaces;ig=ig+1) begin : g_ifs
        assign xcvr_reconfig_write [ig]  = (bcast_en || (if_sel == ig)) ? reconfig_write : 1'b0;
        assign xcvr_reconfig_read  [ig]  = (bcast_en || (if_sel == ig)) ? reconfig_read  : 1'b0;
        assign stream_busy         [ig]  = (bcast_en || (if_sel == ig)) ? busy           : 1'b0;
        assign xcvr_reconfig_writedata [ig*32 +: 32] = {24'b0, reconfig_writedata[ig*xcvr_dprio_data_width +: xcvr_dprio_data_width]};
        assign reduced_reconfig_readdata  [ig*8 +: 8]= xcvr_reconfig_readdata[ig*32 +: 8];
      end
      assign xcvr_reconfig_address  = {xcvr_rcfg_interfaces{reconfig_address}};
      assign reconfig_waitrequest  = bcast_en ? |xcvr_reconfig_waitrequest : xcvr_reconfig_waitrequest[if_sel];
    end
  endgenerate
 
 
 
  //*********************************************************************
  //*************************Parser State Machine************************
  // next state logic
  always @ (*) begin
    case(state)
      IDLE: begin
        if(cfg_load) 
           next_state = ROM_READ;
        else    
          next_state = IDLE;
      end
      ROM_READ: begin
        if(!rom_data_valid)
          next_state = ROM_READ;
        else if (rom_readdata == EOM)
          next_state = IDLE;
        else if (&datamask_from_rom)
          next_state = XCVR_WRITE; // Datamask = FF => Direct Write
        else
          next_state = XCVR_READ; // Datamask != FF => Read-Modify-Write
      end
      XCVR_READ: begin
        if (reconfig_waitrequest)
          next_state = XCVR_READ;
        else 
          next_state = XCVR_WRITE;
      end  
      XCVR_WRITE: begin
        if (reconfig_waitrequest)
          next_state = XCVR_WRITE;
        else 
          next_state = ROM_READ;
      end
      default: next_state = IDLE;
    endcase 
  end

  // state register
  always @(posedge clk or posedge reset)
  begin
    if (reset) 
      state <= IDLE;
    else 
      state <= next_state;
  end

  //*********************************************************************
  //*****************Parser output and internal storage******************
  always @(posedge clk or posedge reset)
  begin
    if (reset) begin
      rom_read           <= 1'b0;
      reconfig_write     <= 1'b0;
      reconfig_read      <= 1'b0;
      cfg_address        <= {cfg_addr_width{1'b0}};
    end
    else begin
      //Address and read for the ROM
      rom_read           <= (next_state == ROM_READ);
      reconfig_write     <= (next_state == XCVR_WRITE);
      reconfig_read      <= (next_state == XCVR_READ);

      // Do not increment for the first read
      cfg_address        <= ((state == XCVR_WRITE) && (next_state == ROM_READ)) ? (cfg_address+addr_incr) :
                                                      (next_state == IDLE)      ? {cfg_addr_width{1'b0}} :
                                                                                  cfg_address;
    end
  end

  //select between word/byte addressing
  assign addr_incr = addr_mode ? 2'd1 : 2'd2; //default to byte addressing 

  //*********************************************************************
  //******************** rom_read and rom_data_valid *********************
  always @ (posedge clk)
    rom_read_r <= rom_read;

  assign rom_data_valid  = rom_read_r & rom_read;

  //*********************************************************************
  //************************** stream_busy*******************************
  always @(posedge clk or posedge reset)
  begin
    if (reset)
      busy <= 1'd0;
    else begin
      if (cfg_load)
        busy <= 1'b1; 
      else if (next_state == IDLE) 
        busy <= 1'b0; 
        //else no change
    end
  end

  //**********************************************************************
  //********************** Save and modify data **************************
  // Save readata for modification
  always @ (posedge clk or posedge reset)
  begin
    if (reset)
      saved_readdata  <= {total_dprio_data_width{1'b0}}; 
    else if (next_state == XCVR_WRITE && !reconfig_waitrequest)
      saved_readdata  <= reduced_reconfig_readdata; 
  end

  // ****** Other DPRIO modified data - applying the mask ******
  assign modify_data  = (saved_readdata & ~extended_datamask_from_rom) | (extended_writedata_from_rom & extended_datamask_from_rom);

endmodule
