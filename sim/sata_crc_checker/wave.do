onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sata_crc_checker/reset
add wave -noupdate /sata_crc_checker/clk
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_crc_checker/i_dat
add wave -noupdate /sata_crc_checker/i_val
add wave -noupdate /sata_crc_checker/i_eop
add wave -noupdate /sata_crc_checker/i_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_crc_checker/o_dat
add wave -noupdate /sata_crc_checker/o_val
add wave -noupdate /sata_crc_checker/o_eop
add wave -noupdate /sata_crc_checker/o_err
add wave -noupdate /sata_crc_checker/o_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_crc_checker/crc_reg
add wave -noupdate -radix hexadecimal /sata_crc_checker/crc_new
add wave -noupdate -radix hexadecimal /sata_crc_checker/dat_reg
add wave -noupdate /sata_crc_checker/val_reg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
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
