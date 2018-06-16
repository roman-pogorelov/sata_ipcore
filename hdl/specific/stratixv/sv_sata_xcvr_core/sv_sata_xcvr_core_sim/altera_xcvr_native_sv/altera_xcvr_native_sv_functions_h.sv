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


//
// Common functions for Stratix V Native PHY IP
//

import altera_xcvr_functions::*;

  
package altera_xcvr_native_sv_functions_h;

    localparam integer MAX_CHAR = 32;
    localparam integer MAX_STR = 16;

    //-----------------------------
    // General purpose functions
    //-----------------------------
    function [MAX_CHAR*8-1:0] set_lcl_true_false (
        input integer enable
    );
       set_lcl_true_false =  (enable == 1) ? "true" : "false";
    endfunction

    function [MAX_CHAR*8-1:0] set_lcl_enable_cond (
        input integer enable,
        input [8*MAX_CHAR:1] enable_string,
        input [8*MAX_CHAR:1] diable_string
    );
       set_lcl_enable_cond =  (enable == 1) ? enable_string : diable_string;
    endfunction

    function [MAX_CHAR*8-1:0] set_lcl_enable_2lvl (
        input integer cond_1,
        input integer cond_2
    );
       set_lcl_enable_2lvl =  cond_1 ? (cond_2 ? "true" : "false") : "false";
    endfunction

    // function to convert at most 40-bit long string to hex
   function [39 : 0] m_str_to_hex;
       input [40*8 : 1] s;
       reg   [40*8 : 1] reg_s;
       reg   [40:1]     res;
   
       integer m;
       begin
         
           reg_s = s;
           for (m = 40; m > 0; m = m-1 )
           begin
               res[m] = reg_s[313];
               reg_s = reg_s << 8;
           end
             
           m_str_to_hex = res;
       end   
   endfunction

    //-----------------------------
    // PMA direct paramaters
    //-----------------------------

