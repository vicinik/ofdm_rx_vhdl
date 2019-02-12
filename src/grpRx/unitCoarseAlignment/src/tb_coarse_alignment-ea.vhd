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
	constant cOsrDataClkPeriod : time := cDataClkPeriod / (2**cOsr);
	constant cSamplesPerSymbol : natural := 320;
	constant cSampleBitWidth : natural := 12;
	constant cTimeBeforeRisingEdge : time := cSysClkPeriod / 10;
	constant cTrainingsSymbolPosition : natural := 2;
	constant cOfdmSignalLength : natural := 511969;

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
			min_level_i => x"0454", --x"A700",
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
		constant cFileName : String := "test_ofdm_symbols.txt";
		constant cValuesPerSample : natural := 2**cOsr;
		variable vOfdmSignal : OFDMSignal(1 to cOfdmSignalLength);
		variable vIdx : natural := 1;
		variable vPrevInterpMode : std_ulogic := '0';
	begin
		-- read data from file
		vOfdmSignal := read_ofdm_signal(cFileName, cOfdmSignalLength);
		wait until enableOfdmSignalGeneration;
		wait_until_given_time_before_rising_edge(sysClk, cTimeBeforeRisingEdge, cSysClkPeriod);
		
		while true loop			
			if enableOfdmSignalGeneration then
				if (vIdx <= vOfdmSignal'right) then		
					
					rxDataInValid <= '1';
					for i in 1 to cValuesPerSample loop
						rxDataIIn <= vOfdmSignal(vIdx).I, (others => '0') after cSysClkPeriod;
						rxDataQIn <= vOfdmSignal(vIdx).Q, (others => '0') after cSysClkPeriod;					
						vIdx := vIdx + 1;
						wait for cSysClkPeriod;
					end loop;
					rxDataInValid <= '0';
	
					wait for (cDataClkPeriod - cValuesPerSample * cSysClkPeriod);
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
		check_value(rxDataOutValid, '0', MATCH_EXACT, ERROR, "Ouput valid signal");
		check_value(rxDataSymbStart, '0', MATCH_EXACT, ERROR, "Symbol start signal");
		check_value(rxDataIOut, "000000000000", ERROR, "I component of output data");
		check_value(rxDataQOut, "000000000000", ERROR, "Q component of output data");
	    
		log(ID_LOG_HDR, "Find correlation peak");
		log(ID_SEQUENCER, "Start OFDM signal transmission");
		enableOfdmSignalGeneration <= true;
		await_value(rxDataSymbStart, '1', 0 ns, 1.5 * vDetectionTime, ERROR, "Start of Symbol '1' when peak is detected after max. 3 ofdm symbols ");		
		
		log(ID_LOG_HDR, "Start of symbol and valid generation");
		await_value(rxDataSymbStart, '1', 0 ns, cDataClkPeriod, ERROR, "Start of symbol active");
		await_value(rxDataSymbStart, '0', 0.99*cSysClkPeriod, 1.01*cSysClkPeriod, ERROR, "Start of symbol inactive");
		await_value(rxDataOutValid, '1', 0 ns, 1.1*cDataClkPeriod, ERROR, "Data valid active");
		await_value(rxDataOutValid, '0', 0.99*cSysClkPeriod, 1.01*cSysClkPeriod, ERROR, "Data valid inactive");		
		await_value(rxDataSymbStart, '1', 0 ns, cSamplesPerSymbol * cDataClkPeriod, ERROR, "Next Start of symbol active");
		
		log(ID_LOG_HDR, "Rx output data stream");		
		for i in 1 to cSamplesPerSymbol loop
			log(ID_SEQUENCER, "OFDM sample " & integer'image(i));
			await_value(rxDataOutValid, '1', 0 ns, cDataClkPeriod, ERROR, "Data valid active");
			check_value(rxDataIIn, rxDataIOut, ERROR, "I part of sample");
			check_value(rxDataQIn, rxDataQOut, ERROR, "Q part of sample");			
			
			if i /= cSamplesPerSymbol then
				await_value(rxDataOutValid, '0', 0.99*cSysClkPeriod, 1.01*cSysClkPeriod, ERROR, "Data valid inactive");
			end if;
			log(ID_SEQUENCER, "");
		end loop;
		await_value(rxDataSymbStart, '1', 0 ns, 1.01*cDataClkPeriod, ERROR, "Start of symbol active at next sample");
		--
		log(ID_LOG_HDR, "Delay and offset signals");
		log(ID_SEQUENCER, "Increase offset 5 times\n");
		-- wait so start of symbol is inactive		
		wait until rxDataSymbStart = '0';
		
		offsetInc <= '1';
		offsetDec <= '0';
		for i in 1 to 5 loop
			log(ID_SEQUENCER, "Increase offset #" & integer'image(i));
			await_value(rxDataSymbStart, '1', cSamplesPerSymbol*cDataClkPeriod - (0.99 * cSysClkPeriod), (cSamplesPerSymbol + 1)*cDataClkPeriod + (0.99 * cSysClkPeriod), ERROR, "Delay was increased by one sample");
			wait until falling_edge(rxDataSymbStart);
			log(ID_SEQUENCER, "");
		end loop;
		
		log(ID_SEQUENCER, "Decrease offset 5 times\n");
		offsetInc <= '0';
		offsetDec <= '1';
		for i in 1 to 5 loop
			log(ID_SEQUENCER, "Decrease offset #" & integer'image(i));
			await_value(rxDataSymbStart, '1', (cSamplesPerSymbol - 1)*cDataClkPeriod - cOsrDataClkPeriod - (0.99 * cSysClkPeriod), cSamplesPerSymbol*cDataClkPeriod - cOsrDataClkPeriod + (0.99 * cSysClkPeriod), ERROR, "Delay was decreased by one sample");
			wait until falling_edge(rxDataSymbStart);
			log(ID_SEQUENCER, "");
		end loop;
        
		offsetInc <= '0';
		offsetDec <= '0';
		
		log(ID_LOG_HDR, "Init signal");
		gen_pulse(init, '1', 4 * cSysClkPeriod, BLOCKING, "Generate init pulse");
		--check_value(interpMode, '0', MATCH_EXACT, ERROR, "Interpolation mode");
		--check_value(delay, "0000", MATCH_EXACT, ERROR, "Delay output");
		--check_value(offset, "0000", MATCH_EXACT, ERROR, "Offset output");
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