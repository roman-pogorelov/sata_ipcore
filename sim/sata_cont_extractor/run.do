vlog +incdir+../../hdl/ -work work ../../hdl/sata_cont_extractor.sv
vopt work.sata_cont_extractor +acc -o sata_cont_extractor_opt
vsim work.sata_cont_extractor_opt
do wave.do

force reset 1 0ns, 0 15ns
force clk 1 0ns, 0 5ns -r 10ns
force i_data 0
force i_datak 0

run 30001ps