// pma_prot_mode legal values are -  (basic,cpri,cpri_rx_tx,disabled_prot_mode,gige, pipe_g1,pipe_g2,pipe_g3,srio_2p1,test,xaui)
    function [MAX_CHAR*8-1:0] set_pma_prot_mode (
        input [MAX_CHAR*8-1:0]  data_path_select,
        input [MAX_CHAR*8-1:0]  std_protocol_hint,
        input [MAX_CHAR*8-1:0]  teng_protocol_hint,
        input [MAX_CHAR*8-1:0]  std_rx_word_aligner_mode
    );
      set_pma_prot_mode = (data_path_select == "standard") ? 
                          (std_protocol_hint == "basic" ? "basic" : 
                           std_protocol_hint == "gige"  ? "gige"  : 
                           std_protocol_hint == "cpri"  ? (std_rx_word_aligner_mode == "manual" ? "cpri_rx_tx" :"cpri") :
                           std_protocol_hint) :
                          (data_path_select == "10G") ? "basic":  
                          "basic";
    endfunction

    function integer set_pma_mode (
        input integer pma_width
    );
        set_pma_mode = pma_width;
    endfunction

    function [MAX_CHAR*8-1:0] set_ppm_thresh (
        input [8*MAX_CHAR:1] user_ppm
    );
      set_ppm_thresh = (user_ppm == "1000") ? "ppmsel_1000" : 
                       (user_ppm == "500")  ? "ppmsel_500"  :
                       (user_ppm == "300")  ? "ppmsel_300"  :
                       (user_ppm == "250")  ? "ppmsel_250"  :                  
                       (user_ppm == "200")  ? "ppmsel_200"  :
                       (user_ppm == "125")  ? "ppmsel_125"  :
                       (user_ppm == "100")  ? "ppmsel_100"  :
                       (user_ppm == "62")   ? "ppmsel_62p5" : "ppmsel_default";
    endfunction

    function [MAX_CHAR*8-1:0] set_pma_clkslip (
        input [8*MAX_CHAR:1] mode
    );
      set_pma_clkslip = (mode == "cpri")? "slip_eight_g_pcs": "pld";
    endfunction


    //-----------------------------
    // Standard PCS parameter mapping
    //-----------------------------
    function [MAX_CHAR*8-1:0] set_std_prot_mode (
        input [8*MAX_CHAR:1] protocol_hint
    );
      set_std_prot_mode =   (protocol_hint == "basic")     ? "basic"    : 
                            (protocol_hint == "cpri")      ? "cpri"     :
                            (protocol_hint == "gige")      ? "gige"     :
                            (protocol_hint == "srio_2p1")  ? "srio_2p1" : "basic";
    endfunction

    function [MAX_CHAR*8-1:0] set_std_pcs_pma_dw (
        input integer width
    );
      set_std_pcs_pma_dw = (width == 8)  ? "eight_bit" :
                           (width == 10) ? "ten_bit" :
                           (width == 16) ? "sixteen_bit" :
                           (width == 20) ? "twenty_bit" : "invalid";
    endfunction


    ///
    // Determine byte_order parameter value
    // @param bo_enable - Byte order block enable
    // @param bo_mode - Byte order mode
    // @param bo_width - Byte order symbol width
    function [MAX_CHAR*8-1:0] set_rx_byte_order (
        input integer bo_enable,
        input [8*MAX_CHAR:1] bo_mode,
        input integer bo_width
    );
       set_rx_byte_order = (bo_enable == 0) ? "dis_bo"
                         : (bo_mode == "manual" && bo_width == 8)  ? "en_pld_ctrl_eight_bit_bo"
                         : (bo_mode == "manual" && bo_width == 9)  ? "en_pld_ctrl_nine_bit_bo"
                         : (bo_mode == "manual" && bo_width == 10) ? "en_pld_ctrl_ten_bit_bo"
                         : (bo_mode == "auto"   && bo_width == 8)  ? "en_pcs_ctrl_eight_bit_bo"
                         : (bo_mode == "auto"   && bo_width == 9)  ? "en_pcs_ctrl_nine_bit_bo"
                         : (bo_mode == "auto"   && bo_width == 10) ? "en_pcs_ctrl_ten_bit_bo"
                         : "dis_bo";
    endfunction


    ///
    // Determine dw_one_or_two_symbol_bo parameter value
    // @param bo_enable - Byte order block enable
    // @param bo_width - Byte order symbol width
    // @param bo_symbol_count - Byte order symbol count
    // @param pma_width - 8G PCS / PMA width
    function [MAX_CHAR*8-1:0] set_std_rx_dw_one_or_two_symbol_bo (
        input integer bo_enable,
        input integer bo_width,
        input integer bo_symbol_count,
        input integer pma_width
    );
        set_std_rx_dw_one_or_two_symbol_bo  = (bo_enable == 1 && pma_width == 16)                   ? bo_symbol_count == 1 ? "one_symbol_bo" : "two_symbol_bo_eight_bit"
                                            : (bo_enable == 1 && pma_width == 20 && bo_width == 9)  ? bo_symbol_count == 1 ? "one_symbol_bo" : "two_symbol_bo_nine_bit"
                                            : (bo_enable == 1 && pma_width == 20 && bo_width == 10) ? bo_symbol_count == 1 ? "one_symbol_bo" : "two_symbol_bo_ten_bit"
                                            : "donot_care_one_two_bo";
    endfunction



    ///
    //
    function [MAX_CHAR*8-1:0] set_std_wa_boundary_lock_ctrl (
      input [MAX_CHAR*8:1]  std_protocol_hint,
      input [MAX_CHAR*8:1]  std_rx_word_aligner_mode
    );
      set_std_wa_boundary_lock_ctrl = (std_protocol_hint == "cpri" && std_rx_word_aligner_mode == "sync_sm") ? "deterministic_latency"
                                      : (std_rx_word_aligner_mode == "manual")  ? "auto_align_pld_ctrl"
                                      : (std_rx_word_aligner_mode == "sync_sm") ? "sync_sm"
                                      : "bit_slip";

    endfunction


   function [MAX_CHAR*8-1:0] set_wa_pd (
    input [8*MAX_CHAR:1]    mode,
    input integer 	    length,
    input integer 	    width,
    input [8*MAX_CHAR:1]    prot
					);
      set_wa_pd = (mode == "bit_slip") ? "<auto_single>" :
      		  (prot == "gige" || prot == "xaui" || prot == "srio_2p1") ? 
		  ((length == 7) ? "wa_pd_fixed_7_k28p5" :
		   (length == 10) ? "wa_pd_fixed_10_k28p5" : "wa_pd_fixed_7_k28p5") :
		  (prot == "basic") ? 
                  ((length == 7)   ? "wa_pd_7" :
                   (length == 8)   ? ((width == 8) ? "wa_pd_8_sw" : "wa_pd_8_dw") :
                   (length == 10)  ? "wa_pd_10" :
                   (length == 16)  ? ((width == 8) ? "wa_pd_16_sw" : "wa_pd_16_dw") :
		   (length == 20)  ? "wa_pd_20" :
                   (length == 32)  ? "wa_pd_32" :
                   (length == 40)  ? "wa_pd_40" : "wa_pd_7") : "wa_pd_fixed_10_k28p5";
   endfunction
   


   
    function [MAX_CHAR*8-1:0] set_wa_cpri_auto (
        input [8*MAX_CHAR:1] prot
    );
      set_wa_cpri_auto =   (prot == "cpri") ? "<auto_any>" : "<auto_single>";
    endfunction

    function [MAX_CHAR*8-1:0] set_std_rmfifo_mode (
        input integer enable,
        input [8*MAX_CHAR:1] prot, 
        input integer width
    );
        set_std_rmfifo_mode = (enable == 1) ? ((prot == "gige") ? "gige_rm" :
                                              (prot == "srio_2p1")? "srio_v2p1_rm_0ppm" :
                                              (width == 20 || width == 16) ? "dw_basic_rm" : "sw_basic_rm") : "dis_rm";
    endfunction

    function [MAX_CHAR*8-1:0] set_std_runlength (
        input integer width
    );
        set_std_runlength = (width == 8 || width == 10) ? "en_runlength_sw" : "en_runlength_dw";
    endfunction 

    function [MAX_CHAR*8-1:0] set_lcl_pld_pcs_if_testbus_sel (
        input [MAX_CHAR*8-1:0]  data_path_select
    );
      set_lcl_pld_pcs_if_testbus_sel = (data_path_select == "standard") ? "eight_g_pcs"  :
                          (data_path_select == "10G")      ? "ten_g_pcs" :  
                          "<auto_single>";
    endfunction

    //-----------------------------
    // 10G PCS parameter mapping
    //-----------------------------
    localparam lp_rx_control_max_width = 10;
    localparam lp_tx_control_max_width = 9;

    //protocol mode
    function [MAX_CHAR*8-1:0] set_10g_prot_mode (
        input [8*MAX_CHAR:1] protocol_hint
    );
      set_10g_prot_mode = (protocol_hint == "basic")      ? "basic_mode"      : 
                          (protocol_hint == "teng_baser") ? "teng_baser_mode" : 
                          (protocol_hint == "sfis")       ? "sfis_mode"       : 
                          (protocol_hint == "interlaken") ? "interlaken_mode" : 
                          (protocol_hint == "teng_sdi")   ? "teng_sdi_mode"   :
                          (protocol_hint == "teng_1588")  ? "teng_1588_mode"  : protocol_hint; 
    endfunction

    //gearbox settings
    function [MAX_CHAR*8-1:0] set_10g_gearbox_pma_width (
        input integer width
    );
      set_10g_gearbox_pma_width = (width == 64)? "width_64" :
                                  (width == 40)? "width_40" :
                                  (width == 32)? "width_32" : "width_40"; 
    endfunction

    function [MAX_CHAR*8-1:0] set_10g_gearbox_pld_width (
        input integer width
    );
      set_10g_gearbox_pld_width = (width == 32) ? "width_32" :
                                  (width == 40) ? "width_40" :
                                  (width == 64) ? "width_64" :
                                  (width == 66) ? "width_66" : "<auto_single>"; 
    endfunction
    
    function [MAX_CHAR*8-1:0] set_10g_tx_fifo_mode (
        input [8*MAX_CHAR:1] mode //register|clk_comp|generic
    );
      set_10g_tx_fifo_mode = (mode == "phase_comp")  ? "phase_comp" : 
                             (mode == "clk_comp")    ? "clk_comp" :
                             (mode == "generic")     ? "basic_generic" :
                             (mode == "register")    ? "register_mode" : 
                             (mode == "interlaken")  ? "interlaken_generic" : "phase_comp";
    endfunction

    function [MAX_CHAR*8-1:0] set_10g_rx_fifo_mode (
        input [8*MAX_CHAR:1] mode //register|clk_comp|generic
    );
      set_10g_rx_fifo_mode = (mode == "phase_comp")  ? "phase_comp" : 
                             (mode == "clk_comp")    ? "clk_comp_10g" :
                             (mode == "generic")     ? "generic_basic" :
                             (mode == "register")    ? "register_mode" : 
                             (mode == "interlaken")  ? "generic_interlaken" : "phase_comp";
    endfunction

    function [MAX_CHAR*8-1:0] set_10g_scrm_mode (
        input [8*MAX_CHAR:1] scrm_mode
    );
      set_10g_scrm_mode = (scrm_mode == "user") ? "scram_seed_user_setting" : 
                          (scrm_mode == "min")  ? "scram_seed_min" :
                          (scrm_mode == "max")  ? "scram_seed_max" : "<auto_single>";
    endfunction

    function [MAX_CHAR*8-1:0] set_gb_synchdr_location (
        input [8*MAX_CHAR:1] protocol_hint,
        input [8*MAX_CHAR:1] user_loc
    );
      set_gb_synchdr_location = (protocol_hint == "teng_baser") ? "lsb" : 
                                (protocol_hint == "interlaken") ? "msb" : user_loc; 
    endfunction // set_gb_synchdr_location


   

   ////////////////////////////////////////////////////////////////////
      // Get number of reconfig interfaces for native PHY
  //
  // @param device_family - Desired device family
  // @param operation_mode - "Duplex","Rx","Tx" or "duplex", "rx_only", "tx_only" in 10gbaser
  // @param lanes - Number of channels
  // @param plls - Number of TX plls (per channel)
  // @param data_path_type - Abuse of function by overloading for ATT support
  //                       - Carry on the abuse
  //
  // @return 0 if the device_family argument is invalid, otherwise
  //          it returns the width of the reconfig_from_xcvr port for that family
  function integer get_native_reconfig_interfaces(
    input [MAX_CHAR*8-1:0] device_family,
    //input [MAX_CHAR*8-1:0] operation_mode,
    input integer           rx_en,
    input integer           tx_en,
    input integer           lanes,
    input integer           plls,
    input [MAX_CHAR*8-1:0] data_path_type = "",
    input [MAX_CHAR*8-1:0] bonded_mode = "xN"
  );
     integer       reconfig_interfaces;
     integer          bonded_group_size;
     
     
     reconfig_interfaces = 0;
     if (altera_xcvr_functions::has_s5_style_hssi(device_family) || altera_xcvr_functions::has_a5_style_hssi(device_family) || altera_xcvr_functions::has_c5_style_hssi(device_family))
       begin
          // Custom PHY calculations
          if(rx_en == 1 && tx_en == 0)
            reconfig_interfaces = lanes;
          else 
       begin
               bonded_group_size = (bonded_mode == "fb_compensation") ? 1 : 
               (bonded_mode == "non_bonded") ? 1 :
               (bonded_mode == "xN") ? lanes : 1;             
               reconfig_interfaces = lanes+(plls*(lanes/bonded_group_size));
            end
       end // if (has_s5_style_hssi(device_family) || has_a5_style_hssi(device_family) || has_c5_style_hssi(device_family))
     get_native_reconfig_interfaces = reconfig_interfaces;
  endfunction // get_native_reconfig_interfaces
   
   
   ////////////////////////////////////////////////////////////////////
   // Get reconfig_to_xcvr total port width for Native PHY
   //
   // @param device_family - Desired device family
   // @param operation_mode - "Duplex","Rx","Tx" or "duplex", "rx_only", "tx_only" in 10gbaser
   // @param lanes - Number of transceiver channels
   // @param plls - Number of plls per bonded group
   // @param data_path_type - Abuse of function to support ATT
   //
   // @return - 0 if the device_family argument is invalid, otherwise
   // it returns the width of the reconfig_from_xcvr port for that family
   function integer get_native_reconfig_to_width(
    input [MAX_CHAR*8-1:0] device_family,
    //input [MAX_CHAR*8-1:0] operation_mode,
    input integer           rx_en,
    input integer           tx_en,
    input integer           lanes,
    input integer           plls,
    input [MAX_CHAR*8-1:0] data_path_type = "",
    input [MAX_CHAR*8-1:0] bonded_mode  = "xN"
                   );
      integer         reconfig_interfaces;
      reconfig_interfaces = get_native_reconfig_interfaces(device_family,rx_en,tx_en,lanes,plls,data_path_type, bonded_mode );
      get_native_reconfig_to_width = altera_xcvr_functions::get_s5_reconfig_to_width(reconfig_interfaces);
   endfunction // get_native_reconfig_to_width
   
   
   ////////////////////////////////////////////////////////////////////
   // Get reconfig_from_xcvr total port width for Native PHY
   //
   // @param device_family - Desired device family
   // @param operation_mode - "Duplex","Rx","Tx" or "duplex", "rx_only", "tx_only" in 10gbaser
   // @param lanes - Number of transceiver channels
   // @param plls - Number of plls per bonded group
   // @param data_path_type - Abuse of function to support ATT
   //
   // @return - 0 if the device_family argument is invalid, otherwise
   // it returns the width of the reconfig_from_xcvr port for that family
   function integer get_native_reconfig_from_width(
    input [MAX_CHAR*8-1:0] device_family,
    //input [MAX_CHAR*8-1:0] operation_mode,
    input integer           rx_en,
    input integer           tx_en,
    input integer           lanes,
    input integer           plls,
    input [MAX_CHAR*8-1:0] data_path_type = "",
    input [MAX_CHAR*8-1:0] bonded_mode = "xN"
   );
      integer         reconfig_interfaces;
      reconfig_interfaces = get_native_reconfig_interfaces(device_family,rx_en,tx_en,lanes,plls,data_path_type, bonded_mode);
      get_native_reconfig_from_width = altera_xcvr_functions::get_s5_reconfig_from_width(reconfig_interfaces);
   endfunction // get_native_reconfig_from_width
   

   function [57:0] set_10g_scrm_seed_user (
    input [8*MAX_CHAR:1] protocol_hint,
    input [57:0] 	 user_seed,
    input integer 	 lane_number
						     
						     );
      set_10g_scrm_seed_user = (protocol_hint == "teng_baser") ? 58'h3FFFFFFFFFFFFFF : 
                               (protocol_hint == "interlaken") ? (58'h123456789abcde + user_seed + (24'h826a3*lane_number)) : user_seed;
      
   endfunction
   


   
endpackage
