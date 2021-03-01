all: build

build:
	verilator -Wno-lint -Wno-UNOPTFLAT -Wno-COMBDLY --cc -f system.vc --top-module peripheral_gpio_testbench

simulate:

clean:
	rm -rf obj_dir
