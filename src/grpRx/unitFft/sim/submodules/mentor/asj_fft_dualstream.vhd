-- (C) 2001-2018 Intel Corporation. All rights reserved.
-- Your use of Intel Corporation's design tools, logic functions and other 
-- software and tools, and its AMPP partner logic functions, and any output 
-- files from any of the foregoing (including device programming or simulation 
-- files), and any associated documentation or information are expressly subject 
-- to the terms and conditions of the Intel Program License Subscription 
-- Agreement, Intel FPGA IP License Agreement, or other applicable 
-- license agreement, including, without limitation, that your use is for the 
-- sole purpose of programming logic devices manufactured by Intel and sold by 
-- Intel or its authorized distributors.  Please refer to the applicable 
-- agreement for further details.


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
--  version   : $Version: 1.0 $ 
--  revision    : $Revision: #1 $ 
--  designer name   : $Author: psgswbuild $ 
--  company name    : altera corp.
--  company address : 101 innovation drive
--                      san jose, california 95134
--                      u.s.a.
-- 
--  copyright altera corp. 2003
-- 
-- 
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_dualstream.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all; 
use work.fft_pack.all;
library work;
use work.auk_dspip_lib_pkg.all;
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
-- Dual Engine Streaming FFT Core
-- Dual Engine required for all streaming FFTs with point sizes, N > 1024.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
entity asj_fft_dualstream is
  generic(
            device_family : string;
            nps : integer :=2048;
            nume : integer :=2;
            bfp  : integer :=1;
            mpr : integer :=16;
            twr : integer :=16;
            fpr : integer :=4;
            bpr  : integer :=16;
            bpb  : integer :=8;
            mult_type : integer :=0;
            mult_imp  : integer :=0;
            dsp_arch  : integer :=0;
            mram : integer :=0;
            m512 : integer :=0;
            rfs1 : string  :="test_1n2048cos.hex";
            rfs2 : string  :="test_2n2048cos.hex";
            rfs3 : string  :="test_3n2048cos.hex";
            rfc1 : string  :="test_1n2048sin.hex";
            rfc2 : string  :="test_2n2048sin.hex";
            rfc3 : string  :="test_3n2048sin.hex";
            srr  : string  :="AUTO_SHIFT_REGISTER_RECOGNITION=OFF"
          );
port(     clk             : in std_logic;
reset_n           : in std_logic;
clk_ena           : in std_logic:='1';
inverse             : in std_logic;
sink_real    : in std_logic_vector(mpr-1 downto 0);
sink_imag    : in std_logic_vector(mpr-1 downto 0);
source_real    : out std_logic_vector(mpr-1 downto 0);
source_imag    : out std_logic_vector(mpr-1 downto 0);
source_exp    : out std_logic_vector(fpr+1 downto 0);
-- Atlantic II Sink Interface Signals
sink_sop             : in std_logic;
sink_eop             : in std_logic;
sink_valid             : in std_logic;
sink_ready             : out std_logic;            
-- Atlantic II Source Signals
sink_error             : in std_logic_vector(1 downto 0);            
source_error             : out std_logic_vector(1 downto 0);            
source_ready             : in std_logic;
source_valid             : out std_logic;
source_sop             : out std_logic;
source_eop             : out std_logic
);
end asj_fft_dualstream;

architecture transform of asj_fft_dualstream is
  constant FRAME_SIZE       : integer := nps;
  constant FRAME_WORD_WIDTH : integer := log2_ceil(nps);  
  constant WORD_LENGTH      : integer := mpr;  
  constant EXP_WIDTH        : integer := fpr+2;
  constant FIFO_DEPTH_c : natural := 7;
  
