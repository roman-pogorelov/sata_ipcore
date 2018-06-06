onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sata_link_layer_tb/reset
add wave -noupdate /sata_link_layer_tb/clk
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_link_layer_tb/tx_fis_dat
add wave -noupdate /sata_link_layer_tb/tx_fis_val
add wave -noupdate /sata_link_layer_tb/tx_fis_eop
add wave -noupdate /sata_link_layer_tb/tx_fis_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_link_layer_tb/rx_fis_dat
add wave -noupdate /sata_link_layer_tb/rx_fis_val
add wave -noupdate /sata_link_layer_tb/rx_fis_eop
add wave -noupdate /sata_link_layer_tb/rx_fis_err
add wave -noupdate /sata_link_layer_tb/rx_fis_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -color {Slate Blue} /sata_link_layer_tb/sata_link_layer_tx/state
add wave -noupdate /sata_link_layer_tb/trm_ready
add wave -noupdate -radix hexadecimal /sata_link_layer_tb/trm_phy_data
add wave -noupdate /sata_link_layer_tb/trm_phy_datak
add wave -noupdate -radix hexadecimal /sata_link_layer_tb/trm_phy_data_dly
add wave -noupdate /sata_link_layer_tb/trm_phy_datak_dly
add wave -noupdate -divider <NULL>
add wave -noupdate -color {Slate Blue} /sata_link_layer_tb/sata_link_layer_rx/state
add wave -noupdate /sata_link_layer_tb/rcv_ready
add wave -noupdate -radix hexadecimal /sata_link_layer_tb/rcv_phy_data
add wave -noupdate /sata_link_layer_tb/rcv_phy_datak
add wave -noupdate -radix hexadecimal /sata_link_layer_tb/rcv_phy_data_dly
add wave -noupdate /sata_link_layer_tb/rcv_phy_datak_dly
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_link_layer_tb/trm_fsm_code
add wave -noupdate /sata_link_layer_tb/trm_link_busy
add wave -noupdate -radix hexadecimal /sata_link_layer_tb/trm_link_result
add wave -noupdate /sata_link_layer_tb/trm_rx_fifo_ovfl
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_link_layer_tb/rcv_fsm_code
add wave -noupdate /sata_link_layer_tb/rcv_link_busy
add wave -noupdate -radix hexadecimal /sata_link_layer_tb/rcv_link_result
add wave -noupdate /sata_link_layer_tb/rcv_rx_fifo_ovfl
add wave -noupdate -divider <NULL>
add wave -noupdate -color Salmon -radix hexadecimal /sata_link_layer_tb/sata_link_layer_tx/the_sata_link_tx_path/fifo_data
add wave -noupdate -color Salmon /sata_link_layer_tb/sata_link_layer_tx/the_sata_link_tx_path/fifo_eop
add wave -noupdate -color Salmon /sata_link_layer_tb/sata_link_layer_tx/the_sata_link_tx_path/fifo_rdreq
add wave -noupdate -color Salmon /sata_link_layer_tb/sata_link_layer_tx/the_sata_link_tx_path/fifo_empty
add wave -noupdate -color Salmon /sata_link_layer_tb/sata_link_layer_tx/the_sata_link_tx_path/fifo_almostempty
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {13853504 ps} 0}
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
WaveRestoreZoom {12728246 ps} {19185334 ps}
