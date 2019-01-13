library ieee;
library std;
library uvvm_util;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.ofdm_helper.all;

context uvvm_util.uvvm_util_context;

entity tbCoarseAlignment is
end tbCoarseAlignment;

architecture Bhv of tbCoarseAlignment is
	-- constants
	constant cOsr : natural := 4;
	constant cSysClkPeriod : time := 10 ns; -- 100 MHz
	constant cDataClkPeriod : time := 250 ns; -- 4 MS/s
	constant cSamplesPerSymbol : natural := 320;
	constant cSampleBitWidth : natural := 12;
	constant cTimeBeforeRisingEdge : time := cSysClkPeriod / 10;
	constant cTrainingsSymbolPosition : natural := 2;
	constant cOfdmSignalLength16MSs : natural := 25569;
	constant cOfdmSignalLength4MSs : natural := 32000;	

	-- signals
	signal sysClk : std_ulogic := '0';
	signal enableSysClk : boolean := false;

	signal enableOfdmSignalGeneration : boolean := false;
	signal ofdmSignalFinished : boolean := false;
	signal refOffset : unsigned(3 downto 0) := x"0";
	signal refDelay : unsigned(3 downto 0) := x"0";
	
	signal reset_n : std_ulogic := '1';
	signal init : std_ulogic := '0';
	
	signal rxDataIIn : signed(11 downto 0) := (others => '0');
	signal rxDataQIn : signed(11 downto 0) := (others => '0');
	signal rxDataInValid : std_ulogic := '0';
	
	signal offsetInc : std_ulogic := '0';
	signal offsetDec : std_ulogic := '0';
	signal interpMode : std_ulogic := '0';
	signal delay : std_ulogic_vector(3 downto 0);
	signal offset : std_ulogic_vector(3 downto 0);
	signal rxDataIOut : signed(11 downto 0) := (others => '0');
	signal rxDataQOut : signed(11 downto 0) := (others => '0');
	signal rxDataOutValid : std_ulogic := '0';
	signal rxDataSymbStart : std_ulogic := '0';
