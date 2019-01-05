library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package TbdOfdmRxPack is
    constant symbol_length_c     : natural := 160;
    constant raw_symbol_length_c : natural := 128;
    constant sample_bit_width_c  : natural := 12;
end package;