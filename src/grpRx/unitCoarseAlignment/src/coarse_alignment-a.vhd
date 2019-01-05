use work.CoarseAlignment_pack.all;

architecture Rtl of CoarseAlignment is
	
	-- type definitions
	type SampleFifo is array (0 to (gSymbolLength / 2) - 1) of signed((gSampleBitWidth - 1) downto 0);
	type CorrelationFifo is array (0 to (gSymbolLength / 2) - 1) of signed(2*gSampleBitWidth - 1 downto 0);
	
	type PValue is record
		I : signed((2*gSampleBitWidth + 1) downto 0);
		Q : signed((2*gSampleBitWidth + 1) downto 0);
	end record;

	-- constants
	constant cInitSampleFifo : SampleFifo := (others => (others => '0'));
	constant cInitCorrelationFifo : CorrelationFifo := (others => (others => '0'));
	
	constant cInitPValue : PValue := (
		I => (others => '0'),
		Q => (others => '0')
	);
	
	-- signals
	signal fifo_samples_i : SampleFifo := cInitSampleFifo;
	signal fifo_samples_q : SampleFifo := cInitSampleFifo;
	signal fifo_p_i : CorrelationFifo := cInitCorrelationFifo;
	signal fifo_p_q : CorrelationFifo := cInitCorrelationFifo;
	
	signal ptab_i : signed(2*gSampleBitWidth - 1 downto 0) := (others => '0');
	signal ptab_q : signed(2*gSampleBitWidth - 1 downto 0) := (others => '0');
	
	signal regPValue, nextRegPValue : PValue := cInitPValue;
begin
	
	-- register process to store all needed states and values
	RegisterProcess: process (sys_clk_i, sys_rstn_i) is
	begin
		if (sys_rstn_i = '0') then
			regPValue <= cInitPValue;
		elsif (rising_edge(sys_clk_i)) then
			if (rx_data_osr_valid_i = '1') then
				regPValue <= nextRegPValue;
			end if;
		end if;	
	end process;
	
	-- fifos for correlation calculation of schmidl cox
	FIFOs: process (sys_clk_i, sys_rstn_i) is
	begin
		if (sys_rstn_i = '0') then
			fifo_samples_i <= cInitSampleFifo;
			fifo_samples_q <= cInitSampleFifo;
			fifo_p_i <= cInitCorrelationFifo;
			fifo_p_i <= cInitCorrelationFifo;
		elsif (rising_edge(sys_clk_i)) then
			if (rx_data_osr_valid_i = '1') then
				fifo_samples_i(0) <= rx_data_i_osr_i;
				fifo_samples_q(0) <= rx_data_q_osr_i;
				fifo_p_i(0) <= ptab_i;
				fifo_p_q(0) <= ptab_q;
			
				for i in 1 to (gSymbolLength / 2) - 1 loop
					fifo_samples_i(i) <= fifo_samples_i(i - 1);
					fifo_samples_q(i) <= fifo_samples_q(i - 1);
					fifo_p_i(i) <= fifo_p_i(i - 1);
					fifo_p_q(i) <= fifo_p_q(i - 1);
				end loop;
			end if;
		end if;	
	end process;
	
	rx_data_i_coarse_o <= (others => '0');
	rx_data_q_coarse_o <= (others => '0');
	
	-- hardware implementation of schmidl cox algorithmn
	SchmidlCox: process (regPValue, rx_data_i_osr_i, rx_data_q_osr_i, fifo_samples_i(fifo_samples_i'right), fifo_samples_q(fifo_samples_q'right), fifo_p_i(fifo_p_i'right), fifo_p_q(fifo_p_q'right)) is	
		variable v_rdm_i : signed((gSampleBitWidth - 1) downto 0) := (others => '0'); -- current I value at input
		variable v_rdm_q : signed((gSampleBitWidth - 1) downto 0) := (others => '0'); -- current Q value at input
		variable v_rdmL_i : signed((gSampleBitWidth - 1) downto 0) := (others => '0'); -- delayed I value
		variable v_rdmL_q : signed((gSampleBitWidth - 1) downto 0) := (others => '0'); -- delayed Q value
		
		variable v_ptab_i, v_ptab_q : signed(2*gSampleBitWidth - 1 downto 0) := (others => '0');
		variable v_ptabL_i, v_ptabL_q : signed(2*gSampleBitWidth - 1 downto 0) := (others => '0');
	begin
		nextRegPValue <= regPValue;
		
		-- current I,Q values
		v_rdm_i := rx_data_i_osr_i;
		v_rdm_q := rx_data_q_osr_i;
		-- delayed I,Q values
		v_rdmL_i := fifo_samples_i(fifo_samples_i'right);
		v_rdmL_q := fifo_samples_q(fifo_samples_q'right);
		
		v_ptab_i := (v_rdm_i * v_rdmL_i) - (-v_rdm_q * v_rdmL_q);
		v_ptab_q := (-v_rdm_q * v_rdmL_i) + (v_rdm_i * v_rdmL_q);
		v_ptabL_i := fifo_p_i(fifo_p_i'right);
		v_ptabL_q := fifo_p_q(fifo_p_q'right);
		ptab_i <= v_ptab_i;
		ptab_q <= v_ptab_q;
		
		nextRegPValue.I <= regPValue.I + (v_ptab_i - v_ptabL_i);
		nextRegPValue.Q <= regPValue.Q + (v_ptab_q - v_ptabL_q);		
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