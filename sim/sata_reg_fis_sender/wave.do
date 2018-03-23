onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sata_reg_fis_sender/reset
add wave -noupdate /sata_reg_fis_sender/clk
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_reg_fis_sender/i_dat_type
add wave -noupdate -radix hexadecimal /sata_reg_fis_sender/i_dat_command
add wave -noupdate -radix hexadecimal /sata_reg_fis_sender/i_dat_address
add wave -noupdate -radix hexadecimal /sata_reg_fis_sender/i_dat_scount
add wave -noupdate /sata_reg_fis_sender/i_val
add wave -noupdate /sata_reg_fis_sender/i_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_reg_fis_sender/o_dat
add wave -noupdate /sata_reg_fis_sender/o_val
add wave -noupdate /sata_reg_fis_sender/o_eop
add wave -noupdate /sata_reg_fis_sender/o_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal -childformat {{{/sata_reg_fis_sender/fis_reg[4]} -radix hexadecimal} {{/sata_reg_fis_sender/fis_reg[3]} -radix hexadecimal} {{/sata_reg_fis_sender/fis_reg[2]} -radix hexadecimal} {{/sata_reg_fis_sender/fis_reg[1]} -radix hexadecimal} {{/sata_reg_fis_sender/fis_reg[0]} -radix hexadecimal}} -subitemconfig {{/sata_reg_fis_sender/fis_reg[4]} {-height 15 -radix hexadecimal} {/sata_reg_fis_sender/fis_reg[3]} {-height 15 -radix hexadecimal} {/sata_reg_fis_sender/fis_reg[2]} {-height 15 -radix hexadecimal} {/sata_reg_fis_sender/fis_reg[1]} {-height 15 -radix hexadecimal} {/sata_reg_fis_sender/fis_reg[0]} {-height 15 -radix hexadecimal}} /sata_reg_fis_sender/fis_reg
add wave -noupdate /sata_reg_fis_sender/rdy_reg
add wave -noupdate /sata_reg_fis_sender/eop_reg
add wave -noupdate -radix hexadecimal /sata_reg_fis_sender/len_cnt
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {22 ns} 0}
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
WaveRestoreZoom {0 ns} {380 ns}
