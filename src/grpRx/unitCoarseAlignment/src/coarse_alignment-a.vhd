
use work.LogDualisPack.all;

architecture Rtl of CoarseAlignment is
	
	-- type definitions
	type aState is (Init, ThresholdDetection, PeakDetection, CoarseAlignmentDone);
	type aSampleFifo is array (0 to (symbol_length_g / 2) - 1) of signed((sample_bit_width_g - 1) downto 0);
	type aCorrelationFifo is array (0 to (symbol_length_g / 2) - 1) of signed(2*sample_bit_width_g - 1 downto 0);
	
	type aPValue is record
		I : signed((2*sample_bit_width_g + 1) downto 0);
		Q : signed((2*sample_bit_width_g + 1) downto 0);
	end record;
	
	type aCoarseAlignmentReg is record
		State : aState;
		PrevPValue : aPValue;
		Threshold : signed(2*sample_bit_width_g downto 0);
		SampleCounter : unsigned(7 downto 0);
		OutputSymbolStart : std_ulogic;
		Delay : unsigned(3 downto 0);
		Offset : unsigned(3 downto 0);
	end record;

	-- constants
	constant cMaxSampleCounterValue : unsigned(LogDualis(symbol_length_g) - 1 downto 0) := to_unsigned(symbol_length_g, LogDualis(symbol_length_g));
	constant cInitSampleFifo : aSampleFifo := (others => (others => '0'));
	constant cInitCorrelationFifo : aCorrelationFifo := (others => (others => '0'));
	
	constant cInitPValue : aPValue := (
		I => (others => '0'),
		Q => (others => '0')
	);
	
	constant cInitCoarseReg : aCoarseAlignmentReg := (
		State => Init,
		PrevPValue => cInitPValue,
		Threshold => (others => '0'),
		SampleCounter => (others => '0'),
		OutputSymbolStart => '0',
		Delay => (others => '0'),
		Offset => (others => '0')
	);
	
	-- signals
	signal fifo_samples_i : aSampleFifo := cInitSampleFifo; -- fifo for I parts of input samples
	signal fifo_samples_q : aSampleFifo := cInitSampleFifo; -- fifo for Q parts of input samples
	signal fifo_pinterim_i : aCorrelationFifo := cInitCorrelationFifo; -- fifo for I parts of correlation interim result
	signal fifo_pinterim_q : aCorrelationFifo := cInitCorrelationFifo; -- fifo for Q parts of correlation interim result
	signal p_interim_i : signed(2*sample_bit_width_g - 1 downto 0) := (others => '0'); -- I part of correlation interim result
	signal p_interim_q : signed(2*sample_bit_width_g - 1 downto 0) := (others => '0');	-- Q part of correlation interim result
	signal regPValue, nextRegPValue : aPValue := cInitPValue; -- register for correlation result
	signal regCoarse, nextRegCoarse	: aCoarseAlignmentReg := cInitCoarseReg; -- register for states of coarse alignment
