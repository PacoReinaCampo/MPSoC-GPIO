@echo off
call ../../../../../../settings64_ghdl.bat

ghdl -a --std=08 ../../../../../../rtl/vhdl/peripheral/wb/peripheral_gpio_wb.vhd
ghdl -a --std=08 ../../../../../../bench/vhdl/tests/peripheral/wb/peripheral_gpio_testbench.vhd
ghdl -m --std=08 peripheral_gpio_testbench
ghdl -r --std=08 peripheral_gpio_testbench --ieee-asserts=disable-at-0 --disp-tree=inst > peripheral_gpio_testbench.tree
pause
