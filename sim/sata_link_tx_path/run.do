vlog +incdir+../../hdl/ -work work ../../hdl/sata_crc_generator.sv
vlog +incdir+../../hdl/ -work work ../../hdl/sata_scrambler.sv
vlog +incdir+../../hdl/ -work work ../../hdl/sata_link_fifo.sv
vlog +incdir+../../hdl/ -work work ../../hdl/sata_link_tx_path.sv
vopt work.sata_link_tx_path +acc -o sata_link_tx_path_opt -L altera_mf_ver
vsim work.sata_link_tx_path_opt
do wave.do

force reset 1 0ns, 0 15ns
force clk 1 0ns, 0 5ns -r 10ns

force tx_dat 0
force tx_val 0
force tx_eop 0
force fifo_rdreq 0

run 30001ps
