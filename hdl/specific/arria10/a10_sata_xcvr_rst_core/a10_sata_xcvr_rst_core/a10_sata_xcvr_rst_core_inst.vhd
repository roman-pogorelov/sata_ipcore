	component a10_sata_xcvr_rst_core is
		port (
			clock              : in  std_logic                    := 'X';             -- clk
			reset              : in  std_logic                    := 'X';             -- reset
			tx_analogreset     : out std_logic_vector(0 downto 0);                    -- tx_analogreset
			tx_digitalreset    : out std_logic_vector(0 downto 0);                    -- tx_digitalreset
			tx_ready           : out std_logic_vector(0 downto 0);                    -- tx_ready
			pll_locked         : in  std_logic_vector(0 downto 0) := (others => 'X'); -- pll_locked
			pll_select         : in  std_logic_vector(0 downto 0) := (others => 'X'); -- pll_select
			tx_cal_busy        : in  std_logic_vector(0 downto 0) := (others => 'X'); -- tx_cal_busy
			rx_analogreset     : out std_logic_vector(0 downto 0);                    -- rx_analogreset
			rx_digitalreset    : out std_logic_vector(0 downto 0);                    -- rx_digitalreset
			rx_ready           : out std_logic_vector(0 downto 0);                    -- rx_ready
			rx_is_lockedtodata : in  std_logic_vector(0 downto 0) := (others => 'X'); -- rx_is_lockedtodata
			rx_cal_busy        : in  std_logic_vector(0 downto 0) := (others => 'X')  -- rx_cal_busy
		);
	end component a10_sata_xcvr_rst_core;

	u0 : component a10_sata_xcvr_rst_core
		port map (
			clock              => CONNECTED_TO_clock,              --              clock.clk
			reset              => CONNECTED_TO_reset,              --              reset.reset
			tx_analogreset     => CONNECTED_TO_tx_analogreset,     --     tx_analogreset.tx_analogreset
			tx_digitalreset    => CONNECTED_TO_tx_digitalreset,    --    tx_digitalreset.tx_digitalreset
			tx_ready           => CONNECTED_TO_tx_ready,           --           tx_ready.tx_ready
			pll_locked         => CONNECTED_TO_pll_locked,         --         pll_locked.pll_locked
			pll_select         => CONNECTED_TO_pll_select,         --         pll_select.pll_select
			tx_cal_busy        => CONNECTED_TO_tx_cal_busy,        --        tx_cal_busy.tx_cal_busy
			rx_analogreset     => CONNECTED_TO_rx_analogreset,     --     rx_analogreset.rx_analogreset
			rx_digitalreset    => CONNECTED_TO_rx_digitalreset,    --    rx_digitalreset.rx_digitalreset
			rx_ready           => CONNECTED_TO_rx_ready,           --           rx_ready.rx_ready
			rx_is_lockedtodata => CONNECTED_TO_rx_is_lockedtodata, -- rx_is_lockedtodata.rx_is_lockedtodata
			rx_cal_busy        => CONNECTED_TO_rx_cal_busy         --        rx_cal_busy.rx_cal_busy
		);