--fft signals
signal global_clock_enable:  std_logic;
signal inv_i:  std_logic;
signal data_real_in    : std_logic_vector(mpr-1 downto 0);
signal data_imag_in    : std_logic_vector(mpr-1 downto 0);
signal fft_real_out    : std_logic_vector(mpr-1 downto 0);
signal fft_imag_out    : std_logic_vector(mpr-1 downto 0);
signal exponent_out    : std_logic_vector(fpr+1 downto 0);
signal master_sink_sop : std_logic;
signal master_sink_eop : std_logic;
signal master_sink_dav : std_logic;
signal master_sink_ena : std_logic;
signal master_source_dav : std_logic;
signal master_source_ena : std_logic;
signal master_source_sop : std_logic;
signal master_source_eop :std_logic;
signal data_count          : std_logic_vector (FRAME_WORD_WIDTH-1 downto 0);     
signal data_count_sig      : natural range 0 to FRAME_SIZE-1;                    
-- atlantic sink 
signal sink_ready_ctrl : std_logic;
signal sink_stall      : std_logic;
signal sink_packet_error    : std_logic_vector (1 downto 0);
signal data_in_sig : std_logic_vector(mpr+mpr-1 downto 0);
signal at_data_in_sig : std_logic_vector(mpr+mpr-1 downto 0);
signal data_avaliable_sig  : std_logic;
-- atlantic source 
signal data_out_sig : std_logic_vector(mpr+mpr+fpr+1 downto 0);
signal at_data_out_sig : std_logic_vector(mpr+mpr+fpr+1 downto 0);
signal source_packet_error    : std_logic_vector (1 downto 0);
signal source_valid_ctrl : std_logic;
signal source_stall      : std_logic;
  signal stall               : std_logic;
  signal fft_ready_sig, sink_in_work : std_logic;      
  signal reset : std_logic;              

                                                                            
  component auk_dspip_avalon_streaming_controller                                  
    port (
      clk : in std_logic;
      clk_en : in std_logic :='1';
      ready               : in  std_logic;                                  
      reset_n               : in  std_logic;                                  
      sink_packet_error   : in  std_logic_vector (1 downto 0);              
      sink_stall          : in  std_logic;                                  
      source_stall        : in  std_logic;                                  
      valid               : in  std_logic;                                  
      reset_design        : out std_logic;                                  
      sink_ready_ctrl     : out std_logic;                                  
      source_packet_error : out std_logic_vector (1 downto 0);              
      source_valid_ctrl   : out std_logic;                                  
      stall               : out std_logic);                                 
  end component;                                                            
                                                                            
  component auk_dspip_avalon_streaming_source                                       
    generic (                                                               
      WIDTH_g           : integer;                                            
      packet_size_g     : natural;                                            
      multi_channel_g   : string);                                           
    port (                                                                  
      clk               : in  std_logic;                                    
      reset_n           : in  std_logic;                                    
      data              : in  std_logic_vector (WIDTH_g-1 downto 0);          
      data_count        : in  std_logic_vector (log2_ceil(PACKET_SIZE_g)-1 downto 0);
      source_valid_ctrl : in  std_logic;
      design_stall : in std_logic;
      source_stall      : out std_logic;                                    
      packet_error      : in  std_logic_vector (1 downto 0);                
      at_source_ready   : in  std_logic;                                    
      at_source_valid   : out std_logic;                                    
      at_source_data    : out std_logic_vector (WIDTH_g-1 downto 0);          
      at_source_channel : out std_logic_vector (log2_ceil(packet_size_g)-1 downto 0);
      at_source_error   : out std_logic_vector (1 downto 0);                
      at_source_sop     : out std_logic;                                    
      at_source_eop     : out std_logic);                                   
  end component;                                                            
 
 component auk_dspip_avalon_streaming_sink                                         
    generic (                                                               
      WIDTH_g           : integer;                                            
      PACKET_SIZE_g    : natural;                                            
      SOP_EOP_CALC_g: string ;
      FAMILY_g : string;
      FIFO_DEPTH_g : natural;
      MEM_TYPE_g : string
      );                                           
    port (                                                                  
      clk             : in  std_logic;                                      
      reset_n         : in  std_logic;                                      
      data            : out std_logic_vector(WIDTH_g-1 downto 0);             
      sink_ready_ctrl : in  std_logic;                                      
      sink_stall      : out std_logic;                                      
      packet_error    : out std_logic_vector (1 downto 0);                  
      send_sop        : out std_logic;                                      
      send_eop        : out std_logic;                                      
      at_sink_ready   : out std_logic;                                      
      at_sink_valid   : in  std_logic;                                      
      at_sink_data    : in  std_logic_vector(WIDTH_g-1 downto 0);             
      at_sink_sop     : in  std_logic;                                      
      at_sink_eop     : in  std_logic;                                      
      at_sink_error   : in  std_logic_vector(1 downto 0));                  
  end component;                                                            




  constant apr : integer :=LOG2_FLOOR(nps)-3; -- apr = log2(nps)-2 fo single engine
  constant apr_mram : integer :=LOG2_FLOOR(nps)-2; -- apr = log2(nps)-2 fo single engine
  constant twa : integer :=LOG2_FLOOR(nps)-2; 
  constant exp_init_fft : integer :=-1*LOG2_FLOOR(nps); 
  constant dpr : integer :=2*mpr;
  constant n_bfly : integer := nps/4;
  constant n_by_16 : integer := nps/16;
  constant log2_nps : integer := LOG2_CEIL(nps);
  constant log2_n_bfly : integer := LOG2_CEIL(n_bfly);
  constant n_passes : integer := LOG4_CEIL(nps);
  constant n_passes_m1 : integer := LOG4_CEIL(nps)-1;
  constant ptc : integer := LOG4_CEIL(nps);
  constant log2_n_passes: integer := LOG2_CEIL(n_passes);
  constant mid_apr : integer :=apr/2;
  -- last_pass_radix = 0 => radix 4
  -- last_pass_radix = 1 => radix 2
  constant last_pass_radix : integer :=(LOG4_CEIL(nps))-(LOG4_FLOOR(nps));
  constant twid_delay : integer :=7;
  
  constant wr_ad_delay : integer :=18;
  constant rbuspr : integer :=4*mpr;
  constant cbuspr : integer :=8*mpr;
  constant abuspr : integer :=4*apr;
  constant switch_read_data : integer:= 1;
  constant initial_en_np_delay : integer :=12;
  
  constant wr_en_null : integer :=24;
  constant arch : integer :=0;
  constant mem_string : string :="AUTO";
  -- State machine variables
  -- Input Interface Control
  type   fft_s1_state is (IDLE,WAIT_FOR_INPUT,WRITE_INPUT,CHECK_DAV,LAST_INPUT);
  signal fft_s1_cur,fft_s1_next :  fft_s1_state;
  
  -- State machine variables
  -- Output Interface Control
  type   fft_s2_state is (IDLE,WAIT_FOR_LPP_INPUT,FIRST_LPP_C,LPP_C_OUTPUT,LAST_LPP_C);
  signal fft_s2_cur,fft_s2_next :  fft_s2_state;
  
  -- Direction selector
  signal dirn_select :  std_logic ;
  
  type complex_data_bus is array (0 to 3,0 to 1) of std_logic_vector(mpr-1 downto 0);
  type real_data_bus    is array (0 to 4*nume-1) of std_logic_vector(mpr-1 downto 0);
  type engine_data_bus  is array (0 to 4*nume-1) of std_logic_vector(2*mpr-1 downto 0);
  type address_bus_vec  is array (0 to 3) of std_logic_vector(apr-1 downto 0);
  type address_array    is array (0 to 3) of std_logic_vector(apr-1 downto 0);  
  
  type twiddle_bus is array (0 to 2,0 to 1) of std_logic_vector(twr-1 downto 0);
  type twiddle_address_array is array (0 to twid_delay-1) of std_logic_vector(twa-1 downto 0);
  type wr_address_delay is array (0 to wr_ad_delay) of std_logic_vector(apr-1 downto 0);
  
  type selector_array is array (0 to 3) of std_logic_vector(1 downto 0);
  type sw_r_array is array (0 to 8) of std_logic_vector(1 downto 0);
  type p_array is array (0 to 18) of std_logic_vector(log2_n_passes-1 downto 0);
  
  signal data_in      : complex_data_bus;
  signal data_in_reg  : complex_data_bus;
  signal data_in_bfp_x  : complex_data_bus;
  signal data_in_bfp_y  : complex_data_bus;
  
  -----------------------------------------------------------------------------------
  -- BFP Signals
  signal last_bfp_factor : std_logic_vector(3 downto 0) := "1000";
  -- INPUT BFP UNIT I/O
  signal real_bfp_input : std_logic_vector(rbuspr-1 downto 0);
  signal imag_bfp_input : std_logic_vector(rbuspr-1 downto 0);
  signal real_bfp_output : std_logic_vector(rbuspr-1 downto 0);
  signal imag_bfp_output : std_logic_vector(rbuspr-1 downto 0);
  
  
  signal twiddle_data_x : twiddle_bus;
  signal twiddle_data_y : twiddle_bus;
  signal twiddle_address : twiddle_address_array;
  --butterfly inputs
  signal dr1i,dr2i,dr3i,dr4i : std_logic_vector(mpr-1 downto 0);
  signal di1i,di2i,di3i,di4i : std_logic_vector(mpr-1 downto 0);
  
  signal dft_r_o             : real_data_bus;
  signal dft_i_o             : real_data_bus;
  
  -- butterfly outputs
  signal dr1o,dr2o,dr3o,dr4o : std_logic_vector(mpr-1 downto 0);
  signal di1o,di2o,di3o,di4o : std_logic_vector(mpr-1 downto 0);
  -- twiddle ROM Outputs
  -- Dual Engine Signals
  signal t1re,t2re,t3re          : std_logic_vector(twr-1 downto 0);
  signal t1ro,t2ro,t3ro          : std_logic_vector(twr-1 downto 0);
  signal t1ie,t2ie,t3ie          : std_logic_vector(twr-1 downto 0);  
  signal t1io,t2io,t3io          : std_logic_vector(twr-1 downto 0);  
  
  -- RAM Select
  -- Selects between RAM Block A or B for input buffer
  signal ram_a_not_b          : std_logic;
  signal ram_a_not_b_vec      : std_logic_vector(31 downto 0); 
  signal sel_mux_a_c              : std_logic_vector(log2_n_passes downto 0);
  ----------------------------------------------------------------------
  signal data_rdy : std_logic;
  signal data_rdy_vec      : std_logic_vector(31 downto 0); 
  
  
  -----------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  -- Direction selector
  signal fft_dirn         : std_logic;
  signal fft_dirn_held    : std_logic;
  signal fft_dirn_held_o  : std_logic;
  signal fft_dirn_held_o2 : std_logic;
  signal fft_dirn_stream  : std_logic;
  -----------------------------------------------------------------------------------------------
  -- Registered Core Signals
  -----------------------------------------------------------------------------------------------
  signal data_real_in_reg : std_logic_vector(mpr-1 downto 0);
  signal data_imag_in_reg : std_logic_vector(mpr-1 downto 0);
  signal core_real_in : std_logic_vector(mpr-1 downto 0);
  signal core_imag_in : std_logic_vector(mpr-1 downto 0);
  -----------------------------------------------------------------------------------
  
  
  signal wraddr_i             : std_logic_vector(apr-1 downto 0); 
  signal i_ram_real           : std_logic_vector(mpr-1 downto 0);
  signal i_ram_imag           : std_logic_vector(mpr-1 downto 0);
  signal i_ram_data_in        : std_logic_vector(2*mpr-1 downto 0);
  signal i_wren               : std_logic_vector(3 downto 0);
  
  signal wraddr               : address_array; 
  signal wraddr_sw            : address_array; 
  signal rdaddr               : address_array; 
  signal rdaddr_sw            : address_array; 
  signal rdaddr_lpp            : address_array; 
  signal rdaddr_lpp_sw            : address_array; 
  
  -- address counters
  signal p_count              : std_logic_vector(log2_n_passes-1 downto 0);
  signal p_count_d              : std_logic_vector(log2_n_passes-1 downto 0);
  signal p_cd_en              : std_logic_vector(log2_n_passes-1 downto 0);
  signal p_tdl                : p_array;
  signal k_count              : std_logic_vector(apr-1 downto 0);
  signal k_count_d              : std_logic_vector(apr-1 downto 0);
  -- switch selects
  signal sw                   : std_logic_vector(1 downto 0);
  signal sw_r                 : std_logic_vector(1 downto 0);
  signal sw_r_d                 : std_logic_vector(1 downto 0);
  signal swd_w                  : std_logic_vector(1 downto 0);
  signal swa_w                  : std_logic_vector(1 downto 0);
  signal sw_rd_lpp                  : std_logic_vector(1 downto 0);
  signal sw_mram                  : std_logic_vector(1 downto 0);
  signal sw_ra_lpp                  : std_logic_vector(1 downto 0);
  signal sw_ra_lpp_d          : std_logic_vector(1 downto 0);
  signal sw_r_tdl             : sw_r_array;
  
  signal butterfly_output     : complex_data_bus;
  
  
  signal slb_x_o              : std_logic_vector(2 downto 0);
  signal slb_y_o              : std_logic_vector(2 downto 0);
  signal slb_last_i           : std_logic_vector(2 downto 0);
  signal dual_eng_slb         : std_logic_vector(3*nume-1 downto 0);
  
  
  -- wren
  signal wren_a               : std_logic_vector(4*nume-1 downto 0);
  signal wren_b               : std_logic_vector(4*nume-1 downto 0);
  signal wren_c               : std_logic_vector(4*nume-1 downto 0);
  signal wren_d               : std_logic_vector(4*nume-1 downto 0);
  signal rden_a               : std_logic_vector(3 downto 0);
  signal rden_b               : std_logic_vector(3 downto 0);
  signal rden_c               : std_logic_vector(3 downto 0);
  signal rden_d               : std_logic_vector(3 downto 0);
  
  signal wa                   : std_logic;
  signal wb                   : std_logic;
  signal wc                   : std_logic;
  signal wd                   : std_logic;
  signal wren_mram            : std_logic;
  
  
  
  
  signal lpp_c_en_early             : std_logic;
  signal lpp_d_en_early             : std_logic;
  signal wc_early             : std_logic;
  signal wd_early             : std_logic;
  signal lpp_c_en_vec               : std_logic_vector(12 downto 0);
  signal lpp_d_en_vec               : std_logic_vector(12 downto 0);
  signal wc_vec               : std_logic_vector(8 downto 0);
  signal wd_vec               : std_logic_vector(8 downto 0);
  
  signal anb_enabled          : std_logic;
  -----------------------------------------------------------------------------------------------
  -- Last Pass Enable Signals
  signal lpp_wrcnt_en           : std_logic;
  signal lpp_rdcnt_en           : std_logic;
  signal lpp_c_en               : std_logic;
  signal lpp_d_en               : std_logic;
  signal lpp_en                 : std_logic;
  signal lpp_fsm_en             : std_logic;
  signal lpp_start              : std_logic;
  signal lpp_start_d            : std_logic;
  signal lpp_start_d2           : std_logic;
  signal lpp_start_mram         : std_logic;
  
  -----------------------------------------------------------------------------------------------
  -- output address counter
  signal output_counter       : std_logic_vector(apr-1 downto 0);
  -- assigned addresses to individual memory banks
  signal wraddress_a          : address_array;  
  signal rdaddress_a          : address_array;  
  signal wraddress_b          : address_array;  
  signal rdaddress_b          : address_array;  
  signal rdaddress_a_bus : std_logic_vector(4*apr-1 downto 0);
  signal wraddress_a_bus : std_logic_vector(4*apr-1 downto 0);
  signal a_ram_data_in_bus_x: std_logic_vector(8*mpr-1 downto 0);
  signal a_ram_data_out_bus_x : std_logic_vector(8*mpr-1 downto 0);
  signal rdaddress_b_bus : std_logic_vector(4*apr-1 downto 0);
  signal wraddress_b_bus : std_logic_vector(4*apr-1 downto 0);
  signal b_ram_data_in_bus_x: std_logic_vector(8*mpr-1 downto 0);
  signal b_ram_data_out_bus_x : std_logic_vector(8*mpr-1 downto 0);
  -- M4K C/D address busses
  signal rdaddress_c_bus : std_logic_vector(4*apr-1 downto 0);
  signal wraddress_c_bus : std_logic_vector(4*apr-1 downto 0);
  -- MRAM C/D address busses
  signal rdaddress_c_x_bus : std_logic_vector(apr_mram-1 downto 0);
  signal rdaddress_c_y_bus : std_logic_vector(apr_mram-1 downto 0);
  signal wraddress_c_x_bus : std_logic_vector(apr_mram-1 downto 0);
  signal wraddress_c_y_bus : std_logic_vector(apr_mram-1 downto 0);
  
  signal c_ram_data_in_bus_x: std_logic_vector(8*mpr-1 downto 0);
  signal c_ram_data_out_bus_x : std_logic_vector(8*mpr-1 downto 0);
  signal d_ram_data_in_bus_x: std_logic_vector(8*mpr-1 downto 0);
  signal d_ram_data_out_bus_x : std_logic_vector(8*mpr-1 downto 0);
  signal a_ram_data_in_bus_y: std_logic_vector(8*mpr-1 downto 0);
  signal a_ram_data_out_bus_y : std_logic_vector(8*mpr-1 downto 0);
  signal b_ram_data_in_bus_y: std_logic_vector(8*mpr-1 downto 0);
  signal b_ram_data_out_bus_y : std_logic_vector(8*mpr-1 downto 0);
  signal c_ram_data_in_bus_y: std_logic_vector(8*mpr-1 downto 0);
  signal c_ram_data_out_bus_y : std_logic_vector(8*mpr-1 downto 0);
  signal d_ram_data_out_bus_y : std_logic_vector(8*mpr-1 downto 0);
  
  
  signal byte_enable_i :  std_logic_vector(bpr-1 downto 0);
    
  
  -- Block I RAM Data Output
  signal ram_data_out    : engine_data_bus;
  signal ram_data_out_sw    : engine_data_bus;
  signal ram_data_in    : engine_data_bus;
  signal ram_data_in_sw    : engine_data_bus;
  signal lpp_ram_data_out    : engine_data_bus;
  signal lpp_ram_data_out_sw : engine_data_bus;
  
  
  -- Debug Signals : De-aggregated data signals from RAM/Engine/LPP
  --signal ram_data_in_sw_debug : complex_data_bus;
  --signal ram_data_out_sw_debug : complex_data_bus;
  --signal ram_data_out_debug : complex_data_bus;
  --signal lpp_ram_data_in_sw_debug : complex_data_bus;
  --signal lpp_ram_data_out_sw_debug : complex_data_bus;
  --signal lpp_ram_data_out_debug : complex_data_bus;
  --signal lpp_ram_data_out_debug_r : real_data_bus;
  --signal lpp_ram_data_out_debug_i : real_data_bus;
  --
  --signal c_ram_data_in_debug_x : complex_data_bus;
  --signal c_ram_data_in_debug_y : complex_data_bus;
  --signal c_ram_data_out_debug_x : complex_data_bus;
  --signal c_ram_data_out_debug_y : complex_data_bus;
  
  signal next_pass  : std_logic ;
  signal next_pass_q  : std_logic ;
  signal next_pass_d  : std_logic ;
  signal block_done  : std_logic ;
  signal block_done_d  : std_logic ;
  
  signal blk_exp  : std_logic_vector(fpr+1 downto 0);
  signal blk_exp_accum  : std_logic_vector(fpr+1 downto 0);
  
  signal en_np  : std_logic ;
  signal twad : std_logic_vector(apr-1 downto 0);
  signal twade : std_logic_vector(apr downto 0);
  signal twado : std_logic_vector(apr downto 0);
  signal count :std_logic_vector(1 downto 0);
  
  
  signal data_real_out : std_logic_vector(mpr-1 downto 0);
  signal data_imag_out : std_logic_vector(mpr-1 downto 0);
  signal lpp_data_val : std_logic;
  signal lpp_count : std_logic_vector(log2_nps downto 0);
  signal lpp_count_offset : std_logic_vector(log2_nps downto 0);
  signal lpp_sel : std_logic;
  signal lpp_mram_wr_sel : std_logic;
  signal next_blk : std_logic;
  
  signal sel_anb_addr : std_logic;
  signal sel_anb_ram  : std_logic;
  signal which_ram_set : std_logic;
  signal which_ram_set_e : std_logic;
  
  signal dsw : std_logic;
  -- output exponent enable
  signal exp_en : std_logic ;
  --output enable
  signal oe : std_logic ;
  -- disable writing to memory by deasserting master_sink_ena
  -- this needs to be generated by the writer, but asserted a few cycles before dopne to account
  -- for latency from the fft to the user's system   
  signal nbc : std_logic_vector(log2_n_passes-1 downto 0) ;
  signal sop_out : std_logic ;
  signal sop_d : std_logic ;
  signal eop_out : std_logic ;
  signal val_out : std_logic ;
  signal val_o : std_logic ;
  signal dav_int      : std_logic ;
  signal load_block     : std_logic ;
  signal unload_block     : std_logic ;
  signal sample_count : std_logic_vector(log2_nps-1 downto 0);
  
  -----------------------------------------------------------------------------------------------
  -- Streaming architecture requires master_sink_val to be high during load of input block
  -- Removing signal form input port list and typing it to VCC for release 2.0.0
  -----------------------------------------------------------------------------------------------
  signal master_sink_val : std_logic;
  -----------------------------------------------------------------------------------------------
   signal sop : std_logic;
  signal source_stall_d : std_logic;
   signal stall_sop : std_logic;
  signal source_valid_ctrl_sop : std_logic;
   signal sink_ready_ctrl_d : std_logic;
  signal start_sop : std_logic;

