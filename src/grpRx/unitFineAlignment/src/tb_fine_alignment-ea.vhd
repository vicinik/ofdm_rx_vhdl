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
	constant cSysClkPeriod : time := 10 ns; -- 100 MHz
	constant cDataClkPeriod : time := 250 ns; -- 4 MS/s
	constant cSamplesPerSymbol : natural := 128;
	constant cSampleBitWidth : natural := 12;
	constant cTimeBeforeRisingEdge : time := cSysClkPeriod / 10;
	constant cTrainingsSymbolPosition : natural := 2;

	-- signals
	signal sys_clk : std_ulogic := '0';
	signal enable_sys_clock : boolean := false;

	signal enable_ofdm_signal_generation : boolean := false;
	signal ofdm_signal_finished : boolean := false;
	
	signal reset_n : std_ulogic := '1';
	signal init : std_ulogic := '0';
	
	signal rx_symbols_i_fft_in : signed(11 downto 0) := (others => '0');
	signal rx_symbols_q_fft_in : signed(11 downto 0) := (others => '0');
	signal rx_symbols_fft_valid: std_ulogic := '0';
	signal rx_symbols_fft_start: std_ulogic := '0';

	signal rx_symbols_i_out : signed(11 downto 0) := (others => '0');
	signal rx_symbols_q_out : signed(11 downto 0) := (others => '0');
	signal rx_symbols_valid : std_ulogic := '0';
	signal rx_symbols_start : std_ulogic := '0';
	
	signal offset_inc : std_ulogic := '0';
	signal offset_dec : std_ulogic := '0';
