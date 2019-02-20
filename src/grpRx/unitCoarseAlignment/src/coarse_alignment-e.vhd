library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CoarseAlignment is
    generic (
        symbol_length_g   	: natural := 320;		
        sample_bit_width_g 	: natural := 12;
			osr_g				: natural := 4
    );
    port (
        -- clock, async reset and init signal
        sys_clk_i               : in std_ulogic;
        sys_rstn_i              : in std_ulogic;
        sys_init_i              : in std_ulogic;
        
        -- input data from interpolator
        rx_data_i_osr_i         : in signed((sample_bit_width_g - 1) downto 0);
        rx_data_q_osr_i         : in signed((sample_bit_width_g - 1) downto 0);
        rx_data_osr_valid_i     : in std_ulogic;
        
        -- inputs from fine alignment and delay outputs for interpolator
        offset_inc_i            : in std_ulogic;
        offset_dec_i            : in std_ulogic;
        
        -- threshold for coarse alignment
        min_level_i             : in unsigned(15 downto 0);
        
        -- output data to cyclic prefix removal
        rx_data_i_coarse_o      : out signed((sample_bit_width_g - 1) downto 0);
        rx_data_q_coarse_o      : out signed((sample_bit_width_g - 1) downto 0);
        rx_data_coarse_valid_o  : out std_ulogic;
        rx_data_coarse_start_o  : out std_ulogic
    );
end CoarseAlignment;