begin
  reset <= not reset_n;                                                                    
                                                                                           
  -----------------------------------------------------------------------------            
  -- the sink                                                                              
  -----------------------------------------------------------------------------            
 auk_dsp_atlantic_sink_1 : auk_dspip_avalon_streaming_sink                                        
    generic map (                                                                          
      WIDTH_g           => WORD_LENGTH*2,                                                    
      PACKET_SIZE_g     => FRAME_SIZE,
      SOP_EOP_CALC_g => "true",
      FIFO_DEPTH_g => FIFO_DEPTH_c,
      FAMILY_g         => "Stratix II",
      MEM_TYPE_g       => "Auto")                                             
    port map (                                                                             
      clk             => clk,                                                              
      reset_n         => reset_n,                                                          
      data            => data_in_sig,                                                      
      sink_ready_ctrl => sink_ready_ctrl,                                                  
      sink_stall      => sink_stall,                                                       
      at_sink_error   => sink_error,                                                             
      packet_error    => sink_packet_error,                                                
      send_sop        => master_sink_sop,                                                  
      send_eop        => master_sink_eop,                                                  
      at_sink_ready   => sink_ready,                                                       
      at_sink_valid   => sink_valid,                                                       
      at_sink_data    => at_data_in_sig,                                                   
      at_sink_eop     => sink_eop,                                                         
      at_sink_sop     => sink_sop);                                                        

                                                                                           
  at_data_in_sig <= (sink_real & sink_imag);                                               
                                                                                           
  -----------------------------------------------------------------------------            
  -- the source                                                                            
  -----------------------------------------------------------------------------            
    auk_dsp_atlantic_source_1 : auk_dspip_avalon_streaming_source                                    
    generic map (                                                                          
      WIDTH_g           => WORD_LENGTH*2+EXP_WIDTH,                                          
      packet_size_g     => FRAME_SIZE,                                                       
      multi_channel_g   => "false")                                                            
    port map (                                                                             
      clk               => clk,                                                            
      reset_n           => reset_n,                                                        
      data              => data_out_sig,                                                   
      data_count        => data_count,                                                     
      source_valid_ctrl => source_valid_ctrl_sop,                                              
      source_stall      => source_stall,                                                   
      design_stall      => stall_sop,                                                   
      packet_error      => source_packet_error,                                            
      at_source_ready   => source_ready,                                                   
      at_source_valid   => source_valid,                                                   
      at_source_error   => source_error,                                                   
      at_source_sop     => source_sop,                                                     
      at_source_eop     => source_eop,                                                     
      at_source_data    => at_data_out_sig);                                               
                                                                                          

                                                                                           
  data_out_sig  <= fft_real_out & fft_imag_out & exponent_out;                             
  fft_ready_sig_proc : process (clk)
  begin     
      if rising_edge(clk) then                 
          if reset_n = '0' then
              sink_in_work <= '0';
          else
              if master_sink_sop = '1' then
                  sink_in_work <= '1';
              elsif master_sink_eop = '1' then
                  sink_in_work <= '0';
              end if;
          end if;
      end if;
  end process;    
  fft_ready_sig <= master_sink_ena when sink_in_work = '0' or master_sink_eop = '1' else   
                   '1';                                                   
  source_real   <= at_data_out_sig(WORD_LENGTH*2+EXP_WIDTH-1 downto WORD_LENGTH+EXP_WIDTH);
  source_imag   <= at_data_out_sig(WORD_LENGTH+EXP_WIDTH-1 downto EXP_WIDTH);              
  source_exp    <= at_data_out_sig(EXP_WIDTH-1 downto 0);                                  
                                                                                           
  -----------------------------------------------------------------------------            
  -- the interface controller                                                              
  -----------------------------------------------------------------------------            
   auk_dsp_interface_controller_1 : auk_dspip_avalon_streaming_controller                          
    port map (
      clk => clk,
      clk_en => clk_ena,
      ready               => fft_ready_sig,                                                
      reset_n               => reset_n,                                                        
      sink_packet_error   => sink_packet_error,                                            
      sink_stall          => sink_stall,                                                   
      source_stall        => source_stall,                                                 
      valid               => master_source_ena,                                            
      sink_ready_ctrl     => sink_ready_ctrl,                                              
      source_packet_error => source_packet_error,                                          
      source_valid_ctrl   => source_valid_ctrl,                                            
      stall               => stall);                                                       
                                                                                 
  counter_p : process (clk, reset_n)
  begin
    if reset_n = '0' then
      sop       <= '1';  -- modified SPR 268207
      source_stall_d <= '0';
       sink_ready_ctrl_d <= '0';
   elsif rising_edge(clk) then
        source_stall_d <= source_stall;
       sink_ready_ctrl_d <= sink_ready_ctrl;
     if master_sink_eop = '1' and sink_ready_ctrl_d = '1' then
            sop       <= '1';
      elsif  master_sink_sop = '1' and sink_ready_ctrl_d = '1'   then
          sop       <= '0';
        end if;
    end if;
  end process counter_p;

  start_sop <= master_sink_sop  and sink_ready_ctrl_d ;

  stall_sop <=stall when sop = '0' or start_sop = '1' else 
                    source_stall_d or (not clk_ena);

  source_valid_ctrl_sop <= source_valid_ctrl when sop = '0' or start_sop = '1' else 
                          master_source_ena  when sop = '1' and clk_ena = '1' else
                           master_source_ena and source_stall_d ;

 

  -----------------------------------------------------------------------------
  -- the fft                                                                   
  -----------------------------------------------------------------------------
   --modified SPR 268207
   global_clock_enable <= (not stall) when sop = '0' or start_sop = '1'  else
                          (not source_stall_d) and clk_ena;  

  data_real_in        <= data_in_sig(WORD_LENGTH*2-1 downto WORD_LENGTH);       
  data_imag_in        <= data_in_sig(WORD_LENGTH-1 downto 0);                   
                                                                                
  -- purpose: counter for each frame                                            
  -- type   : sequential                                                        
  -- inputs : clk, rst, global_clock_enable, data_count_sig                     
  -- outputs: data_count                                                        
  data_sample_counter : process (clk, reset)                                    
  begin  -- process data_sample_counter                                         
    if reset = '1' then                 -- asynchronous reset (active high)     
      data_count_sig <= 0;                                                      
    elsif clk'event and clk = '1' then  -- rising clock edge                    
      if (global_clock_enable = '1') then                                       
        if (master_source_sop = '1') then                                       
          data_count_sig <= 1;                                                  
        elsif (data_count_sig /= 0 and data_count_sig < FRAME_SIZE-1) then      
          data_count_sig <= data_count_sig+1;                                   
        elsif (data_count_sig = FRAME_SIZE-1) then                              
          data_count_sig <= 0;                                                  
        end if;                                                                 
      end if;                                                                   
    end if;                                                                     
  end process data_sample_counter;                                              
                                                                                
  data_count <= std_logic_vector(to_unsigned(data_count_sig, FRAME_WORD_WIDTH));
      master_sink_dav  <= '1';
  master_source_dav  <= '1';

  process (clk)
  begin
    if clk'event and clk = '1' then
      if sink_valid = '1' then
        inv_i <= inverse;
      end if;
    end if;
  end process;

  
    master_sink_val <= '1';
    -----------------------------------------------------------------------------------------------
    -- Counter Logic
    -- Defines k,m,p counters
    -----------------------------------------------------------------------------------------------
    ctrl : asj_fft_m_k_counter 
    generic map(
              nps => nps,
              arch => 0,
              nume => nume,
              n_passes => n_passes_m1, --log4(nps) - 1
              log2_n_passes => log2_n_passes, 
              apr => apr, --apr = log2(nps/4)
              cont => 0
            )
    port map(     
global_clock_enable => global_clock_enable,
              clk      => clk,
              reset    => reset,
              stp      => master_sink_sop,
              start    => data_rdy_vec(3),
              next_block => next_blk,
              p_count  => p_count,
              k_count  => k_count,
              next_pass => next_pass_q,
              blk_done  => block_done
        );
    
    -----------------------------------------------------------------------------------------------
    -- Next Pass Indicator Control    
    --------------------------------------------------------------------------    
    next_pass <= en_np and next_pass_q;
    
    delay_swd : asj_fft_tdl_bit_rst
      generic map( 
                  del   => 10
              )
      port map(   
global_clock_enable => global_clock_enable,
                  clk   => clk,
                  reset => reset,               
                  data_in   => next_pass,
                  data_out  => next_pass_d
          );
    
        
enable_next_pass:process(clk,global_clock_enable,reset,p_tdl(initial_en_np_delay))is
      begin
if((rising_edge(clk) and global_clock_enable='1'))then
          if(reset='1') then
            en_np <='0';
          else
            if(p_tdl(initial_en_np_delay) = int2ustd(1,log2_n_passes)) then
              en_np <= '1';
            elsif(p_tdl(initial_en_np_delay) = int2ustd(ptc,log2_n_passes)) then
              en_np <= '0';
            end if;
          end if;
        end if;
      end process enable_next_pass;
    -----------------------------------------------------------------------------------------------
    -- RAM Bank Selector      
    -----------------------------------------------------------------------------------------------
ram_sel_vec:process(clk,global_clock_enable,reset,ram_a_not_b,ram_a_not_b_vec,data_rdy,data_rdy_vec)is
      begin
if((rising_edge(clk) and global_clock_enable='1'))then
          if(reset='1') then
            ram_a_not_b_vec <=(others=>'1');
            data_rdy_vec <=(others=>'0');
          else
            for i in 31 downto 1 loop
              ram_a_not_b_vec(i) <= ram_a_not_b_vec(i-1);
              data_rdy_vec(i)    <= data_rdy_vec(i-1);
            end loop;
            ram_a_not_b_vec(0) <= ram_a_not_b;
            data_rdy_vec(0) <= data_rdy;
          end if;
        end if;
    end process ram_sel_vec;
    -----------------------------------------------------------------------------------------------
    -- Pass Counter TDL
    -----------------------------------------------------------------------------------------------
p_vec:process(clk,global_clock_enable,p_count,p_tdl)is
      begin
if((rising_edge(clk) and global_clock_enable='1'))then
            for i in 18 downto 1 loop
              p_tdl(i) <= p_tdl(i-1);
            end loop;
            p_tdl(0) <= p_count;
        end if;
    end process p_vec;
    -----------------------------------------------------------------------------------------------
    anb_enabled <= ram_a_not_b_vec(26);
    ----------------------------------------------------------------------------------------------- 
  
    -----------------------------------------------------------------------------------------------
    -- C,D Banks Write Enable Generation
    -----------------------------------------------------------------------------------------------
    p_cd_en <= p_tdl(12);
  
    sel_we :  asj_fft_wrengen 
      generic map(
            nps => nps,
            arch => arch,
            n_passes => n_passes,
            log2_n_passes => log2_n_passes,
            apr => apr,
            del => 0
          )
      port map(     
global_clock_enable => global_clock_enable,
            clk     => clk,
            reset   => reset,
            p_count => p_cd_en,
            anb     => anb_enabled,
            lpp_c_en=> lpp_c_en_early,
            lpp_d_en=> lpp_d_en_early,
            wc      => wc_early,
            wd      => wd_early
      );
      
      --Delay early write enables for RAMS C and D
del_wcd:process(clk,global_clock_enable,reset,wc_early,wd_early,wc_vec,wd_vec,lpp_c_en_vec,lpp_d_en_vec,lpp_c_en_early,lpp_d_en_early)is
        begin 
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset ='1') then
              for i in 0 to 8 loop
                wc_vec(i) <= '0';
                wd_vec(i) <= '0';
              end loop;
              for i in 0 to 12 loop
                lpp_c_en_vec(i) <= '0';
                lpp_d_en_vec(i) <= '0';               
              end loop;
            else
              for i in 8 downto 1 loop
                wc_vec(i) <= wc_vec(i-1);
                wd_vec(i) <= wd_vec(i-1);
              end loop;
              for i in 12 downto 1 loop
                lpp_c_en_vec(i) <= lpp_c_en_vec(i-1);
                lpp_d_en_vec(i) <= lpp_d_en_vec(i-1);
              end loop;
              wc_vec(0) <= wc_early;
              wd_vec(0) <= wd_early;
              lpp_c_en_vec(0) <= lpp_c_en_early;
              lpp_d_en_vec(0) <= lpp_d_en_early;
            end if;
          end if;
        end process del_wcd;
        wc <= wc_vec(4);
        wd <= wd_vec(4);
        
      -----------------------------------------------------------------------------------------------
      -----------------------------------------------------------------------------------------------
      -----------------------------------------------------------------------------------------------
      wren_c <= ( 7 downto 0 => wc);
      wren_d <= ( 7 downto 0 => wd);
      
weab_st:process(clk,global_clock_enable,reset,ram_a_not_b_vec,which_ram_set,i_wren)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
              wren_a <= (7 downto 0 => '1');
              wren_b <= (7 downto 0 => '0');
            else
              if(ram_a_not_b_vec(1)='0') then
                wren_b(3 downto 0) <= i_wren and (3 downto 0 => not(which_ram_set));
                wren_b(7 downto 4) <= i_wren and (3 downto 0 => (which_ram_set));
                wren_a <= (7 downto 0 => not(ram_a_not_b_vec(1) xor ram_a_not_b_vec(wr_en_null)));
              else
                wren_a(3 downto 0) <= i_wren and (3 downto 0 => not(which_ram_set));
                wren_a(7 downto 4) <= i_wren and (3 downto 0 => (which_ram_set));
                wren_b <= (7 downto 0 => not(ram_a_not_b_vec(1) xor ram_a_not_b_vec(wr_en_null)));
              end if;
            end if;
          end if;
        end process weab_st;
        

        -----------------------------------------------------------------------------------------------
        -- Add delay to RAM switch logic to allow for inverison on last input sample
        -----------------------------------------------------------------------------------------------
we_st:process(clk,global_clock_enable,reset,master_sink_sop,which_ram_set)is
          begin
