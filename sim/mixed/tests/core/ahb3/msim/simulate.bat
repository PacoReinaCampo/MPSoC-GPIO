@echo off
source ../../../../../../settings64_msim.sh

vlib work
vlog -sv -f system.verilog.vc
vcom -2008 -f system.vhdl.vc
vsim -c -do run.do work.peripheral_gpio_testbench
pause
