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
--  version		: $Version:	1.0 $ 
--  revision		: $Revision: #1 $ 
--  designer name  	: $Author: psgswbuild $ 
--  company name   	: altera corp.
--  company address	: 101 innovation drive
--                  	  san jose, california 95134
--                  	  u.s.a.
-- 
--  copyright altera corp. 2003
-- 
-- 
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_si_sose_so_b.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all; 
use work.fft_pack.all;
library work;
use work.auk_dspip_lib_pkg.all;

entity asj_fft_si_sose_so_b is
	generic(
						device_family : string;
						nps : integer :=256;
						nume : integer :=1;
						bfp  : integer :=1;
						mpr : integer :=16;
						twr : integer :=16;
						fpr : integer :=4;
						mram : integer :=0;
					  m512 : integer :=0;
						bpr  : integer :=16;
						bpb  : integer :=4;
						mult_type : integer :=0;
						mult_imp  : integer :=0;
						dsp_arch  : integer :=0;
						rfs1 : string  :="test_1n8192cos.hex";
						rfs2 : string  :="test_2n8192cos.hex";
						rfs3 : string  :="test_3n8192cos.hex";
						rfc1 : string  :="test_1n8192sin.hex";
						rfc2 : string  :="test_2n8192sin.hex";
						rfc3 : string  :="test_3n8192sin.hex";
						srr  : string  :="AUTO_SHIFT_REGISTER_RECOGNITION=ON"
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
end asj_fft_si_sose_so_b;

architecture transform of asj_fft_si_sose_so_b is
  constant FRAME_SIZE       : integer := nps;
  constant FRAME_WORD_WIDTH : integer := log2_ceil(nps);  
  constant WORD_LENGTH      : integer := mpr;  
  constant EXP_WIDTH        : integer := fpr+2;
  constant FIFO_DEPTH_c : natural :=7;
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
      FIFO_DEPTH_g : natural;
      SOP_EOP_CALC_g: string ;
      FAMILY_g : string;
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




	-- Single engine : apr = log2(nps)
	-- Dual engine : apr = log2(nps)-1
	constant apr : integer :=LOG2_FLOOR(nps)-nume+1; 
	constant apri : integer :=LOG2_FLOOR(nps); 
	constant twa : integer :=LOG2_FLOOR(nps)-2; 
	constant exp_init_fft : integer :=0; 
	constant dpr : integer :=2*mpr;
	constant n_bfly : integer := nps/4;
	constant log2_nps : integer := LOG2_CEIL(nps);
	constant n_passes : integer := LOG4_CEIL(nps);
	constant n_passes_m1 : integer := LOG4_CEIL(nps)-1;
	-- Make pass counter resolution fixed to 3 bits
	-- constant log2_n_passes: integer := 3;
	constant log2_n_passes: integer := 4; --make it four for fft_length extention upto 64k
	constant mid_apr : integer :=apr/2;
	-- last_pass_radix = 0 => radix 4
	-- last_pass_radix = 1 => radix 2
	constant last_pass_radix : integer :=(LOG4_CEIL(nps))-(LOG4_FLOOR(nps));
	-----------------------------------------------------------------------------------------------
	-- Delay path depths
	constant twid_delay : integer :=9+last_pass_radix;
	constant wr_ad_delay : integer :=20+last_pass_radix;
	-----------------------------------------------------------------------------------------------
	constant newtw : integer :=1;
	
	constant rbuspr : integer :=4*mpr;
	constant cbuspr : integer :=8*mpr;
	constant abuspr : integer :=4*apr;
	constant switch_read_data : integer:= 1;
	constant initial_en_np_delay : integer :=12;
	constant wr_en_null : integer :=25;
	constant wr_cd_en : integer :=5;
	constant wraddr_cd_en : integer := 3;
	constant mem_string : string :="AUTO";
  constant arch : integer :=3;
	constant byte_size : integer := cbuspr/bpr;	
	constant which_fsm : integer :=1;	
	
		
	-- State machine variables
	-- Input Interface Control
	type   fft_s1_state is (IDLE,WAIT_FOR_INPUT,WRITE_INPUT,EARLY_DONE,DONE_WRITING,NO_WRITE,FFT_PROCESS_A);
	signal fft_s1_cur,fft_s1_next :  fft_s1_state;
	-- State machine variables
	-- Output Interface Control
	type   fft_s2_state is (IDLE,WAIT_FOR_LPP_INPUT,START_LPP,FIRST_LPP,LPP_OUTPUT_RDY,LPP_DONE);
	signal fft_s2_cur,fft_s2_next :  fft_s2_state;
	
	
	-- Direction selector
	signal dirn_select :	std_logic ;
	
	type complex_data_bus	is array (0 to 3,0 to 1) of std_logic_vector(mpr-1 downto 0);
	type real_data_bus	  is array (0 to 3) of std_logic_vector(mpr-1 downto 0);
	type engine_data_bus	is array (0 to 3) of std_logic_vector(mpr-1 downto 0);
	type address_bus_vec  is array (0 to 3) of std_logic_vector(apr-1 downto 0);
	type address_array    is array (0 to 3) of std_logic_vector(apr-1 downto 0);  
	
	type twiddle_bus is array (0 to 2,0 to 1) of std_logic_vector(twr-1 downto 0);
	type twiddle_address_array is array (0 to twid_delay-1) of std_logic_vector(twa-1 downto 0);
	type wr_address_delay is array (0 to wr_ad_delay) of std_logic_vector(apr-1 downto 0);
	
	type selector_array is array (0 to 3) of std_logic_vector(1 downto 0);
	type sw_r_array is array (0 to 8) of std_logic_vector(1 downto 0);
	type p_array is array (0 to 18) of std_logic_vector(log2_n_passes-1 downto 0);
	
	-----------------------------------------------------------------------------------
	-- Single Engine I/O Signals
	-----------------------------------------------------------------------------------------------
	signal data_in_bfp_real   :  std_logic_vector(mpr-1 downto 0);
	signal data_in_bfp_imag   :  std_logic_vector(mpr-1 downto 0);
	signal twiddle_data_real  : std_logic_vector(twr-1 downto 0);
	signal twiddle_data_imag  : std_logic_vector(twr-1 downto 0);
	signal dro								: std_logic_vector(mpr-1 downto 0);
  signal dio								: std_logic_vector(mpr-1 downto 0);
  -- ROM twiddle outputs
  signal t1r,t2r,t3r 				: std_logic_vector(twr-1 downto 0);
  signal t1i,t2i,t3i 				: std_logic_vector(twr-1 downto 0);  
  
	-----------------------------------------------------------------------------------
	-- Dual Engine I/O Signals
	-----------------------------------------------------------------------------------------------
	signal data_in_bfp_real_x  :  std_logic_vector(mpr-1 downto 0);
	signal data_in_bfp_imag_x  :  std_logic_vector(mpr-1 downto 0);
	signal data_in_bfp_real_y  :  std_logic_vector(mpr-1 downto 0);
	signal data_in_bfp_imag_y  :  std_logic_vector(mpr-1 downto 0);
	
	signal twiddle_data_real_x : std_logic_vector(twr-1 downto 0);
	signal twiddle_data_imag_x : std_logic_vector(twr-1 downto 0);
	signal twiddle_data_real_y : std_logic_vector(twr-1 downto 0);
	signal twiddle_data_imag_y : std_logic_vector(twr-1 downto 0);
	signal dro_x							 : std_logic_vector(mpr-1 downto 0);
  signal dio_x							 : std_logic_vector(mpr-1 downto 0);
  signal dro_y							 : std_logic_vector(mpr-1 downto 0);
  signal dio_y							 : std_logic_vector(mpr-1 downto 0);
  
  -- ROM twiddle outputs
  signal t1re,t2re,t3re,t1ro,t2ro,t3ro : std_logic_vector(twr-1 downto 0);
  signal t1ie,t2ie,t3ie,t1io,t2io,t3io : std_logic_vector(twr-1 downto 0);  
  
  
  -- RAM Select
  -- Selects between RAM Block A or B for input buffer
  signal ram_a_not_b          : std_logic;
  signal ram_a_not_b_vec      : std_logic_vector(31 downto 0); 
  ----------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
	-- Direction selector
	signal fft_dirn :	std_logic ;
	signal fft_dirn_held :	std_logic ;
	signal fft_dirn_held_o :	std_logic ;
	-----------------------------------------------------------------------------------------------
	-- Registered Core Signals
	-----------------------------------------------------------------------------------------------
	signal data_real_in_reg : std_logic_vector(mpr-1 downto 0);
	signal data_imag_in_reg : std_logic_vector(mpr-1 downto 0);
	signal core_real_in : std_logic_vector(mpr-1 downto 0);
	signal core_imag_in : std_logic_vector(mpr-1 downto 0);
	-----------------------------------------------------------------------------------
  
  signal data_rdy : std_logic ;
  signal data_proc : std_logic ;
  signal data_rdy_vec      : std_logic_vector(31 downto 0); 
  signal data_proc_vec      : std_logic_vector(31 downto 0); 
  -----------------------------------------------------------------------
  signal wraddr_i             : std_logic_vector(apr-1 downto 0); 
  signal i_ram_real           : std_logic_vector(mpr-1 downto 0);
  signal i_ram_imag           : std_logic_vector(mpr-1 downto 0);
  signal i_ram_data_in        : std_logic_vector(2*mpr-1 downto 0);
  signal i_wren               : std_logic_vector(3 downto 0);
  signal wraddr               : address_array; 
  signal wraddr_sw            : address_array; 
  signal rdaddr               : address_array; 
  signal rdaddr_sw            : address_array; 
  signal rdaddr_lpp           : address_array; 
  signal rdaddr_lpp_sw        : address_array; 
  signal wraddr_cd            : address_array; 
	signal wraddr_cd_sw         : address_array; 
                                             
  signal wr_addr_o            : address_array; 
  signal rdaddress_i          : std_logic_vector(abuspr-1 downto 0); 
  signal four_rdata_bus_in    : std_logic_vector(rbuspr-1 downto 0);  
  signal four_idata_bus_in    : std_logic_vector(rbuspr-1 downto 0);  
  
  -- address counters
  signal p_count   	    			: std_logic_vector(log2_n_passes-1 downto 0);
  signal p_cd_en              : std_logic_vector(log2_n_passes-1 downto 0);
	signal p_tdl                : p_array;
	signal k_count							: std_logic_vector(apr-1 downto 0);
	signal k_count_wr						: std_logic_vector(apr-1 downto 0);
	signal k_count_wr_en				: std_logic;
	signal k_count_tw						: std_logic_vector(apr-1 downto 0);
	signal k_count_tw_en				: std_logic;
	
	-- switch selects
	signal sw										: std_logic_vector(1 downto 0);
	signal sw_r									: std_logic_vector(1 downto 0);
	signal sw_i									: std_logic_vector(1 downto 0);
  signal swd_w									: std_logic_vector(1 downto 0);
	signal swa_w									: std_logic_vector(1 downto 0);
	signal sel_tw									: std_logic_vector(1 downto 0);
	signal sw_rd_lpp									: std_logic_vector(1 downto 0);
	signal sw_ra_lpp									: std_logic_vector(1 downto 0);
	signal sw_w_cd									: std_logic_vector(1 downto 0);
	signal sw_r_tdl             : sw_r_array;
	
	signal slb_last_i           : std_logic_vector(2 downto 0);
	signal slb_x_o              : std_logic_vector(2 downto 0);
	signal slb_y_o              : std_logic_vector(2 downto 0);
	signal dual_eng_slb         : std_logic_vector(3*nume-1 downto 0);
	signal blk_exp  : std_logic_vector(fpr+1 downto 0);
  signal blk_exp_accum  : std_logic_vector(fpr+1 downto 0);
	
  -- wren
  signal input_selector       : std_logic_vector(3 downto 0);
  signal wren_i       				: std_logic;
  signal wren_a       				: std_logic;
  signal wren_ad       				: std_logic_vector(nume-1 downto 0);
  signal rden_a       				: std_logic;
  signal rden_b       				: std_logic;
  signal rden_c       				: std_logic;
  signal rden_d       				: std_logic;
  
  signal wa 									: std_logic;
  signal wb 									: std_logic;
  signal wc 									: std_logic;
  signal wd 									: std_logic;
  
  signal ra 									: std_logic;
  signal rb 									: std_logic;
  signal rc 									: std_logic;
  signal rd 									: std_logic;
  
  
  --signal lpp_c_en_early 						: std_logic;
  --signal lpp_c_addr_en 						: std_logic;
  --signal lpp_c_data_en 						: std_logic;
  --signal lpp_d_en_early 						: std_logic;
  --signal wc_early 						: std_logic;
  --signal lpp_c_en_vec 							: std_logic_vector(10 downto 0);
  --signal wc_vec 							: std_logic_vector(8 downto 0);
  
  signal anb_enabled          : std_logic;
  
  -- Last Pass Enable Signals
  --signal lpp_wrcnt_en       : std_logic;
  signal lpp_rdcnt_en       : std_logic;
  signal lpp_c_en             : std_logic;
  signal lpp_en             : std_logic;
  
  -- output address counter
  signal output_counter       : std_logic_vector(apr-1 downto 0);
  
  -- assigned addresses to individual memory banks
  --signal wraddress_a          : address_array;  
  --signal rdaddress_a          : address_array;  
  --signal wraddress_b          : address_array;  
  --signal rdaddress_b          : address_array;  
  
  
  signal rdaddress_i_bus : std_logic_vector(apr-1 downto 0);
  signal wraddress_i_bus : std_logic_vector(apr-1 downto 0);
  signal i_ram_data_in_bus: std_logic_vector(2*mpr-1 downto 0);
  signal i_ram_data_out_bus : std_logic_vector(2*mpr-1 downto 0);
  signal rdaddress_a_bus : std_logic_vector(nume*apr-1 downto 0);
  signal wraddress_a_bus : std_logic_vector(nume*apr-1 downto 0);
  signal rdaddress_a_bus_x : std_logic_vector(apr-1 downto 0);
  signal wraddress_a_bus_x : std_logic_vector(apr-1 downto 0);
  signal rdaddress_a_bus_y : std_logic_vector(apr-1 downto 0);
  signal wraddress_a_bus_y : std_logic_vector(apr-1 downto 0);
  signal rdaddress_a_bus_ctrl : std_logic_vector(nume*apr-1 downto 0);
  signal wraddress_a_bus_ctrl : std_logic_vector(nume*apr-1 downto 0);
  signal rdaddress_a_bus_ctrl_i : std_logic_vector(nume*apr-1 downto 0);
  signal wraddress_a_bus_ctrl_i : std_logic_vector(nume*apr-1 downto 0);
  
  signal a_ram_data_in_bus: std_logic_vector(2*nume*mpr-1 downto 0);
  signal a_ram_data_out_bus : std_logic_vector(2*nume*mpr-1 downto 0);
  -----------------------------------------------------------------------------------------------
  -- Dual Output Engine Data Buses
  -----------------------------------------------------------------------------------------------
  signal a_ram_data_in_bus_x: std_logic_vector(2*mpr-1 downto 0);
  signal a_ram_data_out_bus_x : std_logic_vector(2*mpr-1 downto 0);
  signal a_ram_data_in_bus_y: std_logic_vector(2*mpr-1 downto 0);
  signal a_ram_data_out_bus_y : std_logic_vector(2*mpr-1 downto 0);
  -----------------------------------------------------------------------------------------------
  --debug 
  -----------------------------------------------------------------------------------------------
  signal real_ram_in_dbg : std_logic_vector(mpr-1 downto 0);
  signal imag_ram_in_dbg : std_logic_vector(mpr-1 downto 0);
  signal real_ram_out_dbg : std_logic_vector(mpr-1 downto 0);
  signal imag_ram_out_dbg : std_logic_vector(mpr-1 downto 0);
  signal real_ram_in_1_dbg : std_logic_vector(mpr-1 downto 0);
  signal imag_ram_in_1_dbg : std_logic_vector(mpr-1 downto 0);
  signal real_ram_out_1_dbg : std_logic_vector(mpr-1 downto 0);
  signal imag_ram_out_1_dbg : std_logic_vector(mpr-1 downto 0);
  signal real_ram_in_2_dbg : std_logic_vector(mpr-1 downto 0);
  signal imag_ram_in_2_dbg : std_logic_vector(mpr-1 downto 0);
  signal real_ram_out_2_dbg : std_logic_vector(mpr-1 downto 0);
  signal imag_ram_out_2_dbg : std_logic_vector(mpr-1 downto 0);
  -----------------------------------------------------------------------------------------------
  -- MRAM Input Buffer
  -----------------------------------------------------------------------------------------------
  signal rdaddress_a_mram : std_logic_vector(apr-1 downto 0);
  signal wraddress_a_mram : std_logic_vector(apr-1 downto 0);
  signal a_ram_data_in_mram: std_logic_vector(8*mpr-1 downto 0);
  signal a_ram_data_out_mram : std_logic_vector(8*mpr-1 downto 0);
  signal byte_enable_i : 	std_logic_vector(bpr-1 downto 0);
  -----------------------------------------------------------------------------------------------
  -- Block I RAM Data Output
  -----------------------------------------------------------------------------------------------
  signal i_ram_data_out   : std_logic_vector(2*nume*mpr-1 downto 0);
  signal ram_data_out     : std_logic_vector(2*nume*mpr-1 downto 0);
  signal ram_data_out_sw  :  std_logic_vector(2*nume*mpr-1 downto 0);
  signal ram_data_in    : std_logic_vector(2*nume*mpr-1 downto 0);
  signal ram_data_in_sw  :  std_logic_vector(2*nume*mpr-1 downto 0);
  -----------------------------------------------------------------------------------------------
  -- Block A RAM Data input
  signal lpp_ram_data_out : std_logic_vector(2*mpr-1 downto 0);
  
  
  
  signal next_pass  : std_logic ;
  signal next_pass_q  : std_logic ;
  signal next_pass_d  : std_logic ;
  signal block_done  : std_logic ;
  
  signal en_np  : std_logic ;
  signal first_pass  : std_logic ;
  signal which_ram_set  : std_logic ;
  signal input_data_select : std_logic_vector(1 downto 0);
  signal twad : std_logic_vector(nume*twa-1 downto 0);
  signal twade : std_logic_vector(twa-1 downto 0);
  signal twado : std_logic_vector(twa-1 downto 0);
  signal twad_q : std_logic_vector(2*twa-1 downto 0);
  signal quad  :std_logic_vector(2 downto 0);
  signal quad_del  :std_logic_vector(2 downto 0);
  signal quad_del_0  :std_logic_vector(2 downto 0);
  signal quad_del_1  :std_logic_vector(2 downto 0);
  signal quad_del_2 :std_logic_vector(2 downto 0);
  signal count :std_logic_vector(1 downto 0);
  
  signal data_real_out : std_logic_vector(mpr-1 downto 0);
  signal data_imag_out : std_logic_vector(mpr-1 downto 0);
  signal lpp_data_val : std_logic;
  signal next_blk : std_logic;
  signal next_input_blk : std_logic;
  signal midr2    : std_logic;
  signal midr2_d    : std_logic;
  signal r2_lpp_sel : std_logic_vector(2 downto 0);
  
  signal sel_addr_in : std_logic;
  signal sel_ram_in  : std_logic;       
  signal sel_lpp  	 : std_logic;       
	signal sel_lpp_i   : std_logic;         
	signal sel_lpp_o   : std_logic;         
	signal sel_lpp_o_data   : std_logic;  
	signal sel_lpp_nm1   : std_logic;  	       
  
  -- exponent register enable
  signal exp_en : std_logic ;
  --output enable
  signal oe : std_logic ;
  -- detect if processing can begin
  signal go : std_logic ;
  -- disable writing to memory by deasserting master_sink_ena
  -- this needs to be generated by the writer, but asserted a few cycles before dopne to account
  -- for latency from the fft to the user's system   
  signal dsw : std_logic;
  signal nbc : std_logic_vector(log2_n_passes-1 downto 0) ;
  signal sbc : std_logic_vector(4 downto 0) ;
  signal input_sample_counter : std_logic_vector(apri-1 downto 0) ;
  
  
  signal output_count : std_logic_vector(apri-1 downto 0) ;
  signal del_sop_cnt : std_logic_vector(4 downto 0) ;
  signal sop_out : std_logic ;
  signal sop_d : std_logic ;
  signal sop_de : std_logic ;
  signal sop_det : std_logic ;
  signal eop_out : std_logic ;
  signal val_out : std_logic ;
  signal val_o : std_logic ;
	signal vcc : std_logic ;
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
      FIFO_DEPTH_g => FIFO_DEPTH_c,
       SOP_EOP_CALC_g => "true",
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
      reset_n               => reset_n,                                                        
      ready               => fft_ready_sig,                                                
      sink_packet_error   => sink_packet_error,                                            
      sink_stall          => sink_stall,                                                   
      source_stall        => source_stall,                                                 
      valid               => master_source_ena,
      reset_design => open,
      sink_ready_ctrl     => sink_ready_ctrl,                                              
      source_packet_error => source_packet_error,                                          
      source_valid_ctrl   => source_valid_ctrl,                                            
      stall               => stall);

  counter_p : process (clk, reset_n)
  begin
    if reset_n = '0' then
      sop       <= '1';-- modified SPR 268207
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

		-----------------------------------------------------------------------------------------------
		master_sink_val <= '1';
		-----------------------------------------------------------------------------------------------	
  	vcc <= '1';
  	-----------------------------------------------------------------------------------------------	
  	-- Counter Logic
  	-- Defines k,p counters
  	-----------------------------------------------------------------------------------------------
  	ctrl : asj_fft_m_k_counter 
		generic map(
							nps => nps,
							arch => 3,
							nume => nume,
							n_passes => n_passes, --log4(nps) (no separate lpp)
							log2_n_passes => log2_n_passes, 
							apr => apr, --apr = log2(nps/4)
							cont => 0
						)
		port map(			
global_clock_enable => global_clock_enable,
							clk 		 => clk,
							reset    => reset,
							stp   	 => master_sink_sop,
							start    => data_rdy_vec(4),
							next_block => next_blk,
							p_count  => p_count,
							k_count	 => k_count,
							next_pass => next_pass_q,
							blk_done  => block_done
				);
				
		-----------------------------------------------------------------------------------------------
		next_pass <= data_rdy_vec(27) and next_pass_q;
		-----------------------------------------------------------------------------------------------
		delay_swd : asj_fft_tdl_bit_rst 
			generic map( 
							 		del   => 10
							)
			port map( 	
global_clock_enable => global_clock_enable,
									clk 	=> clk,
									reset => reset,								
									data_in 	=> next_pass,
					 				data_out 	=> next_pass_d
					);
		-----------------------------------------------------------------------------------------------
		
