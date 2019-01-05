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
	constant cTimeBeforeRisingEdge : time := cSysClkPeriod / 10;

	-- signals
	signal sys_clk : std_ulogic := '0';
	signal enable_sys_clock : boolean := false;

	signal enable_ofdm_signal_generation : boolean := false;
	signal ofdm_signal_finished : boolean := false;
	
	signal reset_n : std_ulogic := '1';
	signal init : std_ulogic := '0';
	
	signal rx_data_i_in : signed(11 downto 0) := (others => '0');
	signal rx_data_q_in : signed(11 downto 0) := (others => '0');
	signal rx_data_in_valid : std_ulogic := '0';
	
	signal offset_inc : std_ulogic := '0';
	signal offset_dec : std_ulogic := '0';
	signal interp_mode : std_ulogic := '0';
	signal delay : std_ulogic_vector(3 downto 0);
	signal offset : std_ulogic_vector(3 downto 0);
	signal min_level : unsigned(15 downto 0) := (others => '0');
	signal rx_data_i_out : signed(11 downto 0) := (others => '0');
	signal rx_data_q_out : signed(11 downto 0) := (others => '0');
	signal rx_data_out_valid : std_ulogic := '0';
	signal rx_data_symb_start : std_ulogic := '0';
begin

    ------------------------------------------------------------------
    -- DUV
    ------------------------------------------------------------------
	DUV: entity work.CoarseAlignment
		port map (
			sys_clk_i 	=> sys_clk,
			sys_rstn_i 	=> reset_n,
			sys_init_i	=> init,
			rx_data_i_osr_i => rx_data_i_in,
			rx_data_q_osr_i => rx_data_q_in,
			rx_data_osr_valid_i => rx_data_in_valid,
			offset_inc_i => offset_inc,
			offset_dec_i => offset_dec,
			interp_mode_o => interp_mode,
			rx_data_delay_o => delay,
			rx_data_offset_o => offset,
			min_level_i => min_level,
			rx_data_i_coarse_o => rx_data_i_out,
			rx_data_q_coarse_o => rx_data_q_out,
			rx_data_coarse_valid_o => rx_data_out_valid,
			rx_data_symb_start_o => rx_data_symb_start
		);

	------------------------------------------------------------------
    -- Clock Generators
    ------------------------------------------------------------------
    SystemClockGenerator: clock_generator(sys_clk, enable_sys_clock, cSysClkPeriod, "100 MHz with 50% duty cycle", 50);
	
	------------------------------------------------------------------
    -- OFDM signal generator
    ------------------------------------------------------------------
	OFDMSignalGenerator: process 
		constant cFileName : String := "test_ofdm_symbols.txt";
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
					rx_data_i_in <= v_ofdm_signal(v_idx).I, (others => '0') after cSysClkPeriod;
					rx_data_q_in <= v_ofdm_signal(v_idx).Q, (others => '0') after cSysClkPeriod;
					rx_data_in_valid <= '1', '0' after cSysClkPeriod;
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
		variable test : integer := 0;
	begin	
	    -- init uvvm, set log files and enable log messages
        set_log_file_name("CoarseAlignment.txt");
        set_alert_file_name("CoarseAlignment_alert.txt");
        enable_log_msg(ALL_MESSAGES);
		
		-- generate reset pulse
		log(ID_LOG_HDR, "Start clock and generate reset");
        enable_sys_clock <= true;
        gen_pulse(reset_n, '0', 4 * cSysClkPeriod, BLOCKING, "Generate reset pulse");
		
		log(ID_LOG_HDR, "Check reset condition");
		check_value(interp_mode, '0', MATCH_EXACT, ERROR, "Interpolation mode");
		check_value(delay, "0000", MATCH_EXACT, ERROR, "Delay output");
		check_value(offset, "0000", MATCH_EXACT, ERROR, "Offset output");
		check_value(rx_data_out_valid, '0', MATCH_EXACT, ERROR, "Ouput valid signal");
		check_value(rx_data_symb_start, '0', MATCH_EXACT, ERROR, "Symbol start signal");
		check_value(rx_data_i_out, "000000000000", ERROR, "I component of output data");
		check_value(rx_data_q_out, "000000000000", ERROR, "Q component of output data");
	
		log(ID_LOG_HDR, "Find correlation peak");
		log(ID_SEQUENCER, "Start OFDM signal transmission");
		enable_ofdm_signal_generation <= true;
		wait on ofdm_signal_finished;
		log(ID_SEQUENCER, "OFDM signal transmission is over");
	
		log(ID_LOG_HDR, "Stop simulation");
		enable_sys_clock <= false;
		enable_ofdm_signal_generation <= false;
        wait_num_rising_edge(sys_clk, 2);

        report_alert_counters(VOID);
        wait; -- final wait
	end process;

end architecture;