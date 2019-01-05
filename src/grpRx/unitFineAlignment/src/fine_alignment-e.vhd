library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FineAlignment is
    generic (
        raw_symbol_length_g : natural := 128;
        sample_bit_width_g  : natural := 12
    );
    port(
        -- clock, async reset and init signal
        sys_clk_i               : in std_ulogic;
        sys_rstn_i              : in std_ulogic;
        sys_init_i              : in std_ulogic;

        -- input data from fft wrapper
        rx_symbols_i_fft_i         : in signed((sample_bit_width_g - 1) downto 0);
        rx_symbols_q_fft_i         : in signed((sample_bit_width_g - 1) downto 0);
        rx_symbols_fft_valid_i     : in std_ulogic;
        rx_symbols_fft_start_i     : in std_ulogic;

        -- output data to demodulation
        rx_symbols_i_o          : out signed((sample_bit_width_g - 1) downto 0);
        rx_symbols_q_o          : out signed((sample_bit_width_g - 1) downto 0);
        rx_symbols_valid_o      : out std_ulogic;
        rx_symbols_start_o      : out std_ulogic;

        -- communication with coarse alignment
        offset_inc_o            : out std_ulogic;
        offset_dec_o            : out std_ulogic
    );
end entity;