vlog +incdir+../../hdl/ -work work ../../hdl/sata_cont_inserter.sv
vopt work.sata_cont_inserter +acc -o sata_cont_inserter_opt
vsim work.sata_cont_inserter_opt
do wave.do

force reset 1 0ns, 0 15ns
force clk 1 0ns, 0 5ns -r 10ns
force i_data 0
force i_datak 0
force o_ready 0 0ns, 1 1ns, 0 301ns -r 320ns

run 30001ps