ram_sel_vec:process(clk,global_clock_enable,reset,data_rdy,data_rdy_vec)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
						data_rdy_vec <=(others=>'0');
					else
						for i in 31 downto 1 loop
							data_rdy_vec(i) 	 <= data_rdy_vec(i-1);
						end loop;
						data_rdy_vec(0) <= data_rdy;
					end if;
				end if;
		end process ram_sel_vec;
		
p_vec:process(clk,global_clock_enable,reset,p_count,p_tdl)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				if(reset='1') then
					for i in 18 downto 0 loop
						p_tdl(i) <= (others=>'0');
					end loop;
				else
					for i in 18 downto 1 loop
						p_tdl(i) <= p_tdl(i-1);
					end loop;
					p_tdl(0) <= p_count;
				end if;
			end if;
	end process p_vec;
	
	
	-----------------------------------------------------------------------------------------------
	-- Single Output Architecture RAM Write Enable Generation
	-----------------------------------------------------------------------------------------------
	gen_se_wea : if(nume=1) generate
				
wea_st:process(clk,global_clock_enable,fft_s1_cur,data_rdy_vec,i_wren)is
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						if(fft_s1_cur=IDLE) then
							wren_a <= '0';
							sel_ram_in <='0';
						elsif(fft_s1_cur=WRITE_INPUT or fft_s1_cur=DONE_WRITING or fft_s1_cur=EARLY_DONE) then
							wren_a<=i_wren(0);
							sel_ram_in <='0';
						elsif(fft_s1_cur=NO_WRITE) then
							sel_ram_in <= '1'; 
							wren_a<='0';
						else
							sel_ram_in <= '1'; 
							wren_a		 <= data_rdy_vec(21-last_pass_radix);
						end if;
					end if;
				end process wea_st;
	end generate gen_se_wea;
	
	-----------------------------------------------------------------------------------------------
	-- Dual Output Architecture RAM Write Enable Generation
	-----------------------------------------------------------------------------------------------
	gen_de_wea : if(nume=2) generate
	
			gen_fsm_1_we : if(which_fsm=1) generate
