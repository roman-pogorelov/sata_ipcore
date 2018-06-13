onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sata_fis_arbiter/reset
add wave -noupdate /sata_fis_arbiter/clk
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_fis_arbiter/i1_dat
add wave -noupdate /sata_fis_arbiter/i1_val
add wave -noupdate /sata_fis_arbiter/i1_eop
add wave -noupdate /sata_fis_arbiter/i1_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_fis_arbiter/i2_dat
add wave -noupdate /sata_fis_arbiter/i2_val
add wave -noupdate /sata_fis_arbiter/i2_eop
add wave -noupdate /sata_fis_arbiter/i2_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_fis_arbiter/o_dat
add wave -noupdate /sata_fis_arbiter/o_val
add wave -noupdate /sata_fis_arbiter/o_eop
add wave -noupdate /sata_fis_arbiter/o_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_fis_arbiter/sop_reg
add wave -noupdate /sata_fis_arbiter/select
add wave -noupdate /sata_fis_arbiter/selected_reg
add wave -noupdate /sata_fis_arbiter/selected
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {103 ns} 0}
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
WaveRestoreZoom {0 ns} {1 us}
