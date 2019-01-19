-- fft.vhd

-- Generated using ACDS version 18.0 614

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fft is
	port (
		clk          : in  std_logic                     := 'X';             -- clk
		reset_n      : in  std_logic                     := 'X';             -- reset_n
		sink_valid   : in  std_logic                     := 'X';             -- valid
		sink_ready   : out std_logic;                                        -- ready
		sink_error   : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- error
		sink_sop     : in  std_logic                     := 'X';             -- startofpacket
		sink_eop     : in  std_logic                     := 'X';             -- endofpacket
		inverse      : in  std_logic                     := 'X';             -- data
		sink_imag    : in  std_logic_vector(11 downto 0) := (others => 'X'); -- data
		sink_real    : in  std_logic_vector(11 downto 0) := (others => 'X'); -- data
		source_valid : out std_logic;                                        -- valid
		source_ready : in  std_logic                     := 'X';             -- ready
		source_error : out std_logic_vector(1 downto 0);                     -- error
		source_sop   : out std_logic;                                        -- startofpacket
		source_eop   : out std_logic;                                        -- endofpacket
		source_exp   : out std_logic_vector(5 downto 0);                     -- data
		source_imag  : out std_logic_vector(11 downto 0);                    -- data
		source_real  : out std_logic_vector(11 downto 0)                     -- data
	);
end entity fft;

