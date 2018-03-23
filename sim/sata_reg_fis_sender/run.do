vlog +incdir+../../hdl/ -work work ../../hdl/sata_reg_fis_sender.sv
vopt work.sata_reg_fis_sender +acc -o sata_reg_fis_sender_opt
vsim work.sata_reg_fis_sender_opt
do wave.do

force reset 1 0ns, 0 15ns
force clk 1 0ns, 0 5ns -r 10ns

force i_dat_type 0
force i_dat_command 0
force i_dat_address 0
force i_dat_scount 0
force i_val 0
force o_rdy 0

run 30001ps