wea_st:process(clk,global_clock_enable,fft_s1_cur,k_count,wren_ad,data_rdy_vec)is
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						if(fft_s1_cur=IDLE or fft_s1_cur=WAIT_FOR_INPUT) then
							wren_ad <= "10";
							sel_ram_in <='0';
						elsif(fft_s1_cur=WRITE_INPUT or fft_s1_cur=DONE_WRITING or fft_s1_cur=EARLY_DONE) then
							wren_ad<=not(wren_ad);
		 					sel_ram_in <='0';
						elsif(fft_s1_cur=NO_WRITE) then
							sel_ram_in <= '1'; 
							wren_ad<= "00";
						else
							sel_ram_in <= '1'; 
							--if(k_count=int2ustd(2+last_pass_radix,apr)) then
							if(k_count=int2ustd(1+last_pass_radix,apr)) then
								wren_ad		 <= "00";
							elsif(k_count=int2ustd(21+last_pass_radix,apr)) then
								wren_ad		 <= (1 downto 0 => data_rdy_vec(22));
							else
								wren_ad		 <= wren_ad;
							end if;
						end if;
					end if;
				end process wea_st;
			end generate gen_fsm_1_we;
			
			gen_fsm_2_we : if(which_fsm=2) generate
wea_st:process(clk,global_clock_enable,fft_s1_cur,k_count,wren_ad,data_rdy_vec)is
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						if(fft_s1_cur=IDLE or fft_s1_cur=WAIT_FOR_INPUT) then
							wren_ad <= "10";
							sel_ram_in <='0';
						elsif(fft_s1_cur=WRITE_INPUT or fft_s1_cur=DONE_WRITING or fft_s1_cur=EARLY_DONE) then
								wren_ad<=not(wren_ad);
								sel_ram_in <='0';
						elsif(fft_s1_cur=NO_WRITE) then
							sel_ram_in <= '1'; 
							wren_ad<= "00";
						else
							sel_ram_in <= '1'; 
							if(k_count=int2ustd(2+last_pass_radix,apr)) then
								wren_ad		 <= "00";
							elsif(k_count=int2ustd(21+last_pass_radix,apr)) then
								wren_ad		 <= (1 downto 0 => data_rdy_vec(22));
							else
								wren_ad		 <= wren_ad;
							end if;
						end if;
					end if;
				end process wea_st;
			end generate gen_fsm_2_we;
				
	end generate gen_de_wea;	
	-----------------------------------------------------------------------------------------------
	-- Input Buffer Writer
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
						clk 			=> clk,
						reset 		=> reset,
						stp       => master_sink_sop,
						val       => master_sink_val,
						block_done => block_done,
						data_real_in   	=> core_real_in,
						data_imag_in   	=> core_imag_in,
						wr_address_i    => wraddr_i,
						wren_i          => i_wren,
						byte_enable     => byte_enable_i,
						data_rdy        => data_rdy,
						a_not_b         => ram_a_not_b,
						next_block      => next_blk,
						disable_wr      => dsw,
						data_in_r    		=> i_ram_real,
						data_in_i    		=> i_ram_imag
			);
	-----------------------------------------------------------------------------------------------							
	i_ram_data_in	<= i_ram_real & i_ram_imag;			
	-----------------------------------------------------------------------------------------------
	sel_addr_in <= data_rdy_vec(21);				
	-----------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------
	-- No switch required for Radix 4 Last Pass Arimthmetic?
	-----------------------------------------------------------------------------------------------
	gen_radix_4_lpp_sw : if(last_pass_radix=0) generate		
	
sw_det_nm1:process(clk,global_clock_enable,p_tdl)is
		  begin
if((rising_edge(clk) and global_clock_enable='1'))then
				if(p_tdl(18)=int2ustd(n_passes-1,log2_n_passes)) then
					sel_lpp_nm1 <= '1';
				else
					sel_lpp_nm1 <= '0';
				end if;
			end if;
		end process sw_det_nm1;
	
sw_det:process(clk,global_clock_enable,p_tdl)is
		  begin
if((rising_edge(clk) and global_clock_enable='1'))then
				if(p_tdl(13)=int2ustd(n_passes,log2_n_passes)) then
					sel_lpp <= '1';
				else
					sel_lpp <= '0';
				end if;
			end if;
		end process sw_det;
	
	-----------------------------------------------------------------------------------------------
	-- Data switch required for Radix 4 Last Pass
	-----------------------------------------------------------------------------------------------
sw_det_i:process(clk,global_clock_enable,p_tdl)is
		  begin
if((rising_edge(clk) and global_clock_enable='1'))then
				if(p_tdl(13)=int2ustd(n_passes,log2_n_passes)) then
					sel_lpp_i <= '1';
				else
					sel_lpp_i <= '0';
				end if;
			end if;
		end process sw_det_i;
	end generate gen_radix_4_lpp_sw;
	
	-----------------------------------------------------------------------------------------------
	-- Switch required for Radix 2 Last Pass Input Data Arithmetic
	-----------------------------------------------------------------------------------------------
	gen_radix_2_lpp_sw : if(last_pass_radix=1) generate		
sw_det:process(clk,global_clock_enable,p_tdl)is
		  begin
if((rising_edge(clk) and global_clock_enable='1'))then
				if(p_tdl(13)=int2ustd(n_passes,log2_n_passes)) then
					sel_lpp <= '1';
				else
					sel_lpp <= '0';
				end if;
			end if;
		end process sw_det;
sw_det_i:process(clk,global_clock_enable,p_tdl)is
		  begin
