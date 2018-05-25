onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sata_fis_router/reset
add wave -noupdate /sata_fis_router/clk
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_fis_router/rx_dat
add wave -noupdate /sata_fis_router/rx_val
add wave -noupdate /sata_fis_router/rx_eop
add wave -noupdate /sata_fis_router/rx_err
add wave -noupdate /sata_fis_router/rx_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_fis_router/reg_pio_dat
add wave -noupdate /sata_fis_router/reg_pio_val
add wave -noupdate /sata_fis_router/reg_pio_eop
add wave -noupdate /sata_fis_router/reg_pio_err
add wave -noupdate /sata_fis_router/reg_pio_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_fis_router/dma_act_dat
add wave -noupdate /sata_fis_router/dma_act_val
add wave -noupdate /sata_fis_router/dma_act_eop
add wave -noupdate /sata_fis_router/dma_act_err
add wave -noupdate /sata_fis_router/dma_act_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_fis_router/data_dat
add wave -noupdate /sata_fis_router/data_val
add wave -noupdate /sata_fis_router/data_eop
add wave -noupdate /sata_fis_router/data_err
add wave -noupdate /sata_fis_router/data_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_fis_router/default_dat
add wave -noupdate /sata_fis_router/default_val
add wave -noupdate /sata_fis_router/default_eop
add wave -noupdate /sata_fis_router/default_err
add wave -noupdate /sata_fis_router/default_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_fis_router/rx_sop_reg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {27 ns} 0}
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
WaveRestoreZoom {0 ns} {544 ns}
