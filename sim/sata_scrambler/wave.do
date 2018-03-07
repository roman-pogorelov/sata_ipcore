onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sata_scrambler/reset
add wave -noupdate /sata_scrambler/clk
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_scrambler/i_dat
add wave -noupdate /sata_scrambler/i_val
add wave -noupdate /sata_scrambler/i_eop
add wave -noupdate /sata_scrambler/i_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_scrambler/o_dat
add wave -noupdate /sata_scrambler/o_val
add wave -noupdate /sata_scrambler/o_eop
add wave -noupdate /sata_scrambler/o_rdy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /sata_scrambler/lfsr
add wave -noupdate -radix hexadecimal /sata_scrambler/scram
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
