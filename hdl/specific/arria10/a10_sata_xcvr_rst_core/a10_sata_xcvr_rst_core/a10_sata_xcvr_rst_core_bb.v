
module a10_sata_xcvr_rst_core (
	clock,
	reset,
	tx_analogreset,
	tx_digitalreset,
	tx_ready,
	pll_locked,
	pll_select,
	tx_cal_busy,
	rx_analogreset,
	rx_digitalreset,
	rx_ready,
	rx_is_lockedtodata,
	rx_cal_busy);	

	input		clock;
	input		reset;
	output	[0:0]	tx_analogreset;
	output	[0:0]	tx_digitalreset;
	output	[0:0]	tx_ready;
	input	[0:0]	pll_locked;
	input	[0:0]	pll_select;
	input	[0:0]	tx_cal_busy;
	output	[0:0]	rx_analogreset;
	output	[0:0]	rx_digitalreset;
	output	[0:0]	rx_ready;
	input	[0:0]	rx_is_lockedtodata;
	input	[0:0]	rx_cal_busy;
endmodule
