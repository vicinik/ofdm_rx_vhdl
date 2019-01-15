library ieee;	
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TbFFT is
	
	end entity;


architecture bhv of TbFFT is


       signal sys_clk_i               :  std_ulogic := '0';
       signal sys_rstn_i              :  std_ulogic;
       signal sys_init_i              :  std_ulogic;
	   
        -- input data from cp removal
       signal rx_data_i_fft_i            :  signed(11 downto 0);
       signal rx_data_q_fft_i            :  signed(11 downto 0);
       signal rx_data_fft_valid_i        :  std_ulogic;
       signal rx_data_fft_start_i        :  std_ulogic;
	   
       -- output data to fine alignment
       signal rx_symbols_i_fft_o         :  signed(11 downto 0);
       signal rx_symbols_q_fft_o         :  signed(11 downto 0);
       signal rx_symbols_fft_valid_o     :  std_ulogic;
       signal rx_symbols_fft_start_o     :  std_ulogic;

constant cSysClkPeriod : time := 10 ns; -- 100 MHz

	begin

		DUV: entity work.FftWrapper
		port map (
		sys_clk_i          		  =>  sys_clk_i, 	
        sys_rstn_i                => sys_rstn_i,
        sys_init_i                => sys_init_i,
								  
        rx_data_i_fft_i           => rx_data_i_fft_i,
        rx_data_q_fft_i           => rx_data_q_fft_i,
        rx_data_fft_valid_i       => rx_data_fft_valid_i,
        rx_data_fft_start_i       => rx_data_fft_start_i,
								   
        rx_symbols_i_fft_o        => rx_symbols_i_fft_o,
        rx_symbols_q_fft_o        => rx_symbols_q_fft_o,
        rx_symbols_fft_valid_o    => rx_symbols_fft_valid_o,
        rx_symbols_fft_start_o    => rx_symbols_fft_start_o
		);

		sys_clk_i <= not sys_clk_i after cSysClkPeriod;


end architecture bhv; -- of FftWrapper