if((rising_edge(clk) and global_clock_enable='1'))then
				if(p_tdl(13)=int2ustd(n_passes,log2_n_passes)) then
					sel_lpp_i <= '1';
				else
					sel_lpp_i <= '0';
				end if;
			end if;
		end process sw_det_i;			
		
		sel_lpp_nm1 <= '0';
		
	end generate gen_radix_2_lpp_sw;
	-----------------------------------------------------------------------------------------------
	-- Centralized Control of Data And Address Switching
	-----------------------------------------------------------------------------------------------
	
	gen_add_se : if(nume=1) generate
		rdaddress_a_bus_ctrl_i <= rdaddr(0);
	end generate gen_add_se;
	
	gen_add_de : if(nume=2) generate
		rdaddress_a_bus_ctrl_i <= rdaddr(0) & rdaddr(1);
	end generate gen_add_de;
	
  
	
	ccc :  asj_fft_unbburst_sose_ctrl 
	generic map(
						nps => nps,
						mpr => mpr,
						apr => apr,
						nume => nume,
						abuspr => abuspr, --4*apr
						rbuspr => rbuspr, --4*mpr
						cbuspr => cbuspr --2*4*mpr
					)
	port map(			
global_clock_enable => global_clock_enable,
						clk 					      => clk,
						sel_wraddr_in 			=> sel_addr_in,
						sel_ram_in 					=> sel_ram_in,
						sel_lpp 					  => sel_lpp_i,
						sel_lpp_nm1 				=> sel_lpp_nm1,
						data_rdy            => data_rdy_vec(5),
						wraddr_i_sw    		=> wraddr_i,
						wraddr_sw      		=> wraddress_a_bus_ctrl_i,
						rdaddr_sw      		=> rdaddress_a_bus_ctrl_i,
						lpp_rdaddr_sw      => rdaddr_lpp_sw(0),
						ram_data_in_sw  		=> ram_data_in_sw,
						i_ram_data_in_sw   => i_ram_data_in,
						a_ram_data_out_bus  => a_ram_data_out_bus,
						a_ram_data_in_bus   => a_ram_data_in_bus,
						wraddress_a_bus     => wraddress_a_bus_ctrl,
						rdaddress_a_bus     => rdaddress_a_bus_ctrl,
						ram_data_out       => ram_data_out
			);
			
			rdaddr_lpp_sw(0) <= (others=>'0');
	-----------------------------------------------------------------------------------------------
  		
	---------------------------------------------------------------------------------	
	-- Debug Section
	---------------------------------------------------------------------------------
	--gen_dbg :for i in 0 to 3 generate
	--	ram_data_in_sw_debug(i,0) <= ram_data_in_sw(i)(2*mpr-1 downto mpr);
	--	ram_data_in_sw_debug(i,1) <= ram_data_in_sw(i)(mpr-1 downto 0);
	--	ram_data_out_sw_debug(i,0) <= ram_data_out_sw(i)(2*mpr-1 downto mpr);
	--	ram_data_out_sw_debug(i,1) <= ram_data_out_sw(i)(mpr-1 downto 0);
	--	ram_data_out_debug(i,0) <= ram_data_out(i)(2*mpr-1 downto mpr);
	--	ram_data_out_debug(i,1) <= ram_data_out(i)(mpr-1 downto 0);
	--	lpp_ram_data_out_sw_debug(i,0) <= lpp_ram_data_out_sw(i)(2*mpr-1 downto mpr);
	--	lpp_ram_data_out_sw_debug(i,1) <= lpp_ram_data_out_sw(i)(mpr-1 downto 0);
	--	lpp_ram_data_out_debug(i,0) <= lpp_ram_data_out(i)(2*mpr-1 downto mpr);
	--	lpp_ram_data_out_debug(i,1) <= lpp_ram_data_out(i)(mpr-1 downto 0);
	--	c_ram_data_in_debug(i,0) <= a_ram_data_in_bus((8-2*i)*mpr-1 downto (7-2*i)*mpr);
	--	c_ram_data_in_debug(i,1) <= a_ram_data_in_bus((7-2*i)*mpr-1 downto (6-2*i)*mpr);
	--	
	--end generate gen_dbg;
	---------------------------------------------------------------------------------
	
	
	-----------------------------------------------------------------------------------------------
	rden_a <= '1';
	-----------------------------------------------------------------------------------------------
	-- Single Output Engine Requires 1 RAM Block
	-----------------------------------------------------------------------------------------------
	gen_1_ram : if(nume=1) generate
	
		real_ram_in_dbg <= a_ram_data_in_bus(2*mpr-1 downto mpr);
		imag_ram_in_dbg <= a_ram_data_in_bus(mpr-1 downto 0);
		real_ram_out_dbg <= a_ram_data_out_bus(2*mpr-1 downto mpr);
		imag_ram_out_dbg <= a_ram_data_out_bus(mpr-1 downto 0);
		rdaddress_a_bus <= rdaddress_a_bus_ctrl;
		wraddress_a_bus <= wraddress_a_bus_ctrl;
		
		gen_M4K : if(mram=0) generate
	  	dat_A : asj_fft_1dp_ram
	  	generic map(
							device_family => device_family,
							apr => apr,
							mpr => mpr,
							rfd    => "AUTO"
						)
			port map(			
global_clock_enable => global_clock_enable,
							clk => clk,
							rdaddress => rdaddress_a_bus,
							wraddress	=> wraddress_a_bus,
							data_in		=> a_ram_data_in_bus,
							wren      => wren_a,
							rden      => rden_a,						
							data_out	=> a_ram_data_out_bus
				);
		end generate gen_M4K;
		
		gen_Mega : if(mram=1) generate
	  	dat_A : asj_fft_1dp_ram
	  	generic map(
							device_family => device_family,
							apr => apr,
							mpr => mpr,
							rfd    => "M-RAM"
						)
			port map(			
global_clock_enable => global_clock_enable,
							clk => clk,
							rdaddress => rdaddress_a_bus,
							wraddress	=> wraddress_a_bus,
							data_in		=> a_ram_data_in_bus,
							wren      => wren_a,
							rden      => rden_a,						
							data_out	=> a_ram_data_out_bus
				);
		end generate gen_Mega;
				
	
	end generate gen_1_ram;
			
	-----------------------------------------------------------------------------------------------
	-- Dual Output Engine Requires 2 RAM Blocks
	-----------------------------------------------------------------------------------------------
	gen_2_ram : if(nume=2) generate
	
	--		real_ram_in_1_dbg <= a_ram_data_in_bus(2*mpr-1 downto mpr);
	--		imag_ram_in_1_dbg <= a_ram_data_in_bus(mpr-1 downto 0);
	
			real_ram_out_1_dbg <= a_ram_data_out_bus(4*mpr-1 downto 3*mpr);
			imag_ram_out_1_dbg <= a_ram_data_out_bus(3*mpr-1 downto 2*mpr);
			real_ram_out_2_dbg <= a_ram_data_out_bus(2*mpr-1 downto mpr);
			imag_ram_out_2_dbg <= a_ram_data_out_bus(mpr-1 downto 0);
			real_ram_in_1_dbg <= a_ram_data_in_bus(4*mpr-1 downto 3*mpr);
			imag_ram_in_1_dbg <= a_ram_data_in_bus(3*mpr-1 downto 2*mpr);
			real_ram_in_2_dbg <= a_ram_data_in_bus(2*mpr-1 downto mpr);
			imag_ram_in_2_dbg <= a_ram_data_in_bus(mpr-1 downto 0);
			
			
			
			rdaddress_a_bus_x <= rdaddress_a_bus_ctrl(2*apr-1 downto apr);
			wraddress_a_bus_x <= wraddress_a_bus_ctrl(2*apr-1 downto apr);
			
			a_ram_data_in_bus_x <= a_ram_data_in_bus(4*mpr-1 downto 2*mpr);
			a_ram_data_out_bus(4*mpr-1 downto 2*mpr)<=a_ram_data_out_bus_x;
			
			gen_M4K : if(mram=0) generate
			
		  	dat_A_x : asj_fft_1dp_ram
		  	generic map(
								device_family => device_family,
								apr => apr,
								mpr => mpr,
								rfd    => "AUTO"
							)
				port map(			
global_clock_enable => global_clock_enable,
								clk => clk,
								rdaddress => rdaddress_a_bus_x,
								wraddress	=> wraddress_a_bus_x,
								data_in		=> a_ram_data_in_bus_x,
								wren      => wren_ad(0),
								rden      => rden_a,						
								data_out	=> a_ram_data_out_bus_x
					);
					
				dat_A_y : asj_fft_1dp_ram
			  generic map(
								device_family => device_family,
								apr => apr,
								mpr => mpr,
								rfd    => "AUTO"
							)
				port map(			
global_clock_enable => global_clock_enable,
								clk => clk,
								rdaddress => rdaddress_a_bus_y,
								wraddress	=> wraddress_a_bus_y,
								data_in		=> a_ram_data_in_bus_y,
								wren      => wren_ad(1),
								rden      => rden_a,						
								data_out	=> a_ram_data_out_bus_y
					);

			end generate gen_M4K;
			
			gen_Mega : if(mram=1) generate
			
		  	dat_A_x : asj_fft_1dp_ram
		  	generic map(
								device_family => device_family,
								apr => apr,
								mpr => mpr,
								rfd    => "M-RAM"
							)
				port map(			
global_clock_enable => global_clock_enable,
								clk => clk,
								rdaddress => rdaddress_a_bus_x,
								wraddress	=> wraddress_a_bus_x,
								data_in		=> a_ram_data_in_bus_x,
								wren      => wren_ad(0),
								rden      => rden_a,						
								data_out	=> a_ram_data_out_bus_x
					);
					
				dat_A_y : asj_fft_1dp_ram
			  generic map(
								device_family => device_family,
								apr => apr,
								mpr => mpr,
								rfd    => "M-RAM"
							)
				port map(			
global_clock_enable => global_clock_enable,
								clk => clk,
								rdaddress => rdaddress_a_bus_y,
								wraddress	=> wraddress_a_bus_y,
								data_in		=> a_ram_data_in_bus_y,
								wren      => wren_ad(1),
								rden      => rden_a,						
								data_out	=> a_ram_data_out_bus_y
					);

			
			end generate gen_Mega;
			
			rdaddress_a_bus_y <= rdaddress_a_bus_ctrl(apr-1 downto 0);
			wraddress_a_bus_y <= wraddress_a_bus_ctrl(apr-1 downto 0);
			a_ram_data_in_bus_y <= a_ram_data_in_bus(2*mpr-1 downto 0);
			a_ram_data_out_bus(2*mpr-1 downto 0)<=a_ram_data_out_bus_y;
					
	end generate gen_2_ram;			
			-----------------------------------------------------------------------------------------------
		
--		gen_Mega_input_stage : if(mram=1) generate
--		
--		rdaddress_a_mram <= rdaddress_a_bus_ctrl(apr-1 downto 0);
--		wraddress_a_mram <= wraddress_a_bus_ctrl(apr-1 downto 0);
--		
--	  dat_A : asj_fft_dpi_mram
--  	generic map(
--						apr => apr,
--						dpr => cbuspr,
--						bytesize => byte_size,
--						bpr => bpr
--					)
--		port map(			
--						clock => clk,
--						rdaddress => rdaddress_a_mram,
--						wraddress	=> wraddress_a_mram,
--						data		=> a_ram_data_in_bus,
--						byteena_a => byte_enable_i,
--						wren      => wren_a(0),
--						q	=> a_ram_data_out_bus
--			);
--			
--		
--				
--		end generate gen_Mega_input_stage;
		
    
    
  	
			
		-----------------------------------------------------------------------------------------------
		-- Read Address Generation
		-----------------------------------------------------------------------------------------------
    rd_adgen : asj_fft_dataadgen 
		generic map(
								nps 					=> nps,
								nume          => nume,
								arch          => 3,
								n_passes 			=> n_passes_m1,
								log2_n_passes => log2_n_passes,
								apr 					=> apr
					)
		port map(			
global_clock_enable => global_clock_enable,
								clk 					=> clk,
								k_count   	  => k_count,
								p_count       => p_count,
								rd_addr_a			=> rdaddr(0),
								rd_addr_b			=> rdaddr(1),
								rd_addr_c			=> open,
								rd_addr_d			=> open,
								sw_data_read  => open
						
			);
		-----------------------------------------------------------------------------------------------
  	-- During processing the addresses to write to memory banks are permutations 
		-- of the rdaddr
		-- In the single output engine case this is simply a delay of the generated readaddress
		-----------------------------------------------------------------------------------------------
			
			gen_wraddr_se : if(nume=1) generate		
			
