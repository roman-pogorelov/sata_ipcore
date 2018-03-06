
module a10_sata_xcvr_fpll_core (
	pll_refclk0,
	pll_powerdown,
	pll_locked,
	tx_serial_clk,
	pll_cal_busy,
	reconfig_clk0,
	reconfig_reset0,
	reconfig_write0,
	reconfig_read0,
	reconfig_address0,
	reconfig_writedata0,
	reconfig_readdata0,
	reconfig_waitrequest0);	

	input		pll_refclk0;
	input		pll_powerdown;
	output		pll_locked;
	output		tx_serial_clk;
	output		pll_cal_busy;
	input		reconfig_clk0;
	input		reconfig_reset0;
	input		reconfig_write0;
	input		reconfig_read0;
	input	[9:0]	reconfig_address0;
	input	[31:0]	reconfig_writedata0;
	output	[31:0]	reconfig_readdata0;
	output		reconfig_waitrequest0;
endmodule
