onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sata_dma_engine/usr_reset
add wave -noupdate /sata_dma_engine/usr_clk
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_dma_engine/sata_reset
add wave -noupdate /sata_dma_engine/sata_clk
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_dma_engine/usr_cmd_valid
add wave -noupdate /sata_dma_engine/usr_cmd_type
add wave -noupdate -radix hexadecimal /sata_dma_engine/usr_cmd_address
add wave -noupdate -radix hexadecimal /sata_dma_engine/usr_cmd_size
add wave -noupdate /sata_dma_engine/usr_cmd_ready
add wave -noupdate /sata_dma_engine/usr_cmd_fault
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_dma_engine/usr_info_valid
add wave -noupdate -radix hexadecimal /sata_dma_engine/usr_info_max_lba_address
add wave -noupdate -radix hexadecimal /sata_dma_engine/usr_info_sata_supported
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_dma_engine/usr_wr_dat
add wave -noupdate /sata_dma_engine/usr_wr_val
add wave -noupdate /sata_dma_engine/usr_wr_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_dma_engine/usr_rd_dat
add wave -noupdate /sata_dma_engine/usr_rd_val
add wave -noupdate /sata_dma_engine/usr_rd_eop
add wave -noupdate /sata_dma_engine/usr_rd_err
add wave -noupdate /sata_dma_engine/usr_rd_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_dma_engine/sata_tx_dat
add wave -noupdate /sata_dma_engine/sata_tx_val
add wave -noupdate /sata_dma_engine/sata_tx_eop
add wave -noupdate /sata_dma_engine/sata_tx_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_dma_engine/sata_rx_dat
add wave -noupdate /sata_dma_engine/sata_rx_val
add wave -noupdate /sata_dma_engine/sata_rx_eop
add wave -noupdate /sata_dma_engine/sata_rx_err
add wave -noupdate /sata_dma_engine/sata_rx_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_dma_engine/sata_link_busy
add wave -noupdate -radix hexadecimal /sata_dma_engine/sata_link_result
add wave -noupdate -divider <NULL>
add wave -noupdate -color {Cornflower Blue} /sata_dma_engine/cstate
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_dma_engine/buffer_reset
add wave -noupdate /sata_dma_engine/link_busy
add wave -noupdate -radix hexadecimal /sata_dma_engine/link_result
add wave -noupdate /sata_dma_engine/link_done
add wave -noupdate /sata_dma_engine/tx_select
add wave -noupdate -radix hexadecimal /sata_dma_engine/rx_select
add wave -noupdate -radix hexadecimal /sata_dma_engine/h2d_dat_command
add wave -noupdate -radix hexadecimal /sata_dma_engine/h2d_dat_address
add wave -noupdate -radix hexadecimal /sata_dma_engine/h2d_dat_scount
add wave -noupdate /sata_dma_engine/h2d_valid
add wave -noupdate /sata_dma_engine/h2d_ready
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_dma_engine/tx_dat
add wave -noupdate /sata_dma_engine/tx_val
add wave -noupdate /sata_dma_engine/tx_eop
add wave -noupdate /sata_dma_engine/tx_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_dma_engine/rx_dat
add wave -noupdate /sata_dma_engine/rx_val
add wave -noupdate /sata_dma_engine/rx_eop
add wave -noupdate /sata_dma_engine/rx_err
add wave -noupdate /sata_dma_engine/rx_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_dma_engine/reg_fis_tx_dat
add wave -noupdate /sata_dma_engine/reg_fis_tx_val
add wave -noupdate /sata_dma_engine/reg_fis_tx_eop
add wave -noupdate /sata_dma_engine/reg_fis_tx_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_dma_engine/reg_fis_rx_dat
add wave -noupdate /sata_dma_engine/reg_fis_rx_val
add wave -noupdate /sata_dma_engine/reg_fis_rx_eop
add wave -noupdate /sata_dma_engine/reg_fis_rx_err
add wave -noupdate /sata_dma_engine/reg_fis_rx_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_dma_engine/id_fis_rx_dat
add wave -noupdate /sata_dma_engine/id_fis_rx_val
add wave -noupdate /sata_dma_engine/id_fis_rx_eop
add wave -noupdate /sata_dma_engine/id_fis_rx_err
add wave -noupdate /sata_dma_engine/id_fis_rx_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_dma_engine/cmd_ready
add wave -noupdate /sata_dma_engine/cmd_ready_reg
add wave -noupdate /sata_dma_engine/cmd_fault
add wave -noupdate /sata_dma_engine/cmd_fault_reg
add wave -noupdate /sata_dma_engine/type_reg
add wave -noupdate -radix hexadecimal /sata_dma_engine/address_cnt
add wave -noupdate -radix hexadecimal /sata_dma_engine/max_address_reg
add wave -noupdate /sata_dma_engine/zero_size_reg
add wave -noupdate /sata_dma_engine/trans_start
add wave -noupdate /sata_dma_engine/trans_complete
add wave -noupdate -radix hexadecimal /sata_dma_engine/amount_cnt
add wave -noupdate -radix hexadecimal /sata_dma_engine/scount_reg
add wave -noupdate -radix hexadecimal /sata_dma_engine/data_fis_cnt
add wave -noupdate /sata_dma_engine/data_fis_complete
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_dma_engine/nstate
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3504919 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 194
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
WaveRestoreZoom {2504443 ps} {4478715 ps}
