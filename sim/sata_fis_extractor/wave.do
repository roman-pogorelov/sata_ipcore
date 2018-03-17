onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sata_fis_extractor/reset
add wave -noupdate /sata_fis_extractor/clk
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_fis_extractor/rx_data
add wave -noupdate -radix hexadecimal /sata_fis_extractor/rx_datak
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_fis_extractor/fis_dat
add wave -noupdate /sata_fis_extractor/fis_val
add wave -noupdate /sata_fis_extractor/fis_eop
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_fis_extractor/state_reg
add wave -noupdate -radix hexadecimal /sata_fis_extractor/dat_reg
add wave -noupdate /sata_fis_extractor/val_reg
add wave -noupdate -radix hexadecimal /sata_fis_extractor/fis_dat_reg
add wave -noupdate /sata_fis_extractor/fis_val_reg
add wave -noupdate /sata_fis_extractor/fis_eop_reg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {17 ns} 0}
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
WaveRestoreZoom {0 ns} {378 ns}
