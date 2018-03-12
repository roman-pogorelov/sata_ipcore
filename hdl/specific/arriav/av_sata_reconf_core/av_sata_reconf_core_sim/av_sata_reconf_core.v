// av_sata_reconf_core.v

// Generated using ACDS version 17.1 590

`timescale 1 ps / 1 ps
module av_sata_reconf_core (
		output wire         reconfig_busy,             //      reconfig_busy.reconfig_busy
		input  wire         mgmt_clk_clk,              //       mgmt_clk_clk.clk
		input  wire         mgmt_rst_reset,            //     mgmt_rst_reset.reset
		input  wire [6:0]   reconfig_mgmt_address,     //      reconfig_mgmt.address
		input  wire         reconfig_mgmt_read,        //                   .read
		output wire [31:0]  reconfig_mgmt_readdata,    //                   .readdata
		output wire         reconfig_mgmt_waitrequest, //                   .waitrequest
		input  wire         reconfig_mgmt_write,       //                   .write
		input  wire [31:0]  reconfig_mgmt_writedata,   //                   .writedata
		output wire [139:0] reconfig_to_xcvr,          //   reconfig_to_xcvr.reconfig_to_xcvr
		input  wire [91:0]  reconfig_from_xcvr         // reconfig_from_xcvr.reconfig_from_xcvr
	);

	alt_xcvr_reconfig #(
		.device_family                 ("Arria V"),
		.number_of_reconfig_interfaces (2),
		.enable_offset                 (1),
		.enable_lc                     (0),
		.enable_dcd                    (0),
		.enable_dcd_power_up           (1),
		.enable_analog                 (1),
		.enable_eyemon                 (0),
		.enable_ber                    (0),
		.enable_dfe                    (0),
		.enable_adce                   (0),
		.enable_mif                    (0),
		.enable_pll                    (0)
	) av_sata_reconf_core_inst (
		.reconfig_busy             (reconfig_busy),             //      reconfig_busy.reconfig_busy
		.mgmt_clk_clk              (mgmt_clk_clk),              //       mgmt_clk_clk.clk
		.mgmt_rst_reset            (mgmt_rst_reset),            //     mgmt_rst_reset.reset
		.reconfig_mgmt_address     (reconfig_mgmt_address),     //      reconfig_mgmt.address
		.reconfig_mgmt_read        (reconfig_mgmt_read),        //                   .read
		.reconfig_mgmt_readdata    (reconfig_mgmt_readdata),    //                   .readdata
		.reconfig_mgmt_waitrequest (reconfig_mgmt_waitrequest), //                   .waitrequest
		.reconfig_mgmt_write       (reconfig_mgmt_write),       //                   .write
		.reconfig_mgmt_writedata   (reconfig_mgmt_writedata),   //                   .writedata
		.reconfig_to_xcvr          (reconfig_to_xcvr),          //   reconfig_to_xcvr.reconfig_to_xcvr
		.reconfig_from_xcvr        (reconfig_from_xcvr),        // reconfig_from_xcvr.reconfig_from_xcvr
		.tx_cal_busy               (),                          //        (terminated)
		.rx_cal_busy               (),                          //        (terminated)
		.cal_busy_in               (1'b0),                      //        (terminated)
		.reconfig_mif_address      (),                          //        (terminated)
		.reconfig_mif_read         (),                          //        (terminated)
		.reconfig_mif_readdata     (16'b0000000000000000),      //        (terminated)
		.reconfig_mif_waitrequest  (1'b0)                       //        (terminated)
	);

endmodule