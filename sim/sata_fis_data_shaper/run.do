vlog +incdir+../../hdl/ -work work ../../hdl/sata_fis_data_shaper.sv
vopt work.sata_fis_data_shaper +acc -o sata_fis_data_shaper_opt
vsim work.sata_fis_data_shaper_opt
do wave.do

force reset 1 0ns, 0 15ns
force clk 1 0ns, 0 5ns -r 10ns

force ctl_valid 0
force ctl_count 0
force i_dat 'h11223344
force i_val 1
force o_rdy 1

run 30001ps