onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sata_link_tx_path/reset
add wave -noupdate /sata_link_tx_path/clk
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_link_tx_path/tx_dat
add wave -noupdate /sata_link_tx_path/tx_val
add wave -noupdate /sata_link_tx_path/tx_eop
add wave -noupdate /sata_link_tx_path/tx_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_link_tx_path/fifo_data
add wave -noupdate /sata_link_tx_path/fifo_eop
add wave -noupdate /sata_link_tx_path/fifo_rdreq
add wave -noupdate /sata_link_tx_path/fifo_empty
add wave -noupdate /sata_link_tx_path/fifo_almostempty
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_link_tx_path/crc_dat
add wave -noupdate /sata_link_tx_path/crc_val
add wave -noupdate /sata_link_tx_path/crc_eop
add wave -noupdate /sata_link_tx_path/crc_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_link_tx_path/scram_dat
add wave -noupdate /sata_link_tx_path/scram_val
add wave -noupdate /sata_link_tx_path/scram_eop
add wave -noupdate /sata_link_tx_path/scram_rdyn
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {29161 ps} 0}
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
WaveRestoreZoom {0 ps} {512 ns}