begin
	
	-- register process to store all needed states and values
	RegisterProcess: process (sys_clk_i, sys_rstn_i) is
	begin
		if (sys_rstn_i = '0') then
			regPValue <= cInitPValue;
			regCoarse <= cInitCoarseReg;
		elsif (rising_edge(sys_clk_i)) then
			regCoarse <= nextRegCoarse;
			if (rx_data_osr_valid_i = '1') then
				regPValue <= nextRegPValue;
			end if;
		end if;	
	end process;
	
	-- State machine for coarse alignment
	StateMachine: process (regCoarse, regPValue, min_level_i, rx_data_osr_valid_i) is
	begin
		nextRegCoarse <= regCoarse;
		interp_mode_o <= '0'; -- interpolator is in oversampling mode
		
		case regCoarse.State is
			-- Starts here after reset and activation of init signal. Stores the new threshold value
			when Init =>
				nextRegCoarse.Threshold((2*sample_bit_width_g - 1) downto (2*sample_bit_width_g) - min_level_i'length) <= signed(min_level_i);
				nextRegCoarse.State <= ThresholdDetection;
			-- Scanes the p signal and detectes if the p signal is higher than the given threshold. Afterwards start the peak detection.
			when ThresholdDetection =>
				if regPValue.I > regCoarse.Threshold then
					nextRegCoarse.PrevPValue <= regPValue;
					nextRegCoarse.State <= PeakDetection;
				end if;
			-- Detects the peak in the p signal. The peak was found the p signal starts to fall.
			when PeakDetection =>
				nextRegCoarse.PrevPValue <= regPValue;				
				if regCoarse.PrevPValue.I > regPValue.I then
					nextRegCoarse.State <= CoarseAlignmentDone;
				end if;
			-- Coarse alignment is done. The measured delay is stores and passed to the interpolator. The input samples are passed to the output
			-- and the start of symbol signal is generated. The interpolation mode is set to '1'.
			when CoarseAlignmentDone =>
				interp_mode_o <= '1'; -- interpolator is in offset mode			
				if (rx_data_osr_valid_i = '1') then
					-- increase sample counter to generate the start of symol signal.
					nextRegCoarse.SampleCounter <= regCoarse.SampleCounter + 1;
					
					if (regCoarse.SampleCounter = (cMaxSampleCounterValue - 1)) then
						nextRegCoarse.SampleCounter <= (others => '0');
					end if;
					
					if (regCoarse.SampleCounter = x"00") then
						nextRegCoarse.OutputSymbolStart <= '1';
					else
						nextRegCoarse.OutputSymbolStart <= '0';
					end if;
				else
					nextRegCoarse.OutputSymbolStart <= '0';
				end if;
			when others =>
				null;
		end case;		
	end process;
	
	-- fifos for correlation calculation of schmidl cox
	FIFOs: process (sys_clk_i, sys_rstn_i) is
	begin
		if (sys_rstn_i = '0') then
			fifo_samples_i <= cInitSampleFifo;
			fifo_samples_q <= cInitSampleFifo;
			fifo_pinterim_i <= cInitCorrelationFifo;
			fifo_pinterim_i <= cInitCorrelationFifo;
		elsif (rising_edge(sys_clk_i)) then
			if (rx_data_osr_valid_i = '1') then
				fifo_samples_i(0) <= rx_data_i_osr_i;
				fifo_samples_q(0) <= rx_data_q_osr_i;
				fifo_pinterim_i(0) <= p_interim_i;
				fifo_pinterim_q(0) <= p_interim_q;
			
				for i in 1 to (symbol_length_g / 2) - 1 loop
					fifo_samples_i(i) <= fifo_samples_i(i - 1);
					fifo_samples_q(i) <= fifo_samples_q(i - 1);
					fifo_pinterim_i(i) <= fifo_pinterim_i(i - 1);
					fifo_pinterim_q(i) <= fifo_pinterim_q(i - 1);
				end loop;
			end if;
		end if;	
	end process;
	
	-- hardware implementation of schmidl cox algorithmn
	SchmidlCox: process (regPValue, rx_data_i_osr_i, rx_data_q_osr_i, fifo_samples_i(fifo_samples_i'right), fifo_samples_q(fifo_samples_q'right), fifo_pinterim_i(fifo_pinterim_i'right), fifo_pinterim_q(fifo_pinterim_q'right)) is	
		variable v_rdm_i : signed((sample_bit_width_g - 1) downto 0) := (others => '0'); -- current I value at input
		variable v_rdm_q : signed((sample_bit_width_g - 1) downto 0) := (others => '0'); -- current Q value at input
		variable v_rdmL_i : signed((sample_bit_width_g - 1) downto 0) := (others => '0'); -- delayed I value
		variable v_rdmL_q : signed((sample_bit_width_g - 1) downto 0) := (others => '0'); -- delayed Q value
		
		variable v_pinterim_i, v_pinterim_q : signed(2*sample_bit_width_g - 1 downto 0) := (others => '0'); -- I part of correlation interim result
		variable v_pinterimL_i, v_pinterimL_q : signed(2*sample_bit_width_g - 1 downto 0) := (others => '0'); -- Q part of correlation interim result
	begin
		nextRegPValue <= regPValue;
		
		-- current I,Q samples
		v_rdm_i := rx_data_i_osr_i;
		v_rdm_q := rx_data_q_osr_i;
		-- delayed I,Q samples
		v_rdmL_i := fifo_samples_i(fifo_samples_i'right);
		v_rdmL_q := fifo_samples_q(fifo_samples_q'right);
		
		-- calculate correlation of the input samples. store the interim result in a FIFO
		v_pinterim_i := (v_rdm_i * v_rdmL_i) - (-v_rdm_q * v_rdmL_q);
		v_pinterim_q := (-v_rdm_q * v_rdmL_i) + (v_rdm_i * v_rdmL_q);
		v_pinterimL_i := fifo_pinterim_i(fifo_pinterim_i'right);
		v_pinterimL_q := fifo_pinterim_q(fifo_pinterim_q'right);
		p_interim_i <= v_pinterim_i;
		p_interim_q <= v_pinterim_q;
		
		-- accumulate the differences of the interim results to get the p signal.
		nextRegPValue.I <= regPValue.I + (v_pinterim_i - v_pinterimL_i);
		nextRegPValue.Q <= regPValue.Q + (v_pinterim_q - v_pinterimL_q);		
	end process;
	
	-- pass the input sampels to the output
	rx_data_i_coarse_o <= rx_data_i_osr_i when rx_data_osr_valid_i = '1' and regCoarse.State = CoarseAlignmentDone else (others => '0');
	rx_data_q_coarse_o <= rx_data_q_osr_i when rx_data_osr_valid_i = '1' and regCoarse.State = CoarseAlignmentDone else (others => '0');
	rx_data_coarse_valid_o <= rx_data_osr_valid_i when regCoarse.State = CoarseAlignmentDone else '0';
	rx_data_coarse_start_o <= regCoarse.OutputSymbolStart;
	
	-- pass the delay to the interpolor unit
	rx_data_delay_o <= std_ulogic_vector(regCoarse.Delay) when regCoarse.State = CoarseAlignmentDone else (others => '0');
	rx_data_offset_o <= std_ulogic_vector(regCoarse.Offset) when regCoarse.State = CoarseAlignmentDone else (others => '0');	
end architecture;