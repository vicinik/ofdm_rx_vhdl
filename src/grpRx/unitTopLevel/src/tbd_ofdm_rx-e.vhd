library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.TbdOfdmRxPack.all;

entity TbdOfdmRx is
    port(
        -- clock, reset and init ports
        sys_clk_i  : in std_ulogic;
        sys_rstn_i : in std_ulogic;
        sys_init_i : in std_ulogic;

        -- min level for the coarse alignment
        min_level_i : in unsigned(15 downto 0);

        -- rx filter data inputs
        rx_data_i_i         : in signed((sample_bit_width_c - 1) downto 0);
        rx_data_q_i         : in signed((sample_bit_width_c - 1) downto 0);
        rx_data_valid_i     : in std_ulogic;

        -- bitstream data outputs
        rx_rcv_data_o       : out std_ulogic_vector(1 downto 0);
        rx_rcv_data_valid_o : out std_ulogic;
        rx_rcv_data_start_o : out std_ulogic
    );
end entity;