if((rising_edge(clk) and global_clock_enable='1'))then
              if(reset='1') then
                which_ram_set <= '0';
                which_ram_set_e <= '0';           
              else
                which_ram_set <= which_ram_set_e;
                if(fft_s1_cur=IDLE or fft_s1_cur=WAIT_FOR_INPUT) then
                  which_ram_set_e <= '1';
                else
                  which_ram_set_e <= not(which_ram_set_e);
                end if;
              end if;
            end if;
          end process we_st;
        
        
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  
  writer : asj_fft_in_write_sgl
  generic map(
            nps => nps,
            arch => arch,
            mram => 0,
            nume=> nume,
            mpr => mpr,
            apr => apr,
            bpr => bpr,
            bpb => bpb
          )
  port map( 
global_clock_enable => global_clock_enable,
            clk       => clk,
            reset     => reset,
            stp       => master_sink_sop,
            val       => master_sink_val,
            block_done => '0',
            data_real_in    => core_real_in,
            data_imag_in    => core_imag_in,
            wr_address_i    => wraddr_i,
            wren_i          => i_wren,
            byte_enable     => byte_enable_i,
            data_rdy        => data_rdy,
            a_not_b         => ram_a_not_b,
            next_block      => next_blk,
            disable_wr      => dsw,
            data_in_r       => i_ram_real,
            data_in_i       => i_ram_imag
      );
              
      i_ram_data_in <= i_ram_real & i_ram_imag;     
      
  -----------------------------------------------------------------------------------------   
  -- Continuous requires ram_a_not_b_vec(8)
  --sel_anb_addr      => ram_a_not_b_vec(8),
  sel_anb_addr <= ram_a_not_b_vec(7) and data_rdy_vec(10);
  -- Continuous requires ram_a_not_b_vec(11)
  --sel_anb_ram       => ram_a_not_b_vec(11),
  sel_anb_ram  <= ram_a_not_b_vec(10) and data_rdy_vec(10);
  
  ccc :  asj_fft_cnt_ctrl_de 
  generic map(
            nps => nps,
            mpr => mpr,
            apr => apr,
            abuspr => abuspr, --4*apr
            rbuspr => rbuspr, --4*mpr
            cbuspr => cbuspr --2*4*mpr
          )
  port map(     
global_clock_enable => global_clock_enable,
            clk                 => clk,
            sel_anb_in          => ram_a_not_b_vec(1),
            sel_anb_addr        => sel_anb_addr,
            sel_anb_ram         => sel_anb_ram,
            data_rdy            => data_rdy_vec(4),
            wraddr_i0_sw        => wraddr_i,
            wraddr_i1_sw        => wraddr_i,
            wraddr_i2_sw        => wraddr_i,
            wraddr_i3_sw        => wraddr_i,
            wraddr0_sw          => wraddr_sw(0),
            wraddr1_sw          => wraddr_sw(1),
            wraddr2_sw          => wraddr_sw(2),
            wraddr3_sw          => wraddr_sw(3),
            rdaddr0_sw          => rdaddr_sw(0),
            rdaddr1_sw          => rdaddr_sw(1),
            rdaddr2_sw          => rdaddr_sw(2),
            rdaddr3_sw          => rdaddr_sw(3),
            ram_data_in0_sw_x     => ram_data_in_sw(0),
            ram_data_in1_sw_x     => ram_data_in_sw(1),
            ram_data_in2_sw_x     => ram_data_in_sw(2),
            ram_data_in3_sw_x     => ram_data_in_sw(3),
            ram_data_in0_sw_y     => ram_data_in_sw(4),
            ram_data_in1_sw_y     => ram_data_in_sw(5),
            ram_data_in2_sw_y     => ram_data_in_sw(6),
            ram_data_in3_sw_y     => ram_data_in_sw(7),
            i_ram_data_in0_sw   => i_ram_data_in,
            i_ram_data_in1_sw   => i_ram_data_in,
            i_ram_data_in2_sw   => i_ram_data_in,
            i_ram_data_in3_sw   => i_ram_data_in,
            a_ram_data_out_bus_x => a_ram_data_out_bus_x,
            b_ram_data_out_bus_x  => b_ram_data_out_bus_x,
            a_ram_data_in_bus_x   => a_ram_data_in_bus_x,
            b_ram_data_in_bus_x   => b_ram_data_in_bus_x,
            a_ram_data_out_bus_y => a_ram_data_out_bus_y,
            b_ram_data_out_bus_y  => b_ram_data_out_bus_y,
            a_ram_data_in_bus_y   => a_ram_data_in_bus_y,
            b_ram_data_in_bus_y   => b_ram_data_in_bus_y,
            wraddress_a_bus     => wraddress_a_bus,
            wraddress_b_bus     => wraddress_b_bus,
            rdaddress_a_bus     => rdaddress_a_bus,
            rdaddress_b_bus     => rdaddress_b_bus,
            ram_data_out0_x       => ram_data_out(0),
            ram_data_out1_x       => ram_data_out(1),
            ram_data_out2_x       => ram_data_out(2),
            ram_data_out3_x       => ram_data_out(3),
            ram_data_out0_y       => ram_data_out(4),
            ram_data_out1_y       => ram_data_out(5),
            ram_data_out2_y       => ram_data_out(6),
            ram_data_out3_y       => ram_data_out(7)
      );

  
    
    
    
        
    --------------------------------------------------------------------------------- 
    -- Debug Section
    ---------------------------------------------------------------------------------
    --gen_dbg :for i in 0 to 3 generate
    --  ram_data_in_sw_debug(i,0) <= ram_data_in_sw(i)(2*mpr-1 downto mpr);
    --  ram_data_in_sw_debug(i,1) <= ram_data_in_sw(i)(mpr-1 downto 0);
    --  ram_data_out_debug(i,0) <= ram_data_out(i)(2*mpr-1 downto mpr);
    --  ram_data_out_debug(i,1) <= ram_data_out(i)(mpr-1 downto 0);
    --  ram_data_out_sw_debug(i,0) <= ram_data_out_sw(i)(2*mpr-1 downto mpr);
    --  ram_data_out_sw_debug(i,1) <= ram_data_out_sw(i)(mpr-1 downto 0);
    --  lpp_ram_data_out_sw_debug(i,0) <= lpp_ram_data_out_sw(i)(2*mpr-1 downto mpr);
    --  lpp_ram_data_out_sw_debug(i,1) <= lpp_ram_data_out_sw(i)(mpr-1 downto 0);
    --  lpp_ram_data_out_debug(i,0) <= lpp_ram_data_out(i)(2*mpr-1 downto mpr);
    --  lpp_ram_data_out_debug(i,1) <= lpp_ram_data_out(i)(mpr-1 downto 0);
    --  c_ram_data_in_debug_x(i,0) <= c_ram_data_in_bus_x((8-2*i)*mpr-1 downto (7-2*i)*mpr);
    --  c_ram_data_in_debug_x(i,1) <= c_ram_data_in_bus_x((7-2*i)*mpr-1 downto (6-2*i)*mpr);
    --  c_ram_data_in_debug_y(i,0) <= c_ram_data_in_bus_y((8-2*i)*mpr-1 downto (7-2*i)*mpr);
    --  c_ram_data_in_debug_y(i,1) <= c_ram_data_in_bus_y((7-2*i)*mpr-1 downto (6-2*i)*mpr);
    --  c_ram_data_out_debug_x(i,0) <= c_ram_data_out_bus_x((8-2*i)*mpr-1 downto (7-2*i)*mpr);
    --  c_ram_data_out_debug_x(i,1) <= c_ram_data_out_bus_x((7-2*i)*mpr-1 downto (6-2*i)*mpr);
    --  c_ram_data_out_debug_y(i,0) <= c_ram_data_out_bus_y((8-2*i)*mpr-1 downto (7-2*i)*mpr);
    --  c_ram_data_out_debug_y(i,1) <= c_ram_data_out_bus_y((7-2*i)*mpr-1 downto (6-2*i)*mpr);
    --  
    --end generate gen_dbg;
    
    --gen_dbg2 :for i in 0 to 7 generate
    --  lpp_ram_data_out_debug_r(i) <= lpp_ram_data_out(i)(2*mpr-1 downto mpr);
    --  lpp_ram_data_out_debug_i(i) <= lpp_ram_data_out(i)(mpr-1 downto 0);
    --end generate gen_dbg2;
    
    
    ---------------------------------------------------------------------------------
    
    
    
    rden_a <= (3 downto 0 => '1');
    rden_b <= (3 downto 0 => '1');
    rden_c <= (3 downto 0 => '1');
    rden_d <= (3 downto 0 => '1');
    
    
    
    dat_A_x : asj_fft_4dp_ram
    generic map(
            device_family => device_family,
            apr => apr,
            mpr => mpr,
            abuspr => abuspr,
            cbuspr => cbuspr,
            rfd    => mem_string
          )
    port map(     
global_clock_enable => global_clock_enable,
            clk => clk,
            rdaddress => rdaddress_a_bus,
            wraddress => wraddress_a_bus,
            data_in   => a_ram_data_in_bus_x,
            wren      => wren_a(3 downto 0),
            rden      => rden_a,            
            data_out  => a_ram_data_out_bus_x
      );
    
    dat_A_y : asj_fft_4dp_ram
    generic map(
            device_family => device_family,
            apr => apr,
            mpr => mpr,
            abuspr => abuspr,
            cbuspr => cbuspr,
            rfd    => mem_string
          )
    port map(     
global_clock_enable => global_clock_enable,
            clk => clk,
            rdaddress => rdaddress_a_bus,
            wraddress => wraddress_a_bus,
            data_in   => a_ram_data_in_bus_y,
            wren      => wren_a(7 downto 4),
            rden      => rden_a,            
            data_out  => a_ram_data_out_bus_y
      );
      
      
    
    dat_B_x : asj_fft_4dp_ram
    generic map(
            device_family => device_family,
            apr => apr,
            mpr => mpr,
            abuspr => abuspr,
            cbuspr => cbuspr,
            rfd    => mem_string
          )
    port map(     
global_clock_enable => global_clock_enable,
            clk => clk,
            rdaddress => rdaddress_b_bus,
            wraddress => wraddress_b_bus,
            data_in   => b_ram_data_in_bus_x,
            rden      => rden_b,            
            wren      => wren_b(3 downto 0),
            data_out  => b_ram_data_out_bus_x
      );
      
      
    dat_B_y : asj_fft_4dp_ram
    generic map(
            device_family => device_family,
            apr => apr,
            mpr => mpr,
            abuspr => abuspr,
            cbuspr => cbuspr,
            rfd    => mem_string
          )
    port map(     
global_clock_enable => global_clock_enable,
            clk => clk,
            rdaddress => rdaddress_b_bus,
            wraddress => wraddress_b_bus,
            data_in   => b_ram_data_in_bus_y,
            rden      => rden_b,            
            wren      => wren_b(7 downto 4),
            data_out  => b_ram_data_out_bus_y
      );  
    -----------------------------------------------------------------------------------------------
    -- Output Buffers Implemented in M4K
    ----------------------------------------------------------------------------------------------- 
    gen_M4K_Output : if(mram=0) generate
    
      -- Write Address Generation
      wraddress_c_bus <= wraddr_sw(0) & wraddr_sw(1) & wraddr_sw(2) & wraddr_sw(3);
      c_ram_data_in_bus_x <= ram_data_in_sw(0) & ram_data_in_sw(1) & ram_data_in_sw(2) & ram_data_in_sw(3);
      c_ram_data_in_bus_y <= ram_data_in_sw(4) & ram_data_in_sw(5) & ram_data_in_sw(6) & ram_data_in_sw(7);
      -- Read Address Generation
      

    
    
      dat_C_x : asj_fft_4dp_ram
      generic map(
              device_family => device_family,
              apr => apr,
              mpr => mpr,
              abuspr => abuspr,
              cbuspr => cbuspr,
              rfd    => mem_string
            )
      port map(     
global_clock_enable => global_clock_enable,
              clk => clk,
              rdaddress => rdaddress_c_bus,
              wraddress => wraddress_c_bus,
              data_in   => c_ram_data_in_bus_x,
              wren      => wren_c(3 downto 0),
              rden      => rden_c,            
              data_out  => c_ram_data_out_bus_x
        );
        
      dat_C_y : asj_fft_4dp_ram
      generic map(
              device_family => device_family,
              apr => apr,
              mpr => mpr,
              abuspr => abuspr,
              cbuspr => cbuspr,
              rfd    => mem_string
            )
      port map(     
global_clock_enable => global_clock_enable,
              clk => clk,
              rdaddress => rdaddress_c_bus,
              wraddress => wraddress_c_bus,
              data_in   => c_ram_data_in_bus_y,
              wren      => wren_c(7 downto 4),
              rden      => rden_c,            
              data_out  => c_ram_data_out_bus_y
        );
      
      
      dat_D_x : asj_fft_4dp_ram
        generic map(
                device_family => device_family,
                apr => apr,
                mpr => mpr,
                abuspr => abuspr,
                cbuspr => cbuspr,
                rfd    => mem_string
              )
        port map(     
global_clock_enable => global_clock_enable,
                clk => clk,
                rdaddress => rdaddress_c_bus,
                -- The write address and the data in signals are shared
                -- between C and D. 
                -- Use wren carefully to control filling content
                wraddress => wraddress_c_bus,
                data_in   => c_ram_data_in_bus_x,
                rden      => rden_d,            
                wren      => wren_d(3 downto 0),
                data_out  => d_ram_data_out_bus_x
          );
        
        dat_D_y : asj_fft_4dp_ram
          generic map(
                  device_family => device_family,
                  apr => apr,
                  mpr => mpr,
                  abuspr => abuspr,
                  cbuspr => cbuspr,
                  rfd    => mem_string
                )
          port map(     
global_clock_enable => global_clock_enable,
                  clk => clk,
                  rdaddress => rdaddress_c_bus,
                  -- The write address and the data in signals are shared
                  -- between C and D. 
                  -- Use wren carefully to control filling content
                  wraddress => wraddress_c_bus,
                  data_in   => c_ram_data_in_bus_y,
                  rden      => rden_d,            
                  wren      => wren_d(7 downto 4),
                  data_out  => d_ram_data_out_bus_y
            );
    end generate gen_M4K_Output;
    -----------------------------------------------------------------------------------------------
    -- Output Buffers Implemented in MRAM
    ----------------------------------------------------------------------------------------------- 
    gen_MRAM_Output : if(mram=1) generate
      
      wraddress_c_x_bus <= wd & wraddr_sw(0)(apr-1 downto 0);
      -----------------------------------------------------------------------------------------------
      -- Need different permutation of data on RAM data_in bus for each radix
      -----------------------------------------------------------------------------------------------
      -----------------------------------------------------------------------------------------------
      -- Radix 4 last Pass
      -----------------------------------------------------------------------------------------------
      gen_r4_input_bus : if(last_pass_radix=0) generate
        c_ram_data_in_bus_x <= ram_data_in_sw(0) & ram_data_in_sw(4) & ram_data_in_sw(2) & ram_data_in_sw(6);
        c_ram_data_in_bus_y <= ram_data_in_sw(1) & ram_data_in_sw(5) & ram_data_in_sw(3) & ram_data_in_sw(7);
      end generate gen_r4_input_bus;
      -----------------------------------------------------------------------------------------------
      -- Radix 2 Last Pass
      -----------------------------------------------------------------------------------------------
      gen_r2_input_bus : if(last_pass_radix=1) generate
        c_ram_data_in_bus_x <= ram_data_in_sw(0) & ram_data_in_sw(1) & ram_data_in_sw(2) & ram_data_in_sw(3);
        c_ram_data_in_bus_y <= ram_data_in_sw(4) & ram_data_in_sw(5) & ram_data_in_sw(6) & ram_data_in_sw(7);
      end generate gen_r2_input_bus;
      -----------------------------------------------------------------------------------------------
      wren_mram <= wc or wd;
      -----------------------------------------------------------------------------------------------
