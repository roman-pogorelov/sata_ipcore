onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sata_crc_scramler_tb/reset
add wave -noupdate /sata_crc_scramler_tb/clk
add wave -noupdate -divider <NULL>
add wave -noupdate -color Gold -radix hexadecimal /sata_crc_scramler_tb/i_dat
add wave -noupdate -color Gold /sata_crc_scramler_tb/i_val
add wave -noupdate -color Gold /sata_crc_scramler_tb/i_eop
add wave -noupdate -color Gold /sata_crc_scramler_tb/i_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -color {Cornflower Blue} -radix hexadecimal /sata_crc_scramler_tb/o_dat
add wave -noupdate -color {Cornflower Blue} /sata_crc_scramler_tb/o_val
add wave -noupdate -color {Cornflower Blue} /sata_crc_scramler_tb/o_eop
add wave -noupdate -color {Cornflower Blue} /sata_crc_scramler_tb/o_err
add wave -noupdate -color {Cornflower Blue} /sata_crc_scramler_tb/o_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_crc_scramler_tb/crc_gen_dat
add wave -noupdate /sata_crc_scramler_tb/crc_gen_val
add wave -noupdate /sata_crc_scramler_tb/crc_gen_eop
add wave -noupdate /sata_crc_scramler_tb/crc_gen_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_crc_scramler_tb/scram_dat
add wave -noupdate /sata_crc_scramler_tb/scram_val
add wave -noupdate /sata_crc_scramler_tb/scram_eop
add wave -noupdate /sata_crc_scramler_tb/scram_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_crc_scramler_tb/descram_dat
add wave -noupdate /sata_crc_scramler_tb/descram_val
add wave -noupdate /sata_crc_scramler_tb/descram_eop
add wave -noupdate /sata_crc_scramler_tb/descram_rdy
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {61707 ps} 0}
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
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {256 ns}