offset_k_count:process(clk,global_clock_enable)is
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						if(reset='1') then
							k_count_wr_en <= '0';
						elsif(k_count=int2ustd(wr_ad_delay-2,apr)) then
							k_count_wr_en<='1';
						elsif(k_count_wr=int2ustd(2**apr-1,apr)) then
							k_count_wr_en<='0';
						else
							k_count_wr_en<=k_count_wr_en;
						end if;
						
						if(k_count_wr_en='1') then
							k_count_wr <= k_count_wr + int2ustd(1,apr);
						else
							k_count_wr <= (others=>'0');
						end if;
					end if;
				end process offset_k_count;
				
			
			wr_adgen : asj_fft_dataadgen 
				generic map(
								nps 					=> nps,
								nume          => nume,
								arch          => 3,
								n_passes 			=> n_passes_m1,
								log2_n_passes => log2_n_passes,
								apr 					=> apr
					)
				  port map(			
global_clock_enable => global_clock_enable,
								clk 					=> clk,
								k_count   	  => k_count_wr,
								p_count       => p_tdl(18),
								rd_addr_a			=> wraddr(0),
								rd_addr_b			=> open,
								rd_addr_c			=> open,
								rd_addr_d			=> open,
								sw_data_read  => open
						
				);
		 
			
			
			
			--ram_cxb_wr : asj_fft_tdl                          
			--	generic map(                                    
			--							mpr => apr,                    
			--							del => wr_ad_delay-1,
			--							srr => srr               
			--					)                                       
			--	port map( 	                                    
			--							clk 	=> clk,                       
			--							data_in 	=> rdaddr(0),
			--			 				data_out 	=> wraddr(0) 
			--			);                            
			
			
reg_wr:process(clk,global_clock_enable,wraddr(0))is
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						wraddress_a_bus_ctrl_i <= wraddr(0);					                                              
					end if;
				end process reg_wr;
			end generate gen_wraddr_se;
			
			gen_wraddr_de : if(nume=2) generate			              
			
				ram_cxb_wr : asj_fft_tdl                          
						generic map(                                    
												mpr => apr,                    
												del => wr_ad_delay-1,
												srr => srr                
										)                                       
						port map( 	                                    
global_clock_enable => global_clock_enable,
												clk 	=> clk,                       
												data_in 	=> rdaddr(0),
								 				data_out 	=> wraddr(0) 
								);                            
				
				
			
reg_wr:process(clk,global_clock_enable,wraddr(0))is
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
							wraddress_a_bus_ctrl_i <= wraddr(0) & wraddr(0);					                                              
					end if;
				end process reg_wr;
			end generate gen_wraddr_de;
			
					                                              
		-----------------------------------------------------------------------------------------------
		-- Single Output Engine Interface
		-----------------------------------------------------------------------------------------------
		gen_se : if(nume=1) generate
		
				ram_data_in <= (dro & dio);
				ram_data_in_sw <= ram_data_in;
			 
			 	data_in_bfp_real <= ram_data_out(2*mpr-1 downto mpr);
			 	data_in_bfp_imag <= ram_data_out(mpr-1 downto 0);    
			 
			 	
		   
		   
			
			 bfpdft : asj_fft_dft_bfp_sgl
		   generic map (	         
								    device_family => device_family,
								    nps => nps,
								    bfp => bfp,
								    nume => nume,
		   							mpr=> mpr,
		   							rbuspr => rbuspr,
		            		twr=> twr,
		            		fpr => fpr,
		            		mult_type => mult_type,
		            		mult_imp => mult_imp,
                            dsp_arch => dsp_arch,
		            		nstages=> 7,
		            		pipe => 1,
		            		rev =>0,
		            		cont => 0
			 )
		   port map(
global_clock_enable => global_clock_enable,
				 		        clk   		=> clk,
				 		        reset 		=> reset,
				 		        clken     => vcc,
				 		        sel       => k_count(1 downto 0),
				 		        next_pass => next_pass_d,
				 		        next_blk  => next_input_blk,
				 		        sel_lpp   => sel_lpp,
										alt_slb_i   => slb_last_i,
				 		        alt_slb_o   => slb_x_o,
				 				    data_real_i => data_in_bfp_real,
				 				    data_imag_i => data_in_bfp_imag,
				 				    twid_real	 =>  twiddle_data_real,
				 				    twid_imag	 => twiddle_data_imag,
				 				    data_real_o => dro,
				 				    data_imag_o => dio
				);
				
			
			
			gen_blk_float : if(bfp=1) generate	
				dual_eng_slb <= slb_x_o;	
			end generate gen_blk_float;
	
			gen_fixed : if(bfp=0) generate	
				dual_eng_slb <= (others=>'0');	
			end generate gen_fixed;		
	
			
			bfpc : asj_fft_bfp_ctrl 
			
			
		  generic map( 
		  						 nps => nps,
		  						 nume => nume,
		    				 	 fpr  => fpr,
		    				 	 cont => 0,
		    				 	 arch => 3
								)
		  port map(
global_clock_enable => global_clock_enable,
		  	     			 clk  => clk,
		       				 clken  => vcc,
		       				 reset 	=> reset,
		       				 next_pass => next_pass_d,
		       				 next_blk  => next_blk,
		       				 exp_en    => exp_en,
					 				 alt_slb_i => dual_eng_slb,
		       				 alt_slb_o => slb_last_i,
					     		 blk_exp_o => blk_exp
			);
			
			
			
			gen_new : if(newtw=1) generate
				
butterfly_twiddle:process(clk,global_clock_enable,reset,t1r,t1i)is
			    begin
if((rising_edge(clk) and global_clock_enable='1'))then
			    		if(reset='1') then
			    			twiddle_data_real <= '0' & (twr-2 downto 0=>'1');
			    			twiddle_data_imag <= (others=>'0');
			    			quad_del <= (others=>'0');
			    			quad_del_0 <= (others=>'0');
			    			quad_del_1 <= (others=>'0');
			    		else
			    			quad_del_0 <= quad;
			    			quad_del_1 <= quad_del_0;
			    			case quad_del_1(2 downto 1) is
			    				when "00" =>
			    					if(quad_del_1(0)='1') then
			    						twiddle_data_real <= '0' & (twr-2 downto 0=>'1');
											twiddle_data_imag <= (others=>'0');
										else
			    						twiddle_data_real <= t1r;
											twiddle_data_imag <= t1i;
										end if;
									when "01" =>
			    					if(quad_del_1(0)='1') then
			    						twiddle_data_imag <= '0' & (twr-2 downto 0=>'1');
											twiddle_data_real <= (others=>'0');
										else
											twiddle_data_real <= not(t1r)+int2ustd(1,twr);
											twiddle_data_imag <= t1i;
										end if;
									when "10" =>
			    					if(quad_del_1(0)='1') then
			    						twiddle_data_imag <= (others=>'0');
											twiddle_data_real <= '1' & (twr-2 downto 1=>'0') & '1';
										else
											twiddle_data_real <= not(t1r)+int2ustd(1,twr);
											twiddle_data_imag <= not(t1i)+int2ustd(1,twr);
										end if;
									when others=>
					    			twiddle_data_real <= '0' & (twr-2 downto 0=>'1');
					    			twiddle_data_imag <= (others=>'0');
					    	end case;
						  end if;
			    	end if;
		   end process butterfly_twiddle;
		   
		  
offset_ktw_count:process(clk,global_clock_enable)is
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						if(reset='1') then
							k_count_tw_en <= '0';
						elsif(k_count=int2ustd(twid_delay-2,apr)) then
							k_count_tw_en<='1';
						elsif(k_count_tw=int2ustd(2**apr-1,apr)) then
							k_count_tw_en<='0';
						else
							k_count_tw_en<=k_count_tw_en;
						end if;
						
						if(k_count_tw_en='1') then
							k_count_tw <= k_count_tw + int2ustd(1,apr);
						else
							k_count_tw <= (others=>'0');
						end if;
					end if;
				end process offset_ktw_count; 
			
			twid_factors : asj_fft_twadsogen_q 
			generic map(
									nps 			=> nps,
									nume      => nume,
									n_passes 	=> n_passes_m1,
									apr 			=> apr,
									log2_n_passes => log2_n_passes,
									tw_delay  => 1
							)
			port map (
global_clock_enable => global_clock_enable,
									clk 			=> clk,
									data_addr => k_count_tw,
									p_count   => p_tdl(10),
									tw_addr		=> twad_q,
									quad			=> quad
					);
			-- Twiddle ROM 
			twrom : asj_fft_1tdp_rom 
			generic map(
									device_family  => device_family,
									twr  => twr,
									twa  => twa,
									m512 => m512,
									rfc1 => rfc1,
									rfc2 => rfc2,
									rfc3 => rfc3,
									rfs1 => rfs1,
									rfs2 => rfs2,
									rfs3 => rfs3
								)
				port map(			
global_clock_enable => global_clock_enable,
									clk  => clk,
									twade => twad_q(twa-1 downto 0),
									twado => twad_q(2*twa-1 downto twa),
									t1r	 => t1r,
									t1i	 => t1i
					);
			end generate gen_new;
	 end generate gen_se;		
	 -----------------------------------------------------------------------------------------------
	 -----------------------------------------------------------------------------------------------
	 -----------------------------------------------------------------------------------------------
	 -- Dual Output Architecture Engine and Interface
	 -----------------------------------------------------------------------------------------------
		gen_de : if(nume=2) generate
		
				ram_data_in <= dro_x & dio_x  & dro_y & dio_y;
				ram_data_in_sw <= ram_data_in;
			 
			 	data_in_bfp_real_x <= ram_data_out(4*mpr-1 downto 3*mpr);
			 	data_in_bfp_imag_x <= ram_data_out(3*mpr-1 downto 2*mpr);    
			 	data_in_bfp_real_y <= ram_data_out(2*mpr-1 downto mpr);
			 	data_in_bfp_imag_y <= ram_data_out(mpr-1 downto 0);    
			 	
			 
			 	del_twid_sel : asj_fft_tdl 
				generic map( 
											mpr => 2,
											del   => 13+last_pass_radix,
											srr => srr                
									)
					port map( 	
global_clock_enable => global_clock_enable,
											clk 	=> clk,
											data_in 	=> k_count(1 downto 0),
							 				data_out 	=> sel_tw
							);
		
			 