gen_lpp_mram_sel:process(clk,global_clock_enable)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
              lpp_mram_wr_sel <= '0';
            elsif(lpp_start_mram='1') then
              lpp_mram_wr_sel <= not(lpp_mram_wr_sel);
            end if;
          end if;
      end process gen_lpp_mram_sel;

del_lpp_start:process(clk,global_clock_enable)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
              lpp_start_mram <= '0';
              lpp_start_d<='0';
              lpp_start_d2<='0';
            else
              lpp_start_d<=lpp_start;
              lpp_start_d2<=lpp_start_d;
              lpp_start_mram <= lpp_start_d2;
            end if;
          end if;
      end process del_lpp_start;
  
      
      dat_C_x : asj_fft_dp_mram
        generic map(
                device_family => device_family,
                apr => apr_mram,
                dpr => cbuspr
              )
        port map(     
global_clock_enable => global_clock_enable,
                clock => clk,
                rdaddress => rdaddress_c_x_bus,
                wraddress => wraddress_c_x_bus,
                data    => c_ram_data_in_bus_x,
                wren      => wren_mram,
                q => c_ram_data_out_bus_x
          );
        
      dat_C_y : asj_fft_dp_mram
        generic map(
                device_family => device_family,
                apr => apr_mram,
                dpr => cbuspr
              )
        port map(     
global_clock_enable => global_clock_enable,
                clock => clk,
                rdaddress => rdaddress_c_y_bus,
                wraddress => wraddress_c_x_bus,
                data    => c_ram_data_in_bus_y,
                wren      => wren_mram,
                q => c_ram_data_out_bus_y
          );
    end generate gen_MRAM_Output;
    -----------------------------------------------------------------------------------------------
  
    
    
    
    -- Input Buffer Read Side Logic
    -- sw_r is applied to data output from RAM and is a cxb_data_r switch input
    -- if p_count==1 the generated addresses are applied to the input buffer with no switching
    -- otherwise, they are switched by sw_r to a cxb_addr and applied 
    -- to the "working" RAM blocks 
    
    rd_adgen : asj_fft_dataadgen
    generic map(
                nps           => nps,
                nume          => nume,
                arch          => 0,
                n_passes      => n_passes_m1,
                log2_n_passes => log2_n_passes,
                apr           => apr
          )
    port map(     
global_clock_enable => global_clock_enable,
                clk           => clk,
                k_count       => k_count,
                p_count       => p_count,
                rd_addr_a     => rdaddr(0),
                rd_addr_b     => rdaddr(1),
                rd_addr_c     => rdaddr(2),
                rd_addr_d     => rdaddr(3),
                sw_data_read  => sw_r(1 downto 0)
      );
    
      
    
    ram_cxb_rd : asj_fft_cxb_addr 
    
      generic map(  mpr   =>  apr,
                    xbw   =>  4,
                    pipe   => 1,
                    del   => 0
            )
      port map(   clk       => clk,
global_clock_enable => global_clock_enable,
              sw_0_in   => rdaddr(0),
              sw_1_in   => rdaddr(1),
              sw_2_in   => rdaddr(2),
              sw_3_in   => rdaddr(3),
              ram_sel   => sw_r(1 downto 0),
              sw_0_out  => rdaddr_sw(0),
              sw_1_out  => rdaddr_sw(1),
              sw_2_out  => rdaddr_sw(2),
              sw_3_out  => rdaddr_sw(3)
      );
      
    k_delay : asj_fft_tdl
    generic map( 
                  mpr => apr,
                  del => 16,
                  srr => srr                
              )
      port map(   
global_clock_enable => global_clock_enable,
                  clk   => clk,
                  data_in   => k_count,
                  data_out  => k_count_d
          );
    p_delay : asj_fft_tdl
    generic map( 
                  mpr => log2_n_passes,
                  del   => 2
              )
      port map(   
global_clock_enable => global_clock_enable,
                  clk   => clk,
                  data_in   => p_tdl(13),
                  data_out  => p_count_d
          );
    
    get_wr_swtiches : asj_fft_wrswgen 
    generic map(
                nps => nps,
                cont => 0,
                arch => 0,
                n_passes => n_passes,
                log2_n_passes => log2_n_passes,
                del => 1,
                apr => apr
          )
    port map  ( 
global_clock_enable => global_clock_enable,
                clk           => clk,
                k_count       => k_count_d,
                p_count       => p_count_d,
                sw_data_write => swd_w,
                sw_addr_write => swa_w
      );
    -----------------------------------------------------------------------------------------------
    -- Write Address Generation
    -----------------------------------------------------------------------------------------------
    wr_adgen : asj_fft_dataadgen 
    generic map(
                nps           => nps,
                nume          => nume,
                arch          => 0,
                n_passes      => n_passes_m1,
                log2_n_passes => log2_n_passes,
                apr           => apr
          )
    port map(     
global_clock_enable => global_clock_enable,
                clk           => clk,
                k_count       => k_count_d,
                p_count       => p_count_d,
                rd_addr_a     => wraddr(0),
                rd_addr_b     => wraddr(1),
                rd_addr_c     => wraddr(2),
                rd_addr_d     => wraddr(3),
                sw_data_read  => open
            
      );
    -----------------------------------------------------------------------------------------------
    -- Write Address TDL and Switch
    -----------------------------------------------------------------------------------------------     
      
    ram_cxb_wr : asj_fft_cxb_addr 
    generic map(  mpr   =>  apr,
                  xbw   =>  4,
                  pipe   => 1,
                  del   => 1
          )
    port map(   clk       => clk,
global_clock_enable => global_clock_enable,
            sw_0_in   => wraddr(0),
            sw_1_in   => wraddr(1),
            sw_2_in   => wraddr(2),
            sw_3_in   => wraddr(3),
            ram_sel   => swa_w,
            sw_0_out  => wraddr_sw(0),
            sw_1_out  => wraddr_sw(1),
            sw_2_out  => wraddr_sw(2),
            sw_3_out  => wraddr_sw(3)
    );
      
    delay_blk_done2 : asj_fft_tdl_bit_rst 
      generic map( 
                  --del   => 35
                  del   => 20
              )
      port map(   
global_clock_enable => global_clock_enable,
                  clk   => clk,
                  reset => reset,
                  data_in   => block_done_d,
                  data_out  => lpp_start
          );  
  ----------------------------------------------------------------------------------------------- 
  -- data to be written to RAM block is also switched
  gen_se_ram_data_in : if(nume=1) generate
    gse : for i in 0 to 3 generate
      ram_data_in(i) <= (dft_r_o(i) & dft_i_o(i));
    end generate gse;
  end generate gen_se_ram_data_in;
  
  gen_de_ram_data_in : if(nume=2) generate
    gse : for i in 0 to 7 generate
      ram_data_in(i) <= (dft_r_o(i) & dft_i_o(i));
    end generate gse;
  end generate gen_de_ram_data_in;  
    
    gen_write_sw : for i in 0 to nume-1 generate
    
    ram_cxb_wr_data : asj_fft_cxb_data
    generic map(  mpr   =>  mpr,
                  xbw   =>  4,
                  pipe   => 1
          )
    port map(   clk       => clk,
global_clock_enable => global_clock_enable,
            sw_0_in   => ram_data_in(0+4*i),
            sw_1_in   => ram_data_in(1+4*i),
            sw_2_in   => ram_data_in(2+4*i),
            sw_3_in   => ram_data_in(3+4*i),
            ram_sel   => swd_w(1 downto 0),
            sw_0_out  => ram_data_in_sw(0+4*i),
            sw_1_out  => ram_data_in_sw(1+4*i),
            sw_2_out  => ram_data_in_sw(2+4*i),
            sw_3_out  => ram_data_in_sw(3+4*i)
    );
    
    end generate gen_write_sw;
 
    --switch data prior to BFP
    -- use delayed version of rd_addr switch to account for latency
    sw_r_d_delay : asj_fft_tdl
    generic map( 
                  mpr => 2,
                  del   => 4+nume-1,
                  srr => srr                
                  
              )
      port map(   
global_clock_enable => global_clock_enable,
                  clk   => clk,
                  data_in   => sw_r,
                  data_out  => sw_r_d
          );
  
      
    gen_bfly_input_sw : for i in 0 to nume-1 generate
    
    ram_cxb_bfp_data : asj_fft_cxb_data_r
    generic map(  mpr   =>  mpr,
                  xbw   =>  4,
                  pipe   => 1
          )
    port map(   clk       => clk,
global_clock_enable => global_clock_enable,
            sw_0_in   => ram_data_out(0+4*i),
            sw_1_in   => ram_data_out(1+4*i),
            sw_2_in   => ram_data_out(2+4*i),
            sw_3_in   => ram_data_out(3+4*i),
            ram_sel   => sw_r_d(1 downto 0),
            sw_0_out  => ram_data_out_sw(0+4*i),
            sw_1_out  => ram_data_out_sw(1+4*i),
            sw_2_out  => ram_data_out_sw(2+4*i),
            sw_3_out  => ram_data_out_sw(3+4*i)
    );
    
  end generate gen_bfly_input_sw;
  
    gen_bfly_inputs : for i in 0 to 3 generate
      data_in_bfp_x(i,0) <= ram_data_out_sw(i)(2*mpr-1 downto mpr);
      data_in_bfp_x(i,1) <= ram_data_out_sw(i)(mpr-1 downto 0);
      data_in_bfp_y(i,0) <= ram_data_out_sw(i+4)(2*mpr-1 downto mpr);
      data_in_bfp_y(i,1) <= ram_data_out_sw(i+4)(mpr-1 downto 0);
    end generate gen_bfly_inputs; 
   
   
butterfly_twiddle_x:process(clk,global_clock_enable,reset,t1re,t2re,t3re,t1ie,t2ie,t3ie)is
    begin
if((rising_edge(clk) and global_clock_enable='1'))then
        if(reset='1') then
          for i in 0 to 2 loop
            twiddle_data_x(i,0) <= '0' & (twr-2 downto 0=>'1');
            twiddle_data_x(i,1) <= (others=>'0');
          end loop;
        else
          twiddle_data_x(0,0) <= t1re;
          twiddle_data_x(0,1) <= t1ie;
          twiddle_data_x(1,0) <= t2re;
          twiddle_data_x(1,1) <= t2ie;
          twiddle_data_x(2,0) <= t3re;
          twiddle_data_x(2,1) <= t3ie;
        end if;
      end if;
   end process butterfly_twiddle_x;
   
butterfly_twiddle_y:process(clk,global_clock_enable,reset,t1ro,t2ro,t3ro,t1io,t2io,t3io)is
    begin
