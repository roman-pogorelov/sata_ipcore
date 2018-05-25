vlog +incdir+../../hdl/ -work work ../../hdl/sata_fis_arbiter.sv
vopt work.sata_fis_arbiter +acc -o sata_fis_arbiter_opt
vsim work.sata_fis_arbiter_opt
do wave.do

force reset 1 0ns, 0 15ns
force clk 1 0ns, 0 5ns -r 10ns

force i1_dat 'h11
force i1_val 0
force i1_eop 0
force i2_dat 'h22
force i2_val 0
force i2_eop 0
force o_rdy 1

run 30001ps