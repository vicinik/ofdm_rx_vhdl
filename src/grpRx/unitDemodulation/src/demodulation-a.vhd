architecture Rtl of Demodulation is

--Demodulation: Reqs
--• Zuordnen der complexen Rx Symbole zu einem Datensymbol (00, 01, 10, 11) 
--– Detektion des Quadranten
		
	signal counter, nx_counter			: unsigned(9 downto 0);	
	signal data, nx_data 				: std_ulogic_vector(1 downto 0);
    signal data_valid, nx_data_valid	: std_ulogic;
    signal data_start, nx_data_start	: std_ulogic;
	
	signal rx_symbols_i		: signed((sample_bit_width_g - 1) downto 0);
    signal rx_symbols_q		: signed((sample_bit_width_g - 1) downto 0);
    signal rx_symbols_valid	: std_ulogic;
    signal rx_symbols_start 	: std_ulogic;

begin
	
	process(counter, rx_symbols_i, rx_symbols_q, rx_symbols_valid, rx_symbols_start, data)
		variable tmp_symbol_i	: std_ulogic_vector((sample_bit_width_g - 1) downto 0);
		variable tmp_symbol_q	: std_ulogic_vector((sample_bit_width_g - 1) downto 0);
		variable tmp_i			: std_ulogic;
		variable tmp_q			: std_ulogic;
	begin
		nx_data			<= data;	
		nx_data_valid	<= '0';
		nx_data_start	<= '0';
		nx_counter		<= counter;
		
		--pre calculations 
			tmp_symbol_i 	:= std_ulogic_vector(rx_symbols_i);
			tmp_symbol_q 	:= std_ulogic_vector(rx_symbols_q);
			if (tmp_symbol_i(tmp_symbol_i'LEFT) = '1' or tmp_symbol_i(tmp_symbol_i'LEFT) = '0') then
				tmp_i	:= tmp_symbol_i(tmp_symbol_i'LEFT);
			else
				tmp_i	:= 'X';
			end if;
			if (tmp_symbol_q(tmp_symbol_q'LEFT) = '1' or tmp_symbol_q(tmp_symbol_q'LEFT) = '0') then
				tmp_q	:= tmp_symbol_q(tmp_symbol_q'LEFT);
			else
				tmp_q	:= 'X';
			end if;
		
		if rx_symbols_start = '1' then 
			nx_counter	<= to_unsigned(0, counter'LENGTH);
			if rx_symbols_valid = '1' then
				nx_counter	<= to_unsigned(0, counter'LENGTH);
				
				nx_data(0)	<= tmp_i;
				nx_data(1)	<= tmp_q;
				nx_data_valid	<= '1';
				nx_data_start	<= '1';
			end if;
		elsif counter >= 0 and counter < raw_symbol_length_g and rx_symbols_valid = '1' then
			nx_counter	<= counter+1;
			
			nx_data(0)	<= tmp_i;
			nx_data(1)	<= tmp_q;
			nx_data_valid	<= '1';
			if counter = 0 then
				nx_data_start	<= '1';
			end if;
		else
			--nop
		end if;
	end process; 

	process(sys_clk_i, sys_rstn_i)
	begin
		if(sys_rstn_i = '0') then
			counter		<= to_unsigned(integer(raw_symbol_length_g+1), counter'LENGTH);
			data		<= (others => 'X');
			data_valid	<= '0';
			data_start	<= '0';
		elsif(rising_edge(sys_clk_i)) then
			rx_symbols_i		<= rx_symbols_i_i;
			rx_symbols_q		<= rx_symbols_q_i;
			rx_symbols_valid	<= rx_symbols_valid_i;
			rx_symbols_start	<= rx_symbols_start_i;
			counter		<= nx_counter;
			data		<= nx_data;
			data_valid	<= nx_data_valid;
			data_start	<= nx_data_start;
			if(sys_init_i = '1') then
				--initalize:
				counter		<= to_unsigned(integer(raw_symbol_length_g+1), counter'LENGTH);
				data		<= (others => 'X');
				data_valid	<= '0';
				data_start	<= '0';
			end if;
		end if;
	end process;
	rx_rcv_data_o		<=	data;
	rx_rcv_data_valid_o	<=	data_valid;
	rx_rcv_data_start_o	<=	data_start;

end architecture;