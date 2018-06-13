onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sata_fis_data_shaper/reset
add wave -noupdate /sata_fis_data_shaper/clk
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_fis_data_shaper/ctl_valid
add wave -noupdate -radix unsigned /sata_fis_data_shaper/ctl_count
add wave -noupdate /sata_fis_data_shaper/ctl_ready
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_fis_data_shaper/i_dat
add wave -noupdate /sata_fis_data_shaper/i_val
add wave -noupdate /sata_fis_data_shaper/i_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_fis_data_shaper/o_dat
add wave -noupdate /sata_fis_data_shaper/o_val
add wave -noupdate /sata_fis_data_shaper/o_eop
add wave -noupdate /sata_fis_data_shaper/o_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_fis_data_shaper/o_sop_reg
add wave -noupdate /sata_fis_data_shaper/pass_reg
add wave -noupdate -radix unsigned /sata_fis_data_shaper/word_cnt
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {20 ns} 0}
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
