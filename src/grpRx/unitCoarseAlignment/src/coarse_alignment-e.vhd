library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CoarseAlignment is
	port (
		-- clock, async reset and init signal
		sys_clk_i				: in std_ulogic;
		sys_rstn_i				: in std_ulogic;
		sys_init_i				: in std_ulogic;
		
		-- input data from interpolator
		rx_data_i_osr_i			: in std_ulogic_vector(11 downto 0);
		rx_data_q_osr_i			: in std_ulogic_vector(11 downto 0);
		rx_data_osr_valid_i		: in std_ulogic;
		
		-- inputs from fine alignment and delay outputs for interpolator
		offset_inc_i			: in std_ulogic;
		offset_dec_i			: in std_ulogic;
		interp_mode_o			: out std_ulogic;
		rx_data_delay_o			: out std_ulogic_vector(3 downto 0);
		rx_data_offset_o		: out std_ulogic_vector(3 downto 0);
		
		-- threshold for coarse alignment
		min_level_i				: in std_ulogic_vector(15 downto 0);
		
		-- output data to cyclic prefix removal
		rx_data_i_coarse_o		: out std_ulogic_vector(11 downto 0);
		rx_data_q_coarse_o		: out std_ulogic_vector(11 downto 0);
		rx_data_coarse_valid_o	: out std_ulogic;
		rx_data_symb_start_o	: out std_ulogic	
	);
end CoarseAlignment;