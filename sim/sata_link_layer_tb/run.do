vlog +incdir+../../hdl/ -work work ../../hdl/sata_crc_checker.sv
vlog +incdir+../../hdl/ -work work ../../hdl/sata_crc_generator.sv
vlog +incdir+../../hdl/ -work work ../../hdl/sata_scrambler.sv
vlog +incdir+../../hdl/ -work work ../../hdl/sata_link_fifo.sv
vlog +incdir+../../hdl/ -work work ../../hdl/sata_link_rx_path.sv
vlog +incdir+../../hdl/ -work work ../../hdl/sata_link_tx_path.sv
vlog +incdir+../../hdl/ -work work ../../hdl/sata_cont_extractor.sv
vlog +incdir+../../hdl/ -work work ../../hdl/sata_cont_inserter.sv
vlog +incdir+../../hdl/ -work work ../../hdl/sata_fis_extractor.sv
vlog +incdir+../../hdl/ -work work ../../hdl/sata_link_layer.sv
vlog +incdir+../../hdl/ -work work ./sata_link_layer_tb.sv
vopt work.sata_link_layer_tb +acc -o sata_link_layer_tb_opt -L altera_mf_ver
vsim -fsmdebug work.sata_link_layer_tb_opt
do wave.do
run 30001ps
