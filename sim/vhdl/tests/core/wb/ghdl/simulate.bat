@echo off
call ../../../../../../settings64_ghdl.bat

ghdl -a --std=08 ../../../../../../rtl/vhdl/wb/mpsoc_wb_gpio.vhd
ghdl -a --std=08 ../../../../../../bench/vhdl/tests/core/wb/mpsoc_gpio_testbench.vhd
ghdl -m --std=08 mpsoc_gpio_testbench
ghdl -r --std=08 mpsoc_gpio_testbench --ieee-asserts=disable-at-0 --disp-tree=inst > mpsoc_gpio_testbench.tree
pause
