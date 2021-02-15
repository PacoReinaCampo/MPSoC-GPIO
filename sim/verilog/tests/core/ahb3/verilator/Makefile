all: build

build:
	verilator -Wno-lint --cc -f system.vc --top-module mpsoc_gpio_testbench

simulate:

clean:
	rm -rf obj_dir
