
use work.LogDualisPack.all;

architecture Rtl of CoarseAlignment is
	-- constants
	constant cBufferLength : natural := (symbol_length_g * 2**(osr_g)) / 2;
	constant cResultValueLength : natural := 35;
	constant cMaxOffsetCounter : natural := 2**(osr_g) - 1;
	
	-- type definitions	
	type aState is (Init, ThresholdDetection, PeakDetection, WaitOnSymbolFinished, CoarseAlignmentDone);
	type aSampleMemory is array (0 to cBufferLength - 1) of std_ulogic_vector(2*sample_bit_width_g - 1 downto 0);
	type aCorrelationMemory is array (0 to cBufferLength - 1) of std_ulogic_vector(4*sample_bit_width_g - 1 downto 0);
	
	type aComplexSample is record
		I : signed(sample_bit_width_g - 1 downto 0);
		Q : signed(sample_bit_width_g - 1 downto 0);
	end record;
	
	type aPInterimValue is record
		I : signed(2*sample_bit_width_g - 1 downto 0);
		Q : signed(2*sample_bit_width_g - 1 downto 0);
	end record;
		
	type aPValue is record
		I : signed(cResultValueLength - 1 downto 0);
		Q : signed(cResultValueLength - 1 downto 0);
	end record;
	
	type aCoarseAlignmentReg is record
		State : aState;
		PrevPValue : aPValue;
		Threshold : signed(cResultValueLength - 1 downto 0);
		SampleCounter : unsigned(LogDualis(symbol_length_g) - 1 downto 0);
		OffsetCounter : unsigned(LogDualis(2**(osr_g)) downto 0);
		OutputSymbolStart : std_ulogic;
		OutputValid : std_ulogic;
		OutputActive : std_ulogic;
		WriteIdx : unsigned(LogDualis(cBufferLength) - 1 downto 0);
		ReadIdx : unsigned(LogDualis(cBufferLength) - 1 downto 0);
	end record;

	-- constants
	constant cMaxSampleCounterValue : unsigned(LogDualis(symbol_length_g) - 1 downto 0) := to_unsigned(symbol_length_g, LogDualis(symbol_length_g));
	constant cInitWriteIdx : unsigned(LogDualis(cBufferLength) - 1 downto 0) :=  to_unsigned(cBufferLength - 1, LogDualis(cBufferLength));
	constant cInitReadIdx : unsigned(LogDualis(cBufferLength) - 1 downto 0) :=  (others => '0');
	constant cInitPInterim : aPInterimValue := (others => (others => '0'));
	
	constant cInitPValue : aPValue := (
		I => (others => '0'),
		Q => (others => '0')
	);
	
	constant cInitCoarseReg : aCoarseAlignmentReg := (
		State => Init,
		PrevPValue => cInitPValue,
		Threshold => (others => '0'),
		SampleCounter => (others => '0'),
		OffsetCounter => (others => '0'),
		OutputSymbolStart => '0',
		OutputValid => '0',
		OutputActive => '0',
		WriteIdx => to_unsigned(cBufferLength - 1, LogDualis(cBufferLength)),
		ReadIdx => (others => '0')
	);
	
	-- signals
	signal sampleBuffer : aSampleMemory := (others => (others => '0')); -- memory for sample circular buffer
	signal correlationBuffer : aCorrelationMemory := (others => (others => '0')); -- memory for correlation circular buffer
	signal regPValue : aPValue := cInitPValue; -- register for correlation result
	signal regCoarse, nextRegCoarse	: aCoarseAlignmentReg := cInitCoarseReg; -- register for states of coarse alignment
	
	signal rdm : std_ulogic_vector(2*sample_bit_width_g - 1 downto 0) := (others => '0'); -- I,Q signal to circulat buffer
	signal rdmL : std_ulogic_vector(2*sample_bit_width_g - 1 downto 0) := (others => '0'); -- I,Q signal from circular buffer	
	signal pInterim : std_ulogic_vector(4*sample_bit_width_g - 1 downto 0) := (others => '0'); -- I,Q part of correlation interim result
	signal pInterimL : std_ulogic_vector(4*sample_bit_width_g - 1 downto 0) := (others => '0'); -- I,Q part of correlation interim result
	
	signal regPInterim : aPInterimValue := (others => (others => '0')); -- register for interim result of correlation
	signal regValid : std_ulogic := '0'; -- delay valid for correlation result buffer
	
	signal regWriteIdxSamples : unsigned(LogDualis(cBufferLength) - 1 downto 0) := cInitWriteIdx; -- write idx for circular buffer of sampels
	signal regReadIdxSamples : unsigned(LogDualis(cBufferLength) - 1 downto 0) := (others => '0');  -- read idx for circular buffer of sampels
	signal regWriteIdxCorrelation : unsigned(LogDualis(cBufferLength) - 1 downto 0) := cInitWriteIdx;  -- write idx for circular buffer of correlation results
	signal regReadIdxCorrelation : unsigned(LogDualis(cBufferLength) - 1 downto 0) := (others => '0'); -- read idx for circular buffer of correlation results
