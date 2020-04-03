all: build

build:
	@if [ ! -e work ]; then vlib work; fi
	@vlog -sv +incdir+../../../../rtl/verilog/pkg -f gpio_verilog.vc
	@vcom -2008 -f gpio_vhdl.vc
	vsim -c -do run.do work.mpsoc_gpio_testbench
