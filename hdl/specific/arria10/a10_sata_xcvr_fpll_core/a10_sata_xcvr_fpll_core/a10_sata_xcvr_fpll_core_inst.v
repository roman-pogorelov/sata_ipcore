	a10_sata_xcvr_fpll_core u0 (
		.pll_refclk0           (<connected-to-pll_refclk0>),           //     pll_refclk0.clk
		.pll_powerdown         (<connected-to-pll_powerdown>),         //   pll_powerdown.pll_powerdown
		.pll_locked            (<connected-to-pll_locked>),            //      pll_locked.pll_locked
		.tx_serial_clk         (<connected-to-tx_serial_clk>),         //   tx_serial_clk.clk
		.pll_cal_busy          (<connected-to-pll_cal_busy>),          //    pll_cal_busy.pll_cal_busy
		.reconfig_clk0         (<connected-to-reconfig_clk0>),         //   reconfig_clk0.clk
		.reconfig_reset0       (<connected-to-reconfig_reset0>),       // reconfig_reset0.reset
		.reconfig_write0       (<connected-to-reconfig_write0>),       //  reconfig_avmm0.write
		.reconfig_read0        (<connected-to-reconfig_read0>),        //                .read
		.reconfig_address0     (<connected-to-reconfig_address0>),     //                .address
		.reconfig_writedata0   (<connected-to-reconfig_writedata0>),   //                .writedata
		.reconfig_readdata0    (<connected-to-reconfig_readdata0>),    //                .readdata
		.reconfig_waitrequest0 (<connected-to-reconfig_waitrequest0>)  //                .waitrequest
	);

