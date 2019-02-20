architecture Rtl of CpRemoval is



-- CP Removal: Reqs
-- • Entfernen der ersten 64 Samples nach Empfang des start Signals der Eingangsdaten 
--– Ausgangsdatenrate reduziert sich von MS/s auf 3.2MS/s 
--– Sample am Ausgang nicht äquidistant

	--integer(ceil(log2(symbol_length_g+1)))
	signal counter, nx_counter			: unsigned(9 downto 0);
	signal data_i, nx_data_i			: signed((sample_bit_width_g - 1) downto 0);
	signal data_q, nx_data_q 			: signed((sample_bit_width_g - 1) downto 0);
    signal data_valid, nx_data_valid	: std_ulogic;
    signal data_start, nx_data_start	: std_ulogic;
	
	signal rx_data_i		: signed((sample_bit_width_g - 1) downto 0);
    signal rx_data_q		: signed((sample_bit_width_g - 1) downto 0);
    signal rx_data_valid	: std_ulogic;
    signal rx_data_start 	: std_ulogic;
	
	
	
	
	
	
begin

	process(counter, data_i, data_q, data_valid, data_start, rx_data_i, rx_data_q, rx_data_valid, rx_data_start)
	begin
		nx_data_i		<= data_i;	
		nx_data_q		<= data_q;	
		nx_data_valid	<= '0';
		nx_data_start	<= '0';
		nx_counter		<= counter;
		if rx_data_start = '1' then 
			nx_counter	<= to_unsigned(0, counter'LENGTH);
			if rx_data_valid = '1' then 
				nx_counter	<= to_unsigned(1, counter'LENGTH);
			end if;
		elsif counter >= 0 and counter < symbol_length_g-raw_symbol_length_g and rx_data_valid = '1' then
			nx_counter	<= counter+1;
		elsif counter < symbol_length_g and rx_data_valid = '1' then
			nx_counter <= counter+1;
			nx_data_valid	<= '1';
			nx_data_i		<= rx_data_i;
			nx_data_q		<= rx_data_q;
			if counter = symbol_length_g-raw_symbol_length_g then
				nx_data_start	<= '1';
			end if;
		else
			--nop
		end if;
	end process; 


	process(sys_clk_i, sys_rstn_i)
	begin
		if(sys_rstn_i = '0') then
			counter		<= to_unsigned(integer(symbol_length_g+1), counter'LENGTH);
			data_i		<= (others => 'X');
			data_q		<= (others => 'X');
			data_valid	<= '0';
			data_start	<= '0';
		elsif(rising_edge(sys_clk_i)) then
			rx_data_i		<= rx_data_i_coarse_i;
			rx_data_q		<= rx_data_q_coarse_i;
			rx_data_valid	<= rx_data_coarse_valid_i;
			rx_data_start	<= rx_data_coarse_start_i;
			counter		<= nx_counter;
			data_i		<= nx_data_i;
			data_q		<= nx_data_q;
			data_valid	<= nx_data_valid;
			data_start	<= nx_data_start;
			if(sys_init_i = '1') then
				--initalize:
				counter		<= to_unsigned(integer(symbol_length_g+1), counter'LENGTH);
				data_i		<= (others => 'X');
				data_q		<= (others => 'X');
				data_valid	<= '0';
				data_start	<= '0';
			end if;
		end if;
	end process;
	rx_data_i_fft_o		<=	data_i;
	rx_data_q_fft_o		<=	data_q;
	rx_data_fft_valid_o	<=	data_valid;
	rx_data_fft_start_o	<=	data_start;
end architecture;