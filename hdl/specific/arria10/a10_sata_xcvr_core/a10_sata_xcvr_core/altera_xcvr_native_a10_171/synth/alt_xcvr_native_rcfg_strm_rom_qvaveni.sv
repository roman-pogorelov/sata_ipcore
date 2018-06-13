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
// Synchronous ROM for storing multiple configurations
//**********************************************************************************
`timescale 1 ps/1 ps

import alt_xcvr_native_rcfg_strm_functions::*;
import alt_xcvr_native_rcfg_strm_params_qvaveni::*;

module alt_xcvr_native_rcfg_strm_rom_qvaveni #(
  parameter rcfg_rom_style   = "LOGIC",           //Type of inferred rom ("", "MLAB", or "M20K")
  parameter rcfg_profile_cnt = 2                  //Number of configerations in file
)(
  input  wire                                                                  clk,
  input  wire [(altera_xcvr_native_a10_functions_h::clogb2_alt_xcvr_native_a10(rcfg_profile_cnt-1))-1:0]                               cfg_sel, //Selects a single configuration
  input  wire [altera_xcvr_native_a10_functions_h::clogb2_alt_xcvr_native_a10(get_max_value(rcfg_profile_cnt, rcfg_cfg_depths)-1)-1:0] addr,    //Address within the particular configuration (not rom address)
  output reg  [rom_data_width-1:0]                                             data
);

  localparam rom_addr_width  = altera_xcvr_native_a10_functions_h::clogb2_alt_xcvr_native_a10(rom_depth-1); //Calculate address width

  wire [31:0]                rom_addr_long;
  wire [rom_addr_width-1:0]  rom_addr;

  assign rom_addr_long = get_sum(cfg_sel, rcfg_cfg_depths) + addr; //Calculate rom address using sum of preceding configuration depths and address within current configuration
  assign rom_addr      = rom_addr_long[rom_addr_width-1:0];        //Truncate rom address to correct width

  (* romstyle = rcfg_rom_style *) reg [rom_data_width-1:0] rom [0:rom_depth-1]; //Inferred rom

  initial begin
    rom = config_rom;
  end

  always @ (posedge clk) begin
    data <= rom[rom_addr]; //Synchronously read data from rom
  end

endmodule

