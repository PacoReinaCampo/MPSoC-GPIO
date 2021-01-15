all: build simulate

build:
	verilator -Wno-lint +incdir+../../../../../rtl/verilog/ahb3/pkg --cc -f system.vc --top-module mpsoc_gpio_testbench

simulate:

clean:
	rm -rf obj_dir
