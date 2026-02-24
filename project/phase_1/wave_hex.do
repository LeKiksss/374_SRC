# Add DUT outputs and key signals with Hexadecimal radix by default.
# Run this after vsim has started: do wave_hex.do
# Adjust the instance name if your testbench is not datapath_tb (e.g. tb_add, tb_or).

add wave -radix hex /datapath_tb/Clock
add wave -radix unsigned /datapath_tb/Present_state
add wave -radix hex /datapath_tb/DUT/BusMuxOut
add wave -radix hex /datapath_tb/DUT/Z
add wave -radix hex /datapath_tb/DUT/IR
add wave -radix hex /datapath_tb/DUT/PC
add wave -radix hex /datapath_tb/DUT/HI
add wave -radix hex /datapath_tb/DUT/LO
add wave -radix hex /datapath_tb/DUT/R0
add wave -radix hex /datapath_tb/DUT/R1
add wave -radix hex /datapath_tb/DUT/R2
add wave -radix hex /datapath_tb/DUT/R3
add wave -radix hex /datapath_tb/DUT/R4
add wave -radix hex /datapath_tb/DUT/R5
add wave -radix hex /datapath_tb/DUT/R6
add wave -radix hex /datapath_tb/DUT/R7
add wave -radix hex /datapath_tb/DUT/R8
add wave -radix hex /datapath_tb/DUT/R9
add wave -radix hex /datapath_tb/DUT/R10
add wave -radix hex /datapath_tb/DUT/R11
add wave -radix hex /datapath_tb/DUT/R12
add wave -radix hex /datapath_tb/DUT/R13
add wave -radix hex /datapath_tb/DUT/R14
add wave -radix hex /datapath_tb/DUT/R15
