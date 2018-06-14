onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /a10_sata_xcvr_reconf/reset
add wave -noupdate /a10_sata_xcvr_reconf/clk
add wave -noupdate -divider <NULL>
add wave -noupdate /a10_sata_xcvr_reconf/cmd_reconfig
add wave -noupdate -radix hexadecimal /a10_sata_xcvr_reconf/cmd_sata_gen
add wave -noupdate /a10_sata_xcvr_reconf/cmd_ready
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /a10_sata_xcvr_reconf/recfg_addr
add wave -noupdate /a10_sata_xcvr_reconf/recfg_wreq
add wave -noupdate -radix hexadecimal /a10_sata_xcvr_reconf/recfg_wdat
add wave -noupdate /a10_sata_xcvr_reconf/recfg_rreq
add wave -noupdate -radix hexadecimal /a10_sata_xcvr_reconf/recfg_rdat
add wave -noupdate /a10_sata_xcvr_reconf/recfg_busy
add wave -noupdate -divider <NULL>
add wave -noupdate /a10_sata_xcvr_reconf/ready
add wave -noupdate /a10_sata_xcvr_reconf/ready_reg
add wave -noupdate -radix hexadecimal /a10_sata_xcvr_reconf/cfg_sel_reg
add wave -noupdate -divider <NULL>
add wave -noupdate -color {Slate Blue} /a10_sata_xcvr_reconf/cstate
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {526 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {1 us}
