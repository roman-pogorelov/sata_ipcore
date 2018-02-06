vlog -work work ../../hdl/verilog/sata_oob_coder.sv
vlog -work work ../../hdl/verilog/sata_oob_decoder.sv
vlog -work work ./sata_oob_coder_decoder_tb.sv
vopt work.sata_oob_coder_decoder_tb +acc -o sata_oob_coder_decoder_tb_opt
vsim -fsmdebug work.sata_oob_coder_decoder_tb_opt

do wave.do

run 30001ps