begin

    ------------------------------------------------------------------
    -- DUV
    ------------------------------------------------------------------
	DUV: entity work.CoarseAlignment
		generic map (
			symbol_length_g => cSamplesPerSymbol,
			osr_g => cOsr,
			sample_bit_width_g => cSampleBitWidth
		)
		port map (
			sys_clk_i 	=> sysClk,
			sys_rstn_i 	=> reset_n,
			sys_init_i	=> init,
			rx_data_i_osr_i => rxDataIIn,
			rx_data_q_osr_i => rxDataQIn,
			rx_data_osr_valid_i => rxDataInValid,
			offset_inc_i => offsetInc,
			offset_dec_i => offsetDec,
			interp_mode_o => interpMode,
			rx_data_delay_o => delay,
			rx_data_offset_o => offset,
			min_level_i => x"8F10",
			rx_data_i_coarse_o => rxDataIOut,
			rx_data_q_coarse_o => rxDataQOut,
			rx_data_coarse_valid_o => rxDataOutValid,
			rx_data_coarse_start_o => rxDataSymbStart
		);

	------------------------------------------------------------------
    -- Clock Generators
    ------------------------------------------------------------------
    SystemClockGenerator: clock_generator(sysClk, enableSysClk, cSysClkPeriod, "100 MHz with 50% duty cycle", 50);
	
	------------------------------------------------------------------
    -- OFDM signal generator
    ------------------------------------------------------------------
	OFDMSignalGenerator: process 
		constant cFileName16MSs : String := "test_ofdm_symbols_16MSs.txt";
		constant cFileName4MSs : String := "test_ofdm_symbols_4MSs.txt";
		variable vValuesPerSample : natural := 0;
		variable vOfdmSignal16MSs : OFDMSignal(1 to cOfdmSignalLength16MSs);
		variable vOfdmSignal4MSs : OFDMSignal(1 to cOfdmSignalLength4MSs);
		variable vIdx : natural := 1;
		variable vPrevInterpMode : std_ulogic := '0';
	begin
		-- read data from file
		vOfdmSignal16MSs := read_ofdm_signal(cFileName16MSs, cOfdmSignalLength16MSs);
		vOfdmSignal4MSs := read_ofdm_signal(cFileName4MSs, cOfdmSignalLength4MSs);
		wait until enableOfdmSignalGeneration;
		wait_until_given_time_before_rising_edge(sysClk, cTimeBeforeRisingEdge, cSysClkPeriod);
		
		while true loop			
			if enableOfdmSignalGeneration then
				if ((interpMode = '0') and (vIdx <= vOfdmSignal16MSs'right)) or ((interpMode = '1') and (vIdx <= vOfdmSignal4MSs'right)) then		

					if (interpMode = '0') then
						vValuesPerSample := 2**cOsr;
					else
						vValuesPerSample := 1;
					end if;
					
					rxDataInValid <= '1';
					for i in 0 to (vValuesPerSample - 1) loop
						if (interpMode = '0') then
							rxDataIIn <= vOfdmSignal16MSs(vIdx).I, (others => '0') after cSysClkPeriod;
							rxDataQIn <= vOfdmSignal16MSs(vIdx).Q, (others => '0') after cSysClkPeriod;
						else
							rxDataIIn <= vOfdmSignal4MSs(vIdx).I after i*cSysClkPeriod, (others => '0') after (i+1)*cSysClkPeriod;
							rxDataQIn <= vOfdmSignal4MSs(vIdx).Q after i*cSysClkPeriod, (others => '0') after (i+1)*cSysClkPeriod;
						end if;											
						
						vIdx := vIdx + 1;
						wait for cSysClkPeriod;
					end loop;
					rxDataInValid <= '0';
				
					--rxDataIIn <= vOfdmSignal(vIdx).I, (others => '0') after cSysClkPeriod;
					--rxDataQIn <= vOfdmSignal(vIdx).Q, (others => '0') after cSysClkPeriod;
					---rxDataInValid <= '1', '0' after cSysClkPeriod;
					wait for (cDataClkPeriod - vValuesPerSample * cSysClkPeriod);
					if vPrevInterpMode /= interpMode then
						vIdx := 1;
					end if;
					vPrevInterpMode := interpMode;
					--vIdx := vIdx + 1;
				else
					-- signal generation is done so this process can stop
					ofdmSignalFinished <= true;
					wait;
				end if;
			else
				wait until enableOfdmSignalGeneration;
				wait_until_given_time_before_rising_edge(sysClk, cTimeBeforeRisingEdge, cSysClkPeriod);
			end if;
		end loop;		
	end process;
	
	------------------------------------------------------------------
    -- Offset and delay reference calculation
    ------------------------------------------------------------------
	DelayOffsetReference: process
		variable vCurrOffset : unsigned(3 downto 0) := (others => '0');
		variable vCurrDelay : unsigned(3 downto 0) := (others => '0');
	begin
		wait until rising_edge(rxDataSymbStart);
		vCurrOffset := refOffset;
		vCurrDelay := refDelay;
		
		if (offsetInc = '1') and (offsetDec = '0') then
			vCurrOffset := vCurrOffset + 1;
			if (refOffset = x"F") then
				vCurrOffset := x"0";
				vCurrDelay := vCurrDelay + 1;
				if (refDelay = x"F") then
					vCurrDelay := x"0";
				end if;
			end if;
		elsif (offsetInc = '0') and (offsetDec = '1') then
			vCurrOffset := vCurrOffset - 1;
			if (refOffset = x"0") then
				vCurrOffset := x"F";
				vCurrDelay := vCurrDelay - 1;
				if (refDelay = x"0") then
					vCurrDelay := x"F";
				end if;
			end if;
		end if;
		
		refOffset <= vCurrOffset;
		refDelay <= vCurrDelay;
	end process;
	
	------------------------------------------------------------------
    -- Testcase Sequencer 
    ------------------------------------------------------------------
	TestcaseSequencer: process
		variable vDetectionTime : time := cTrainingsSymbolPosition * cSamplesPerSymbol * cDataClkPeriod;
	begin	
	    -- init uvvm, set log files and enable log messages
        set_log_file_name("CoarseAlignment.txt");
        set_alert_file_name("CoarseAlignment_alert.txt");
        enable_log_msg(ALL_MESSAGES);
		
		-- generate reset pulse
		log(ID_LOG_HDR, "Start clock and generate reset");
        enableSysClk <= true;
        gen_pulse(reset_n, '0', 4 * cSysClkPeriod, BLOCKING, "Generate reset pulse");
		
		log(ID_LOG_HDR, "Check reset condition");
		check_value(interpMode, '0', MATCH_EXACT, ERROR, "Interpolation mode");
		check_value(delay, "0000", MATCH_EXACT, ERROR, "Delay output");
		check_value(offset, "0000", MATCH_EXACT, ERROR, "Offset output");
		check_value(rxDataOutValid, '0', MATCH_EXACT, ERROR, "Ouput valid signal");
		check_value(rxDataSymbStart, '0', MATCH_EXACT, ERROR, "Symbol start signal");
		check_value(rxDataIOut, "000000000000", ERROR, "I component of output data");
		check_value(rxDataQOut, "000000000000", ERROR, "Q component of output data");
	
		log(ID_LOG_HDR, "Find correlation peak");
		log(ID_SEQUENCER, "Start OFDM signal transmission");
		enableOfdmSignalGeneration <= true;
		await_value(interpMode, '1', 0 ns, 1.5 * vDetectionTime, ERROR, "Interpolation mode '1' when peak is detected after max. 3 ofdm symbols ");		
		
		log(ID_LOG_HDR, "Start of symbol and valid generation");
		await_value(rxDataSymbStart, '1', 0 ns, cDataClkPeriod, ERROR, "Start of symbol active");
		await_value(rxDataSymbStart, '0', 0.99*cSysClkPeriod, 1.01*cSysClkPeriod, ERROR, "Start of symbol inactive");
		await_value(rxDataOutValid, '1', 0 ns, cDataClkPeriod, ERROR, "Data valid active");
		await_value(rxDataOutValid, '0', 0.99*cSysClkPeriod, 1.01*cSysClkPeriod, ERROR, "Data valid inactive");		
		await_value(rxDataSymbStart, '1', 0 ns, cSamplesPerSymbol * cDataClkPeriod, ERROR, "Next Start of symbol active");
		
		log(ID_LOG_HDR, "Rx output data stream");		
		for i in 1 to cSamplesPerSymbol loop
			log(ID_SEQUENCER, "OFDM sample " & integer'image(i));
			check_value(rxDataOutValid, '1', MATCH_EXACT, ERROR, "Data valid active for sample");
			check_value(rxDataIIn, rxDataIOut, ERROR, "I part of sample");
			check_value(rxDataQIn, rxDataQOut, ERROR, "Q part of sample");
			log(ID_SEQUENCER, "");
			
			if i /= cSamplesPerSymbol then
				wait for cDataClkPeriod;
			end if;
		end loop;
		await_value(rxDataSymbStart, '1', 0 ns, 1.01*cDataClkPeriod, ERROR, "Start of symbol active at next sample");
		
		log(ID_LOG_HDR, "Delay and offset signals");
		log(ID_SEQUENCER, "Increase offset 32 times\n");
		-- wait so start of symbol is inactive		
		wait until rxDataSymbStart = '0';
		
		offsetInc <= '1';
		offsetDec <= '0';
		for i in 1 to 35 loop
			log(ID_SEQUENCER, "Increase offset #" & integer'image(i));
			wait until falling_edge(rxDataSymbStart) or ofdmSignalFinished;
			
			if ofdmSignalFinished then
				error("OFDM signal finished before testbench ended");
			end if;
			
			check_value(delay, std_ulogic_vector(refDelay), MATCH_EXACT, ERROR, "Interpolator delay");
			check_value(offset, std_ulogic_vector(refOffset), MATCH_EXACT, ERROR, "Interpolator offset");
			log(ID_SEQUENCER, "");
		end loop;

		offsetInc <= '0';
		offsetDec <= '1';
		for i in 1 to 32 loop
			log(ID_SEQUENCER, "Decrease offset #" & integer'image(i));
			wait until falling_edge(rxDataSymbStart) or ofdmSignalFinished;
			
			if ofdmSignalFinished then
				error("OFDM signal finished before testbench ended");
			end if;
			
			check_value(delay, std_ulogic_vector(refDelay), MATCH_EXACT, ERROR, "Interpolator delay");
			check_value(offset, std_ulogic_vector(refOffset), MATCH_EXACT, ERROR, "Interpolator offset");
			log(ID_SEQUENCER, "");
		end loop;
		offsetInc <= '0';
		offsetDec <= '0';
		
		log(ID_LOG_HDR, "Init signal");
		gen_pulse(init, '1', 4 * cSysClkPeriod, BLOCKING, "Generate init pulse");
		check_value(interpMode, '0', MATCH_EXACT, ERROR, "Interpolation mode");
		check_value(delay, "0000", MATCH_EXACT, ERROR, "Delay output");
		check_value(offset, "0000", MATCH_EXACT, ERROR, "Offset output");
		check_value(rxDataOutValid, '0', MATCH_EXACT, ERROR, "Ouput valid signal");
		check_value(rxDataSymbStart, '0', MATCH_EXACT, ERROR, "Symbol start signal");
		check_value(rxDataIOut, "000000000000", ERROR, "I component of output data");
		check_value(rxDataQOut, "000000000000", ERROR, "Q component of output data");
	
		log(ID_LOG_HDR, "Stop simulation");
		enableSysClk <= false;
		enableOfdmSignalGeneration <= false;
        wait_num_rising_edge(sysClk, 2);

        report_alert_counters(VOID);
        wait; -- final wait
	end process;

end architecture;