if((rising_edge(clk) and global_clock_enable='1'))then
        if(reset='1') then
          for i in 0 to 2 loop
            twiddle_data_y(i,0) <= '0' & (twr-2 downto 0=>'1');
            twiddle_data_y(i,1) <= (others=>'0');
          end loop;
        else
            twiddle_data_y(0,0) <= t1ro;
            twiddle_data_y(0,1) <= t1io;
            twiddle_data_y(1,0) <= t2ro;
            twiddle_data_y(1,1) <= t2io;
            twiddle_data_y(2,0) <= t3ro;
            twiddle_data_y(2,1) <= t3io;
        end if;
      end if;
   end process butterfly_twiddle_y;
   
  
   bfpdft_x : asj_fft_dft_bfp
   generic map (  
                device_family => device_family,
                nps => nps,
                bfp => bfp,
                nume => nume,
                mpr=> mpr,
                arch => 0,
                rbuspr => rbuspr,
                twr=> twr,
                fpr => fpr,
                mult_type => mult_type,
                mult_imp => mult_imp,
                dsp_arch => dsp_arch,
                nstages=> 7,
                pipe => 1,
                cont => 0
   )
   port map(
global_clock_enable => global_clock_enable,
                clk       => clk,
                reset     => reset,
                clken     => en_np,
                next_pass => next_pass_d,
                next_blk  => next_blk,
                blk_done  => '0',
                alt_slb_i   => slb_last_i,
                alt_slb_o   => slb_x_o,
                data_1_real_i => data_in_bfp_x(0,0),
                data_2_real_i => data_in_bfp_x(1,0),
                data_3_real_i => data_in_bfp_x(2,0),
                data_4_real_i => data_in_bfp_x(3,0),
                data_1_imag_i => data_in_bfp_x(0,1),
                data_2_imag_i => data_in_bfp_x(1,1),
                data_3_imag_i => data_in_bfp_x(2,1),
                data_4_imag_i => data_in_bfp_x(3,1),
                twid_1_real  => twiddle_data_x(0,0),
                twid_2_real  => twiddle_data_x(1,0),
                twid_3_real  => twiddle_data_x(2,0),
                twid_1_imag  => twiddle_data_x(0,1),
                twid_2_imag  => twiddle_data_x(1,1),
                twid_3_imag  => twiddle_data_x(2,1),
                data_1_real_o => dft_r_o(0),
                data_2_real_o => dft_r_o(1),
                data_3_real_o => dft_r_o(2),
                data_4_real_o => dft_r_o(3),
                data_1_imag_o => dft_i_o(0),
                data_2_imag_o => dft_i_o(1),
                data_3_imag_o => dft_i_o(2),
                data_4_imag_o => dft_i_o(3)
    );
  
   bfpdft_y : asj_fft_dft_bfp
   generic map (             
                device_family => device_family,
                nps => nps,
                bfp => bfp,
                nume => nume,
                mpr=> mpr,
                arch => 0,
                rbuspr => rbuspr,
                twr=> twr,
                mult_type => mult_type,
                mult_imp => mult_imp,
                dsp_arch => dsp_arch,
                fpr => fpr,
                nstages=> 7,
                pipe => 1,
                cont => 0
   )
   port map(
global_clock_enable => global_clock_enable,
                clk       => clk,
                reset     => reset,
                clken     => en_np,
                next_pass => next_pass_d,
                next_blk  => next_blk,
                blk_done  => '0',
                alt_slb_i   => slb_last_i,
                alt_slb_o   => slb_y_o,
                data_1_real_i => data_in_bfp_y(0,0),
                data_2_real_i => data_in_bfp_y(1,0),
                data_3_real_i => data_in_bfp_y(2,0),
                data_4_real_i => data_in_bfp_y(3,0),
                data_1_imag_i => data_in_bfp_y(0,1),
                data_2_imag_i => data_in_bfp_y(1,1),
                data_3_imag_i => data_in_bfp_y(2,1),
                data_4_imag_i => data_in_bfp_y(3,1),
                twid_1_real  => twiddle_data_y(0,0),
                twid_2_real  => twiddle_data_y(1,0),
                twid_3_real  => twiddle_data_y(2,0),
                twid_1_imag  => twiddle_data_y(0,1),
                twid_2_imag  => twiddle_data_y(1,1),
                twid_3_imag  => twiddle_data_y(2,1),
                data_1_real_o => dft_r_o(4),
                data_2_real_o => dft_r_o(5),
                data_3_real_o => dft_r_o(6),
                data_4_real_o => dft_r_o(7),
                data_1_imag_o => dft_i_o(4),
                data_2_imag_o => dft_i_o(5),
                data_3_imag_o => dft_i_o(6),
                data_4_imag_o => dft_i_o(7)
    );
  
  gen_blk_float : if(bfp=1) generate  
    dual_eng_slb <= slb_y_o & slb_x_o;  
  end generate gen_blk_float;
  
  gen_fixed : if(bfp=0) generate  
    dual_eng_slb <= (others=>'0');  
  end generate gen_fixed;
  
  
  delay_blk_done : asj_fft_tdl_bit_rst 
      generic map( 
                  del   => 24
              )
      port map(   
global_clock_enable => global_clock_enable,
                  clk   => clk,
                  reset   => reset,
                  data_in   => block_done,
                  data_out  => block_done_d
          );  
          
--register_en_slb:process(clk,global_clock_enable)is
  --  begin
--if((rising_edge(clk) and global_clock_enable='1'))then
  --      if(p_count="001") then
  --        en_slb <= '0';
  --      else
  --        en_slb <= next_pass_ctrl; 
  --      end if;
  --    end if;
  --  end process register_en_slb;          
    
  bfpc : asj_fft_bfp_ctrl 
  
  generic map( 
               nps => nps,
               nume => nume,
               fpr  => fpr,
               cont => 0,
               arch => 0
            )
  port map(
global_clock_enable => global_clock_enable,
               clk  => clk,
               clken  => en_np,
               reset  => reset,
               next_pass => next_pass_d,
               next_blk  => block_done_d,
               exp_en    => lpp_en,
               alt_slb_i => dual_eng_slb,
               alt_slb_o => slb_last_i,
               blk_exp_o => blk_exp
  );
    
  
  gen_de_twad : if(nume=2) generate
    twid_factors : asj_fft_twadgen_dual
      generic map(
                  nps       => nps,
                  nume      => nume,
                  n_passes  => n_passes_m1,
                  apr       => apr+1,
                  log2_n_passes => log2_n_passes,
                  tw_delay  => twid_delay
              )
      port map (
global_clock_enable => global_clock_enable,
                  clk       => clk,
                  k_count   => k_count,
                  p_count   => p_count,
                  tw_addre    => twade,
                  tw_addro    => twado
          );
  end generate gen_de_twad;   
  
  gen_3tdp_rom : if (nume=2) generate 
    twrom :  asj_fft_3tdp_rom 
      generic map(
                device_family => device_family,
                twr => twr,
                twa => twa,
                m512 => m512,
                rfc1 => rfc1,
                rfc2 => rfc2,
                rfc3 => rfc3,
                rfs1 => rfs1,
                rfs2 => rfs2,
                rfs3 => rfs3
              )
      port map(     clk       => clk,
global_clock_enable => global_clock_enable,
                twade       => twade,
                twado       => twado,
                t1re      => t1re,
                t2re      => t2re,
                t3re      => t3re,
                t1ie      => t1ie,
                t2ie      => t2ie,
                t3ie      => t3ie,
                t1ro      => t1ro,
                t2ro      => t2ro,
                t3ro      => t3ro,
                t1io      => t1io,
                t2io      => t2io,
                t3io      => t3io
          );
    end generate gen_3tdp_rom;
   
   ---------------------------------------------------------------------------------------------------
   
   
   
    ---------------------------------------------------------------------------------------------------
    -- Last Pass Processor Read Address Generation
    ---------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------
    -- Dual Engine Radix 4 Serial LPP 
    -----------------------------------------------------------------------------------------------
    gen_radix_4_last_pass : if(last_pass_radix=0) generate
    
        gen_lpp_addr : asj_fft_lpprdadgen 
        generic map(
                  nps           => nps,
                  mram          => mram,
                  arch          => 0,
                  nume          => nume,
                  n_passes      => n_passes_m1,
                  log2_n_passes => log2_n_passes,
                  apr           => apr
                )
        port map(
global_clock_enable => global_clock_enable,
                  clk           => clk,
                  reset         => reset,
                  lpp_en        => lpp_start,
                  data_rdy      => data_rdy,
                  rd_addr_a     => rdaddr_lpp(0),
                  rd_addr_b     => rdaddr_lpp(1),
                  rd_addr_c     => rdaddr_lpp(2),
                  rd_addr_d     => rdaddr_lpp(3),
                  sw_data_read  => sw_rd_lpp,
                  sw_addr_read  => sw_ra_lpp,
                  en            => lpp_en
            ); 
   
    
switch_c_d:process(clk,global_clock_enable)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
              lpp_count_offset <= (others=>'0');
            elsif(fft_s2_cur/=WAIT_FOR_LPP_INPUT) then
              lpp_count_offset <= lpp_count+int2ustd(7,log2_nps+1);
            end if;
          end if;
      end process switch_c_d;
          
gen_lpp_sel:process(clk,global_clock_enable)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
              lpp_sel <= '0';
            elsif(lpp_en='1') then
              lpp_sel <= not(lpp_sel);
            end if;
          end if;
      end process gen_lpp_sel;

    -----------------------------------------------------------------------------------------------
    --
    -----------------------------------------------------------------------------------------------     
    gen_m4k_output_sel : if(mram=0) generate
    
      ram_cxb_rd_lpp : asj_fft_cxb_addr 
        generic map(  mpr   =>  apr,
                      xbw   =>  4,
                      pipe   => 1,
                      del   => 0
              )
        port map(   clk       => clk,
global_clock_enable => global_clock_enable,
                sw_0_in   => rdaddr_lpp(0),
                sw_1_in   => rdaddr_lpp(2),
                sw_2_in   => rdaddr_lpp(0),
                sw_3_in   => rdaddr_lpp(2),
                ram_sel   => sw_ra_lpp,
                sw_0_out  => rdaddr_lpp_sw(0),
                sw_1_out  => rdaddr_lpp_sw(1),
                sw_2_out  => rdaddr_lpp_sw(2),
                sw_3_out  => rdaddr_lpp_sw(3)
        );   
    
       
sel_lpp_addr:process(clk,global_clock_enable)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
                rdaddress_c_bus <= (others=>'0');
            else
                rdaddress_c_bus <= rdaddr_lpp_sw(0) & rdaddr_lpp_sw(1) & rdaddr_lpp_sw(2) & rdaddr_lpp_sw(3);
            end if;
          end if;
        end process sel_lpp_addr;
        
sel_lpp_data:process(clk,global_clock_enable,lpp_c_en_vec,c_ram_data_out_bus_x,c_ram_data_out_bus_y,d_ram_data_out_bus_x,d_ram_data_out_bus_y)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
              for i in 0 to 7 loop
                lpp_ram_data_out(i) <= (others=>'0');
              end loop;
            else
              if(lpp_sel = '1' ) then
                lpp_ram_data_out(0) <= c_ram_data_out_bus_x(8*mpr-1 downto 6*mpr);
                lpp_ram_data_out(1) <= c_ram_data_out_bus_x(6*mpr-1 downto 4*mpr);
                lpp_ram_data_out(2) <= c_ram_data_out_bus_x(4*mpr-1 downto 2*mpr);
                lpp_ram_data_out(3) <= c_ram_data_out_bus_x(2*mpr-1 downto 0);
                lpp_ram_data_out(4) <= c_ram_data_out_bus_y(8*mpr-1 downto 6*mpr);
                lpp_ram_data_out(5) <= c_ram_data_out_bus_y(6*mpr-1 downto 4*mpr);
                lpp_ram_data_out(6) <= c_ram_data_out_bus_y(4*mpr-1 downto 2*mpr);
                lpp_ram_data_out(7) <= c_ram_data_out_bus_y(2*mpr-1 downto 0);
              else
                lpp_ram_data_out(0) <= d_ram_data_out_bus_x(8*mpr-1 downto 6*mpr);
                lpp_ram_data_out(1) <= d_ram_data_out_bus_x(6*mpr-1 downto 4*mpr);
                lpp_ram_data_out(2) <= d_ram_data_out_bus_x(4*mpr-1 downto 2*mpr);
                lpp_ram_data_out(3) <= d_ram_data_out_bus_x(2*mpr-1 downto 0);
                lpp_ram_data_out(4) <= d_ram_data_out_bus_y(8*mpr-1 downto 6*mpr);
                lpp_ram_data_out(5) <= d_ram_data_out_bus_y(6*mpr-1 downto 4*mpr);
                lpp_ram_data_out(6) <= d_ram_data_out_bus_y(4*mpr-1 downto 2*mpr);
                lpp_ram_data_out(7) <= d_ram_data_out_bus_y(2*mpr-1 downto 0);
              end if;
            end if;
          end if;
        end process sel_lpp_data;
        
sel_lpp_ram:process(clk,global_clock_enable,sw_rd_lpp,lpp_ram_data_out)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            -- switch between RAM Sub-block outputs
            case sw_rd_lpp(1 downto 0) is
              when "00" =>
                lpp_ram_data_out_sw(0) <= lpp_ram_data_out(0);
                lpp_ram_data_out_sw(1) <= lpp_ram_data_out(4);
                lpp_ram_data_out_sw(2) <= lpp_ram_data_out(1);
                lpp_ram_data_out_sw(3) <= lpp_ram_data_out(5);                
              when "01" =>
                lpp_ram_data_out_sw(0) <= lpp_ram_data_out(1);
                lpp_ram_data_out_sw(1) <= lpp_ram_data_out(5);
                lpp_ram_data_out_sw(2) <= lpp_ram_data_out(2);
                lpp_ram_data_out_sw(3) <= lpp_ram_data_out(6);                
              when "10" =>
                lpp_ram_data_out_sw(0) <= lpp_ram_data_out(2);
                lpp_ram_data_out_sw(1) <= lpp_ram_data_out(6);
                lpp_ram_data_out_sw(2) <= lpp_ram_data_out(3);
                lpp_ram_data_out_sw(3) <= lpp_ram_data_out(7);                
              when "11" =>
                lpp_ram_data_out_sw(0) <= lpp_ram_data_out(3);
                lpp_ram_data_out_sw(1) <= lpp_ram_data_out(7);
                lpp_ram_data_out_sw(2) <= lpp_ram_data_out(0);
                lpp_ram_data_out_sw(3) <= lpp_ram_data_out(4);                
              when others =>
                lpp_ram_data_out_sw(0) <= (others=>'0');
                lpp_ram_data_out_sw(1) <= (others=>'0');
                lpp_ram_data_out_sw(2) <= (others=>'0');
                lpp_ram_data_out_sw(3) <= (others=>'0');
            end case;
          end if;
        end process sel_lpp_ram;

    end generate gen_m4k_output_sel;
    -----------------------------------------------------------------------------------------------
    --
    -----------------------------------------------------------------------------------------------
    gen_mram_output_sel : if(mram=1) generate
      
sel_lpp_addr:process(clk,global_clock_enable,reset)is
        variable a : std_logic_vector(apr-1 downto 0);
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
              rdaddress_c_x_bus <= (others=>'0');
              rdaddress_c_y_bus <= (others=>'0');
              rdaddr_lpp_sw(0)  <= (others=>'0');
              rdaddr_lpp_sw(1)  <= (others=>'0');
            else
              rdaddr_lpp_sw(0)  <= rdaddr_lpp(0);
              rdaddr_lpp_sw(1)  <= rdaddr_lpp(1);
              rdaddress_c_x_bus <= not(lpp_mram_wr_sel) & rdaddr_lpp_sw(0);
              rdaddress_c_y_bus <= not(lpp_mram_wr_sel) & rdaddr_lpp_sw(1);
            end if;
          end if;
        end process sel_lpp_addr;

    
