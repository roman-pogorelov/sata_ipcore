onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sata_link_layer/reset
add wave -noupdate /sata_link_layer/clk
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_link_layer/tx_fis_dat
add wave -noupdate /sata_link_layer/tx_fis_val
add wave -noupdate /sata_link_layer/tx_fis_eop
add wave -noupdate /sata_link_layer/tx_fis_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_link_layer/rx_fis_dat
add wave -noupdate /sata_link_layer/rx_fis_val
add wave -noupdate /sata_link_layer/rx_fis_eop
add wave -noupdate /sata_link_layer/rx_fis_err
add wave -noupdate /sata_link_layer/rx_fis_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_link_layer/trans_req
add wave -noupdate /sata_link_layer/trans_ack
add wave -noupdate /sata_link_layer/trans_err
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_link_layer/phy_tx_data
add wave -noupdate /sata_link_layer/phy_tx_datak
add wave -noupdate /sata_link_layer/phy_tx_ready
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_link_layer/phy_rx_data
add wave -noupdate /sata_link_layer/phy_rx_datak
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_link_layer/stat_fsm_code
add wave -noupdate /sata_link_layer/stat_link_busy
add wave -noupdate -radix hexadecimal /sata_link_layer/stat_link_result
add wave -noupdate /sata_link_layer/stat_rx_fifo_ovfl
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_link_layer/state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {62958 ps} 0}
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
