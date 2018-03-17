vlog +incdir+../../hdl/ -work work ../../hdl/sata_fis_extractor.sv
vopt work.sata_fis_extractor +acc -o sata_fis_extractor_opt
vsim work.sata_fis_extractor_opt
do wave.do

force reset 1 0ns, 0 15ns
force clk 1 0ns, 0 5ns -r 10ns
force rx_data 32'hb5b5957c
force rx_datak 1

run 30001ps