onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /pcs_byte_aligner/BYTES
add wave -noupdate -radix unsigned /pcs_byte_aligner/BWIDTH
add wave -noupdate -divider <NULL>
add wave -noupdate /pcs_byte_aligner/reset
add wave -noupdate /pcs_byte_aligner/clk
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /pcs_byte_aligner/i_data
add wave -noupdate -radix hexadecimal /pcs_byte_aligner/i_datak
add wave -noupdate -radix hexadecimal /pcs_byte_aligner/i_patdet
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /pcs_byte_aligner/o_data
add wave -noupdate -radix hexadecimal /pcs_byte_aligner/o_datak
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /pcs_byte_aligner/patdet_code
add wave -noupdate -radix hexadecimal /pcs_byte_aligner/patdet_code_reg
add wave -noupdate -radix hexadecimal /pcs_byte_aligner/data_hold_reg
add wave -noupdate -radix hexadecimal /pcs_byte_aligner/datak_hold_reg
add wave -noupdate -radix hexadecimal /pcs_byte_aligner/data_cat
add wave -noupdate -radix hexadecimal /pcs_byte_aligner/datak_cat
add wave -noupdate -radix hexadecimal /pcs_byte_aligner/data_reg
add wave -noupdate -radix hexadecimal /pcs_byte_aligner/datak_reg
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
