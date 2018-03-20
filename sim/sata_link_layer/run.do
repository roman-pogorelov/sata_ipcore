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
vopt work.sata_link_layer +acc -o sata_link_layer_opt -L altera_mf_ver
vsim -fsmdebug work.sata_link_layer_opt
do wave.do

force reset 1 0ns, 0 15ns
force clk 1 0ns, 0 5ns -r 10ns

force tx_fis_dat 0
force tx_fis_val 0
force tx_fis_eop 0
force rx_fis_rdy 1
force trans_ack 0
force trans_err 0
force phy_tx_ready 1
force phy_rx_data 32'hb5b5957c
force phy_rx_datak 1

run 30001ps
