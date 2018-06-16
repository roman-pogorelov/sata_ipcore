set_global_assignment -entity "sv_sata_xcvr_rst_core" -library "lib_sv_sata_xcvr_rst_core" -name IP_TOOL_NAME "altera_xcvr_reset_control"
set_global_assignment -entity "sv_sata_xcvr_rst_core" -library "lib_sv_sata_xcvr_rst_core" -name IP_TOOL_VERSION "17.1"
set_global_assignment -entity "sv_sata_xcvr_rst_core" -library "lib_sv_sata_xcvr_rst_core" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_sv_sata_xcvr_rst_core" -name SPD_FILE [file join $::quartus(sip_path) "sv_sata_xcvr_rst_core.spd"]

set_global_assignment -library "lib_sv_sata_xcvr_rst_core" -name MISC_FILE [file join $::quartus(sip_path) "sv_sata_xcvr_rst_core_sim/sv_sata_xcvr_rst_core.v"]
set_global_assignment -library "lib_sv_sata_xcvr_rst_core" -name MISC_FILE [file join $::quartus(sip_path) "sv_sata_xcvr_rst_core_sim/altera_xcvr_reset_control/altera_xcvr_functions.sv"]
set_global_assignment -library "lib_sv_sata_xcvr_rst_core" -name MISC_FILE [file join $::quartus(sip_path) "sv_sata_xcvr_rst_core_sim/altera_xcvr_reset_control/mentor/altera_xcvr_functions.sv"]
set_global_assignment -library "lib_sv_sata_xcvr_rst_core" -name MISC_FILE [file join $::quartus(sip_path) "sv_sata_xcvr_rst_core_sim/altera_xcvr_reset_control/alt_xcvr_resync.sv"]
set_global_assignment -library "lib_sv_sata_xcvr_rst_core" -name MISC_FILE [file join $::quartus(sip_path) "sv_sata_xcvr_rst_core_sim/altera_xcvr_reset_control/mentor/alt_xcvr_resync.sv"]
set_global_assignment -library "lib_sv_sata_xcvr_rst_core" -name MISC_FILE [file join $::quartus(sip_path) "sv_sata_xcvr_rst_core_sim/altera_xcvr_reset_control/altera_xcvr_reset_control.sv"]
set_global_assignment -library "lib_sv_sata_xcvr_rst_core" -name MISC_FILE [file join $::quartus(sip_path) "sv_sata_xcvr_rst_core_sim/altera_xcvr_reset_control/alt_xcvr_reset_counter.sv"]
set_global_assignment -library "lib_sv_sata_xcvr_rst_core" -name MISC_FILE [file join $::quartus(sip_path) "sv_sata_xcvr_rst_core_sim/altera_xcvr_reset_control/mentor/altera_xcvr_reset_control.sv"]
set_global_assignment -library "lib_sv_sata_xcvr_rst_core" -name MISC_FILE [file join $::quartus(sip_path) "sv_sata_xcvr_rst_core_sim/altera_xcvr_reset_control/mentor/alt_xcvr_reset_counter.sv"]
set_global_assignment -library "lib_sv_sata_xcvr_rst_core" -name MISC_FILE [file join $::quartus(sip_path) "sv_sata_xcvr_rst_core_sim/altera_xcvr_reset_control/plain_files.txt"]
set_global_assignment -library "lib_sv_sata_xcvr_rst_core" -name MISC_FILE [file join $::quartus(sip_path) "sv_sata_xcvr_rst_core_sim/altera_xcvr_reset_control/mentor_files.txt"]
set_global_assignment -library "lib_sv_sata_xcvr_rst_core" -name MISC_FILE [file join $::quartus(sip_path) "sv_sata_xcvr_rst_core_sim/altera_xcvr_reset_control/cadence_files.txt"]
set_global_assignment -library "lib_sv_sata_xcvr_rst_core" -name MISC_FILE [file join $::quartus(sip_path) "sv_sata_xcvr_rst_core_sim/altera_xcvr_reset_control/synopsys_files.txt"]
set_global_assignment -library "lib_sv_sata_xcvr_rst_core" -name MISC_FILE [file join $::quartus(sip_path) "sv_sata_xcvr_rst_core_sim/altera_xcvr_reset_control/aldec_files.txt"]
