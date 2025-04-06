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





create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 4096 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 2 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list xilinx_mmcm_u1/clk_out1]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 3 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {ctrl_fsm_u1/next_state[0]} {ctrl_fsm_u1/next_state[1]} {ctrl_fsm_u1/next_state[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 12 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {bits_detector_u1/corr_dat[1]} {bits_detector_u1/corr_dat[2]} {bits_detector_u1/corr_dat[3]} {bits_detector_u1/corr_dat[5]} {bits_detector_u1/corr_dat[6]} {bits_detector_u1/corr_dat[7]} {bits_detector_u1/corr_dat[9]} {bits_detector_u1/corr_dat[10]} {bits_detector_u1/corr_dat[11]} {bits_detector_u1/corr_dat[13]} {bits_detector_u1/corr_dat[14]} {bits_detector_u1/corr_dat[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 3 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {pie_encoder_u1/state[0]} {pie_encoder_u1/state[1]} {pie_encoder_u1/state[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 3 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {ctrl_fsm_u1/state[0]} {ctrl_fsm_u1/state[1]} {ctrl_fsm_u1/state[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list bits_detector_u1/corr_vld]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list preamble_detected]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list sampler_u1/sample_strobe]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]
