onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sata_oob_coder_decoder_tb/reset
add wave -noupdate /sata_oob_coder_decoder_tb/clk
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_oob_coder_decoder_tb/txready
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_oob_coder_decoder_tb/txcominit
add wave -noupdate /sata_oob_coder_decoder_tb/txcomwake
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_oob_coder_decoder_tb/elecidle
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_oob_coder_decoder_tb/rxcominit
add wave -noupdate /sata_oob_coder_decoder_tb/rxcomwake
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
add wave -noupdate -radix unsigned /sata_oob_coder_decoder_tb/the_sata_oob_coder/CLKFREQ
add wave -noupdate -radix unsigned /sata_oob_coder_decoder_tb/the_sata_oob_coder/REFFREQ
add wave -noupdate -radix unsigned /sata_oob_coder_decoder_tb/the_sata_oob_coder/BURST
add wave -noupdate -radix unsigned /sata_oob_coder_decoder_tb/the_sata_oob_coder/GAPINIT
add wave -noupdate -radix unsigned /sata_oob_coder_decoder_tb/the_sata_oob_coder/GAPWAKE
add wave -noupdate -radix unsigned /sata_oob_coder_decoder_tb/the_sata_oob_coder/BURSTWIDTH
add wave -noupdate -radix unsigned /sata_oob_coder_decoder_tb/the_sata_oob_coder/GAPWIDTH
add wave -noupdate -radix unsigned /sata_oob_coder_decoder_tb/the_sata_oob_coder/AMOUNT
add wave -noupdate /sata_oob_coder_decoder_tb/the_sata_oob_coder/ready
add wave -noupdate /sata_oob_coder_decoder_tb/the_sata_oob_coder/cominit
add wave -noupdate /sata_oob_coder_decoder_tb/the_sata_oob_coder/comwake
add wave -noupdate /sata_oob_coder_decoder_tb/the_sata_oob_coder/txelecidle
add wave -noupdate -radix unsigned /sata_oob_coder_decoder_tb/the_sata_oob_coder/burst_len_cnt
add wave -noupdate -radix unsigned /sata_oob_coder_decoder_tb/the_sata_oob_coder/gap_len_cnt
add wave -noupdate -radix unsigned /sata_oob_coder_decoder_tb/the_sata_oob_coder/burst_cnt
add wave -noupdate /sata_oob_coder_decoder_tb/the_sata_oob_coder/txelecidle_reg
add wave -noupdate /sata_oob_coder_decoder_tb/the_sata_oob_coder/state
add wave -noupdate -radix hexadecimal /sata_oob_coder_decoder_tb/the_sata_oob_coder/st
add wave -noupdate /sata_oob_coder_decoder_tb/the_sata_oob_coder/comtype
add wave -noupdate /sata_oob_coder_decoder_tb/the_sata_oob_coder/elstate
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {38316 ps} 0}
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
