vlog -work work ../../hdl/verilog/pcs_byte_aligner.sv
vopt work.pcs_byte_aligner +acc -o pcs_byte_aligner_opt
vsim work.pcs_byte_aligner_opt
do wave.do

force reset 1 0ns, 0 10ns
force clk 1 0ns, 0 5ns -r 10ns
force i_data 32'h28727b4A 0ns, 32'h4ABCA54B 10ns -r 20ns
force i_datak 4'h0 0ns, 4'h4 10ns -r 20ns
force i_patdet 0

run 30001ps