sel_lpp_data:process(clk,global_clock_enable,lpp_c_en_vec,c_ram_data_out_bus_x,c_ram_data_out_bus_y,d_ram_data_out_bus_x,d_ram_data_out_bus_y)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
              for i in 0 to 7 loop
                lpp_ram_data_out(i) <= (others=>'0');
              end loop;
            else
              lpp_ram_data_out(0) <= c_ram_data_out_bus_x(8*mpr-1 downto 6*mpr);
              lpp_ram_data_out(1) <= c_ram_data_out_bus_x(6*mpr-1 downto 4*mpr);
              lpp_ram_data_out(2) <= c_ram_data_out_bus_x(4*mpr-1 downto 2*mpr);
              lpp_ram_data_out(3) <= c_ram_data_out_bus_x(2*mpr-1 downto 0);
              lpp_ram_data_out(4) <= c_ram_data_out_bus_y(8*mpr-1 downto 6*mpr);
              lpp_ram_data_out(5) <= c_ram_data_out_bus_y(6*mpr-1 downto 4*mpr);
              lpp_ram_data_out(6) <= c_ram_data_out_bus_y(4*mpr-1 downto 2*mpr);
              lpp_ram_data_out(7) <= c_ram_data_out_bus_y(2*mpr-1 downto 0);
            end if;
          end if;
        end process sel_lpp_data;
        
sel_lpp_ram:process(clk,global_clock_enable,sw_rd_lpp,lpp_ram_data_out)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            -- switch between RAM Sub-block outputs
            case sw_rd_lpp(1 downto 0) is
              when "00" =>
                lpp_ram_data_out_sw(0) <= lpp_ram_data_out(0);
                lpp_ram_data_out_sw(1) <= lpp_ram_data_out(1);
                lpp_ram_data_out_sw(2) <= lpp_ram_data_out(4);
                lpp_ram_data_out_sw(3) <= lpp_ram_data_out(5);                
              when "01" =>
                lpp_ram_data_out_sw(0) <= lpp_ram_data_out(4);
                lpp_ram_data_out_sw(1) <= lpp_ram_data_out(5);
                lpp_ram_data_out_sw(2) <= lpp_ram_data_out(2);
                lpp_ram_data_out_sw(3) <= lpp_ram_data_out(3);                
              when "10" =>
                lpp_ram_data_out_sw(0) <= lpp_ram_data_out(2);
                lpp_ram_data_out_sw(1) <= lpp_ram_data_out(3);
                lpp_ram_data_out_sw(2) <= lpp_ram_data_out(6);
                lpp_ram_data_out_sw(3) <= lpp_ram_data_out(7);                
              when "11" =>
                lpp_ram_data_out_sw(0) <= lpp_ram_data_out(6);
                lpp_ram_data_out_sw(1) <= lpp_ram_data_out(7);
                lpp_ram_data_out_sw(2) <= lpp_ram_data_out(0);
                lpp_ram_data_out_sw(3) <= lpp_ram_data_out(1);                
              when others =>
                lpp_ram_data_out_sw(0) <= (others=>'0');
                lpp_ram_data_out_sw(1) <= (others=>'0');
                lpp_ram_data_out_sw(2) <= (others=>'0');
                lpp_ram_data_out_sw(3) <= (others=>'0');
            end case;
          end if;
        end process sel_lpp_ram;

    end generate gen_mram_output_sel;
    ---------------------------------------------------------------------------------------------------
    -- Last Pass Processor 
    ---------------------------------------------------------------------------------------------------
      lpp :  asj_fft_lpp_serial 
        generic map(
                mpr         => mpr,
                arch        => 0,
                apr         => apr,
                nume        => nume,
                del         => 6
        )
        port map (
global_clock_enable => global_clock_enable,
                clk       => clk,
                reset    => reset,
                lpp_en   => lpp_en,
                data_1_real_i => lpp_ram_data_out_sw(0)(2*mpr-1 downto mpr),
                data_2_real_i => lpp_ram_data_out_sw(1)(2*mpr-1 downto mpr),
                data_3_real_i => lpp_ram_data_out_sw(2)(2*mpr-1 downto mpr),
                data_4_real_i => lpp_ram_data_out_sw(3)(2*mpr-1 downto mpr),
                data_1_imag_i => lpp_ram_data_out_sw(0)(mpr-1 downto 0),
                data_2_imag_i => lpp_ram_data_out_sw(1)(mpr-1 downto 0),
                data_3_imag_i => lpp_ram_data_out_sw(2)(mpr-1 downto 0),
                data_4_imag_i => lpp_ram_data_out_sw(3)(mpr-1 downto 0),
                data_real_o   => data_real_out,
                data_imag_o   => data_imag_out,
                data_val      => lpp_data_val
        );
    
  end generate gen_radix_4_last_pass;   
  
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------     
  
  gen_radix_2_last_pass : if(last_pass_radix=1) generate
  
      gen_lpp_addr : asj_fft_lpprdadr2gen 
        generic map(
                  nps => nps,
                  nume=> nume,
                  arch => 0,
                  mram => mram,
                  n_passes => n_passes,
                  log2_n_passes =>log2_n_passes,
                  apr => apr
              )
        port map(     
global_clock_enable => global_clock_enable,
                  clk => clk,
                  reset => reset,
                  lpp_en => lpp_start,
                  data_rdy => data_rdy,
                  rd_addr_a => rdaddr_lpp(0),
                  rd_addr_b => open,
                  sw_data_read => sw_rd_lpp,
                  sw_addr_read => sw_ra_lpp,
                  qe_select    => open,
                  en           => lpp_en
          );
      
           
switch_c_d:process(clk,global_clock_enable)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
              --lpp_sel <= '0';
              lpp_count_offset <= (others=>'0');
            elsif(fft_s2_cur/=WAIT_FOR_LPP_INPUT) then
              --lpp_count_offset <= lpp_count+int2ustd(5,log2_nps+1);
              lpp_count_offset <= lpp_count+int2ustd(5,log2_nps+1);
              --if(lpp_count_offset(log2_nps-1 downto 0) = (log2_nps-1 downto 0 =>'0')) then
              --  lpp_sel <= not(lpp_sel);
              --end if;
            end if;
          end if;
      end process switch_c_d;
          
gen_lpp_sel:process(clk,global_clock_enable)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
              lpp_sel <= '0';
            elsif(lpp_en='1') then
              lpp_sel <= not(lpp_sel);
            end if;
          end if;
      end process gen_lpp_sel;
    
    gen_m4k_output_sel : if(mram=0) generate
      
sel_lpp_addr:process(clk,global_clock_enable,reset)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
              rdaddress_c_bus <= (others=>'0');
              rdaddr_lpp_sw(0) <= rdaddr_lpp(0);
            else
              --balance pipeline with r4
              rdaddr_lpp_sw(0) <= rdaddr_lpp(0);
              rdaddress_c_bus <= rdaddr_lpp_sw(0) & rdaddr_lpp_sw(0) & rdaddr_lpp_sw(0) & rdaddr_lpp_sw(0);
            end if;
          end if;
        end process sel_lpp_addr;
    
    
sel_lpp_data:process(clk,global_clock_enable,lpp_c_en_vec,c_ram_data_out_bus_x,c_ram_data_out_bus_y,d_ram_data_out_bus_x,d_ram_data_out_bus_y)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
              for i in 0 to 7 loop
                lpp_ram_data_out(i) <= (others=>'0');
              end loop;
            else
              if(lpp_sel = '1' ) then
                lpp_ram_data_out(0) <= c_ram_data_out_bus_x(8*mpr-1 downto 6*mpr);
                lpp_ram_data_out(1) <= c_ram_data_out_bus_x(6*mpr-1 downto 4*mpr);
                lpp_ram_data_out(2) <= c_ram_data_out_bus_x(4*mpr-1 downto 2*mpr);
                lpp_ram_data_out(3) <= c_ram_data_out_bus_x(2*mpr-1 downto 0);
                lpp_ram_data_out(4) <= c_ram_data_out_bus_y(8*mpr-1 downto 6*mpr);
                lpp_ram_data_out(5) <= c_ram_data_out_bus_y(6*mpr-1 downto 4*mpr);
                lpp_ram_data_out(6) <= c_ram_data_out_bus_y(4*mpr-1 downto 2*mpr);
                lpp_ram_data_out(7) <= c_ram_data_out_bus_y(2*mpr-1 downto 0);
              else
                lpp_ram_data_out(0) <= d_ram_data_out_bus_x(8*mpr-1 downto 6*mpr);
                lpp_ram_data_out(1) <= d_ram_data_out_bus_x(6*mpr-1 downto 4*mpr);
                lpp_ram_data_out(2) <= d_ram_data_out_bus_x(4*mpr-1 downto 2*mpr);
                lpp_ram_data_out(3) <= d_ram_data_out_bus_x(2*mpr-1 downto 0);
                lpp_ram_data_out(4) <= d_ram_data_out_bus_y(8*mpr-1 downto 6*mpr);
                lpp_ram_data_out(5) <= d_ram_data_out_bus_y(6*mpr-1 downto 4*mpr);
                lpp_ram_data_out(6) <= d_ram_data_out_bus_y(4*mpr-1 downto 2*mpr);
                lpp_ram_data_out(7) <= d_ram_data_out_bus_y(2*mpr-1 downto 0);
              end if;
            end if;
          end if;
        end process sel_lpp_data;

    end generate gen_m4k_output_sel;
    
    gen_mram_output_sel : if(mram=1) generate
      
sel_lpp_addr:process(clk,global_clock_enable,reset)is
        variable a : std_logic_vector(apr-1 downto 0);
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
              rdaddr_lpp_sw(0)<=(others=>'0');
              rdaddress_c_x_bus <= (others=>'0');
              rdaddress_c_y_bus <= (others=>'0');
            else
              rdaddr_lpp_sw(0) <= rdaddr_lpp(0);
              rdaddress_c_x_bus <= not(lpp_mram_wr_sel) & rdaddr_lpp_sw(0);
              rdaddress_c_y_bus <= not(lpp_mram_wr_sel) & rdaddr_lpp_sw(0);
            end if;
          end if;
        end process sel_lpp_addr;

    
sel_lpp_data:process(clk,global_clock_enable,lpp_c_en_vec,c_ram_data_out_bus_x,c_ram_data_out_bus_y,d_ram_data_out_bus_x,d_ram_data_out_bus_y)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
              for i in 0 to 7 loop
                lpp_ram_data_out(i) <= (others=>'0');
              end loop;
            else
              lpp_ram_data_out(0) <= c_ram_data_out_bus_x(8*mpr-1 downto 6*mpr);
              lpp_ram_data_out(1) <= c_ram_data_out_bus_x(6*mpr-1 downto 4*mpr);
              lpp_ram_data_out(2) <= c_ram_data_out_bus_x(4*mpr-1 downto 2*mpr);
              lpp_ram_data_out(3) <= c_ram_data_out_bus_x(2*mpr-1 downto 0);
              lpp_ram_data_out(4) <= c_ram_data_out_bus_y(8*mpr-1 downto 6*mpr);
              lpp_ram_data_out(5) <= c_ram_data_out_bus_y(6*mpr-1 downto 4*mpr);
              lpp_ram_data_out(6) <= c_ram_data_out_bus_y(4*mpr-1 downto 2*mpr);
              lpp_ram_data_out(7) <= c_ram_data_out_bus_y(2*mpr-1 downto 0);
            end if;
          end if;
        end process sel_lpp_data;

    end generate gen_mram_output_sel;
        
    
sel_lpp_ram_r2:process(clk,global_clock_enable,sw_rd_lpp,lpp_ram_data_out)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            -- switch between RAM Sub-block outputs
            case sw_rd_lpp(1 downto 0) is
              when "00" =>
                lpp_ram_data_out_sw(0) <= lpp_ram_data_out(0);
                lpp_ram_data_out_sw(1) <= lpp_ram_data_out(4);
              when "01" =>
                lpp_ram_data_out_sw(0) <= lpp_ram_data_out(1);
                lpp_ram_data_out_sw(1) <= lpp_ram_data_out(5);
              when "10" =>
                lpp_ram_data_out_sw(0) <= lpp_ram_data_out(2);
                lpp_ram_data_out_sw(1) <= lpp_ram_data_out(6);
              when "11" =>
                lpp_ram_data_out_sw(0) <= lpp_ram_data_out(3);
                lpp_ram_data_out_sw(1) <= lpp_ram_data_out(7);
              when others =>
                lpp_ram_data_out_sw(0) <= (others=>'0');
                lpp_ram_data_out_sw(1) <= (others=>'0');
            end case;
          end if;
        end process sel_lpp_ram_r2;
        
        ---------------------------------------------------------------------------------------------------
    -- Last Pass Processor 
    ---------------------------------------------------------------------------------------------------
      lpp_r2 :  asj_fft_lpp_serial_r2
        generic map(
                mpr         => mpr,
                arch        => 0,
                apr         => apr,
                nume        => nume,
                del         => 4
        )
        port map (
global_clock_enable => global_clock_enable,
                clk       => clk,
                reset    => reset,
                lpp_en   => lpp_en,
                data_1_real_i => lpp_ram_data_out_sw(0)(2*mpr-1 downto mpr),
                data_2_real_i => lpp_ram_data_out_sw(1)(2*mpr-1 downto mpr),
                data_1_imag_i => lpp_ram_data_out_sw(0)(mpr-1 downto 0),
                data_2_imag_i => lpp_ram_data_out_sw(1)(mpr-1 downto 0),
                data_real_o   => data_real_out,
                data_imag_o   => data_imag_out,
                data_val      => lpp_data_val
        );
    
    end generate gen_radix_2_last_pass;         
    -----------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------
    
    
process(clk,global_clock_enable,reset,oe,fft_dirn_held_o2,fft_dirn_stream,data_real_out,data_imag_out,val_out,eop_out,sop_out)
       begin
