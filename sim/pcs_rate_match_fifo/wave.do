onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /pcs_rate_match_fifo/BYTES
add wave -noupdate -radix hexadecimal /pcs_rate_match_fifo/DPATTERN
add wave -noupdate -radix hexadecimal /pcs_rate_match_fifo/KPATTERN
add wave -noupdate -radix unsigned /pcs_rate_match_fifo/FIFOLEN
add wave -noupdate -radix unsigned /pcs_rate_match_fifo/MAXUSED
add wave -noupdate -radix unsigned /pcs_rate_match_fifo/MINUSED
add wave -noupdate -radix unsigned /pcs_rate_match_fifo/WTIME
add wave -noupdate -radix unsigned /pcs_rate_match_fifo/HALFFIFOLEN
add wave -noupdate -divider <NULL>
add wave -noupdate /pcs_rate_match_fifo/reset
add wave -noupdate /pcs_rate_match_fifo/rcv_clk
add wave -noupdate /pcs_rate_match_fifo/ref_clk
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /pcs_rate_match_fifo/rcv_data
add wave -noupdate -radix hexadecimal /pcs_rate_match_fifo/rcv_datak
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal /pcs_rate_match_fifo/ref_data
add wave -noupdate -radix hexadecimal /pcs_rate_match_fifo/ref_datak
add wave -noupdate -divider <NULL>
add wave -noupdate /pcs_rate_match_fifo/stat_rcv_del
add wave -noupdate /pcs_rate_match_fifo/stat_rcv_ovfl
add wave -noupdate /pcs_rate_match_fifo/stat_ref_ins
add wave -noupdate /pcs_rate_match_fifo/stat_ref_unfl
add wave -noupdate -divider <NULL>
add wave -noupdate /pcs_rate_match_fifo/rcv_reset
add wave -noupdate /pcs_rate_match_fifo/ref_reset
add wave -noupdate -color {Cornflower Blue} /pcs_rate_match_fifo/wr_state
add wave -noupdate -color {Cornflower Blue} /pcs_rate_match_fifo/rd_state
add wave -noupdate -radix hexadecimal /pcs_rate_match_fifo/rcv_data_reg
add wave -noupdate -radix hexadecimal /pcs_rate_match_fifo/rcv_datak_reg
add wave -noupdate /pcs_rate_match_fifo/rcv_patdet_reg
add wave -noupdate -radix hexadecimal /pcs_rate_match_fifo/ref_data_int
add wave -noupdate -radix hexadecimal /pcs_rate_match_fifo/ref_datak_int
add wave -noupdate -radix hexadecimal /pcs_rate_match_fifo/ref_data_reg
add wave -noupdate -radix hexadecimal /pcs_rate_match_fifo/ref_datak_reg
add wave -noupdate /pcs_rate_match_fifo/ref_patdet_reg
add wave -noupdate /pcs_rate_match_fifo/fifo_wrreq
add wave -noupdate /pcs_rate_match_fifo/fifo_wrfull
add wave -noupdate /pcs_rate_match_fifo/fifo_wrempty
add wave -noupdate -radix unsigned -childformat {{{/pcs_rate_match_fifo/fifo_wrusedw[5]} -radix unsigned} {{/pcs_rate_match_fifo/fifo_wrusedw[4]} -radix unsigned} {{/pcs_rate_match_fifo/fifo_wrusedw[3]} -radix unsigned} {{/pcs_rate_match_fifo/fifo_wrusedw[2]} -radix unsigned} {{/pcs_rate_match_fifo/fifo_wrusedw[1]} -radix unsigned} {{/pcs_rate_match_fifo/fifo_wrusedw[0]} -radix unsigned}} -subitemconfig {{/pcs_rate_match_fifo/fifo_wrusedw[5]} {-radix unsigned} {/pcs_rate_match_fifo/fifo_wrusedw[4]} {-radix unsigned} {/pcs_rate_match_fifo/fifo_wrusedw[3]} {-radix unsigned} {/pcs_rate_match_fifo/fifo_wrusedw[2]} {-radix unsigned} {/pcs_rate_match_fifo/fifo_wrusedw[1]} {-radix unsigned} {/pcs_rate_match_fifo/fifo_wrusedw[0]} {-radix unsigned}} /pcs_rate_match_fifo/fifo_wrusedw
add wave -noupdate -radix unsigned -childformat {{{/pcs_rate_match_fifo/fifo_wrcnt[6]} -radix unsigned} {{/pcs_rate_match_fifo/fifo_wrcnt[5]} -radix unsigned} {{/pcs_rate_match_fifo/fifo_wrcnt[4]} -radix unsigned} {{/pcs_rate_match_fifo/fifo_wrcnt[3]} -radix unsigned} {{/pcs_rate_match_fifo/fifo_wrcnt[2]} -radix unsigned} {{/pcs_rate_match_fifo/fifo_wrcnt[1]} -radix unsigned} {{/pcs_rate_match_fifo/fifo_wrcnt[0]} -radix unsigned}} -subitemconfig {{/pcs_rate_match_fifo/fifo_wrcnt[6]} {-radix unsigned} {/pcs_rate_match_fifo/fifo_wrcnt[5]} {-radix unsigned} {/pcs_rate_match_fifo/fifo_wrcnt[4]} {-radix unsigned} {/pcs_rate_match_fifo/fifo_wrcnt[3]} {-radix unsigned} {/pcs_rate_match_fifo/fifo_wrcnt[2]} {-radix unsigned} {/pcs_rate_match_fifo/fifo_wrcnt[1]} {-radix unsigned} {/pcs_rate_match_fifo/fifo_wrcnt[0]} {-radix unsigned}} /pcs_rate_match_fifo/fifo_wrcnt
add wave -noupdate /pcs_rate_match_fifo/fifo_rdreq
add wave -noupdate /pcs_rate_match_fifo/fifo_rdfull
add wave -noupdate /pcs_rate_match_fifo/fifo_rdempty
add wave -noupdate -radix unsigned /pcs_rate_match_fifo/fifo_rdusedw
add wave -noupdate -radix unsigned /pcs_rate_match_fifo/fifo_rdcnt
add wave -noupdate -radix unsigned /pcs_rate_match_fifo/wr_wait_cnt
add wave -noupdate /pcs_rate_match_fifo/wr_wait_inc
add wave -noupdate -radix unsigned /pcs_rate_match_fifo/rd_wait_cnt
add wave -noupdate /pcs_rate_match_fifo/rd_wait_inc
add wave -noupdate /pcs_rate_match_fifo/rcv_del_reg
add wave -noupdate /pcs_rate_match_fifo/rcv_ovfl_reg
add wave -noupdate /pcs_rate_match_fifo/ref_ins_reg
add wave -noupdate /pcs_rate_match_fifo/ref_unfl_reg
add wave -noupdate -radix hexadecimal /pcs_rate_match_fifo/wr_st
add wave -noupdate -radix hexadecimal /pcs_rate_match_fifo/rd_st
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {368680000 ps} 0}
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
WaveRestoreZoom {257563201 ps} {519707201 ps}
