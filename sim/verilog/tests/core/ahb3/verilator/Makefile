all: build

build:
	verilator -Wno-lint --cc -f system.vc --top-module peripheral_gpio_testbench

simulate:

clean:
	rm -rf obj_dir