if((rising_edge(clk) and global_clock_enable='1'))then
          if(reset='1') then
            fft_real_out<=(others=>'0');
            fft_imag_out<=(others=>'0');
            master_source_ena         <= val_out;
            master_source_sop         <= '0'; 
            master_source_eop         <= '0'; 
            --fft_dirn_stream <= '0';
          else
            --fft_dirn_stream <= fft_dirn_held_o2;
            if(oe='1') then
              if(fft_dirn_stream='0') then
                fft_real_out<=data_real_out;
                fft_imag_out<=data_imag_out;
              else
                fft_real_out<=data_imag_out;
                fft_imag_out<=data_real_out;
              end if;
              master_source_ena <= val_out;
              master_source_sop <= sop_out;
              master_source_eop <= eop_out;
            else
              fft_real_out<=(others=>'0');
              fft_imag_out<=(others=>'0');
              master_source_ena         <= '0';
              master_source_sop         <= '0'; 
              master_source_eop         <= '0'; 
            end if;
          end if;
        end if;
       end process;
    -----------------------------------------------------------------------------------------------
    -- Block Floating Point
    -----------------------------------------------------------------------------------------------   
    gen_blk_float_out : if(bfp=1) generate
    
flt_exp:process(clk,global_clock_enable,reset,oe,blk_exp_accum)is
         begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
              exponent_out <= (others=>'0');
            else
              if(oe='1') then
                exponent_out <= blk_exp_accum(fpr+1 downto 0);
              else
                exponent_out <= (others=>'0');
              end if;
            end if;
          end if;
         end process flt_exp;
      
         
exp_en_ctrl:process(clk,global_clock_enable,fft_s2_cur,blk_exp,blk_exp_accum)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            case fft_s2_cur is
              when IDLE =>
                blk_exp_accum <=(others=>'0');
              when FIRST_LPP_C =>
                blk_exp_accum <=blk_exp(fpr+1 downto 0);
              when others=>
                blk_exp_accum <=blk_exp_accum;
            end case;   
          end if;
        end process exp_en_ctrl;
        
    end generate gen_blk_float_out;
    -----------------------------------------------------------------------------------------------
    -- Fixed Point
    -----------------------------------------------------------------------------------------------
    gen_fixed_out : if(bfp=0) generate
      exponent_out <=(others=>'0');
    end generate gen_fixed_out;     
    -----------------------------------------------------------------------------------------------  
       
       
oe_ctrl:process(clk,global_clock_enable,reset,fft_s2_cur)is
       begin
if((rising_edge(clk) and global_clock_enable='1'))then
          if(reset='1') then
              oe <='0';
              sop_out <= '0';
              eop_out <= '0';
              val_out <= '0';
          else
            case fft_s2_cur is
              when IDLE =>
                oe <='0';
                sop_out <= '0';
                eop_out <= '0';
                val_out <= '0';
              when WAIT_FOR_LPP_INPUT =>
                oe <='0';
                sop_out <= '0';
                eop_out <= '0';
                val_out <= '0';
              when FIRST_LPP_C =>
                oe <='1';
                sop_out <= '1';
                eop_out <= '0';
                val_out <= '1'; 
              when LPP_C_OUTPUT =>
                oe <='1';
                sop_out <= '0';
                eop_out <= '0';
                val_out <= '1';
              when LAST_LPP_C =>
                oe <='1';
                sop_out <= '0';
                eop_out <= '1';
                val_out <= '1';
              when others=>
                oe <='0';
                sop_out <= '0';
                eop_out <= '0';
                val_out <= '0';
            end case; 
          end if; 
        end if;
      end process oe_ctrl;
      
      
      exp_en <= unload_block;  
  
      -----------------------------------------------------------------------------------------------
      -- Delay the Last Pass Processor Indicator  to account for latency in start-up
      -- of LPP
      -----------------------------------------------------------------------------------------------
      delay_lpp_en : asj_fft_tdl_bit_rst 
        generic map( 
                    del   => 6-2*last_pass_radix
                )
        port map(   
global_clock_enable => global_clock_enable,
                    clk   => clk,
                    reset => reset,               
                    data_in   => lpp_en,
                    data_out  => lpp_fsm_en
            );
              
lpp_counter:process(clk,global_clock_enable,reset,fft_s2_cur)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
              lpp_count<=(others=>'0');
            else
              case fft_s2_cur is
                when IDLE => 
                  lpp_count<=(others=>'0');
                when WAIT_FOR_LPP_INPUT=>
                  -- the initial value of the lpp_counter needs to be adjusted
                  --  to allow for lower latency of the radix 2 last pass
                  lpp_count<=int2ustd(2**(log2_nps+1)-5+2*last_pass_radix,log2_nps+1);
                when others=>
                  lpp_count<=lpp_count+int2ustd(1,log2_nps+1);
              end case;
            end if;
          end if;
        end process lpp_counter;
                
    -----------------------------------------------------------------------------------------------
    -- FFT Input Flow Control
    -----------------------------------------------------------------------------------------------   
fsm_1:process(clk,global_clock_enable,reset,master_sink_sop,master_sink_val,fft_s1_cur,master_sink_dav,load_block)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
              fft_s1_cur <= IDLE;
            else
              case fft_s1_cur is
                when IDLE =>
                  if(master_sink_dav='1') then
                    fft_s1_cur <= WAIT_FOR_INPUT;
                  end if;
                when WAIT_FOR_INPUT =>
                  if(master_sink_sop='1') then
                    fft_s1_cur <= WRITE_INPUT;
                  end if;
                when WRITE_INPUT =>
                  if(sample_count=int2ustd(nps-5,apr+3)) then
                    fft_s1_cur <= CHECK_DAV;
                  else
                    fft_s1_cur <= WRITE_INPUT;
                  end if;
                when CHECK_DAV =>   
                  if(load_block='1') then
                    fft_s1_cur <= LAST_INPUT;
                  else
                    fft_s1_cur <= CHECK_DAV;
                  end if;
                when LAST_INPUT=>
                  if(master_sink_val='0' or dav_int='0' or master_sink_sop='0') then
                    fft_s1_cur <= WAIT_FOR_INPUT;
                  else
                    fft_s1_cur <= WRITE_INPUT;
                  end if;
                when others =>
                  fft_s1_cur <= IDLE;
              end case;
            end if;
          end if;
        end process fsm_1;
    -----------------------------------------------------------------------------------------------
    -- FFT LPP STATE MACHINE
    -- Controls and enables the Last Pass Processor
fsm_2:process(clk,global_clock_enable,reset,lpp_en,fft_s2_cur,master_source_dav)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
              fft_s2_cur <= IDLE;
            else
              case fft_s2_cur is
                when IDLE =>
                  fft_s2_cur <= WAIT_FOR_LPP_INPUT;
                when WAIT_FOR_LPP_INPUT =>
                  if(master_source_dav='1' and lpp_fsm_en='1') then
                    fft_s2_cur <=FIRST_LPP_C;               
                  else
                    fft_s2_cur <=WAIT_FOR_LPP_INPUT;                
                  end if;
                when FIRST_LPP_C =>
                    fft_s2_cur <=LPP_C_OUTPUT;
                when LPP_C_OUTPUT =>
                  if(lpp_count_offset(log2_nps-1 downto 0)=int2ustd(2**(log2_nps)-1,log2_nps)) then
                    fft_s2_cur <=LAST_LPP_C;
                  end if;
                when LAST_LPP_C =>
                  if(master_source_dav='1' and lpp_fsm_en='1') then
                    fft_s2_cur <=FIRST_LPP_C;               
                  else
                    fft_s2_cur <=WAIT_FOR_LPP_INPUT;                
                  end if;
                when others =>
                  fft_s2_cur <= IDLE;
              end case;
            end if;
         end if;
        end process fsm_2;
    -----------------------------------------------------------------------------------------------
    --
    -----------------------------------------------------------------------------------------------           
input_sample_count:process(clk,global_clock_enable,fft_s1_cur,sample_count)is
      begin
if((rising_edge(clk) and global_clock_enable='1'))then
          case fft_s1_cur is
            when IDLE =>
              sample_count <= (others=>'0');
              load_block <= '0';
              dav_int <= master_sink_dav;
            when WRITE_INPUT =>
              sample_count <= sample_count + int2ustd(1,log2_nps);
              load_block<='0';
              dav_int <= master_sink_dav;
            when CHECK_DAV =>
              if(sample_count=int2ustd(nps-4,log2_nps)) then
                dav_int <= master_sink_dav;
              else
                dav_int <= dav_int;
              end if;
              if(sample_count=int2ustd(nps-3,log2_nps)) then
                load_block<='1';
              else
                load_block<='0';
              end if;
              sample_count <= sample_count + int2ustd(1,log2_nps);
            when LAST_INPUT =>
              load_block <= load_block;
              dav_int <= dav_int;
              sample_count <= sample_count + int2ustd(1,log2_nps);
            when others =>
              dav_int <= dav_int;
              sample_count <= sample_count;
              load_block <= load_block;
          end case;
        end if;
      end process input_sample_count;
      
-----------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------
    -- Registering here to enable registered muxing based on dirn
    -- This implies that two levels of delay must be removed from
    -- in_write_sgl
    
    
is_data_valid:process(clk,global_clock_enable,reset,master_sink_val,data_real_in,data_imag_in,data_real_in_reg,data_imag_in_reg)is
      begin
if((rising_edge(clk) and global_clock_enable='1'))then
          if(reset='1') then
            data_real_in_reg <= (others=>'0');
            data_imag_in_reg <= (others=>'0');
          else
            if(master_sink_val='1') then
              data_real_in_reg <= data_real_in;
              data_imag_in_reg <= data_imag_in;     
            else
              data_real_in_reg <= data_real_in_reg;
              data_imag_in_reg <= data_imag_in_reg;     
            end if;
          end if;
        end if;
    end process is_data_valid;    

i_dirn_mux:process(clk,global_clock_enable,fft_dirn,data_real_in,data_imag_in,data_real_in_reg,data_imag_in_reg)is
      begin
if((rising_edge(clk) and global_clock_enable='1'))then
          if(reset='1') then
            core_real_in <=(others=>'0');
            core_imag_in <=(others=>'0');
          elsif(fft_dirn='0') then
            core_real_in <=data_real_in_reg;
            core_imag_in <=data_imag_in_reg;
          else
            core_real_in <=data_imag_in_reg;
            core_imag_in <=data_real_in_reg;
          end if;
        end if;
      end process i_dirn_mux;
    
      
regfftdirn:process(clk,global_clock_enable,fft_dirn,fft_dirn_held,fft_dirn_held_o,master_sink_sop,inv_i)is
      begin
if((rising_edge(clk) and global_clock_enable='1'))then
          if(reset='1') then
            fft_dirn <='0';
          elsif(master_sink_sop='1') then
            fft_dirn <= inv_i;
          else
            fft_dirn <= fft_dirn;
          end if;
        end if;
      end process regfftdirn;
    
regfftdirni:process(clk,global_clock_enable,fft_dirn,fft_dirn_held,fft_dirn_held_o,master_sink_sop,inv_i)is
      begin
if((rising_edge(clk) and global_clock_enable='1'))then
          if(reset='1') then
            fft_dirn_held <= '0';
          else
            fft_dirn_held <= fft_dirn;
          end if;
        end if;
      end process regfftdirni;

regfftdirni1:process(clk,global_clock_enable,fft_dirn,fft_dirn_held,fft_dirn_held_o,master_sink_sop,inv_i)is
      begin
if((rising_edge(clk) and global_clock_enable='1'))then
          if(reset='1') then
            fft_dirn_held_o <= '0';
          elsif(next_blk='1') then
            fft_dirn_held_o <= fft_dirn_held;
          else
            fft_dirn_held_o <= fft_dirn_held_o;
          end if;
        end if;
      end process regfftdirni1;
      
            
regfftdirnt:process(clk,global_clock_enable,fft_dirn,fft_dirn_held,fft_dirn_held_o,master_sink_sop,inv_i)is
      begin
if((rising_edge(clk) and global_clock_enable='1'))then
          if(reset='1') then
            fft_dirn_held_o2 <= '0';
          elsif(block_done='1') then
            fft_dirn_held_o2 <= fft_dirn_held_o;
          else
            fft_dirn_held_o2 <= fft_dirn_held_o2;
          end if;
        end if;
      end process regfftdirnt;
    
regfftdirno:process(clk,global_clock_enable,fft_s2_cur,fft_dirn_held_o,fft_dirn_held_o2)is
      begin
if((rising_edge(clk) and global_clock_enable='1'))then
          if(reset='1') then
            fft_dirn_stream <= '0';
          elsif(fft_s2_cur=FIRST_LPP_C) then
            fft_dirn_stream <= fft_dirn_held_o2;
          else
            fft_dirn_stream <= fft_dirn_stream;
          end if;
        end if;
      end process regfftdirno;

en_unloader:process(clk,global_clock_enable,fft_s2_cur,fft_dirn_held_o,fft_dirn_held_o2)is
      begin
if((rising_edge(clk) and global_clock_enable='1'))then
          if(reset='1') then
            unload_block <= '0';
          elsif(fft_s2_cur=FIRST_LPP_C) then
            unload_block <= '1';
          else
            unload_block <= '0';
          end if;
        end if;
      end process en_unloader;
       
ena_gen:process(clk,global_clock_enable,fft_s1_cur,master_sink_dav,master_sink_sop)is
      begin
if((rising_edge(clk) and global_clock_enable='1'))then
          if(reset='1') then
            master_sink_ena <='0';
          else
            case fft_s1_cur is
              when IDLE =>
                if(master_sink_dav='1') then
                  master_sink_ena <='1';
                else
                  master_sink_ena <='0';
                end if;
              when others => 
                master_sink_ena <='1';
            end case;
          end if;
        end if;
      end process ena_gen;      
  
end transform;











