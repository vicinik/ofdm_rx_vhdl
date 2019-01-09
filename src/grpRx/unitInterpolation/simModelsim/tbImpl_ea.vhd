library ieee;
library std;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tbInterpolation is
end tbInterpolation;

architecture Bhv of tbInterpolation is
	-- constants
	constant cSysClkPeriod : time := 10 ns; -- 100 MHz
	constant cDataClkPeriod : time := 250 ns; -- 4 MS/s
	constant cSamplesPerSymbol : natural := 160;
	constant cSampleBitWidth : natural := 12;
	constant cTimeBeforeRisingEdge : time := cSysClkPeriod / 10;
	constant cTrainingsSymbolPosition : natural := 2;

	-- signals
	signal sys_clk : std_ulogic := '0';
	signal enable_sys_clock : boolean := false;

	signal reset_n : std_ulogic := '1';
	signal init : std_ulogic := '0';
	
	signal rx_data_i_in : signed(11 downto 0) := (others => '0');
	signal rx_data_q_in : signed(11 downto 0) := (others => '0');
	signal rx_data_in_valid : std_ulogic := '0';
	
	signal interp_mode : std_ulogic := '0';
	signal delay : std_ulogic_vector(3 downto 0);
	signal offset : std_ulogic_vector(3 downto 0);
	signal rx_data_i_out : signed(11 downto 0) := (others => '0');
	signal rx_data_q_out : signed(11 downto 0) := (others => '0');
	signal rx_data_out_valid : std_ulogic := '0';
begin

    ------------------------------------------------------------------
    -- DUV
    ------------------------------------------------------------------
	DUV: entity work.Interpolation
		port map (
			-- clock, async reset and init signal
			sys_clk_i		=>	sys_clk,
			sys_rstn_i      =>  reset_n,
			sys_init_i      =>  init,
        
			-- input data
			rx_data_i_i      =>  rx_data_i_in, 
			rx_data_q_i      =>  rx_data_q_in,
			rx_data_valid_i  =>  rx_data_in_valid,
        
			-- inputs from fine alignment and delay outputs for interpolator
			interp_mode_i      =>  interp_mode, 
			rx_data_delay_i    =>  delay, 
			rx_data_offset_i   =>  offset,
			  
			-- output data to cyclic prefix removal
			rx_data_i_osr_o       =>	rx_data_i_out,
			rx_data_q_osr_o       =>	rx_data_q_out,
			rx_data_osr_valid_o   =>	rx_data_out_valid
		);

	------------------------------------------------------------------
    -- Clock Generators
    ------------------------------------------------------------------
    sys_clk <= not sys_clk after cSysClkPeriod/2;
	
	
	
	------------------------------------------------------------------
    -- Testcase
    ------------------------------------------------------------------
	Test: process		
	begin	
		reset_n	<= '0';
		wait for 1000 ns;
		reset_n	<= '1';
		rx_data_i_in <= to_signed(1800, rx_data_i_in'length);
		rx_data_q_in <= to_signed(1800, rx_data_q_in'length);
		rx_data_in_valid  <= '1';
		wait for cSysClkPeriod;
		rx_data_in_valid  <= '0';
		wait for cDataClkPeriod;

		rx_data_i_in <= to_signed(1900, rx_data_i_in'length);
		rx_data_q_in <= to_signed(1900, rx_data_q_in'length);
		rx_data_in_valid  <= '1';
		wait for cSysClkPeriod;
		rx_data_in_valid  <= '0';
		wait for cDataClkPeriod;

		rx_data_i_in <= to_signed(2000, rx_data_i_in'length);
		rx_data_q_in <= to_signed(2000, rx_data_q_in'length);
		rx_data_in_valid  <= '1';
		wait for cSysClkPeriod;
		rx_data_in_valid  <= '0';
		wait for cDataClkPeriod;

		rx_data_i_in <= to_signed(2000, rx_data_i_in'length);
		rx_data_q_in <= to_signed(2000, rx_data_q_in'length);
		rx_data_in_valid  <= '1';
		wait for cSysClkPeriod;
		rx_data_in_valid  <= '0';
		wait for cDataClkPeriod;

		rx_data_i_in <= to_signed(1900, rx_data_i_in'length);
		rx_data_q_in <= to_signed(1900, rx_data_q_in'length);
		rx_data_in_valid  <= '1';
		wait for cSysClkPeriod;
		rx_data_in_valid  <= '0';
		wait for 1000 us;
		



        wait; -- final wait

	end process;

end architecture;
