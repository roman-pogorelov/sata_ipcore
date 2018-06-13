onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /sata_oob_decoder/BURST_MIN
add wave -noupdate -radix unsigned /sata_oob_decoder/BURST_MAX
add wave -noupdate -radix unsigned /sata_oob_decoder/GAPINIT_MIN
add wave -noupdate -radix unsigned /sata_oob_decoder/GAPINIT_MAX
add wave -noupdate -radix unsigned /sata_oob_decoder/GAPWAKE_MIN
add wave -noupdate -radix unsigned /sata_oob_decoder/GAPWAKE_MAX
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_oob_decoder/reset
add wave -noupdate /sata_oob_decoder/clk
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_oob_decoder/rxsignaldetect
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_oob_decoder/cominit
add wave -noupdate /sata_oob_decoder/comwake
add wave -noupdate /sata_oob_decoder/oobfinish
add wave -noupdate -divider <NULL>
add wave -noupdate /sata_oob_decoder/sigdet
add wave -noupdate /sata_oob_decoder/sigdet_rise
add wave -noupdate /sata_oob_decoder/sigdet_fall
add wave -noupdate /sata_oob_decoder/sigdet_change
add wave -noupdate -radix unsigned /sata_oob_decoder/cont_cnt
add wave -noupdate /sata_oob_decoder/burst_det_reg
add wave -noupdate /sata_oob_decoder/gapinit_det_reg
add wave -noupdate /sata_oob_decoder/gapwake_det_reg
add wave -noupdate /sata_oob_decoder/high_cont_reg
add wave -noupdate /sata_oob_decoder/low_cont_reg
add wave -noupdate -radix unsigned /sata_oob_decoder/burst_cnt
add wave -noupdate -radix unsigned /sata_oob_decoder/gapinit_cnt
add wave -noupdate -radix unsigned /sata_oob_decoder/gapwake_cnt
add wave -noupdate /sata_oob_decoder/cominit_reg
add wave -noupdate /sata_oob_decoder/comwake_reg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3049 ns} 0}
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
WaveRestoreZoom {0 ns} {16 us}
