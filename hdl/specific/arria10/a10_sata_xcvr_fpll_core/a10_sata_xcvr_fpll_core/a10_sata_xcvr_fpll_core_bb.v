
module a10_sata_xcvr_fpll_core (
	pll_cal_busy,
	pll_locked,
	pll_powerdown,
	pll_refclk0,
	tx_serial_clk);	

	output		pll_cal_busy;
	output		pll_locked;
	input		pll_powerdown;
	input		pll_refclk0;
	output		tx_serial_clk;
endmodule
