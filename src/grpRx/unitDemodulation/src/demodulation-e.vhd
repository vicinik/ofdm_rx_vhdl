library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Demodulation is
    generic (
        raw_symbol_length_g : natural := 128;
        sample_bit_width_g  : natural := 12
    );
    port(
        -- clock, async reset and init signal
        sys_clk_i               : in std_ulogic;
        sys_rstn_i              : in std_ulogic;
        sys_init_i              : in std_ulogic;

        -- input data from fine alignment
        rx_symbols_i_i      : in signed((sample_bit_width_g - 1) downto 0);
        rx_symbols_q_i      : in signed((sample_bit_width_g - 1) downto 0);
        rx_symbols_valid_i  : in std_ulogic;
        rx_symbols_start_i  : in std_ulogic;

        -- output bitstream
        rx_rcv_data_o       : out std_ulogic_vector(1 downto 0);
        rx_rcv_data_valid_o : out std_ulogic;
        rx_rcv_data_start_o : out std_ulogic
    );
end entity;