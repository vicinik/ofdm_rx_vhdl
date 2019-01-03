use work.CoarseAlignment_pack.all;

architecture Rtl of CoarseAlignment is
	
	-- type definitions
	type SampleFifo is array (0 to (gSymbolLength / 2) - 1) of signed((gSampleBitWidth - 1) downto 0);
	type CorrelationFifo is array (0 to (gSymbolLength / 2) - 1) of signed((15) downto 0);

	-- constants
	constant cInitSampleFifo : SampleFifo := (others => (others => '0'));
	constant cInitCorrelationFifo : CorrelationFifo := (others => (others => '0'));
	
	-- signals
	signal fifo_samples_i : SampleFifo := cInitSampleFifo;
	signal fifo_samples_q : SampleFifo := cInitSampleFifo;
	signal fifo_p_i : CorrelationFifo := cInitCorrelationFifo;
	signal fifo_p_q : CorrelationFifo := cInitCorrelationFifo;
begin
	
	-- register process to store all needed states and values
	RegisterProcess: process (sys_clk_i, sys_rstn_i) is
	begin
		if (sys_rstn_i = '0') then
		
		elsif (rising_edge(sys_clk_i)) then
		
		end if;	
	end process;
	
	-- fifos for correlation calculation of schmidl cox
	FIFOs: process (sys_clk_i, sys_rstn_i) is
	begin
		if (sys_rstn_i = '0') then
			fifo_samples_i <= cInitSampleFifo;
			fifo_samples_q <= cInitSampleFifo;
		elsif (rising_edge(sys_clk_i)) then
			if (rx_data_osr_valid_i = '1') then
				fifo_samples_i(0) <= rx_data_i_osr_i;
				fifo_samples_q(0) <= rx_data_q_osr_i;
			
				for i in 1 to (gSymbolLength / 2) - 1 loop
					fifo_samples_i(i) <= fifo_samples_i(i - 1);
					fifo_samples_q(i) <= fifo_samples_q(i - 1);
				end loop;
			end if;
		end if;	
	end process;
	
	rx_data_i_coarse_o <= fifo_samples_i(fifo_samples_i'right);
	rx_data_q_coarse_o <= fifo_samples_q(fifo_samples_q'right);
	
	-- hardware implementation of schmidl cox algorithmn
	SchmidlCox: process (rx_data_i_osr_i, rx_data_q_osr_i, fifo_samples_i(fifo_samples_i'right), fifo_samples_q(fifo_samples_q'right)) is	
	begin
	
	end process;
	
	-- default outputs
	interp_mode_o <= '0';
	rx_data_delay_o <= (others => '0');
	rx_data_offset_o <= (others => '0');
	rx_data_i_coarse_o <= (others => '0');
	rx_data_q_coarse_o <= (others => '0');
	rx_data_coarse_valid_o <= '0';
	rx_data_symb_start_o <= '0';
	
end architecture;