##========================================================
## EDGE Spartan-7 xc7s15ftgb196-1
## 4x4 Systolic Matrix Multiplier
##========================================================

## 50 MHz onboard clock
set_property PACKAGE_PIN H11 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

create_clock -name sys_clk -period 20.000 [get_ports clk]

## Reset push button PB2 (active HIGH)
set_property PACKAGE_PIN J13 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]