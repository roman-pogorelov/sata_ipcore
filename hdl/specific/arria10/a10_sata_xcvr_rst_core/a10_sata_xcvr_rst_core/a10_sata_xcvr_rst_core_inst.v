	a10_sata_xcvr_rst_core u0 (
		.clock              (<connected-to-clock>),              //              clock.clk
		.pll_locked         (<connected-to-pll_locked>),         //         pll_locked.pll_locked
		.pll_powerdown      (<connected-to-pll_powerdown>),      //      pll_powerdown.pll_powerdown
		.pll_select         (<connected-to-pll_select>),         //         pll_select.pll_select
		.reset              (<connected-to-reset>),              //              reset.reset
		.rx_analogreset     (<connected-to-rx_analogreset>),     //     rx_analogreset.rx_analogreset
		.rx_cal_busy        (<connected-to-rx_cal_busy>),        //        rx_cal_busy.rx_cal_busy
		.rx_digitalreset    (<connected-to-rx_digitalreset>),    //    rx_digitalreset.rx_digitalreset
		.rx_is_lockedtodata (<connected-to-rx_is_lockedtodata>), // rx_is_lockedtodata.rx_is_lockedtodata
		.rx_ready           (<connected-to-rx_ready>),           //           rx_ready.rx_ready
		.tx_analogreset     (<connected-to-tx_analogreset>),     //     tx_analogreset.tx_analogreset
		.tx_cal_busy        (<connected-to-tx_cal_busy>),        //        tx_cal_busy.tx_cal_busy
		.tx_digitalreset    (<connected-to-tx_digitalreset>),    //    tx_digitalreset.tx_digitalreset
		.tx_ready           (<connected-to-tx_ready>),           //           tx_ready.tx_ready
		.pll_cal_busy       (<connected-to-pll_cal_busy>)        //       pll_cal_busy.pll_cal_busy
	);

