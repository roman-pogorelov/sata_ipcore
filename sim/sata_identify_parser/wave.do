onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sata_identify_parser/reset
add wave -noupdate /sata_identify_parser/clk
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_identify_parser/i_dat
add wave -noupdate /sata_identify_parser/i_val
add wave -noupdate /sata_identify_parser/i_eop
add wave -noupdate /sata_identify_parser/i_err
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_identify_parser/identify_done
add wave -noupdate /sata_identify_parser/sata1_supported
add wave -noupdate /sata_identify_parser/sata2_supported
add wave -noupdate /sata_identify_parser/sata3_supported
add wave -noupdate -radix hexadecimal /sata_identify_parser/max_lba_address
add wave -noupdate /sata_identify_parser/bad_checksum
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_identify_parser/sop_reg
add wave -noupdate -radix unsigned /sata_identify_parser/len_cnt
add wave -noupdate /sata_identify_parser/done_reg
add wave -noupdate -radix hexadecimal /sata_identify_parser/sata_supported_reg
add wave -noupdate -radix hexadecimal /sata_identify_parser/max_lba_low_reg
add wave -noupdate -radix hexadecimal /sata_identify_parser/max_lba_high_reg
add wave -noupdate /sata_identify_parser/bad_crc_reg
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
