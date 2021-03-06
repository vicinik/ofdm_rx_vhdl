library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.STD_LOGIC_SIGNED.all;

entity Interpolation is
    generic (
        symbol_length_g    	: natural := 160;
        sample_bit_width_g 	: natural := 12;
		osr_g				: natural := 4
    );
    port (
        -- clock, async reset and init signal
        sys_clk_i               : in std_ulogic;
        sys_rstn_i              : in std_ulogic;
        sys_init_i              : in std_ulogic;
        
        -- input data
        rx_data_i_i         	: in signed((sample_bit_width_g - 1) downto 0);
        rx_data_q_i         	: in signed((sample_bit_width_g - 1) downto 0);
        rx_data_valid_i     	: in std_ulogic;
		
        -- output data to cyclic prefix removal
        rx_data_i_osr_o      	: out signed((sample_bit_width_g - 1) downto 0);
        rx_data_q_osr_o      	: out signed((sample_bit_width_g - 1) downto 0);
        rx_data_osr_valid_o  	: out std_ulogic
    );
end entity;