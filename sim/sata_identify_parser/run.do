vlog +incdir+../../hdl/ -work work ../../hdl/sata_identify_parser.sv
vopt work.sata_identify_parser +acc -o sata_identify_parser_opt
vsim work.sata_identify_parser_opt
do wave.do

force reset 1 0ns, 0 15ns
force clk 1 0ns, 0 5ns -r 10ns

force i_dat 0
force i_val 0
force i_eop 0
force i_err 0

run 30001ps