vlog +incdir+../../hdl/ -work work ../../hdl/sata_dma_engine.sv
vlog +incdir+../../hdl/ -work work ../../hdl/sata_dma_resync_buffer.sv
vlog +incdir+../../hdl/ -work work ../../hdl/sata_dma_stream_demux.sv
vlog +incdir+../../hdl/ -work work ../../hdl/sata_dma_stream_mux.sv
vlog +incdir+../../hdl/ -work work ../../hdl/sata_identify_parser.sv
vlog +incdir+../../hdl/ -work work ../../hdl/sata_reg_fis_receiver.sv
vlog +incdir+../../hdl/ -work work ../../hdl/sata_reg_fis_sender.sv
vopt work.sata_dma_engine +acc -o sata_dma_engine_opt -L altera_mf_ver
vsim -fsmdebug work.sata_dma_engine_opt

do wave.do

force usr_reset 1 0ns, 0 30ns
force usr_clk 1 0ns, 0 10ns -r 20ns

force sata_reset 1 0ns, 0 15ns
force sata_clk 1 0ns, 0 5ns -r 10ns

force usr_cmd_valid 0
force usr_cmd_type 0
force usr_cmd_address 0
force usr_cmd_size 0

force usr_wr_dat 0
force usr_wr_val 0

force usr_rd_rdy 1

force sata_tx_rdy 1

force sata_rx_dat 0
force sata_rx_val 0
force sata_rx_eop 0
force sata_rx_err 0

force sata_link_busy 0
force sata_link_result 0

run 50001ps