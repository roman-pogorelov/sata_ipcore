
module a10_sata_xcvr_rst_core (
	clock,
	pll_locked,
	pll_powerdown,
	pll_select,
	reset,
	rx_analogreset,
	rx_cal_busy,
	rx_digitalreset,
	rx_is_lockedtodata,
	rx_ready,
	tx_analogreset,
	tx_cal_busy,
	tx_digitalreset,
	tx_ready,
	pll_cal_busy);	

	input		clock;
	input	[0:0]	pll_locked;
	output	[0:0]	pll_powerdown;
	input	[0:0]	pll_select;
	input		reset;
	output	[0:0]	rx_analogreset;
	input	[0:0]	rx_cal_busy;
	output	[0:0]	rx_digitalreset;
	input	[0:0]	rx_is_lockedtodata;
	output	[0:0]	rx_ready;
	output	[0:0]	tx_analogreset;
	input	[0:0]	tx_cal_busy;
	output	[0:0]	tx_digitalreset;
	output	[0:0]	tx_ready;
	input	[0:0]	pll_cal_busy;
endmodule
