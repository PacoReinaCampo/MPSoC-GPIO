@echo off
call ../../../../../../settings64_ghdl.bat

ghdl -a --std=08 ../../../../../../rtl/vhdl/pkg/core/vhdl_pkg.vhd
ghdl -a --std=08 ../../../../../../rtl/vhdl/pkg/peripheral/ahb3/peripheral_ahb3_pkg.vhd
ghdl -a --std=08 ../../../../../../rtl/vhdl/peripheral/ahb3/peripheral_apb42ahb3.vhd
ghdl -a --std=08 ../../../../../../rtl/vhdl/peripheral/ahb3/peripheral_gpio_apb4.vhd
ghdl -a --std=08 ../../../../../../bench/vhdl/tests/peripheral/ahb3/peripheral_gpio_testbench.vhd
ghdl -m --std=08 peripheral_gpio_testbench
ghdl -r --std=08 peripheral_gpio_testbench --ieee-asserts=disable-at-0 --disp-tree=inst > peripheral_gpio_testbench.tree
pause
