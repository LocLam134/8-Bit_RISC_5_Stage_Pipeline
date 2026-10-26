## =============================================================================
## File        : risc8.xdc
## Description : Vivado Timing and Pin Constraints for 8-bit 5-Stage RISC Core.
##               Target clock: 100 MHz (10.000 ns period).
## =============================================================================

## 1. Primary System Clock Constraint (100 MHz -> 10.0 ns period)
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]

## 2. Optional Board Pin Assignments (Uncomment for Basys-3 xc7a35tcpg236-1)
# set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports clk]
# set_property -dict { PACKAGE_PIN U18  IOSTANDARD LVCMOS33 } [get_ports rst]
# set_property -dict { PACKAGE_PIN U16  IOSTANDARD LVCMOS33 } [get_ports {pc_out[0]}]
# set_property -dict { PACKAGE_PIN E19  IOSTANDARD LVCMOS33 } [get_ports {pc_out[1]}]
# set_property -dict { PACKAGE_PIN U19  IOSTANDARD LVCMOS33 } [get_ports {pc_out[2]}]
# set_property -dict { PACKAGE_PIN V19  IOSTANDARD LVCMOS33 } [get_ports {pc_out[3]}]
# set_property -dict { PACKAGE_PIN W18  IOSTANDARD LVCMOS33 } [get_ports {pc_out[4]}]
# set_property -dict { PACKAGE_PIN U15  IOSTANDARD LVCMOS33 } [get_ports {pc_out[5]}]
# set_property -dict { PACKAGE_PIN U14  IOSTANDARD LVCMOS33 } [get_ports {pc_out[6]}]
# set_property -dict { PACKAGE_PIN V14  IOSTANDARD LVCMOS33 } [get_ports {pc_out[7]}]
# set_property -dict { PACKAGE_PIN V13  IOSTANDARD LVCMOS33 } [get_ports {flags_out[0]}]
# set_property -dict { PACKAGE_PIN V3   IOSTANDARD LVCMOS33 } [get_ports {flags_out[1]}]
# set_property -dict { PACKAGE_PIN W3   IOSTANDARD LVCMOS33 } [get_ports instr_done]
# set_property -dict { PACKAGE_PIN L1   IOSTANDARD LVCMOS33 } [get_ports halted]