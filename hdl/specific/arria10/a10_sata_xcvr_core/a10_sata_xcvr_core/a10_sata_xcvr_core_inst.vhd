	component a10_sata_xcvr_core is
		port (
			tx_analogreset          : in  std_logic_vector(0 downto 0)  := (others => 'X'); -- tx_analogreset
			tx_digitalreset         : in  std_logic_vector(0 downto 0)  := (others => 'X'); -- tx_digitalreset
			rx_analogreset          : in  std_logic_vector(0 downto 0)  := (others => 'X'); -- rx_analogreset
			rx_digitalreset         : in  std_logic_vector(0 downto 0)  := (others => 'X'); -- rx_digitalreset
			tx_cal_busy             : out std_logic_vector(0 downto 0);                     -- tx_cal_busy
			rx_cal_busy             : out std_logic_vector(0 downto 0);                     -- rx_cal_busy
			tx_serial_clk0          : in  std_logic_vector(0 downto 0)  := (others => 'X'); -- clk
			rx_cdr_refclk0          : in  std_logic                     := 'X';             -- clk
			tx_serial_data          : out std_logic_vector(0 downto 0);                     -- tx_serial_data
			rx_serial_data          : in  std_logic_vector(0 downto 0)  := (others => 'X'); -- rx_serial_data
			rx_is_lockedtoref       : out std_logic_vector(0 downto 0);                     -- rx_is_lockedtoref
			rx_is_lockedtodata      : out std_logic_vector(0 downto 0);                     -- rx_is_lockedtodata
			tx_coreclkin            : in  std_logic_vector(0 downto 0)  := (others => 'X'); -- clk
			rx_coreclkin            : in  std_logic_vector(0 downto 0)  := (others => 'X'); -- clk
			tx_clkout               : out std_logic_vector(0 downto 0);                     -- clk
			rx_clkout               : out std_logic_vector(0 downto 0);                     -- clk
			tx_parallel_data        : in  std_logic_vector(31 downto 0) := (others => 'X'); -- tx_parallel_data
			rx_parallel_data        : out std_logic_vector(31 downto 0);                    -- rx_parallel_data
			unused_tx_parallel_data : in  std_logic_vector(91 downto 0) := (others => 'X'); -- unused_tx_parallel_data
			unused_rx_parallel_data : out std_logic_vector(71 downto 0);                    -- unused_rx_parallel_data
			tx_pma_elecidle         : in  std_logic_vector(0 downto 0)  := (others => 'X'); -- tx_pma_elecidle
			rx_patterndetect        : out std_logic_vector(3 downto 0);                     -- rx_patterndetect
			rx_syncstatus           : out std_logic_vector(3 downto 0);                     -- rx_syncstatus
			rx_std_wa_patternalign  : in  std_logic_vector(0 downto 0)  := (others => 'X'); -- rx_std_wa_patternalign
			rx_std_signaldetect     : out std_logic_vector(0 downto 0);                     -- rx_std_signaldetect
			tx_datak                : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- tx_datak
			rx_datak                : out std_logic_vector(3 downto 0);                     -- rx_datak
			rx_errdetect            : out std_logic_vector(3 downto 0);                     -- rx_errdetect
			rx_disperr              : out std_logic_vector(3 downto 0);                     -- rx_disperr
			rx_runningdisp          : out std_logic_vector(3 downto 0)                      -- rx_runningdisp
		);
	end component a10_sata_xcvr_core;

	u0 : component a10_sata_xcvr_core
		port map (
			tx_analogreset          => CONNECTED_TO_tx_analogreset,          --          tx_analogreset.tx_analogreset
			tx_digitalreset         => CONNECTED_TO_tx_digitalreset,         --         tx_digitalreset.tx_digitalreset
			rx_analogreset          => CONNECTED_TO_rx_analogreset,          --          rx_analogreset.rx_analogreset
			rx_digitalreset         => CONNECTED_TO_rx_digitalreset,         --         rx_digitalreset.rx_digitalreset
			tx_cal_busy             => CONNECTED_TO_tx_cal_busy,             --             tx_cal_busy.tx_cal_busy
			rx_cal_busy             => CONNECTED_TO_rx_cal_busy,             --             rx_cal_busy.rx_cal_busy
			tx_serial_clk0          => CONNECTED_TO_tx_serial_clk0,          --          tx_serial_clk0.clk
			rx_cdr_refclk0          => CONNECTED_TO_rx_cdr_refclk0,          --          rx_cdr_refclk0.clk
			tx_serial_data          => CONNECTED_TO_tx_serial_data,          --          tx_serial_data.tx_serial_data
			rx_serial_data          => CONNECTED_TO_rx_serial_data,          --          rx_serial_data.rx_serial_data
			rx_is_lockedtoref       => CONNECTED_TO_rx_is_lockedtoref,       --       rx_is_lockedtoref.rx_is_lockedtoref
			rx_is_lockedtodata      => CONNECTED_TO_rx_is_lockedtodata,      --      rx_is_lockedtodata.rx_is_lockedtodata
			tx_coreclkin            => CONNECTED_TO_tx_coreclkin,            --            tx_coreclkin.clk
			rx_coreclkin            => CONNECTED_TO_rx_coreclkin,            --            rx_coreclkin.clk
			tx_clkout               => CONNECTED_TO_tx_clkout,               --               tx_clkout.clk
			rx_clkout               => CONNECTED_TO_rx_clkout,               --               rx_clkout.clk
			tx_parallel_data        => CONNECTED_TO_tx_parallel_data,        --        tx_parallel_data.tx_parallel_data
			rx_parallel_data        => CONNECTED_TO_rx_parallel_data,        --        rx_parallel_data.rx_parallel_data
			unused_tx_parallel_data => CONNECTED_TO_unused_tx_parallel_data, -- unused_tx_parallel_data.unused_tx_parallel_data
			unused_rx_parallel_data => CONNECTED_TO_unused_rx_parallel_data, -- unused_rx_parallel_data.unused_rx_parallel_data
			tx_pma_elecidle         => CONNECTED_TO_tx_pma_elecidle,         --         tx_pma_elecidle.tx_pma_elecidle
			rx_patterndetect        => CONNECTED_TO_rx_patterndetect,        --        rx_patterndetect.rx_patterndetect
			rx_syncstatus           => CONNECTED_TO_rx_syncstatus,           --           rx_syncstatus.rx_syncstatus
			rx_std_wa_patternalign  => CONNECTED_TO_rx_std_wa_patternalign,  --  rx_std_wa_patternalign.rx_std_wa_patternalign
			rx_std_signaldetect     => CONNECTED_TO_rx_std_signaldetect,     --     rx_std_signaldetect.rx_std_signaldetect
			tx_datak                => CONNECTED_TO_tx_datak,                --                tx_datak.tx_datak
			rx_datak                => CONNECTED_TO_rx_datak,                --                rx_datak.rx_datak
			rx_errdetect            => CONNECTED_TO_rx_errdetect,            --            rx_errdetect.rx_errdetect
			rx_disperr              => CONNECTED_TO_rx_disperr,              --              rx_disperr.rx_disperr
			rx_runningdisp          => CONNECTED_TO_rx_runningdisp           --          rx_runningdisp.rx_runningdisp
		);

