vlog -work work ../../hdl/pcs_rate_match_fifo.sv
vopt work.pcs_rate_match_fifo +acc -o pcs_rate_match_fifo_opt -L altera_mf_ver
vsim -fsmdebug work.pcs_rate_match_fifo_opt

do wave.do

force reset 1 0ns, 0 10ns

force rcv_clk 1 0ps, 0 5000ps -r 10000ps
force ref_clk 1 0ps, 0 5004ps -r 10008ps
force rcv_data 0
force rcv_datak 0

run 30001ps

force  rcv_data 32'h00000000 0ps, 32'h7B4A4ABC 2540000ps -r 2560000ps
force  rcv_datak 4'h0 0ps, 4'h1 2540000ps -r 2560000ps