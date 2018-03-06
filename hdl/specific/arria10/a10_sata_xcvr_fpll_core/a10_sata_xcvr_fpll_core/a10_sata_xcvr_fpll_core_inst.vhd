	component a10_sata_xcvr_fpll_core is
		port (
			pll_refclk0           : in  std_logic                     := 'X';             -- clk
			pll_powerdown         : in  std_logic                     := 'X';             -- pll_powerdown
			pll_locked            : out std_logic;                                        -- pll_locked
			tx_serial_clk         : out std_logic;                                        -- clk
			pll_cal_busy          : out std_logic;                                        -- pll_cal_busy
			reconfig_clk0         : in  std_logic                     := 'X';             -- clk
			reconfig_reset0       : in  std_logic                     := 'X';             -- reset
			reconfig_write0       : in  std_logic                     := 'X';             -- write
			reconfig_read0        : in  std_logic                     := 'X';             -- read
			reconfig_address0     : in  std_logic_vector(9 downto 0)  := (others => 'X'); -- address
			reconfig_writedata0   : in  std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
			reconfig_readdata0    : out std_logic_vector(31 downto 0);                    -- readdata
			reconfig_waitrequest0 : out std_logic                                         -- waitrequest
		);
	end component a10_sata_xcvr_fpll_core;

	u0 : component a10_sata_xcvr_fpll_core
		port map (
			pll_refclk0           => CONNECTED_TO_pll_refclk0,           --     pll_refclk0.clk
			pll_powerdown         => CONNECTED_TO_pll_powerdown,         --   pll_powerdown.pll_powerdown
			pll_locked            => CONNECTED_TO_pll_locked,            --      pll_locked.pll_locked
			tx_serial_clk         => CONNECTED_TO_tx_serial_clk,         --   tx_serial_clk.clk
			pll_cal_busy          => CONNECTED_TO_pll_cal_busy,          --    pll_cal_busy.pll_cal_busy
			reconfig_clk0         => CONNECTED_TO_reconfig_clk0,         --   reconfig_clk0.clk
			reconfig_reset0       => CONNECTED_TO_reconfig_reset0,       -- reconfig_reset0.reset
			reconfig_write0       => CONNECTED_TO_reconfig_write0,       --  reconfig_avmm0.write
			reconfig_read0        => CONNECTED_TO_reconfig_read0,        --                .read
			reconfig_address0     => CONNECTED_TO_reconfig_address0,     --                .address
			reconfig_writedata0   => CONNECTED_TO_reconfig_writedata0,   --                .writedata
			reconfig_readdata0    => CONNECTED_TO_reconfig_readdata0,    --                .readdata
			reconfig_waitrequest0 => CONNECTED_TO_reconfig_waitrequest0  --                .waitrequest
		);

