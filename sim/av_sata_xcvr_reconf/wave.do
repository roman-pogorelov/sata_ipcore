onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /av_sata_xcvr_reconf/reset
add wave -noupdate /av_sata_xcvr_reconf/clk
add wave -noupdate -divider <NULL>
add wave -noupdate /av_sata_xcvr_reconf/cmd_reconfig
add wave -noupdate -radix hexadecimal /av_sata_xcvr_reconf/cmd_sata_gen
add wave -noupdate /av_sata_xcvr_reconf/cmd_ready
add wave -noupdate -divider <NULL>
add wave -noupdate -radix hexadecimal -childformat {{{/av_sata_xcvr_reconf/recfg_addr[6]} -radix hexadecimal} {{/av_sata_xcvr_reconf/recfg_addr[5]} -radix hexadecimal} {{/av_sata_xcvr_reconf/recfg_addr[4]} -radix hexadecimal} {{/av_sata_xcvr_reconf/recfg_addr[3]} -radix hexadecimal} {{/av_sata_xcvr_reconf/recfg_addr[2]} -radix hexadecimal} {{/av_sata_xcvr_reconf/recfg_addr[1]} -radix hexadecimal} {{/av_sata_xcvr_reconf/recfg_addr[0]} -radix hexadecimal}} -subitemconfig {{/av_sata_xcvr_reconf/recfg_addr[6]} {-radix hexadecimal} {/av_sata_xcvr_reconf/recfg_addr[5]} {-radix hexadecimal} {/av_sata_xcvr_reconf/recfg_addr[4]} {-radix hexadecimal} {/av_sata_xcvr_reconf/recfg_addr[3]} {-radix hexadecimal} {/av_sata_xcvr_reconf/recfg_addr[2]} {-radix hexadecimal} {/av_sata_xcvr_reconf/recfg_addr[1]} {-radix hexadecimal} {/av_sata_xcvr_reconf/recfg_addr[0]} {-radix hexadecimal}} /av_sata_xcvr_reconf/recfg_addr
add wave -noupdate /av_sata_xcvr_reconf/recfg_wreq
add wave -noupdate -radix hexadecimal /av_sata_xcvr_reconf/recfg_wdat
add wave -noupdate /av_sata_xcvr_reconf/recfg_rreq
add wave -noupdate -radix hexadecimal /av_sata_xcvr_reconf/recfg_rdat
add wave -noupdate /av_sata_xcvr_reconf/recfg_busy
add wave -noupdate -divider <NULL>
add wave -noupdate -radix unsigned /av_sata_xcvr_reconf/write_cnt
add wave -noupdate -radix unsigned /av_sata_xcvr_reconf/wait_cnt
add wave -noupdate /av_sata_xcvr_reconf/ready_reg
add wave -noupdate -radix hexadecimal -childformat {{{/av_sata_xcvr_reconf/offset_reg[3]} -radix hexadecimal} {{/av_sata_xcvr_reconf/offset_reg[2]} -radix hexadecimal} {{/av_sata_xcvr_reconf/offset_reg[1]} -radix hexadecimal} {{/av_sata_xcvr_reconf/offset_reg[0]} -radix hexadecimal}} -subitemconfig {{/av_sata_xcvr_reconf/offset_reg[3]} {-radix hexadecimal} {/av_sata_xcvr_reconf/offset_reg[2]} {-radix hexadecimal} {/av_sata_xcvr_reconf/offset_reg[1]} {-radix hexadecimal} {/av_sata_xcvr_reconf/offset_reg[0]} {-radix hexadecimal}} /av_sata_xcvr_reconf/offset_reg
add wave -noupdate -radix hexadecimal -childformat {{{/av_sata_xcvr_reconf/param_reg[3]} -radix hexadecimal} {{/av_sata_xcvr_reconf/param_reg[2]} -radix hexadecimal} {{/av_sata_xcvr_reconf/param_reg[1]} -radix hexadecimal} {{/av_sata_xcvr_reconf/param_reg[0]} -radix hexadecimal}} -subitemconfig {{/av_sata_xcvr_reconf/param_reg[3]} {-radix hexadecimal} {/av_sata_xcvr_reconf/param_reg[2]} {-radix hexadecimal} {/av_sata_xcvr_reconf/param_reg[1]} {-radix hexadecimal} {/av_sata_xcvr_reconf/param_reg[0]} {-radix hexadecimal}} /av_sata_xcvr_reconf/param_reg
add wave -noupdate -radix hexadecimal /av_sata_xcvr_reconf/addr_reg
add wave -noupdate /av_sata_xcvr_reconf/wreq_reg
add wave -noupdate -radix hexadecimal /av_sata_xcvr_reconf/wdat_reg
add wave -noupdate /av_sata_xcvr_reconf/rreq_reg
add wave -noupdate -divider <NULL>
add wave -noupdate -color {Slate Blue} /av_sata_xcvr_reconf/cstate
add wave -noupdate /av_sata_xcvr_reconf/nstate
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {46 ns} 0}
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
WaveRestoreZoom {0 ns} {588 ns}
