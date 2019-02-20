library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TbdOfdmRx is
    generic(
        sample_bit_width_g  : natural := 12;
        symbol_length_g     : natural := 160;
        raw_symbol_length_g : natural := 128;
        osr_g               : natural := 10;
        fft_exp_g           : natural := 9
    );
    port(
        -- clock, reset and init ports
        sys_clk_i  : in std_ulogic;
        sys_rstn_i : in std_ulogic;
        sys_init_i : in std_ulogic;

        -- min level for the coarse alignment
        min_level_i : in unsigned(15 downto 0);

        -- rx filter data inputs
        rx_data_i_i         : in signed((sample_bit_width_g - 1) downto 0);
        rx_data_q_i         : in signed((sample_bit_width_g - 1) downto 0);
        rx_data_valid_i     : in std_ulogic;

        -- bitstream data outputs
        rx_rcv_data_o       : out std_ulogic_vector(1 downto 0);
        rx_rcv_data_valid_o : out std_ulogic;
        rx_rcv_data_start_o : out std_ulogic
    );
end entity;