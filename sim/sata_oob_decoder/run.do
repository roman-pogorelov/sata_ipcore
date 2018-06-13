vlog -work work ../../hdl/sata_oob_decoder.sv
vopt work.sata_oob_decoder +acc -o sata_oob_decoder_opt
vsim work.sata_oob_decoder_opt

do wave.do

force reset 1 0ns, 0 10ns
force clk 1 0ns, 0 5ns -r 10ns

force rxsignaldetect 0

run 30001ps