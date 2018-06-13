// Parameters for embedded reconfiguration streamer

package alt_xcvr_native_rcfg_strm_params_qvaveni;

  localparam rom_data_width = 26; // ROM data width 
  localparam rom_depth = 12; // Depth of reconfiguration rom
  localparam rcfg_cfg_depths = "4,4,4"; // Depths of individual configuration profiles in rom

  // Reconfiguration rom containing all profiles in order
  localparam reg [25:0] config_rom [0:11] = '{
    26'h1190C08,
    26'h1350C00,
    26'h13A3828,
    26'h3FFFFFF,
    26'h1190C04,
    26'h1350C0C,
    26'h13A3820,
    26'h3FFFFFF,
    26'h1190C00,
    26'h1350C0C,
    26'h13A3818,
    26'h3FFFFFF
  };
endpackage