architecture rtl of fft is
	component fft_fft_ii_0 is
		port (
			clk          : in  std_logic                     := 'X';             -- clk
			reset_n      : in  std_logic                     := 'X';             -- reset_n
			sink_valid   : in  std_logic                     := 'X';             -- valid
			sink_ready   : out std_logic;                                        -- ready
			sink_error   : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- error
			sink_sop     : in  std_logic                     := 'X';             -- startofpacket
			sink_eop     : in  std_logic                     := 'X';             -- endofpacket
			inverse      : in  std_logic                     := 'X';             -- data
			sink_imag    : in  std_logic_vector(11 downto 0) := (others => 'X'); -- data
			sink_real    : in  std_logic_vector(11 downto 0) := (others => 'X'); -- data
			source_valid : out std_logic;                                        -- valid
			source_ready : in  std_logic                     := 'X';             -- ready
			source_error : out std_logic_vector(1 downto 0);                     -- error
			source_sop   : out std_logic;                                        -- startofpacket
			source_eop   : out std_logic;                                        -- endofpacket
			source_exp   : out std_logic_vector(5 downto 0);                     -- data
			source_imag  : out std_logic_vector(11 downto 0);                    -- data
			source_real  : out std_logic_vector(11 downto 0)                     -- data
		);
	end component fft_fft_ii_0;

	component altera_reset_controller is
		generic (
			NUM_RESET_INPUTS          : integer := 6;
			OUTPUT_RESET_SYNC_EDGES   : string  := "deassert";
			SYNC_DEPTH                : integer := 2;
			RESET_REQUEST_PRESENT     : integer := 0;
			RESET_REQ_WAIT_TIME       : integer := 1;
			MIN_RST_ASSERTION_TIME    : integer := 3;
			RESET_REQ_EARLY_DSRT_TIME : integer := 1;
			USE_RESET_REQUEST_IN0     : integer := 0;
			USE_RESET_REQUEST_IN1     : integer := 0;
			USE_RESET_REQUEST_IN2     : integer := 0;
			USE_RESET_REQUEST_IN3     : integer := 0;
			USE_RESET_REQUEST_IN4     : integer := 0;
			USE_RESET_REQUEST_IN5     : integer := 0;
			USE_RESET_REQUEST_IN6     : integer := 0;
			USE_RESET_REQUEST_IN7     : integer := 0;
			USE_RESET_REQUEST_IN8     : integer := 0;
			USE_RESET_REQUEST_IN9     : integer := 0;
			USE_RESET_REQUEST_IN10    : integer := 0;
			USE_RESET_REQUEST_IN11    : integer := 0;
			USE_RESET_REQUEST_IN12    : integer := 0;
			USE_RESET_REQUEST_IN13    : integer := 0;
			USE_RESET_REQUEST_IN14    : integer := 0;
			USE_RESET_REQUEST_IN15    : integer := 0;
			ADAPT_RESET_REQUEST       : integer := 0
		);
		port (
			reset_in0      : in  std_logic := 'X'; -- reset
			clk            : in  std_logic := 'X'; -- clk
			reset_out      : out std_logic;        -- reset
			reset_req      : out std_logic;        -- reset_req
			reset_req_in0  : in  std_logic := 'X'; -- reset_req
			reset_in1      : in  std_logic := 'X'; -- reset
			reset_req_in1  : in  std_logic := 'X'; -- reset_req
			reset_in2      : in  std_logic := 'X'; -- reset
			reset_req_in2  : in  std_logic := 'X'; -- reset_req
			reset_in3      : in  std_logic := 'X'; -- reset
			reset_req_in3  : in  std_logic := 'X'; -- reset_req
			reset_in4      : in  std_logic := 'X'; -- reset
			reset_req_in4  : in  std_logic := 'X'; -- reset_req
			reset_in5      : in  std_logic := 'X'; -- reset
			reset_req_in5  : in  std_logic := 'X'; -- reset_req
			reset_in6      : in  std_logic := 'X'; -- reset
			reset_req_in6  : in  std_logic := 'X'; -- reset_req
			reset_in7      : in  std_logic := 'X'; -- reset
			reset_req_in7  : in  std_logic := 'X'; -- reset_req
			reset_in8      : in  std_logic := 'X'; -- reset
			reset_req_in8  : in  std_logic := 'X'; -- reset_req
			reset_in9      : in  std_logic := 'X'; -- reset
			reset_req_in9  : in  std_logic := 'X'; -- reset_req
			reset_in10     : in  std_logic := 'X'; -- reset
			reset_req_in10 : in  std_logic := 'X'; -- reset_req
			reset_in11     : in  std_logic := 'X'; -- reset
			reset_req_in11 : in  std_logic := 'X'; -- reset_req
			reset_in12     : in  std_logic := 'X'; -- reset
			reset_req_in12 : in  std_logic := 'X'; -- reset_req
			reset_in13     : in  std_logic := 'X'; -- reset
			reset_req_in13 : in  std_logic := 'X'; -- reset_req
			reset_in14     : in  std_logic := 'X'; -- reset
			reset_req_in14 : in  std_logic := 'X'; -- reset_req
			reset_in15     : in  std_logic := 'X'; -- reset
			reset_req_in15 : in  std_logic := 'X'  -- reset_req
		);
	end component altera_reset_controller;

	signal rst_controller_reset_out_reset           : std_logic;                     -- rst_controller:reset_out -> rst_controller_reset_out_reset:in
	signal reset_reset_n_ports_inv                  : std_logic;                     -- reset_reset_n:inv -> rst_controller:reset_in0
	signal rst_controller_reset_out_reset_ports_inv : std_logic;                     -- rst_controller_reset_out_reset:inv -> fft_ii_0:reset_n
	signal fft_ii_0_inverse                         : std_logic;                     -- port fragment
	signal fft_ii_0_source_imag                     : std_logic_vector(11 downto 0); -- port fragment
	signal fft_ii_0_source_real                     : std_logic_vector(11 downto 0); -- port fragment
	signal fft_ii_0_sink_real                       : std_logic_vector(11 downto 0); -- port fragment
	signal fft_ii_0_source_exp                      : std_logic_vector(5 downto 0);  -- port fragment
	signal fft_ii_0_sink_imag                       : std_logic_vector(11 downto 0); -- port fragment