begin
	
		-- hardware implementation of schmidl cox algorithmn
	SchmidlCox: process (sys_clk_i, sys_rstn_i, sys_init_i) is	
		variable vRdm : aComplexSample := (I => (others => '0'), Q => (others => '0')); -- current I,Q value at input
		variable vRdmL : aComplexSample := (I => (others => '0'), Q => (others => '0')); -- delayed I,Q value		
		variable vPInterim : aPInterimValue := (I => (others => '0'), Q => (others => '0')); -- I,Q part of correlation interim result
		variable vPInterimL : aPInterimValue := (I => (others => '0'), Q => (others => '0')); -- I,Q part of correlation interim result
	begin	
		if (sys_rstn_i = '0') or (sys_init_i = '1') then
			regPInterim <= cInitPInterim;
			regValid <= '0';
			regPValue <= cInitPValue;			
			regWriteIdxSamples <= cInitWriteIdx;
			regWriteIdxCorrelation <= cInitWriteIdx;
			regReadIdxSamples <= cInitReadIdx;
			regReadIdxCorrelation <= cInitReadIdx;
		elsif (rising_edge(sys_clk_i)) then		
			vRdm := (I => signed(rdm((2*sample_bit_width_g - 1) downto sample_bit_width_g)), Q => signed(rdm(sample_bit_width_g - 1 downto 0))); -- current I,Q samples			
			vRdmL := (I => signed(rdmL((2*sample_bit_width_g - 1) downto sample_bit_width_g)), Q => signed(rdmL(sample_bit_width_g - 1 downto 0))); -- delayed I,Q samples			
			vPInterimL := (I => signed(pInterimL(4*sample_bit_width_g - 1 downto 2*sample_bit_width_g)), Q => signed(pInterimL(2*sample_bit_width_g - 1 downto 0))); -- delayed correlation results		
			regValid <= rx_data_osr_valid_i; -- store valid signal for next stage
		
			-- complex multipilcation
			if (rx_data_osr_valid_i = '1') then
				regPInterim.I <= (vRdm.I * vRdmL.I) - (-vRdm.Q * vRdmL.Q);
				regPInterim.Q <= (vRdm.Q * vRdmL.I) - (vRdm.I * vRdmL.Q);			
			
				regWriteIdxSamples <= regWriteIdxSamples + 1;
				regReadIdxSamples <= regReadIdxSamples + 1;

				if (regWriteIdxSamples = (cBufferLength - 1)) then
					regWriteIdxSamples <= (others => '0');
				end if;
				
				if (regReadIdxSamples = (cBufferLength - 1)) then
					regReadIdxSamples <= (others => '0');
				end if;
			end if;
			
			-- accumulation of p signal
			if (regValid = '1') then
				regPValue.I <= regPValue.I + (regPInterim.I - vPInterimL.I);
				regPValue.Q <= regPValue.Q + (regPInterim.Q - vPInterimL.Q);
				
				regWriteIdxCorrelation <= regWriteIdxCorrelation + 1;
				regReadIdxCorrelation <= regReadIdxCorrelation + 1;

				if (regWriteIdxCorrelation = (cBufferLength - 1)) then
					regWriteIdxCorrelation <= (others => '0');
				end if;
				
				if (regReadIdxCorrelation = (cBufferLength - 1)) then
					regReadIdxCorrelation <= (others => '0');
				end if;
			end if;
			
			-- init of p value
			--if (sys_init_i = '1') then
			--	regPValue.I <= (others => '0');
			--end if;
		end if;			
	end process;
	
	-- register process to store all needed states and values
	RegisterProcess: process (sys_clk_i, sys_rstn_i) is
	begin
		if (sys_rstn_i = '0') then
			regCoarse <= cInitCoarseReg;
		elsif (rising_edge(sys_clk_i)) then
			if (sys_init_i = '1') then
				regCoarse <= cInitCoarseReg;
			else
				regCoarse <= nextRegCoarse;
			end if;
		end if;	
	end process;
	
	-- State machine for coarse alignment
	StateMachine: process (regCoarse, regPValue, min_level_i, rx_data_osr_valid_i, rx_data_i_osr_i, rx_data_q_osr_i, offset_inc_i, offset_dec_i) is
		variable vMaxCounterValue : natural := 0;
	begin
		nextRegCoarse <= regCoarse;
		rx_data_coarse_valid_o <= '0';
		rx_data_coarse_start_o <= '0';
		rx_data_i_coarse_o <= (others => '0');
		rx_data_q_coarse_o <= (others => '0');
		
		if (rx_data_osr_valid_i = '1') and (regCoarse.State /= CoarseAlignmentDone) then
			nextRegCoarse.WriteIdx <= regCoarse.WriteIdx + 1;
			nextRegCoarse.ReadIdx <= regCoarse.ReadIdx + 1;
			
			if (regCoarse.WriteIdx = cBufferLength - 1) then
				nextRegCoarse.WriteIdx <= (others => '0');
			end if;
			
			if (regCoarse.ReadIdx = cBufferLength - 1) then
				nextRegCoarse.ReadIdx <= (others => '0');
			end if;
		end if;
		
		case regCoarse.State is
			-- Starts here after reset and activation of init signal. Stores the new threshold value
			when Init =>
				nextRegCoarse.Threshold(cResultValueLength - 2 downto cResultValueLength - min_level_i'length - 1) <= signed(min_level_i);
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
					rx_data_coarse_start_o <= '1';
					rx_data_coarse_valid_o <= '1';
					rx_data_i_coarse_o <= rx_data_i_osr_i;
					rx_data_q_coarse_o <= rx_data_q_osr_i;
				end if;
			-- wait if the current symbol at the high rate is done
			when WaitOnSymbolFinished =>
				if (rx_data_osr_valid_i = '0') then
					nextRegCoarse.State <= CoarseAlignmentDone;
				end if;
			-- Coarse alignment is done. The measured delay is ajusted according to the fine alignment and passed to the interpolator. The input samples are passed to the output
			-- and the start of symbol signal is generated. The interpolation mode is set to '1'.
			when CoarseAlignmentDone =>		
				if (rx_data_osr_valid_i = '1') then				
					nextRegCoarse.OffsetCounter <= regCoarse.OffsetCounter + 1;
						
					if ((regCoarse.SampleCounter = (symbol_length_g - 1)) and (offset_inc_i = '1') and (offset_dec_i = '0')) then
						vMaxCounterValue := cMaxOffsetCounter + 1;
					elsif ((regCoarse.SampleCounter = (symbol_length_g - 1)) and (offset_inc_i = '0') and (offset_dec_i = '1')) then
						vMaxCounterValue := cMaxOffsetCounter - 1;
					else
						vMaxCounterValue := cMaxOffsetCounter;
					end if;
					
					if (regCoarse.OffsetCounter = vMaxCounterValue) then
						nextRegCoarse.OffsetCounter <= (others => '0');
						nextRegCoarse.OutputActive <= '1';
						nextRegCoarse.SampleCounter <= regCoarse.SampleCounter + 1;	
						
						if (regCoarse.SampleCounter = (symbol_length_g - 1)) then
							nextRegCoarse.SampleCounter <= (others => '0');
						end if;
					end if;		
					
				else
					nextRegCoarse.OutputSymbolStart <= '0';
					nextRegCoarse.OutputValid <= '0';
				end if;
				
				if ((regCoarse.OffsetCounter = x"00") and (regCoarse.OutputActive = '1')) then
					rx_data_coarse_valid_o <= '1';
					rx_data_i_coarse_o <= rx_data_i_osr_i;
					rx_data_q_coarse_o <= rx_data_q_osr_i;
					nextRegCoarse.OutputActive <= '0';
					
					if (regCoarse.SampleCounter = x"00") then
						rx_data_coarse_start_o <= '1';
					end if;
				end if;

			when others =>
				null;
		end case;		
	end process;
		
	-- memories for circular buffers
	rdm((2*sample_bit_width_g - 1) downto sample_bit_width_g) <= std_ulogic_vector(rx_data_i_osr_i);
	rdm(sample_bit_width_g - 1 downto 0) <= std_ulogic_vector(rx_data_q_osr_i);	
	
	SampleMemory: process (sys_clk_i, sys_init_i) is
	begin
		if (sys_init_i = '1') then
			sampleBuffer <= (others => (others => '0'));
			rdmL <= (others => '0');
		elsif (rising_edge(sys_clk_i)) then
			if (rx_data_osr_valid_i = '1') then
				sampleBuffer(to_integer(regWriteIdxSamples)) <= rdm;
			end if;		
			rdmL <= sampleBuffer(to_integer(regReadIdxSamples));
		end if;
	end process;
	
	pInterim((4*sample_bit_width_g - 1) downto (2*sample_bit_width_g)) <= std_ulogic_vector(regPInterim.I);
	pInterim((2*sample_bit_width_g - 1) downto 0) <= std_ulogic_vector(regPInterim.Q);
	
	CorrelationMemory: process (sys_clk_i, sys_init_i) is
	begin
		if (sys_init_i = '1') then
			correlationBuffer <= (others => (others => '0'));
			pInterimL <= (others => '0');
		elsif (rising_edge(sys_clk_i)) then
			if (regValid = '1') then
				correlationBuffer(to_integer(regWriteIdxCorrelation)) <= pInterim;
			end if;
			pInterimL <= correlationBuffer(to_integer(regReadIdxCorrelation));
		end if;
	end process;
end architecture;
