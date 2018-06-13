
module a10_sata_xcvr_core (
	reconfig_write,
	reconfig_read,
	reconfig_address,
	reconfig_writedata,
	reconfig_readdata,
	reconfig_waitrequest,
	reconfig_clk,
	reconfig_reset,
	rx_analogreset,
	rx_cal_busy,
	rx_cdr_refclk0,
	rx_clkout,
	rx_coreclkin,
	rx_datak,
	rx_digitalreset,
	rx_disperr,
	rx_errdetect,
	rx_is_lockedtodata,
	rx_is_lockedtoref,
	rx_parallel_data,
	rx_patterndetect,
	rx_runningdisp,
	rx_serial_data,
	rx_std_signaldetect,
	rx_std_wa_patternalign,
	rx_syncstatus,
	tx_analogreset,
	tx_cal_busy,
	tx_clkout,
	tx_coreclkin,
	tx_datak,
	tx_digitalreset,
	tx_parallel_data,
	tx_pma_elecidle,
	tx_serial_clk0,
	tx_serial_data,
	unused_rx_parallel_data,
	unused_tx_parallel_data);	

	input	[0:0]	reconfig_write;
	input	[0:0]	reconfig_read;
	input	[9:0]	reconfig_address;
	input	[31:0]	reconfig_writedata;
	output	[31:0]	reconfig_readdata;
	output	[0:0]	reconfig_waitrequest;
	input	[0:0]	reconfig_clk;
	input	[0:0]	reconfig_reset;
	input	[0:0]	rx_analogreset;
	output	[0:0]	rx_cal_busy;
	input		rx_cdr_refclk0;
	output	[0:0]	rx_clkout;
	input	[0:0]	rx_coreclkin;
	output	[3:0]	rx_datak;
	input	[0:0]	rx_digitalreset;
	output	[3:0]	rx_disperr;
	output	[3:0]	rx_errdetect;
	output	[0:0]	rx_is_lockedtodata;
	output	[0:0]	rx_is_lockedtoref;
	output	[31:0]	rx_parallel_data;
	output	[3:0]	rx_patterndetect;
	output	[3:0]	rx_runningdisp;
	input	[0:0]	rx_serial_data;
	output	[0:0]	rx_std_signaldetect;
	input	[0:0]	rx_std_wa_patternalign;
	output	[3:0]	rx_syncstatus;
	input	[0:0]	tx_analogreset;
	output	[0:0]	tx_cal_busy;
	output	[0:0]	tx_clkout;
	input	[0:0]	tx_coreclkin;
	input	[3:0]	tx_datak;
	input	[0:0]	tx_digitalreset;
	input	[31:0]	tx_parallel_data;
	input	[0:0]	tx_pma_elecidle;
	input	[0:0]	tx_serial_clk0;
	output	[0:0]	tx_serial_data;
	output	[71:0]	unused_rx_parallel_data;
	input	[91:0]	unused_tx_parallel_data;
endmodule