begin

	fft_ii_0 : component fft_fft_ii_0
		port map (
			inverse      => inverse,                                     -- fragmented-port.data
			source_real  => source_real,                                     -- fragmented-port.data
			source_imag  => source_imag,                                     -- fragmented-port.data
			sink_real    => sink_real,                                     -- fragmented-port.data
			source_exp   => source_exp,                                     -- fragmented-port.data
			sink_imag    => sink_imag,                                     -- fragmented-port.data
			clk          => clk,                                  --             clk.clk
			reset_n      => rst_controller_reset_out_reset_ports_inv, --             rst.reset_n
			sink_valid   => sink_valid,                                     --            sink.valid
			sink_ready   => sink_ready,                                     --                .ready
			sink_error   => sink_error,                                     --                .error
			sink_sop     => sink_sop,                                     --                .startofpacket
			sink_eop     => sink_eop,                                     --                .endofpacket
			source_valid => source_valid,                                     --          source.valid
			source_ready => source_ready,                                     --                .ready
			source_error => source_error,                                     --                .error
			source_sop   => source_sop,                                     --                .startofpacket
			source_eop   => source_eop                                      --                .endofpacket
		);

	rst_controller : component altera_reset_controller
		generic map (
			NUM_RESET_INPUTS          => 1,
			OUTPUT_RESET_SYNC_EDGES   => "deassert",
			SYNC_DEPTH                => 2,
			RESET_REQUEST_PRESENT     => 0,
			RESET_REQ_WAIT_TIME       => 1,
			MIN_RST_ASSERTION_TIME    => 3,
			RESET_REQ_EARLY_DSRT_TIME => 1,
			USE_RESET_REQUEST_IN0     => 0,
			USE_RESET_REQUEST_IN1     => 0,
			USE_RESET_REQUEST_IN2     => 0,
			USE_RESET_REQUEST_IN3     => 0,
			USE_RESET_REQUEST_IN4     => 0,
			USE_RESET_REQUEST_IN5     => 0,
			USE_RESET_REQUEST_IN6     => 0,
			USE_RESET_REQUEST_IN7     => 0,
			USE_RESET_REQUEST_IN8     => 0,
			USE_RESET_REQUEST_IN9     => 0,
			USE_RESET_REQUEST_IN10    => 0,
			USE_RESET_REQUEST_IN11    => 0,
			USE_RESET_REQUEST_IN12    => 0,
			USE_RESET_REQUEST_IN13    => 0,
			USE_RESET_REQUEST_IN14    => 0,
			USE_RESET_REQUEST_IN15    => 0,
			ADAPT_RESET_REQUEST       => 0
		)
		port map (
			reset_in0      => reset_reset_n_ports_inv,        -- reset_in0.reset
			clk            => clk,                        --       clk.clk
			reset_out      => rst_controller_reset_out_reset, -- reset_out.reset
			reset_req      => open,                           -- (terminated)
			reset_req_in0  => '0',                            -- (terminated)
			reset_in1      => '0',                            -- (terminated)
			reset_req_in1  => '0',                            -- (terminated)
			reset_in2      => '0',                            -- (terminated)
			reset_req_in2  => '0',                            -- (terminated)
			reset_in3      => '0',                            -- (terminated)
			reset_req_in3  => '0',                            -- (terminated)
			reset_in4      => '0',                            -- (terminated)
			reset_req_in4  => '0',                            -- (terminated)
			reset_in5      => '0',                            -- (terminated)
			reset_req_in5  => '0',                            -- (terminated)
			reset_in6      => '0',                            -- (terminated)
			reset_req_in6  => '0',                            -- (terminated)
			reset_in7      => '0',                            -- (terminated)
			reset_req_in7  => '0',                            -- (terminated)
			reset_in8      => '0',                            -- (terminated)
			reset_req_in8  => '0',                            -- (terminated)
			reset_in9      => '0',                            -- (terminated)
			reset_req_in9  => '0',                            -- (terminated)
			reset_in10     => '0',                            -- (terminated)
			reset_req_in10 => '0',                            -- (terminated)
			reset_in11     => '0',                            -- (terminated)
			reset_req_in11 => '0',                            -- (terminated)
			reset_in12     => '0',                            -- (terminated)
			reset_req_in12 => '0',                            -- (terminated)
			reset_in13     => '0',                            -- (terminated)
			reset_req_in13 => '0',                            -- (terminated)
			reset_in14     => '0',                            -- (terminated)
			reset_req_in14 => '0',                            -- (terminated)
			reset_in15     => '0',                            -- (terminated)
			reset_req_in15 => '0'                             -- (terminated)
		);

	reset_reset_n_ports_inv <= not reset_n;

	rst_controller_reset_out_reset_ports_inv <= not rst_controller_reset_out_reset;

end architecture rtl; -- of fft