butterfly_twiddle:process(clk,global_clock_enable,reset,sel_tw,t1re,t2re,t3re,t1ro,t2ro,t3ro,t1ie,t2ie,t3ie,t1io,t2io,t3io)is
		    begin
if((rising_edge(clk) and global_clock_enable='1'))then
		    		if(reset='1') then
		    			twiddle_data_real_x <= '0' & (twr-2 downto 0=>'1');
		    			twiddle_data_imag_x <= (others=>'0');
		    			twiddle_data_real_y <= '0' & (twr-2 downto 0=>'1');
		    			twiddle_data_imag_y <= (others=>'0');
		    		else
		    			case sel_tw is
		    				when "00" =>
				    			twiddle_data_real_x <= '0' & (twr-2 downto 0=>'1');
		    					twiddle_data_imag_x <= (others=>'0');
				    			twiddle_data_real_y <= '0' & (twr-2 downto 0=>'1');
		    					twiddle_data_imag_y <= (others=>'0');
		    				when "01" =>
				    			twiddle_data_real_x <= t1re;
							    twiddle_data_imag_x <= t1ie;
							    twiddle_data_real_y <= t1ro;
							    twiddle_data_imag_y <= t1io;
		    				when "10" =>
				    			twiddle_data_real_x <= t2re;
							    twiddle_data_imag_x <= t2ie;
							    twiddle_data_real_y <= t2ro;
							    twiddle_data_imag_y <= t2io;
		    				when "11" =>
				    			twiddle_data_real_x <= t3re;
							    twiddle_data_imag_x <= t3ie;
							    twiddle_data_real_y <= t3ro;
							    twiddle_data_imag_y <= t3io;
							  when others=>
				    			twiddle_data_real_x <= '0' & (twr-2 downto 0=>'1');
		    					twiddle_data_imag_x <= (others=>'0');
				    			twiddle_data_real_y <= '0' & (twr-2 downto 0=>'1');
		    					twiddle_data_imag_y <= (others=>'0');
							end case;
					  end if;
		    	end if;
		   end process butterfly_twiddle;
		   -----------------------------------------------------------------------------------------------
			 -- Engine 1
			 -----------------------------------------------------------------------------------------------
			 bfpdft_x : asj_fft_dft_bfp_sgl
		   generic map (	         
								    device_family => device_family,
								    nps => nps,
								    nume => nume,
		   							mpr=> mpr,
		   							rbuspr => rbuspr,
		            		twr=> twr,
		            		fpr => fpr,
		            		mult_type => mult_type,
		            		mult_imp => mult_imp,
                            dsp_arch => dsp_arch,
		            		nstages=> 7,
		            		pipe => 1,
		            		rev =>0,
		            		cont => 0
			 )
		   port map(
global_clock_enable => global_clock_enable,
				 		        clk   		=> clk,
				 		        reset 		=> reset,
				 		        clken     => vcc,
				 		        sel       => k_count(1 downto 0),
				 		        next_pass => next_pass_d,
				 		        next_blk  => next_input_blk,
				 		        sel_lpp   => sel_lpp,
										alt_slb_i   => slb_last_i,
				 		        alt_slb_o   => slb_x_o,
				 				    data_real_i => data_in_bfp_real_x,
				 				    data_imag_i => data_in_bfp_imag_x,
				 				    twid_real	 =>  twiddle_data_real_x,
				 				    twid_imag	 => twiddle_data_imag_x,
				 				    data_real_o => dro_x,
				 				    data_imag_o => dio_x
				);
			 -----------------------------------------------------------------------------------------------
			 -- Engine 2
			 -- Reverse Order in Engine
			 -- N/2,3N/4,0,N/4
			 -----------------------------------------------------------------------------------------------
			 bfpdft_y : asj_fft_dft_bfp_sgl
		   generic map (	         
								    device_family => device_family,
								    nps => nps,
								    nume => nume,
		   							mpr=> mpr,
		   							rbuspr => rbuspr,
		            		twr=> twr,
		            		fpr => fpr,
		            		mult_type => mult_type,
		            		mult_imp => mult_imp,
                            dsp_arch => dsp_arch,
		            		nstages=> 7,
		            		pipe => 1,
		            		rev =>1,
		            		cont => 0
			 )
		   port map(
global_clock_enable => global_clock_enable,
				 		        clk   		=> clk,
				 		        reset 		=> reset,
				 		        clken     => vcc,
				 		        sel       => k_count(1 downto 0),
				 		        next_pass => next_pass_d,
				 		        next_blk  => next_input_blk,
				 		        sel_lpp   => sel_lpp,
										alt_slb_i   => slb_last_i,
				 		        alt_slb_o   => slb_y_o,
				 				    data_real_i => data_in_bfp_real_y,
				 				    data_imag_i => data_in_bfp_imag_y,
				 				    twid_real	 =>  twiddle_data_real_y,
				 				    twid_imag	 => twiddle_data_imag_y,
				 				    data_real_o => dro_y,
				 				    data_imag_o => dio_y
				);
				
			gen_blk_float : if(bfp=1) generate	
				dual_eng_slb <= slb_x_o & slb_y_o;
			end generate gen_blk_float;
	
			gen_fixed : if(bfp=0) generate	
				dual_eng_slb <= (others=>'0');	
			end generate gen_fixed;		
	
			
			bfpc : asj_fft_bfp_ctrl 
		  generic map( 
		  						 nps => nps,
		  						 nume => nume,
		    				 	 fpr  => fpr,
		    				 	 cont => 0,
		    				 	 arch => 3
								)
		  port map(
global_clock_enable => global_clock_enable,
		  	     			 clk  => clk,
		       				 clken  => vcc,
		       				 reset 	=> reset,
		       				 next_pass => next_pass_d,
		       				 next_blk  => next_blk,
		       				 exp_en    => exp_en,
					 				 alt_slb_i => dual_eng_slb,
		       				 alt_slb_o => slb_last_i,
					     		 blk_exp_o => blk_exp
			);
			
			twid_factors : asj_fft_twadsogen 
			generic map(
									nps 			=> nps,
									nume      => nume,
									n_passes 	=> n_passes_m1,
									apr 			=> apr+1,
									log2_n_passes => log2_n_passes,
									tw_delay  => twid_delay
							)
			port map (
global_clock_enable => global_clock_enable,
									clk 			=> clk,
									data_addr   => rdaddr(0),
									p_count   => p_tdl(10),
									tw_addr		=> twad
					);
			-----------------------------------------------------------------------------------------------
			-- Dual Port Twiddle ROM Addresses
			-----------------------------------------------------------------------------------------------		
			twade <= twad(2*twa-1 downto twa);
			twado <= twad(twa-1 downto 0);
			-----------------------------------------------------------------------------------------------
			-- Twiddle ROM 
			-----------------------------------------------------------------------------------------------
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
			port map(			clk 			=> clk,
global_clock_enable => global_clock_enable,
						twade   	  => twade,
						twado   	  => twado,
						t1re			=> t1re,
						t2re			=> t2re,
						t3re			=> t3re,
						t1ie			=> t1ie,
						t2ie			=> t2ie,
						t3ie			=> t3ie,
						t1ro			=> t1ro,
						t2ro			=> t2ro,
						t3ro			=> t3ro,
						t1io			=> t1io,
						t2io			=> t2io,
						t3io			=> t3io
			);
	
	end generate gen_de;		
	-----------------------------------------------------------------------------------------------
	--lpp_wrcnt_en <= wc_vec(wraddr_cd_en);
	---------------------------------------------------------------------------------------------------
	--Radix 4  Last Pass Control 
	-----------------------------------------------------------------------------------------------
	gen_radix_4_last_pass : if(last_pass_radix=0) generate
	 
	 		--lpp_c_addr_en <= lpp_c_en_early and lpp_c_en_vec(3);
	 		--lpp_c_data_en <= lpp_c_en_vec(1) and lpp_c_en_vec(6);
	 		-----------------------------------------------------------------------------------------------
	 		-- Single Output Architecture
	 		-----------------------------------------------------------------------------------------------
	 		gen_data_out_lpp_se : if(nume=1) generate
--sel_lpp_data:process(clk,global_clock_enable,fft_s2_cur,a_ram_data_out_bus)is
			--		begin
--if((rising_edge(clk) and global_clock_enable='1'))then
			--				case fft_s2_cur is
			--					when IDLE =>
			--						lpp_ram_data_out <= (others=>'0');
			--					when FIRST_LPP=>
			--						lpp_ram_data_out <= a_ram_data_out_bus(2*mpr-1 downto 0);
			--					when LPP_OUTPUT_RDY =>
			--  					lpp_ram_data_out <= a_ram_data_out_bus(2*mpr-1 downto 0);
			--  				when LPP_DONE =>
			--						lpp_ram_data_out <= a_ram_data_out_bus(2*mpr-1 downto 0);
			--  				when others =>				
			--						lpp_ram_data_out <= (others=>'0');
			--  			end case;
			--  		end if;
			--  	end process sel_lpp_data;
			  
--sel_lpp_data:process(clk,global_clock_enable,reset,a_ram_data_out_bus)is
				--	begin
--if((rising_edge(clk) and global_clock_enable='1'))then
				--			if(reset='1') then
				--				lpp_ram_data_out <= (others=>'0');
				--			else
				--				lpp_ram_data_out <= a_ram_data_out_bus(2*mpr-1 downto 0);
			  --			end if;
			  --		end if;
			  --	end process sel_lpp_data;
			  
			  lpp_ram_data_out <= a_ram_data_out_bus(2*mpr-1 downto 0);
			  
			  	
	  	end generate gen_data_out_lpp_se;
	  	-----------------------------------------------------------------------------------------------
	  	-- Dual Output Architecture
	  	-----------------------------------------------------------------------------------------------
	  	gen_data_out_lpp_de : if(nume=2) generate
	  	
