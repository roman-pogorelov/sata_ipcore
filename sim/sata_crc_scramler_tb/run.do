vlog +incdir+../../hdl/ -work work ../../hdl/sata_crc_generator.sv
vlog +incdir+../../hdl/ -work work ../../hdl/sata_crc_checker.sv
vlog +incdir+../../hdl/ -work work ../../hdl/sata_scrambler.sv
vlog +incdir+../../hdl/ -work work ./sata_crc_scramler_tb.sv
vopt work.sata_crc_scramler_tb +acc -o sata_crc_scramler_tb_opt
vsim work.sata_crc_scramler_tb_opt
do wave.do

run 30001ps
