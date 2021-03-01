all: build simulate

build:
	ghdl -a --std=08 ../../../../../../rtl/vhdl/wb/peripheral_gpio_wb.vhd
	ghdl -a --std=08 ../../../../../../bench/vhdl/tests/core/wb/peripheral_gpio_testbench.vhd

simulate:
	ghdl -m --std=08 peripheral_gpio_testbench
	ghdl -r --std=08 peripheral_gpio_testbench --ieee-asserts=disable-at-0 --disp-tree=inst > peripheral_gpio_testbench.tree

clean:
	rm -f *.cf *.tree
