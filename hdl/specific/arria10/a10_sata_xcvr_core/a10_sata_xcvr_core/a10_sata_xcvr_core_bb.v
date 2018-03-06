
module a10_sata_xcvr_core (
	tx_analogreset,
	tx_digitalreset,
	rx_analogreset,
	rx_digitalreset,
	tx_cal_busy,
	rx_cal_busy,
	tx_serial_clk0,
	rx_cdr_refclk0,
	tx_serial_data,
	rx_serial_data,
	rx_is_lockedtoref,
	rx_is_lockedtodata,
	tx_coreclkin,
	rx_coreclkin,
	tx_clkout,
	rx_clkout,
	tx_parallel_data,
	rx_parallel_data,
	unused_tx_parallel_data,
	unused_rx_parallel_data,
	tx_pma_elecidle,
	rx_patterndetect,
	rx_syncstatus,
	rx_std_wa_patternalign,
	rx_std_signaldetect,
	tx_datak,
	rx_datak,
	rx_errdetect,
	rx_disperr,
	rx_runningdisp);	

	input	[0:0]	tx_analogreset;
	input	[0:0]	tx_digitalreset;
	input	[0:0]	rx_analogreset;
	input	[0:0]	rx_digitalreset;
	output	[0:0]	tx_cal_busy;
	output	[0:0]	rx_cal_busy;
	input	[0:0]	tx_serial_clk0;
	input		rx_cdr_refclk0;
	output	[0:0]	tx_serial_data;
	input	[0:0]	rx_serial_data;
	output	[0:0]	rx_is_lockedtoref;
	output	[0:0]	rx_is_lockedtodata;
	input	[0:0]	tx_coreclkin;
	input	[0:0]	rx_coreclkin;
	output	[0:0]	tx_clkout;
	output	[0:0]	rx_clkout;
	input	[31:0]	tx_parallel_data;
	output	[31:0]	rx_parallel_data;
	input	[91:0]	unused_tx_parallel_data;
	output	[71:0]	unused_rx_parallel_data;
	input	[0:0]	tx_pma_elecidle;
	output	[3:0]	rx_patterndetect;
	output	[3:0]	rx_syncstatus;
	input	[0:0]	rx_std_wa_patternalign;
	output	[0:0]	rx_std_signaldetect;
	input	[3:0]	tx_datak;
	output	[3:0]	rx_datak;
	output	[3:0]	rx_errdetect;
	output	[3:0]	rx_disperr;
	output	[3:0]	rx_runningdisp;
endmodule
