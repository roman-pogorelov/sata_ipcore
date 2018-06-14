vlog +incdir+../../hdl/ -work work ../../hdl/specific/arria10/a10_sata_xcvr_reconf.sv
vopt work.a10_sata_xcvr_reconf +acc -o a10_sata_xcvr_reconf_opt
vsim -fsmdebug work.a10_sata_xcvr_reconf_opt
do wave.do

force reset 1 0ns, 0 15ns
force clk 1 0ns, 0 5ns -r 10ns
force cmd_reconfig 0
force cmd_sata_gen 0
force recfg_rdat 0
force recfg_busy 1

run 30001ps