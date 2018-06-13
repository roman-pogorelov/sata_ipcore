vlog -work work ../../hdl/specific/arriav/av_sata_xcvr_reconf.sv
vopt work.av_sata_xcvr_reconf +acc -o av_sata_xcvr_reconf_opt
vsim -fsmdebug work.av_sata_xcvr_reconf_opt
do wave.do

force reset 1 0ns, 0 15ns
force clk 1 0ns, 0 5ns -r 10ns
force cmd_reconfig 0
force cmd_sata_gen 0
force recfg_rdat 0
force recfg_busy 1

run 30001ps