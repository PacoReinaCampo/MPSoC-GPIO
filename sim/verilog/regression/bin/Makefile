all: build

build:
	@if [ ! -e work ]; then vlib work; fi
	@vlog -sv +incdir+../../../../rtl/verilog/pkg -f gpio.vc
	vsim -c -do run.do work.mpsoc_gpio_testbench
