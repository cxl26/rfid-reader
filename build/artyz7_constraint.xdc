set_property IOSTANDARD LVCMOS33 [get_ports sys_rst]
set_property IOSTANDARD LVCMOS33 [get_ports pmod1]
set_property IOSTANDARD LVCMOS33 [get_ports pmod2]
set_property IOSTANDARD LVCMOS33 [get_ports pmod3]
set_property IOSTANDARD LVCMOS33 [get_ports pmod4]
set_property IOSTANDARD LVCMOS33 [get_ports pmod7]
set_property IOSTANDARD LVCMOS33 [get_ports pmod8]
set_property IOSTANDARD LVCMOS33 [get_ports pmod9]
set_property IOSTANDARD LVCMOS33 [get_ports pmod10]
set_property PACKAGE_PIN D19 [get_ports sys_rst]
set_property PACKAGE_PIN Y18 [get_ports pmod1]
set_property PACKAGE_PIN Y19 [get_ports pmod2]
set_property PACKAGE_PIN Y16 [get_ports pmod3]
set_property PACKAGE_PIN Y17 [get_ports pmod4]
set_property PACKAGE_PIN U18 [get_ports pmod7]
set_property PACKAGE_PIN U19 [get_ports pmod8]
set_property PACKAGE_PIN W18 [get_ports pmod9]
set_property PACKAGE_PIN W19 [get_ports pmod10]

set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports sys_clk]
create_clock -period 8.000 -name sys_clk_pin -waveform {0.000 4.000} -add [get_ports sys_clk]
create_generated_clock -name clk -source [get_ports sys_clk] -divide_by 5 [get_pins xilinx_mmcm_u1/clkout1_buf/O]



