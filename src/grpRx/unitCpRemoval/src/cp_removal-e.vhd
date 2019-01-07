library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CpRemoval is
    generic (
        symbol_length_g    : natural := 160;
        raw_symbol_length_g : natural := 128;
        sample_bit_width_g  : natural := 12
    );
    port(
        -- clock, async reset and init signal
        sys_clk_i               : in std_ulogic;
        sys_rstn_i              : in std_ulogic;
        sys_init_i              : in std_ulogic;

        -- input data from coarse alignment
        rx_data_i_coarse_i         : in signed((sample_bit_width_g - 1) downto 0);
        rx_data_q_coarse_i         : in signed((sample_bit_width_g - 1) downto 0);
        rx_data_coarse_valid_i     : in std_ulogic;
        rx_data_coarse_start_i     : in std_ulogic;

        -- output data to fft
        rx_data_i_fft_o            : out signed((sample_bit_width_g - 1) downto 0);
        rx_data_q_fft_o            : out signed((sample_bit_width_g - 1) downto 0);
        rx_data_fft_valid_o        : out std_ulogic;
        rx_data_fft_start_o        : out std_ulogic
    );
end entity;