onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sata_reg_fis_receiver/reset
add wave -noupdate /sata_reg_fis_receiver/clk
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_reg_fis_receiver/i_dat
add wave -noupdate /sata_reg_fis_receiver/i_val
add wave -noupdate /sata_reg_fis_receiver/i_eop
add wave -noupdate /sata_reg_fis_receiver/i_err
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_reg_fis_receiver/o_dat_type
add wave -noupdate -radix hexadecimal /sata_reg_fis_receiver/o_dat_status
add wave -noupdate -radix hexadecimal /sata_reg_fis_receiver/o_dat_error
add wave -noupdate -radix hexadecimal /sata_reg_fis_receiver/o_dat_address
add wave -noupdate -radix hexadecimal /sata_reg_fis_receiver/o_dat_scount
add wave -noupdate -radix hexadecimal /sata_reg_fis_receiver/o_dat_tcount
add wave -noupdate /sata_reg_fis_receiver/o_dat_badcrc
add wave -noupdate /sata_reg_fis_receiver/o_val
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_reg_fis_receiver/val_reg
add wave -noupdate -radix hexadecimal -childformat {{{/sata_reg_fis_receiver/pos_reg[5]} -radix hexadecimal} {{/sata_reg_fis_receiver/pos_reg[4]} -radix hexadecimal} {{/sata_reg_fis_receiver/pos_reg[3]} -radix hexadecimal} {{/sata_reg_fis_receiver/pos_reg[2]} -radix hexadecimal} {{/sata_reg_fis_receiver/pos_reg[1]} -radix hexadecimal} {{/sata_reg_fis_receiver/pos_reg[0]} -radix hexadecimal}} -subitemconfig {{/sata_reg_fis_receiver/pos_reg[5]} {-radix hexadecimal} {/sata_reg_fis_receiver/pos_reg[4]} {-radix hexadecimal} {/sata_reg_fis_receiver/pos_reg[3]} {-radix hexadecimal} {/sata_reg_fis_receiver/pos_reg[2]} {-radix hexadecimal} {/sata_reg_fis_receiver/pos_reg[1]} {-radix hexadecimal} {/sata_reg_fis_receiver/pos_reg[0]} {-radix hexadecimal}} /sata_reg_fis_receiver/pos_reg
add wave -noupdate -radix hexadecimal /sata_reg_fis_receiver/fis_reg
add wave -noupdate /sata_reg_fis_receiver/crc_reg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {40 ns} 0}
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
