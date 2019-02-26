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
