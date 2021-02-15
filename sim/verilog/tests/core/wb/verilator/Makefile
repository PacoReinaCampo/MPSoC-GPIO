all: build

build:
	verilator -Wno-lint -Wno-UNOPTFLAT -Wno-COMBDLY --cc -f system.vc --top-module mpsoc_gpio_testbench

simulate:

clean:
	rm -rf obj_dir
