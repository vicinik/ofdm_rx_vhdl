
use work.LogDualisPack.all;

architecture Rtl of CoarseAlignment is
	
	-- type definitions	
	type aState is (Init, ThresholdDetection, PeakDetection, CoarseAlignmentDone);
	
	type aComplexSample is record
		I : signed(sample_bit_width_g - 1 downto 0);
		Q : signed(sample_bit_width_g - 1 downto 0);
	end record;
	
	type aPInterimValue is record
		I : signed(2*sample_bit_width_g - 1 downto 0);
		Q : signed(2*sample_bit_width_g - 1 downto 0);
	end record;
	
	type aSampleFifo is array (0 to (symbol_length_g / 2) - 1) of aComplexSample;
	type aCorrelationFifo is array (0 to (symbol_length_g / 2) - 1) of aPInterimValue;
	
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
	constant cInitSampleFifo : aSampleFifo := (others => (I => (others => '0'), Q => (others => '0')));
	constant cInitCorrelationFifo : aCorrelationFifo := (others => (I => (others => '0'), Q => (others => '0')));
	constant cMaxDelayOffsetValue : unsigned(3 downto 0) := x"F";
	
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
	signal fifoSamples: aSampleFifo := cInitSampleFifo; -- fifo for I,Q parts of input samples
	signal fifoPInterim : aCorrelationFifo := cInitCorrelationFifo; -- fifo for I,Q parts of correlation interim result
	signal pInterim : aPInterimValue := (I => (others => '0'), Q => (others => '0')); -- I,Q part of correlation interim result
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
			if (sys_init_i = '1') then
				regPValue <= cInitPValue;
				regCoarse <= cInitCoarseReg;
			else
				regCoarse <= nextRegCoarse;
				if (rx_data_osr_valid_i = '1') then
					regPValue <= nextRegPValue;
				end if;
			end if;
		end if;	
	end process;
	
	-- State machine for coarse alignment
	StateMachine: process (regCoarse, regPValue, min_level_i, rx_data_osr_valid_i, offset_inc_i, offset_dec_i) is
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
			-- Coarse alignment is done. The measured delay is ajusted according to the fine alignment and passed to the interpolator. The input samples are passed to the output
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
						
						-- adjust delay and offset for interpolator
						-- increment offset and delay
						if (offset_inc_i = '1') and (offset_dec_i = '0') then
							nextRegCoarse.Offset <= regCoarse.Offset + 1;
							if (regCoarse.Offset = cMaxDelayOffsetValue) then
								nextRegCoarse.Offset <= (others => '0');
								nextRegCoarse.Delay <= regCoarse.Delay + 1;
								if (regCoarse.Delay = cMaxDelayOffsetValue) then
									nextRegCoarse.Delay <= (others => '0');
								end if;
							end if;						
						-- decrement offset and delay
						elsif (offset_inc_i = '0') and (offset_dec_i = '1') then
							nextRegCoarse.Offset <= regCoarse.Offset - 1;
							if (regCoarse.Offset = x"0") then
								nextRegCoarse.Offset <= cMaxDelayOffsetValue;
								nextRegCoarse.Delay <= regCoarse.Delay - 1;
								if (regCoarse.Delay = x"0") then
									nextRegCoarse.Delay <= cMaxDelayOffsetValue;
								end if;
							end if;	
						end if;						
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
			fifoSamples <= cInitSampleFifo;
			fifoPInterim <= cInitCorrelationFifo;
		elsif (rising_edge(sys_clk_i)) then
			if (sys_init_i = '1') then
				fifoSamples <= cInitSampleFifo;
				fifoPInterim <= cInitCorrelationFifo;
			else
				if (rx_data_osr_valid_i = '1') then
					fifoSamples(0) <= (I => rx_data_i_osr_i, Q => rx_data_q_osr_i);
					fifoPInterim(0) <= pInterim;
				
					for i in 1 to (symbol_length_g / 2) - 1 loop
						fifoSamples(i) <= fifoSamples(i - 1);
						fifoPInterim(i) <= fifoPInterim(i - 1);
					end loop;
				end if;
			end if;
		end if;	
	end process;
	
	-- hardware implementation of schmidl cox algorithmn
	SchmidlCox: process (regPValue, rx_data_i_osr_i, rx_data_q_osr_i, fifoSamples(fifoSamples'right), fifoPInterim(fifoPInterim'right)) is	
		variable vRdm : aComplexSample := (I => (others => '0'), Q => (others => '0')); -- current I,Q value at input
		variable vRdmL : aComplexSample := (I => (others => '0'), Q => (others => '0')); -- delayed I,Q value		
		variable vPInterim : aPInterimValue := (I => (others => '0'), Q => (others => '0')); -- I,Q part of correlation interim result
		variable vPInterimL : aPInterimValue := (I => (others => '0'), Q => (others => '0')); -- I,Q part of correlation interim result
	begin
		nextRegPValue <= regPValue;
		
		-- current I,Q samples
		vRdm := (I => rx_data_i_osr_i, Q => rx_data_q_osr_i);
		-- delayed I,Q samples
		vRdmL := fifoSamples(fifoSamples'right);
		
		-- calculate correlation of the input samples. store the interim result in a FIFO
		vPInterim.I := (vRdm.I * vRdmL.I) - (-vRdm.Q * vRdmL.Q);
		vPInterim.Q := (-vRdm.Q * vRdmL.I) + (vRdm.I * vRdmL.Q);
		vPInterimL := fifoPInterim(fifoPInterim'right);
		pInterim <= vPInterim;
		
		-- accumulate the differences of the interim results to get the p signal.
		nextRegPValue.I <= regPValue.I + (vPInterim.I - vPInterimL.I);
		nextRegPValue.Q <= regPValue.Q + (vPInterim.Q - vPInterimL.Q);		
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
