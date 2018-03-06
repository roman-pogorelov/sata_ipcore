	a10_sata_xcvr_core u0 (
		.tx_analogreset          (<connected-to-tx_analogreset>),          //          tx_analogreset.tx_analogreset
		.tx_digitalreset         (<connected-to-tx_digitalreset>),         //         tx_digitalreset.tx_digitalreset
		.rx_analogreset          (<connected-to-rx_analogreset>),          //          rx_analogreset.rx_analogreset
		.rx_digitalreset         (<connected-to-rx_digitalreset>),         //         rx_digitalreset.rx_digitalreset
		.tx_cal_busy             (<connected-to-tx_cal_busy>),             //             tx_cal_busy.tx_cal_busy
		.rx_cal_busy             (<connected-to-rx_cal_busy>),             //             rx_cal_busy.rx_cal_busy
		.tx_serial_clk0          (<connected-to-tx_serial_clk0>),          //          tx_serial_clk0.clk
		.rx_cdr_refclk0          (<connected-to-rx_cdr_refclk0>),          //          rx_cdr_refclk0.clk
		.tx_serial_data          (<connected-to-tx_serial_data>),          //          tx_serial_data.tx_serial_data
		.rx_serial_data          (<connected-to-rx_serial_data>),          //          rx_serial_data.rx_serial_data
		.rx_is_lockedtoref       (<connected-to-rx_is_lockedtoref>),       //       rx_is_lockedtoref.rx_is_lockedtoref
		.rx_is_lockedtodata      (<connected-to-rx_is_lockedtodata>),      //      rx_is_lockedtodata.rx_is_lockedtodata
		.tx_coreclkin            (<connected-to-tx_coreclkin>),            //            tx_coreclkin.clk
		.rx_coreclkin            (<connected-to-rx_coreclkin>),            //            rx_coreclkin.clk
		.tx_clkout               (<connected-to-tx_clkout>),               //               tx_clkout.clk
		.rx_clkout               (<connected-to-rx_clkout>),               //               rx_clkout.clk
		.tx_parallel_data        (<connected-to-tx_parallel_data>),        //        tx_parallel_data.tx_parallel_data
		.rx_parallel_data        (<connected-to-rx_parallel_data>),        //        rx_parallel_data.rx_parallel_data
		.unused_tx_parallel_data (<connected-to-unused_tx_parallel_data>), // unused_tx_parallel_data.unused_tx_parallel_data
		.unused_rx_parallel_data (<connected-to-unused_rx_parallel_data>), // unused_rx_parallel_data.unused_rx_parallel_data
		.tx_pma_elecidle         (<connected-to-tx_pma_elecidle>),         //         tx_pma_elecidle.tx_pma_elecidle
		.rx_patterndetect        (<connected-to-rx_patterndetect>),        //        rx_patterndetect.rx_patterndetect
		.rx_syncstatus           (<connected-to-rx_syncstatus>),           //           rx_syncstatus.rx_syncstatus
		.rx_std_wa_patternalign  (<connected-to-rx_std_wa_patternalign>),  //  rx_std_wa_patternalign.rx_std_wa_patternalign
		.rx_std_signaldetect     (<connected-to-rx_std_signaldetect>),     //     rx_std_signaldetect.rx_std_signaldetect
		.tx_datak                (<connected-to-tx_datak>),                //                tx_datak.tx_datak
		.rx_datak                (<connected-to-rx_datak>),                //                rx_datak.rx_datak
		.rx_errdetect            (<connected-to-rx_errdetect>),            //            rx_errdetect.rx_errdetect
		.rx_disperr              (<connected-to-rx_disperr>),              //              rx_disperr.rx_disperr
		.rx_runningdisp          (<connected-to-rx_runningdisp>)           //          rx_runningdisp.rx_runningdisp
	);

