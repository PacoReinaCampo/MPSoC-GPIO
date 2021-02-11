@echo off
call ../../../../../../settings64_verilator.bat

verilator -Wno-lint -Wno-UNOPTFLAT -Wno-COMBDLY +incdir+../../../../../../rtl/verilog/ahb3/pkg --cc -f system.vc --top-module mpsoc_gpio_testbench
pause