sel_lpp_data:process(clk,global_clock_enable,fft_s2_cur,a_ram_data_out_bus,output_count)is
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case fft_s2_cur is
							when IDLE =>
								lpp_ram_data_out <= (others=>'0');
							when FIRST_LPP=>
								lpp_ram_data_out <= a_ram_data_out_bus(4*mpr-1 downto 2*mpr);
							when LPP_OUTPUT_RDY=>
								-- 4 for 256
								-- 6 for 1024
								-- 8 for 4096
								-- 10 for 16384 
								if(output_count(log2_nps-4)='0') then
			  					lpp_ram_data_out <= a_ram_data_out_bus(4*mpr-1 downto 2*mpr);
			  				else
			  					lpp_ram_data_out <= a_ram_data_out_bus(2*mpr-1 downto 0);
			  				end if;
							when LPP_DONE =>
								lpp_ram_data_out <= a_ram_data_out_bus(2*mpr-1 downto 0);
		  				when others =>				
		  					lpp_ram_data_out <= (others=>'0');
		  			end case;
		  		end if;
		  	end process sel_lpp_data;
		  end generate gen_data_out_lpp_de;
	  	-----------------------------------------------------------------------------------------------
		 	 
			
		end generate gen_radix_4_last_pass;	 
	  ---------------------------------------------------------------------------------------------------
	  --Radix 2  Last Pass Processor 
	  -----------------------------------------------------------------------------------------------
	  --Read Address Generation
	  ---------------------------------------------------------------------------------------------------
	  gen_radix_2_last_pass : if(last_pass_radix=1) generate
	 		--rdaddr_lpp_sw(0) <= rdaddr_lpp(0);
	  	--lpp_c_addr_en <= lpp_c_en_early and lpp_c_en_vec(3);
	 		--lpp_c_data_en <= lpp_c_en_vec(1) and lpp_c_en_vec(6);
	 
			-----------------------------------------------------------------------------------------------
	 		-- Single Output Architecture
	 		-----------------------------------------------------------------------------------------------
	 		gen_data_out_lpp_se : if(nume=1) generate
--sel_lpp_data:process(clk,global_clock_enable,fft_s2_cur,a_ram_data_out_bus)is
				--	begin
--if((rising_edge(clk) and global_clock_enable='1'))then
				--			case fft_s2_cur is
				--				when IDLE =>
				--					lpp_ram_data_out <= (others=>'0');
				--				when FIRST_LPP=>
				--					lpp_ram_data_out <= a_ram_data_out_bus(2*mpr-1 downto 0);
				--				when LPP_OUTPUT_RDY =>
			  --					lpp_ram_data_out <= a_ram_data_out_bus(2*mpr-1 downto 0);
			  --				when LPP_DONE =>
				--					lpp_ram_data_out <= a_ram_data_out_bus(2*mpr-1 downto 0);
			  --				when others =>				
				--					lpp_ram_data_out <= (others=>'0');
			  --			end case;
			  --		end if;
			  --	end process sel_lpp_data;
--sel_lpp_data:process(clk,global_clock_enable,reset,a_ram_data_out_bus)is
				--	begin
--if((rising_edge(clk) and global_clock_enable='1'))then
				--			if(reset=='1') then
				--				lpp_ram_data_out <= (others=>'0');
				--			else
				--				lpp_ram_data_out <= a_ram_data_out_bus(2*mpr-1 downto 0);
			  --			end if;
			  --		end if;
			  --	end process sel_lpp_data;
			  lpp_ram_data_out <= a_ram_data_out_bus(2*mpr-1 downto 0);

	  	end generate gen_data_out_lpp_se;
	  	-----------------------------------------------------------------------------------------------
	  	-- Dual Output Architecture
	  	-----------------------------------------------------------------------------------------------
	  	gen_data_out_lpp_de : if(nume=2) generate
	  	
sel_lpp_data:process(clk,global_clock_enable,fft_s2_cur,output_count,a_ram_data_out_bus)is
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case fft_s2_cur is
							when IDLE =>
								lpp_ram_data_out <= (others=>'0');
							when FIRST_LPP=>
								lpp_ram_data_out <= a_ram_data_out_bus(4*mpr-1 downto 2*mpr);
							when LPP_OUTPUT_RDY=>
								-- 5 for 128
								-- 7 for 512
								-- 9 for 2048
								if(output_count(log2_nps-2)='0') then
			  					lpp_ram_data_out <= a_ram_data_out_bus(4*mpr-1 downto 2*mpr);
			  				else
			  					lpp_ram_data_out <= a_ram_data_out_bus(2*mpr-1 downto 0);
			  				end if;
							when LPP_DONE =>
								lpp_ram_data_out <= a_ram_data_out_bus(2*mpr-1 downto 0);
		  				when others =>				
		  					lpp_ram_data_out <= (others=>'0');
		  			end case;
		  		end if;
		  	end process sel_lpp_data;
		  end generate gen_data_out_lpp_de;
	  	
	  	

	    
		end generate gen_radix_2_last_pass;					
	  
	 	
		
		-----------------------------------------------------------------------------------------------
		-----------------------------------------------------------------------------------------------
		-----------------------------------------------------------------------------------------------
		
		
process(clk,global_clock_enable,reset,fft_dirn,lpp_ram_data_out,val_out,eop_out,sop_out,oe)
		   begin
if((rising_edge(clk) and global_clock_enable='1'))then
		   		if(reset='1') then
		   			fft_real_out<=(others=>'0');
		   			fft_imag_out<=(others=>'0');
		   			master_source_ena         <= '0';
		   			master_source_sop         <= '0'; 
		   			master_source_eop         <= '0'; 
		   		else
		   			if(oe='1') then
		   				if(fft_dirn='0') then
		   					fft_real_out<=lpp_ram_data_out(2*mpr-1 downto mpr);
		   					fft_imag_out<=lpp_ram_data_out(mpr-1 downto 0);
		   				else
		   					fft_real_out<=lpp_ram_data_out(mpr-1 downto 0);
		   					fft_imag_out<=lpp_ram_data_out(2*mpr-1 downto mpr);
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
		
flt_exp:process(clk,global_clock_enable,reset,oe,blk_exp)is
			   begin
if((rising_edge(clk) and global_clock_enable='1'))then
			   		if(reset='1') then
			   			exponent_out <= (others=>'0');
			   		else
			   			if(oe='1') then
			   				exponent_out <= blk_exp(fpr+1 downto 0);
			   			else
			   				exponent_out <= (others=>'0');
			   			end if;
			   		end if;
			   	end if;
			   end process flt_exp;
			  
		end generate gen_blk_float_out;
		-----------------------------------------------------------------------------------------------
		-- Fixed Point
		-----------------------------------------------------------------------------------------------
		gen_fixed_out : if(bfp=0) generate
		  exponent_out <=(others=>'0');
		end generate gen_fixed_out;  		
		-----------------------------------------------------------------------------------------------  	
   
		   
oe_ctrl:process(clk,global_clock_enable,fft_s2_cur)is
		   begin
if((rising_edge(clk) and global_clock_enable='1'))then
		   		if(fft_s2_cur=IDLE) then
		   			oe <='0';
		   			sop_out <= '0';
		   			eop_out <= '0';
		   			val_out <= '0';
		   		elsif(fft_s2_cur=WAIT_FOR_LPP_INPUT) then
		   			oe <='0';
		   			sop_out <= '0';
		   			eop_out <= '0';
		   			val_out <= '0';
		   		elsif(fft_s2_cur=START_LPP) then
		   			oe <='0';
		   			sop_out <= '0';
		   			eop_out <= '0';
		   			val_out <= '0';
		   		elsif(fft_s2_cur=FIRST_LPP) then
		   			oe <='1';
		   			sop_out <= '1';
		   			eop_out <= '0';
		   			val_out <= '1';
		   		elsif(fft_s2_cur=LPP_OUTPUT_RDY) then
		   			oe <='1';
		   			sop_out <= '0';
		   			eop_out <= '0';
		   			val_out <= '1';
		   		elsif(fft_s2_cur=LPP_DONE) then
		   			oe <='1';
		   			sop_out <= '0';
		   			eop_out <= '1';
		   			val_out <= '1';
		   		else
		   			oe <='0';
		   			sop_out <= '0';
		   			eop_out <= '0';
		   			val_out <= '0';
		   		end if;
		   	end if;
		   end process oe_ctrl;
		
		-----------------------------------------------------------------------------------------------
		-- Transition to State of First Last Pass Processor Output is controlled by assertion of sop_d
		-----------------------------------------------------------------------------------------------
		gen_sel_sop_r2:if(last_pass_radix=1) generate
		
		gen_sbc_se : if(nume=1) generate
			sbc<=int2ustd(19,5);
delay_sop:process(clk,global_clock_enable,fft_s2_cur,del_sop_cnt,sbc)is
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						if(fft_s2_cur=START_LPP) then
							del_sop_cnt <= del_sop_cnt + int2ustd(1,5);
							if(del_sop_cnt=sbc) then
								sop_de<='1';
							else
								sop_de<='0';
							end if;
						else
							del_sop_cnt <=(others=>'0');
							sop_de<='0';
						end if;
					end if;
				end process delay_sop;
	 
exp_en_ctrl:process(clk,global_clock_enable,sop_de)is
			 	begin
if((rising_edge(clk) and global_clock_enable='1'))then
				  	exp_en <=sop_de;
				  	sop_d  <=sop_de;
				  end if;
				end process exp_en_ctrl;   	
		end generate gen_sbc_se;
		
		gen_sbc_de : if(nume=2) generate
				sbc<=int2ustd(22,5);
delay_sop:process(clk,global_clock_enable,fft_s2_cur,del_sop_cnt,sbc)is
					begin
if((rising_edge(clk) and global_clock_enable='1'))then
							if(fft_s2_cur=START_LPP) then
								del_sop_cnt <= del_sop_cnt + int2ustd(1,5);
								if(del_sop_cnt=sbc) then
									sop_de<='1';
								else
									sop_de<='0';
								end if;
							else
								del_sop_cnt <=(others=>'0');
								sop_de<='0';
							end if;
						end if;
					end process delay_sop;
		 
exp_en_ctrl:process(clk,global_clock_enable,sop_de)is
				  	begin
if((rising_edge(clk) and global_clock_enable='1'))then
				      		exp_en <=block_done;
				      		sop_d  <=sop_de;
				    	end if;
				end process exp_en_ctrl;   	
			end generate gen_sbc_de; 
	end generate gen_sel_sop_r2;
		-----------------------------------------------------------------------------------------------
		-- Block Exponent Output Enable, exp_en needs to be triggered one cycle earlier in radix 4
		-----------------------------------------------------------------------------------------------
		gen_sel_sop_r4:if(last_pass_radix=0) generate
		
		gen_sbc_se : if(nume=1) generate
		  -- N = 256 => sbc = 18
			sbc<=int2ustd(19,5);
delay_sop:process(clk,global_clock_enable,fft_s2_cur,del_sop_cnt,sbc)is
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						if(fft_s2_cur=START_LPP) then
							del_sop_cnt <= del_sop_cnt + int2ustd(1,5);
							if(del_sop_cnt=sbc) then
								sop_de<='1';
							else
								sop_de<='0';
							end if;
						else
							del_sop_cnt <=(others=>'0');
							sop_de<='0';
						end if;
					end if;
				end process delay_sop;
	 
