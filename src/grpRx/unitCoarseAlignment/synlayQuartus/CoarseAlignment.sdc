#**************************************************************
# Altera DE1-SoC SDC settings
# Users are recommended to modify this file to match users logic.
#**************************************************************

#**************************************************************
# Create Clock
#**************************************************************
create_clock -period 10 [get_ports sys_clk_i]


#**************************************************************
# Create Generated Clock
#**************************************************************
derive_pll_clocks

# Automatically calculate clock uncertainty to jitter and other effects.
derive_clock_uncertainty

# No timing analysis is needed on those inputs as well as on
# DataAvailable.
set_false_path -from [get_ports {rx_data_i_osr_i[*] rx_data_q_osr_i[*] min_level_i[*]\
				 sys_init_i\
				 rx_data_osr_valid_i\
				 offset_inc_i\
				 offset_dec_i}]
