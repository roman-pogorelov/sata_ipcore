vlog +incdir+../../hdl/ -work work ../../hdl/sata_fis_router.sv
vopt work.sata_fis_router +acc -o sata_fis_router_opt
vsim work.sata_fis_router_opt
do wave.do

force reset 1 0ns, 0 15ns
force clk 1 0ns, 0 5ns -r 10ns

force rx_dat 0
force rx_val 0
force rx_eop 0
force rx_err 0
force reg_pio_rdy 1
force dma_act_rdy 1
force data_rdy 1
force default_rdy 1

run 30001ps