begin

    ------------------------------------------------------------------
    -- DUV
    ------------------------------------------------------------------
  	DUV: entity work.FineAlignment
    port map (
      sys_clk_i              => sys_clk,
      sys_rstn_i             => reset_n,
      sys_init_i             => init,
      rx_symbols_i_fft_i     => rx_symbols_i_fft_in,
      rx_symbols_q_fft_i     => rx_symbols_q_fft_in,
      rx_symbols_fft_valid_i => rx_symbols_fft_valid,
      rx_symbols_fft_start_i => rx_symbols_fft_start,
      rx_symbols_i_o         => rx_symbols_i_out,
      rx_symbols_q_o         => rx_symbols_q_out,
      rx_symbols_valid_o     => rx_symbols_valid,
      rx_symbols_start_o     => rx_symbols_start,
      offset_inc_o           => offset_inc,
      offset_dec_o           => offset_dec);

    ------------------------------------------------------------------
    -- Clock Generators
    ------------------------------------------------------------------
    SystemClockGenerator: clock_generator(sys_clk, enable_sys_clock, cSysClkPeriod, "100 MHz with 50% duty cycle", 50);
	
    ------------------------------------------------------------------
    -- OFDM signal generator
    ------------------------------------------------------------------
	OFDMSignalGenerator: process 
		constant cFileName : String := "../simMatlab/Test_RxModSymbols.txt";
		variable v_ofdm_signal : OFDMSignal;
		variable v_idx : natural := v_ofdm_signal'left;
	begin
		-- read data from file
		v_ofdm_signal := read_ofdm_signal(cFileName);
		wait until enable_ofdm_signal_generation;
		wait_until_given_time_before_rising_edge(sys_clk, cTimeBeforeRisingEdge, cSysClkPeriod);
		
		while true loop			
			if enable_ofdm_signal_generation then
				if (v_idx <= v_ofdm_signal'right) then				
					rx_symbols_i_fft_in <= v_ofdm_signal(v_idx).I, (others => '0') after cSysClkPeriod;
					rx_symbols_q_fft_in <= v_ofdm_signal(v_idx).Q, (others => '0') after cSysClkPeriod;
					rx_symbols_fft_valid <= '1', '0' after cSysClkPeriod;
					rx_symbols_fft_start <= '1', '0' after cSysClkPeriod;
					wait for cDataClkPeriod;
					v_idx := v_idx + 1;
				else
					-- signal generation is done so this process can stop
					ofdm_signal_finished <= true;
					wait;
				end if;
			else
				wait until enable_ofdm_signal_generation;
				wait_until_given_time_before_rising_edge(sys_clk, cTimeBeforeRisingEdge, cSysClkPeriod);
			end if;
		end loop;		
	end process;
	
	------------------------------------------------------------------
    -- Testcase Sequencer 
    ------------------------------------------------------------------
	TestcaseSequencer: process
		variable vDetectionTime : time := (cTrainingsSymbolPosition * cSamplesPerSymbol) * cDataClkPeriod;
	begin	
		-- init uvvm, set log files and enable log messages
		set_log_file_name("FineAlignment.txt");
		set_alert_file_name("FineAlignment_alert.txt");
		enable_log_msg(ALL_MESSAGES);
		
		-- generate reset pulse
		log(ID_LOG_HDR, "Start clock and generate reset");
		enable_sys_clock <= true;
		gen_pulse(reset_n, '0', 4 * cSysClkPeriod, BLOCKING, "Generate reset pulse");
			
		log(ID_LOG_HDR, "Check reset condition");
		check_value(rx_symbols_i_out, "000000000000", ERROR, "I component of output data");
		check_value(rx_symbols_q_out, "000000000000", ERROR,"Q component of output data");
		check_value(rx_symbols_valid, '0', MATCH_EXACT, ERROR, "Output valid signal");
		check_value(rx_symbols_start, '0', MATCH_EXACT, ERROR, "Output start signal");
		check_value(offset_inc, '0', MATCH_EXACT, ERROR, "Increment");
		check_value(offset_dec, '1', MATCH_EXACT, ERROR, "Decrement");
		
		log(ID_LOG_HDR, "Fine tune samples");
		log(ID_SEQUENCER, "Start OFDM signal transmission");
		enable_ofdm_signal_generation <= true;	
			
		log(ID_LOG_HDR, "Start of symbol and valid generation");
		await_value(rx_symbols_fft_start, '1', 0 ns, cDataClkPeriod, ERROR, "Start of symbol active");
		await_value(rx_symbols_fft_start, '0', 0.99 * cSysClkPeriod, 1.01 * cSysClkPeriod, ERROR, "Start of symbol inactive");
		await_value(rx_symbols_fft_valid, '1', 0 ns, cDataClkPeriod, ERROR, "Data valid active");
		await_value(rx_symbols_fft_valid, '0', 0.99 * cSysClkPeriod, 1.01 * cSysClkPeriod, ERROR, "Data valid inactive");
		await_value(rx_symbols_fft_start, '1', 0 ns, cSamplesPerSymbol * cDataClkPeriod, ERROR, "Next start of symbole active");
			
		log(ID_LOG_HDR, "Rx output data stream");		
		for i in 1 to cSamplesPerSymbol loop
			log(ID_SEQUENCER, "OFDM sample " & integer'image(i));
			-- TODO ask Flo why this is a problem (following check_values)?
			-- TODo ask Flo about symbol generation -> start on every sample?
			--check_value(rx_symbols_valid, rx_symbols_fft_valid ,MATCH_EXACT, ERROR, "Data valid active for sample");
			--check_value(rx_symbols_start, rx_symbols_fft_start, MATCH_EXACT, ERROR, "Data start active for sample");
			--check_value(rx_symbols_i_out, rx_symbols_i_fft_in, ERROR, "I component of data");
			--check_value(rx_symbols_q_out, rx_symbols_q_fft_in, ERROR, "Q component of data");

			if i = 32 then -- check after 32 samples if phase is kept until next symbol
				check_value(offset_inc, '1', MATCH_EXACT, ERROR, "Offset increment");
				check_value(offset_dec, '0', MATCH_EXACT, ERROR, "Offset decrement");
			end if;
						
			log(ID_SEQUENCER, "");
			
			if i /= cSamplesPerSymbol then
				wait for cDataClkPeriod;
			end if;
		end loop;
		await_value(rx_symbols_fft_start, '1', 0 ns, 1.01*cDataClkPeriod, ERROR, "Start of symbol active at next sample");

		log(ID_LOG_HDR, "Check init condition");
		init <= '1';
		wait for cDataClkPeriod;
		init <= '0';
		check_value(rx_symbols_i_out, "000000000000", ERROR, "I component of output data");
		check_value(rx_symbols_q_out, "000000000000", ERROR,"Q component of output data");
		check_value(rx_symbols_valid, '0', MATCH_EXACT, ERROR, "Output valid signal");
		check_value(rx_symbols_start, '0', MATCH_EXACT, ERROR, "Output start signal");
		check_value(offset_inc, '0', MATCH_EXACT, ERROR, "Increment");
		check_value(offset_dec, '1', MATCH_EXACT, ERROR, "Decrement");

		log(ID_LOG_HDR, "Stop simulation");
		enable_sys_clock <= false;
		enable_ofdm_signal_generation <= false;
		wait_num_rising_edge(sys_clk, 2);

		report_alert_counters(VOID);
		wait; -- final wait
	end process;

end architecture;
