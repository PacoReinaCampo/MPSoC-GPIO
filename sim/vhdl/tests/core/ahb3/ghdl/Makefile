all: build simulate

build:
	ghdl -a --std=08 ../../../../../../rtl/vhdl/ahb3/pkg/mpsoc_gpio_ahb3_pkg.vhd
	ghdl -a --std=08 ../../../../../../rtl/vhdl/ahb3/core/mpsoc_apb42ahb3.vhd
	ghdl -a --std=08 ../../../../../../rtl/vhdl/ahb3/core/mpsoc_apb4_gpio.vhd
	ghdl -a --std=08 ../../../../../../bench/vhdl/tests/core/ahb3/mpsoc_gpio_testbench.vhd

simulate:
	ghdl -m --std=08 mpsoc_gpio_testbench
	ghdl -r --std=08 mpsoc_gpio_testbench --ieee-asserts=disable-at-0 --disp-tree=inst > mpsoc_gpio_testbench.tree

clean:
	rm -f *.cf *.tree
