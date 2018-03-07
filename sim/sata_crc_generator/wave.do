onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sata_crc_generator/reset
add wave -noupdate /sata_crc_generator/clk
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_crc_generator/i_dat
add wave -noupdate /sata_crc_generator/i_val
add wave -noupdate /sata_crc_generator/i_eop
add wave -noupdate /sata_crc_generator/i_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_crc_generator/o_dat
add wave -noupdate /sata_crc_generator/o_val
add wave -noupdate /sata_crc_generator/o_eop
add wave -noupdate /sata_crc_generator/o_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_crc_generator/crc_reg
add wave -noupdate -radix hexadecimal /sata_crc_generator/crc_new
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {48 ns} 0}
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
WaveRestoreZoom {0 ns} {202 ns}
