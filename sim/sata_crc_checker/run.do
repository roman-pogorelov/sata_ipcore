vlog +incdir+../../hdl/ -work work ../../hdl/sata_crc_checker.sv
vopt work.sata_crc_checker +acc -o sata_crc_checker_opt
vsim work.sata_crc_checker_opt
do wave.do

force reset 1 0ns, 0 15ns
force clk 1 0ns, 0 5ns -r 10ns

force i_dat 0
force i_val 0
force i_eop 0

force o_rdy 0

run 30001ps