exp_en_ctrl:process(clk,global_clock_enable,sop_de)is
		  	begin
if((rising_edge(clk) and global_clock_enable='1'))then
		      		exp_en <=sop_de;
		      		sop_d  <=sop_de;
		    	end if;
		  	end process exp_en_ctrl;
		end generate gen_sbc_se;
		
		gen_sbc_de : if(nume=2) generate
			sbc<=int2ustd(22,5);
delay_sop:process(clk,global_clock_enable,fft_s2_cur,del_sop_cnt,sbc)is
					begin
if((rising_edge(clk) and global_clock_enable='1'))then
							if(fft_s2_cur=START_LPP) then
								del_sop_cnt <= del_sop_cnt + int2ustd(1,5);
								if(del_sop_cnt=sbc) then
									sop_de<='1';
								else
									sop_de<='0';
								end if;
							else
								del_sop_cnt <=(others=>'0');
								sop_de<='0';
							end if;
						end if;
					end process delay_sop;
		 
exp_en_ctrl:process(clk,global_clock_enable,sop_de)is
			  	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			      		exp_en <=block_done;
			      		sop_d  <=sop_de;
			    	end if;
			  	end process exp_en_ctrl;
		end generate gen_sbc_de;
	end generate gen_sel_sop_r4;
	-----------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------
	--IDLE,WAIT_FOR_LPP_INPUT,START_LPP,LPP_OUTPUT_RDY_1
fsm_2:process(clk,global_clock_enable,reset,block_done,master_source_dav,fft_s2_cur,sop_d,output_count)is
		    	begin
if((rising_edge(clk) and global_clock_enable='1'))then
		    			if(reset='1') then
		    				fft_s2_cur <= IDLE;
		    		  else
				  		case fft_s2_cur is
				  			when IDLE =>
				  			  fft_s2_cur <= WAIT_FOR_LPP_INPUT;
				  			when WAIT_FOR_LPP_INPUT =>
				  				if(block_done='1' and master_source_dav='1') then
				  					fft_s2_cur <= START_LPP;
				  				else
				  					fft_s2_cur <= WAIT_FOR_LPP_INPUT;
				  				end if;
				  			when START_LPP =>
				  				if(sop_d='1') then
				  					fft_s2_cur <= FIRST_LPP;
				  				else
				  					fft_s2_cur <= START_LPP;
				  				end if;
				  			when FIRST_LPP=>
				  					fft_s2_cur <= LPP_OUTPUT_RDY;
				  			when LPP_OUTPUT_RDY=>
				  				if(output_count=int2ustd((2**apri)-2,apri)) then
				  					fft_s2_cur <=LPP_DONE;
				  				else
				  					fft_s2_cur <=LPP_OUTPUT_RDY;
				  				end if;
				  			when LPP_DONE =>
				  					fft_s2_cur <=WAIT_FOR_LPP_INPUT;
				  			when others =>
				  				fft_s2_cur <= IDLE;
				  		end case;
				  	end if;
		  	 end if;
		  	end process fsm_2;
		
		  
output_sample_counter:process(clk,global_clock_enable,fft_s2_cur,output_count)is
		  		begin
if((rising_edge(clk) and global_clock_enable='1'))then
		  				if(fft_s2_cur=FIRST_LPP or fft_s2_cur=LPP_OUTPUT_RDY) then
		  					output_count <= output_count + int2ustd(1,apri);
		  				else
		  					output_count <= (others=>'0');
		  				end if;
		  			end if;
		  		end process output_sample_counter;
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
			
regfftdirni:process(clk,global_clock_enable,fft_dirn,master_sink_sop,inv_i)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(master_sink_sop='1') then
						fft_dirn <= inv_i;
					else
						fft_dirn <= fft_dirn;
					end if;
				end if;
			end process regfftdirni;
						
		del_input_blk_indicator : if(nps>1024) generate
						
		delay_next_block : asj_fft_tdl_bit
		generic map( 
							 		del   => 1
							)
			port map( 	
global_clock_enable => global_clock_enable,
									clk 	=> clk,
									data_in 	=> next_blk,
					 				data_out 	=> next_input_blk
					);
		
	end generate del_input_blk_indicator;
		
	no_del_input_blk : if(nps<=1024) generate
						
		delay_next_block : asj_fft_tdl_bit
		generic map( 
							 		del   => 1
							)
			port map( 	
global_clock_enable => global_clock_enable,
									clk 	=> clk,
									data_in 	=> next_blk,
					 				data_out 	=> next_input_blk
					);
		
	end generate no_del_input_blk;
	
	
	-----------------------------------------------------------------------------------------------
	gen_fsm_1 : if(which_fsm=1) generate
	
ena_gen:process(clk,global_clock_enable,fft_s1_cur,master_sink_dav)is
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
							when WAIT_FOR_INPUT =>		
								master_sink_ena <='1';
							when WRITE_INPUT =>	
								master_sink_ena <='1';
							when EARLY_DONE	=>
								master_sink_ena <='0';
							when DONE_WRITING =>	
								master_sink_ena <='0';
							when NO_WRITE =>	
								master_sink_ena <='0';
							when FFT_PROCESS_A =>
								master_sink_ena <='0';
							when others =>
								master_sink_ena <='1';
						end case;
					end if;
				end if;
			end process ena_gen;
						
	
		   
fsm_1:process(clk,global_clock_enable,reset,master_sink_dav,master_sink_val,master_sink_sop,data_rdy_vec,fft_s1_cur,next_blk,dsw,next_input_blk,eop_out)is
		  	begin
if((rising_edge(clk) and global_clock_enable='1'))then
		  			if(reset='1') then
		  				fft_s1_cur <= IDLE;
		  			else
			  			case fft_s1_cur is
				  			when IDLE =>
				  				if(master_sink_dav='1') then
				  			  	fft_s1_cur <= WAIT_FOR_INPUT;
				  			  else
				  			  	fft_s1_cur <= IDLE;
				  			  end if;
				  			when WAIT_FOR_INPUT =>
				  				if(master_sink_sop='1' and master_sink_val='1') then
				  					fft_s1_cur <= WRITE_INPUT;
				  				else
				  					fft_s1_cur <= WAIT_FOR_INPUT;
				  				end if;
				  			when WRITE_INPUT =>
				  				if(dsw='1') then
				  					fft_s1_cur <= EARLY_DONE;
				  				else
				  					fft_s1_cur <= WRITE_INPUT;
				  				end if;
				  			when EARLY_DONE =>
				  				if(next_blk='1') then
				  					fft_s1_cur <= DONE_WRITING;
				  				else
				  					fft_s1_cur <= EARLY_DONE;
				  				end if;
				  			when DONE_WRITING =>
				  				if(next_input_blk='1') then
				  					fft_s1_cur <= NO_WRITE;
				  				else
										fft_s1_cur <= DONE_WRITING;			  						
				  				end if;
				  			when NO_WRITE =>
				  				if(data_rdy_vec(24)='1') then
				  					fft_s1_cur <= FFT_PROCESS_A;
				  				else
				  					fft_s1_cur <= NO_WRITE;
				  				end if;
				  			when FFT_PROCESS_A =>
				  				if(eop_out='1') then
				  					fft_s1_cur <=IDLE;
				  				else
				  					fft_s1_cur <= FFT_PROCESS_A;
				  				end if;
				  			when others =>
				  				fft_s1_cur <= IDLE;
				  		end case;
				  	end if;
				  end if;
		  end process fsm_1;
	  end generate gen_fsm_1;
		-----------------------------------------------------------------------------------------------
		gen_fsm_2 : if(which_fsm=2) generate
ena_gen:process(clk,global_clock_enable,fft_s1_cur,master_sink_dav)is
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case fft_s1_cur is
							when IDLE =>
								if(master_sink_dav='1') then
									master_sink_ena <='1';
								else
									master_sink_ena <='0';
								end if;
							when WAIT_FOR_INPUT =>		
								master_sink_ena <='1';
							when WRITE_INPUT =>	
								master_sink_ena <='1';
							when EARLY_DONE	=>
								master_sink_ena <='0';
							when DONE_WRITING =>	
								master_sink_ena <='0';
							when NO_WRITE =>	
								master_sink_ena <='0';									
							when FFT_PROCESS_A =>
								master_sink_ena <='0';
							when others =>
								master_sink_ena <='1';
						end case;
					end if;
				end process ena_gen;
		   
fsm_1:process(clk,global_clock_enable,reset,master_sink_sop,master_sink_dav,master_sink_val,fft_s1_cur,dsw,next_blk,next_input_blk,next_pass,p_count,nbc)is
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
						  			if(master_sink_sop='1' and master_sink_val='1') then
						  				fft_s1_cur <= WRITE_INPUT;
						  			end if;
						  		when WRITE_INPUT =>
						  			if(input_sample_counter=int2ustd(2**(apri)-3, apri)) then
						  				fft_s1_cur <= EARLY_DONE;
						  			end if;
						  		when EARLY_DONE =>
										if(input_sample_counter=int2ustd(2**(apri)-1, apri) and master_sink_val='1') then
						  				fft_s1_cur <= DONE_WRITING;
						  			end if;
						  		when DONE_WRITING =>
										if(next_input_blk='1') then
			  							fft_s1_cur <= NO_WRITE;
			  						end if;
			  					when NO_WRITE =>
			  						if(data_rdy_vec(24)='1') then
			  							fft_s1_cur <= FFT_PROCESS_A;
			  						end if;
					  			when FFT_PROCESS_A =>
					  				if(eop_out='1') then
					  					fft_s1_cur <=IDLE;
					  				end if;
						  		when others =>
						  			fft_s1_cur <= IDLE;
						  	end case;
							end if;
					  end if;
			  	end process fsm_1;
			  	
loader:process(clk,global_clock_enable,fft_s1_cur)is
		   		begin
if((rising_edge(clk) and global_clock_enable='1'))then
		   				if(fft_s1_cur=WRITE_INPUT or fft_s1_cur=EARLY_DONE) then
		   					if(master_sink_val='1') then
		   						input_sample_counter <= input_sample_counter + int2ustd(1,apri);
								else                                          
									input_sample_counter <= input_sample_counter;
								end if;
							elsif(fft_s1_cur=WAIT_FOR_INPUT) then
									input_sample_counter <= int2ustd(1,apri);
							else
									input_sample_counter <= (others=>'0');
							end if;
						end if;
				 end process loader;
	end generate gen_fsm_2;
	-----------------------------------------------------------------------------------------------
		    
	
  
end transform;











