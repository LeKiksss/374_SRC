# ModelSim script: compile design + testbench, then run AND testbench (datapath_tb)
# Usage: do run_and_test.do
# To run another testbench: change the last line (vsim ...) to tb_or, tb_add, etc.

vlib work
vlog -work work general_purpose_register.v
vlog -work work inc32.v
vlog -work work adder32.v
vlog -work work addsub32.v
vlog -work work mult32x32_booth.v
vlog -work work div32_nonrestoring.v
vlog -work work alu_core.v
vlog -work work mdr.v
vlog -work work datapath.v
vlog -work work datapath_top.v
vlog -work work testbench.v
vlog -work work tb_or.v
vlog -work work tb_add.v
vlog -work work tb_sub.v
vlog -work work tb_mul.v
vlog -work work tb_div.v
vlog -work work tb_shr.v
vlog -work work tb_shra.v
vlog -work work tb_shl.v
vlog -work work tb_ror.v
vlog -work work tb_rol.v
vlog -work work tb_neg.v
vlog -work work tb_not.v

# Run AND testbench (default). Change the module name to run another testbench:
# tb_or, tb_add, tb_sub, tb_mul, tb_div, tb_shr, tb_shra, tb_shl, tb_ror, tb_rol, tb_neg, tb_not
vsim -t 1ps work.datapath_tb

# Optional: add waves and run
# add wave -radix hex /datapath_tb/DUT/*
# add wave -radix unsigned /datapath_tb/Present_state
# add wave /datapath_tb/Clock
# run 5us
