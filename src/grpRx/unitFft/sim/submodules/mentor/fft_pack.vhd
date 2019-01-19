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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/pkg/fft_pack.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package fft_pack is

    function LOG2_CEIL(a : in integer) return integer;
    function LOG2_FLOOR(a : in integer) return integer;
    function LOG4_CEIL(a : in integer) return integer;
    function LOG4_FLOOR(a : in integer) return integer;
    function LOG10_CEIL(a : in integer) return integer;
    function GET_BYTE_SIZE(dpr : in integer) return integer;
    function max (L, R: integer) return integer;
    function minimum (L, R: integer) return integer;
    function abs_aminusb (L, R: integer) return integer;
    function sgn_ex(inval : std_logic_vector; w : integer; b : integer) return std_logic_vector;
    function int2ustd(value : integer; width : integer) return std_logic_vector;
    function int2bit(value : integer) return std_logic;
    --------------------------------------------------------------------------------
    
    
    component asj_fft_mult_add 
			generic(
				device_family : string;
				mpr : integer :=16;
				twr : integer :=12;
				dirn : string :="SUB"
			);
			port
			(
global_clock_enable : in std_logic;
				clock0		: in std_logic  := '1';
				dataa_0		: in std_logic_vector (mpr-1 downto 0) :=  (others => '0');
				dataa_1		: in std_logic_vector (mpr-1 downto 0) :=  (others => '0');
				datab_0		: in std_logic_vector (twr-1 downto 0) :=  (others => '0');
				datab_1		: in std_logic_vector (twr-1 downto 0) :=  (others => '0');
				result		: out std_logic_vector (twr+mpr downto 0)
			);
		end component;
		component asj_fft_lcm_mult 
    generic (mpr : integer :=24;
    				 twr : integer := 24;
    				 use_dedicated_for_all : integer :=0;
    				 pipe : integer :=1
		);
    port (
global_clock_enable : in std_logic;
         clk   				 : in std_logic;
         dataa : in std_logic_vector(mpr-1 downto 0);
		     datab : in std_logic_vector(twr-1 downto 0);
		     result : out std_logic_vector(mpr+twr-1 downto 0)
		     );
		end component;
		
		component asj_fft_lcm_mult_2m 
    generic (mpr : integer :=24;
    				 twr : integer := 18;
    				 use_dedicated_for_all : integer :=0;
    				 pipe : integer :=1
		);
    port (
global_clock_enable : in std_logic;
         clk   				 : in std_logic;
         dataa : in std_logic_vector(mpr-1 downto 0);
		     datab : in std_logic_vector(twr-1 downto 0);
		     result : out std_logic_vector(mpr+twr-1 downto 0)
		     );
		end component;

        component apn_fft_mult_cpx
			generic(
				mpr : integer :=27;
				twr : integer :=25
			);
			port
			(
				clk         : in std_logic;
                reset       : in std_logic;
                global_clock_enable : in std_logic;
				a		    : in std_logic_vector (mpr-1 downto 0) :=  (others => '0');
				b		    : in std_logic_vector (mpr-1 downto 0) :=  (others => '0');
				c		    : in std_logic_vector (twr-1 downto 0) :=  (others => '0');
				d	    	: in std_logic_vector (twr-1 downto 0) :=  (others => '0');
				rout		: out std_logic_vector (twr+mpr downto 0);
                iout        : out std_logic_vector (twr+mpr downto 0) 
			);
		end component;

        component apn_fft_mult_cpx_1825
			generic(
				mpr : integer :=25;
				twr : integer :=18
			);
			port
			(
				clk         : in std_logic;
                reset       : in std_logic;
                global_clock_enable : in std_logic;
				a_r		    : in std_logic_vector (mpr-1 downto 0) :=  (others => '0');
				a_i		    : in std_logic_vector (mpr-1 downto 0) :=  (others => '0');
				b_r		    : in std_logic_vector (twr-1 downto 0) :=  (others => '0');
				b_i	    	: in std_logic_vector (twr-1 downto 0) :=  (others => '0');
				p_r	    	: out std_logic_vector (twr+mpr downto 0);
                p_i         : out std_logic_vector (twr+mpr downto 0) 
			);
		end component;

        component apn_fft_mult_can
			generic(
				mpr : integer :=27;
				twr : integer :=25
			);
			port
			(
				clk         : in std_logic;
                reset       : in std_logic;
                global_clock_enable : in std_logic;
				a		    : in std_logic_vector (mpr-1 downto 0) :=  (others => '0');
				b		    : in std_logic_vector (mpr-1 downto 0) :=  (others => '0');
				c		    : in std_logic_vector (twr-1 downto 0) :=  (others => '0');
				d	    	: in std_logic_vector (twr-1 downto 0) :=  (others => '0');
				rout		: out std_logic_vector (twr+mpr downto 0);
                iout        : out std_logic_vector (twr+mpr downto 0) 
			);
		end component;
        
		component asj_fft_paradd4 
			GENERIC(
					mpr : integer :=24
			);
			PORT
			(
global_clock_enable : in std_logic;
				clock		: IN STD_LOGIC  := '0';
				data3x		: IN STD_LOGIC_VECTOR (mpr-1 DOWNTO 0);
				data2x		: IN STD_LOGIC_VECTOR (mpr-1 DOWNTO 0);
				data1x		: IN STD_LOGIC_VECTOR (mpr-1 DOWNTO 0);
				data0x		: IN STD_LOGIC_VECTOR (mpr-1 DOWNTO 0);
				result		: OUT STD_LOGIC_VECTOR (mpr+1 DOWNTO 0)
			);
		end component;
		
		component asj_fft_cmult_can
			generic(mpr  	: integer :=18;
						 	twr  	: integer :=18;
						 	opr  	: integer :=36;
						 	oprp1 : integer :=37;
						 	oprp2 : integer :=38;
						 	pipe  : integer :=0;
						 	mult_imp  : integer  :=0
			);
			port( 	clk 		: in std_logic;
global_clock_enable : in std_logic;
							reset   : in std_logic;
					 		dataa 	: in std_logic_vector(mpr-1 downto 0);
					 		datab 	: in std_logic_vector(mpr-1 downto 0);
					 		datac 	: in std_logic_vector(twr-1 downto 0);
					 		datad 	: in std_logic_vector(twr-1 downto 0);
					 		real_out : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
					 		imag_out : out std_logic_vector(mpr-1 downto 0):=(others=>'0')
			);
		
		end component;
		
		component asj_fft_cmult_std
			generic(device_family  	: string;
                 mpr  	: integer :=18;
						 	twr  	: integer :=18;
						 	mult_imp : integer :=0;
						 	pipe  : integer :=0
			);
			port( 	clk 		: in std_logic;
global_clock_enable : in std_logic;
							reset   : in std_logic;
					 		dataa 	: in std_logic_vector(mpr-1 downto 0);
					 		datab 	: in std_logic_vector(mpr-1 downto 0);
					 		datac 	: in std_logic_vector(twr-1 downto 0);
					 		datad 	: in std_logic_vector(twr-1 downto 0);
					 		real_out : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
					 		imag_out : out std_logic_vector(mpr-1 downto 0):=(others=>'0')
			);
		
		end component;
		
    
		component apn_fft_cmult_cpx
			generic(
						 	mpr  	: integer :=18;
						 	twr  	: integer :=18;
						 	pipe  : integer :=0
			);
			port( 	
                            clk 		: in std_logic;
                            global_clock_enable : in std_logic;
							reset   : in std_logic;
					 		dataa 	: in std_logic_vector(mpr-1 downto 0);
					 		datab 	: in std_logic_vector(mpr-1 downto 0);
					 		datac 	: in std_logic_vector(twr-1 downto 0);
					 		datad 	: in std_logic_vector(twr-1 downto 0);
					 		real_out : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
					 		imag_out : out std_logic_vector(mpr-1 downto 0):=(others=>'0')
			);
		
		end component;

		component apn_fft_cmult_cpx2
			generic(
						 	mpr  	: integer :=18;
						 	twr  	: integer :=18;
						 	pipe  : integer :=0
			);
			port( 	
                            clk 		: in std_logic;
                            global_clock_enable : in std_logic;
							reset   : in std_logic;
					 		dataa 	: in std_logic_vector(mpr-1 downto 0);
					 		datab 	: in std_logic_vector(mpr-1 downto 0);
					 		datac 	: in std_logic_vector(twr-1 downto 0);
					 		datad 	: in std_logic_vector(twr-1 downto 0);
					 		real_out : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
					 		imag_out : out std_logic_vector(mpr-1 downto 0):=(others=>'0')
			);
		
		end component;
    
    component asj_fft_oe 
	    generic (
	    	nps : integer :=1024;
	    	log2_n_passes : integer:=3;
	    	nume : integer :=1;
	     	apr : integer :=4;
	     	oec : integer :=34
			);
	    port (
global_clock_enable : in std_logic;
	         clk   			: in std_logic;
	         reset 			: in std_logic;
	         data_proc	: in std_logic;
	         k_count  	: in std_logic_vector(apr-1 downto 0); 
	         p_count  	: in std_logic_vector(log2_n_passes-1 downto 0); 
	         exp_en     : out std_logic;
	         oe       	: out std_logic
	         );
		end component;
		
    component asj_fft_twadgen 
			generic(
							nps : integer :=4096;
							nume : integer :=1;
							n_passes : integer :=5;
							apr : integer :=10;
							log2_n_passes : integer:=3;
							tw_delay : integer:=3
			);
			port(			
global_clock_enable : in std_logic;
							clk 						: in std_logic;
							k_count   	  : in std_logic_vector(apr-1 downto 0);
							p_count   	  : in std_logic_vector(log2_n_passes-1 downto 0);
							tw_addr				  : out std_logic_vector(apr-1 downto 0)
			);
			end component;
			component asj_fft_twadgen_dual 
				generic(
									nps : integer :=4096;
									nume : integer :=2;
									n_passes : integer :=5;
									log2_n_passes : integer :=3;
									apr : integer :=10;
									tw_delay : integer:=3
								);
				port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
									k_count   	  : in std_logic_vector(apr-2 downto 0);
									p_count   	  : in std_logic_vector(log2_n_passes-1 downto 0);
									tw_addre				  : out std_logic_vector((nume/2)*apr-1 downto 0);
									tw_addro				  : out std_logic_vector((nume/2)*apr-1 downto 0)
						);
			
		end component; 
		
		component asj_fft_twadsogen 
			generic(
								nps : integer :=4096;
								nume : integer :=2;
								n_passes : integer :=5;
								log2_n_passes : integer :=3;
								apr : integer :=10;
								tw_delay : integer:=3
							);
			port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
								data_addr   	  : in std_logic_vector(apr-nume downto 0);
								p_count     	  : in std_logic_vector(log2_n_passes-1 downto 0);
								tw_addr				  : out std_logic_vector(nume*(apr-3)+nume-1 downto 0)
					);
			end component;
		
		component asj_fft_twadsogen_q 
			generic(
								nps : integer :=4096;
								nume : integer :=2;
								n_passes : integer :=5;
								log2_n_passes : integer :=3;
								apr : integer :=10;
								tw_delay : integer:=3
							);
			port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
								data_addr   	  : in std_logic_vector(apr-nume downto 0);
								p_count     	  : in std_logic_vector(log2_n_passes-1 downto 0);
								quad            : out std_logic_vector(2 downto 0);
								tw_addr				  : out std_logic_vector(2*(apr-3)+1 downto 0)
					);
			end component;
		
		
		component asj_fft_dataadgen 
			generic(  nps : integer  :=4096; 
								nume :  integer :=2; 
								arch : integer :=0;  
								n_passes : integer :=5; 
								log2_n_passes  : integer:= 3; 
								apr : integer :=10 );  
			port(			clk : in std_logic; 
global_clock_enable : in std_logic;
								k_count   	   :  in std_logic_vector(apr-1 downto 0);
								p_count        :  in std_logic_vector(log2_n_passes-1 downto 0);
								rd_addr_a			 :  out std_logic_vector(apr-1 downto 0);
								rd_addr_b			 :  out std_logic_vector(apr-1 downto 0);
								rd_addr_c			 :  out std_logic_vector(apr-1 downto 0);
								rd_addr_d			 :  out std_logic_vector(apr-1 downto 0); 
								sw_data_read      : out std_logic_vector(1 downto 0)
					);
		end component;
		
		component asj_fft_lppwradgen 
		generic(
						nps : integer :=4096;
						nume : integer :=1;		
						mram : integer :=1;				
						n_passes : integer :=5;
						log2_n_passes : integer:= 3;
						apr : integer :=10
					);
		port(		clk 							: in std_logic;
global_clock_enable : in std_logic;
						count_en          : in std_logic;
						wr_addr_a				  : out std_logic_vector(apr-1 downto 0);
						wr_addr_b				  : out std_logic_vector(apr-1 downto 0);
						wr_addr_c				  : out std_logic_vector(apr-1 downto 0);
						wr_addr_d				  : out std_logic_vector(apr-1 downto 0);
						sw                : out std_logic_vector(1 downto 0)
			);
		end component;
		component asj_fft_lppwradgen_mram 
			generic(
							nps : integer :=4096;
							nume : integer :=1;		
							n_passes : integer :=5;
							log2_n_passes : integer:= 3;
							apr : integer :=10
						);
			port(		clk 							: in std_logic;
global_clock_enable : in std_logic;
							count_en          : in std_logic;
							k_count           : in std_logic_vector(apr-1 downto 0);
							wr_addr_a				  : out std_logic_vector(apr-1 downto 0);
							sw                : out std_logic
				);
		end component;
		
		component asj_fft_wrengen 
			generic(
								nps : integer :=4096;
								arch : integer:=0;
								n_passes : integer :=5;
								log2_n_passes : integer:= 3;
								apr : integer :=10;
								del : integer :=17
							);
			port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
								reset         : in std_logic;
								p_count       : in std_logic_vector(log2_n_passes-1 downto 0);
								anb           : in std_logic;
								lpp_c_en      : out std_logic;
								lpp_d_en      : out std_logic;
								wc            : out std_logic;
								wd            : out std_logic
					);
		end component;
		
		component asj_fft_rdengen 
			generic(
								nps : integer :=4096;
								n_passes : integer :=5;
								log2_n_passes : integer:= 3;
								apr : integer :=10;
								del : integer :=17
							);
			port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
								k_count   	  : in std_logic_vector(apr-1 downto 0);
								p_count       : in std_logic_vector(log2_n_passes-1 downto 0);
								anb           : in std_logic;
								cnd           : in std_logic;
								rdy           : in std_logic;
								ra            : out std_logic;
								rb            : out std_logic;
								rc            : out std_logic;
								rd            : out std_logic
					);
		end component;
		
		component asj_fft_around
		generic 	(     
			widthin		:	natural :=8;
			widthout	:	natural :=4;
			pipe      : natural :=1 
			);
		port 	( 
global_clock_enable : in std_logic;
		  clk   : in std_logic;
		  clken : in std_logic;
			xin		: in std_logic_vector(widthin-1 downto 0);
			yout	: out std_logic_vector(widthout-1 downto 0)
			);	
		end component;
		
		component asj_fft_cround
		generic 	(     
			widthin		:	natural :=8;
			widthout	:	natural :=4;
			pipe      : natural :=1 
			);
		port 	( 
global_clock_enable : in std_logic;
		  clk   : in std_logic;
		  clken : in std_logic;
			xin		: in std_logic_vector(widthin-1 downto 0);
			yout	: out std_logic_vector(widthout-1 downto 0)
			);	
		end component;
		
		component asj_fft_pround
		generic 	(     
			widthin		:	natural :=8;
			widthout	:	natural :=4;
			pipe      : natural :=1 
			);
		port 	( 
global_clock_enable : in std_logic;
		  clk   : in std_logic;
		  clken : in std_logic;
			xin		: in std_logic_vector(widthin-1 downto 0);
			yout	: out std_logic_vector(widthout-1 downto 0)
			);	
		end component;
		
		
		component asj_fft_lpprdadgen 
			generic(
								nps : integer :=4096;
								mram : integer :=0;
								arch : integer :=1;
								nume : integer :=1;
								n_passes : integer :=5;
								log2_n_passes : integer:= 3;
								apr : integer :=10
							);
			port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
								data_rdy        : in std_logic;
								lpp_en 					: in std_logic;
								reset           : in std_logic;
								rd_addr_a				: out std_logic_vector(apr-1 downto 0);
								rd_addr_b				: out std_logic_vector(apr-1 downto 0);
								rd_addr_c				: out std_logic_vector(apr-1 downto 0);
								rd_addr_d				: out std_logic_vector(apr-1 downto 0);
								sw_data_read    : out std_logic_vector(1 downto 0);
								sw_addr_read    : out std_logic_vector(1 downto 0);
								en              : out std_logic
								
					);
		end component;
		
		component asj_fft_lpprdadr2gen 
			generic(
								nps : integer :=4096;
								nume : integer :=2;
								arch : integer :=1;
								mram : integer :=0;
								n_passes : integer :=5;
								log2_n_passes : integer:= 3;
								apr : integer :=10
							);
			port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
								reset           : in std_logic;
								lpp_en 					: in std_logic;
								data_rdy 				: in std_logic;
								rd_addr_a				: out std_logic_vector(apr-1 downto 0);
								rd_addr_b				: out std_logic_vector(apr-1 downto 0);
								sw_data_read    : out std_logic_vector(1 downto 0);
								sw_addr_read    : out std_logic_vector(1 downto 0);
								qe_select			  : out std_logic_vector(1 downto 0);
								mid_point      : out std_logic:='0';
								en              : out std_logic
					);
			end component;
		
		component asj_fft_tdl 
			generic( 
							 mpr  	: integer :=16;
							 del    : integer :=6;
							 srr    : string :="AUTO_SHIFT_REGISTER_RECOGNITION=OFF"
							);
			port( 	clk 			: in std_logic;
global_clock_enable : in std_logic;
							--reset   	: in std_logic;
					 		data_in 	: in std_logic_vector(mpr-1 downto 0);
					 		data_out 	: out std_logic_vector(mpr-1 downto 0)
					);
		end component;
		
		component asj_fft_alt_shift_tdl 
			generic
			(
				mpr :   integer:=8;
				depth : integer:=4;
				m512 :  integer:=1
			);
			port
			(
global_clock_enable : in std_logic;
				shiftin		: in std_logic_vector ( mpr-1 downto 0);
				clock		: in std_logic ;
				shiftout		: out std_logic_vector (mpr-1 downto 0);
				taps		: out std_logic_vector (mpr-1 downto 0)
			);
		end component;
		
				
		component		asj_fft_tdl_rst is 
			generic( 
							 mpr  	: integer :=16;
							 del    : integer :=6
							);
			port( 	clk 			: in std_logic;
global_clock_enable : in std_logic;
							reset   	: in std_logic;
					 		data_in 	: in std_logic_vector(mpr-1 downto 0);
					 		data_out 	: out std_logic_vector(mpr-1 downto 0)
					);
		end component;
		component asj_fft_del_bit is 
			generic( 
							 del    : integer :=2
							);
			port( 	clk 			: in std_logic;
global_clock_enable : in std_logic;
							reset   	: in std_logic;
					 		data_in 	: in std_logic;
					 		data_out 	: out std_logic
					);
			
		end component;
		component asj_fft_tdl_bit
			generic( 
							 del    : integer :=6
							);
			port( 	clk 			: in std_logic;
global_clock_enable : in std_logic;
							--reset   	: in std_logic;
					 		data_in 	: in std_logic;
					 		data_out 	: out std_logic
					);
		end component;
		
		component asj_fft_tdl_bit_rst
			generic( 
							 del    : integer :=6
							);
			port( 	clk 			: in std_logic;
global_clock_enable : in std_logic;
							reset   	: in std_logic;
					 		data_in 	: in std_logic;
					 		data_out 	: out std_logic
					);
		end component;
		
		
		component asj_fft_wrswgen 
			generic(
								nps : integer :=4096;
								cont : integer:=0;
								arch : integer:=0;
								nume : integer :=1;
								n_passes : integer :=5;
								log2_n_passes : integer:= 3;
								apr : integer :=10;
								del : integer :=17
							);
			port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
								k_count   	  : in std_logic_vector(apr-1 downto 0);
								p_count       : in std_logic_vector(log2_n_passes-1 downto 0);
								sw_data_write : out std_logic_vector(1 downto 0); -- swd
								sw_addr_write : out std_logic_vector(1 downto 0) --swa
					);
		end component;
		
    component asj_fft_m_k_counter 
			generic(
						nps : integer :=4096;
						arch : integer :=0;
						nume : integer :=1;
						n_passes : integer :=5;
						log2_n_passes : integer := 3;
						apr : integer :=10;
						cont : integer :=1
					);
			port(			
global_clock_enable : in std_logic;
						clk 						: in std_logic;
						reset   	      : in std_logic;
						stp   	        : in std_logic; --"start" signal (may not be needed)
						start   	      : in std_logic; --"start" signal (may not be needed)
						next_block      : in std_logic;
						p_count   	    : out std_logic_vector(log2_n_passes-1 downto 0);
						k_count				  : out std_logic_vector(apr-1 downto 0);
						next_pass       : out std_logic;
						blk_done        : out std_logic
			);
			end component;
		component asj_fft_in_write_sgl 
			generic(
								nps : integer :=1024;
								arch : integer :=0;
								mram : integer :=0;
								nume: integer :=1; -- # Engines
								mpr : integer :=16;
								apr : integer :=8;
								bpr : integer :=4;
								bpb : integer :=4
							);
			port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
								reset 					: in std_logic;
								stp             : in std_logic;
								val             : in std_logic;
								block_done      : in std_logic;
								data_real_in   	: in std_logic_vector(mpr-1 downto 0);
								data_imag_in   	: in std_logic_vector(mpr-1 downto 0);
								wr_address_i    : out std_logic_vector(apr-1 downto 0);
								wren_i          : out std_logic_vector(3 downto 0);
								byte_enable     : out std_logic_vector(bpr-1 downto 0);
								data_rdy        : out std_logic;
								a_not_b         : out std_logic;
								next_block      : out std_logic;
								disable_wr      : out std_logic;
								data_in_r    		: out std_logic_vector(mpr-1 downto 0);
								data_in_i    		: out std_logic_vector(mpr-1 downto 0)
					);
		end component;	
		component asj_fft_in_write 
			generic(
								nps : integer :=1024;
								mpr : integer :=16;
								apr : integer :=8;
								abuspr : integer :=32; --4*apr
								rbuspr : integer :=64 --4*mpr
							);
			port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
								reset 					: in std_logic;
								stp             : in std_logic;
								data_real_in   	: in std_logic_vector(mpr-1 downto 0);
								data_imag_in   	: in std_logic_vector(mpr-1 downto 0);
								wr_address_i    : out std_logic_vector(abuspr-1 downto 0);
								sw_i            : out std_logic_vector(1 downto 0);
								data_rdy   	    : out std_logic; 
								a_not_b         : out std_logic;
								next_block      : out std_logic;
								data_in_r    		: out std_logic_vector(rbuspr-1 downto 0);
								data_in_i    		: out std_logic_vector(rbuspr-1 downto 0)
					);
		end component;
    
    component asj_fft_cxb_data 
			generic( mpr  	: integer :=16;
						 xbw    : integer :=4;
						 pipe   : integer :=1
						);
			port( 	clk 			: in std_logic;
global_clock_enable : in std_logic;
						--reset   	: in std_logic;
				 		sw_0_in 	: in std_logic_vector(2*mpr-1 downto 0);
				 		sw_1_in 	: in std_logic_vector(2*mpr-1 downto 0);
				 		sw_2_in 	: in std_logic_vector(2*mpr-1 downto 0);
				 		sw_3_in 	: in std_logic_vector(2*mpr-1 downto 0);
				 		ram_sel  	: in std_logic_vector(1 downto 0);
				 	  sw_0_out 	: out std_logic_vector(2*mpr-1 downto 0);
				 	  sw_1_out 	: out std_logic_vector(2*mpr-1 downto 0);
				 	  sw_2_out 	: out std_logic_vector(2*mpr-1 downto 0);
				 	  sw_3_out 	: out std_logic_vector(2*mpr-1 downto 0)
			);
		end component;
		component asj_fft_cxb_data_r 
			generic( mpr  	: integer :=16;
						 xbw    : integer :=4;
						 pipe   : integer :=1
						);
			port( 	clk 			: in std_logic;
global_clock_enable : in std_logic;
						--reset   	: in std_logic;
				 		sw_0_in 	: in std_logic_vector(2*mpr-1 downto 0);
				 		sw_1_in 	: in std_logic_vector(2*mpr-1 downto 0);
				 		sw_2_in 	: in std_logic_vector(2*mpr-1 downto 0);
				 		sw_3_in 	: in std_logic_vector(2*mpr-1 downto 0);
				 		ram_sel  	: in std_logic_vector(1 downto 0);
				 	  sw_0_out 	: out std_logic_vector(2*mpr-1 downto 0);
				 	  sw_1_out 	: out std_logic_vector(2*mpr-1 downto 0);
				 	  sw_2_out 	: out std_logic_vector(2*mpr-1 downto 0);
				 	  sw_3_out 	: out std_logic_vector(2*mpr-1 downto 0)
			);
		end component;
		
		component asj_fft_cxb_data_mram  
			generic( mpr  	: integer :=16;
					 xbw    : integer :=4;
					 pipe   : integer :=1
					);
			port( 	clk 			: in std_logic;
global_clock_enable : in std_logic;
					--reset   	: in std_logic;
			 		sw_0_in 	: in std_logic_vector(2*mpr-1 downto 0);
			 		sw_1_in 	: in std_logic_vector(2*mpr-1 downto 0);
			 		sw_2_in 	: in std_logic_vector(2*mpr-1 downto 0);
			 		sw_3_in 	: in std_logic_vector(2*mpr-1 downto 0);
			 		sw_4_in 	: in std_logic_vector(2*mpr-1 downto 0);
			 		sw_5_in 	: in std_logic_vector(2*mpr-1 downto 0);
			 		sw_6_in 	: in std_logic_vector(2*mpr-1 downto 0);
			 		sw_7_in 	: in std_logic_vector(2*mpr-1 downto 0);
			 		ram_sel  	: in std_logic;
			 	  sw_0_out 	: out std_logic_vector(2*mpr-1 downto 0);
			 	  sw_1_out 	: out std_logic_vector(2*mpr-1 downto 0);
			 	  sw_2_out 	: out std_logic_vector(2*mpr-1 downto 0);
			 	  sw_3_out 	: out std_logic_vector(2*mpr-1 downto 0);
			 	  sw_4_out 	: out std_logic_vector(2*mpr-1 downto 0);
			 	  sw_5_out 	: out std_logic_vector(2*mpr-1 downto 0);
			 	  sw_6_out 	: out std_logic_vector(2*mpr-1 downto 0);
			 	  sw_7_out 	: out std_logic_vector(2*mpr-1 downto 0)
			);

		end component;

		
		
		component asj_fft_cxb_addr 
			generic( mpr  	: integer :=16;
							 xbw    : integer :=4;
							 pipe   : integer :=1;
							 del    : integer :=6
							);
			port( 	clk 			: in std_logic;
global_clock_enable : in std_logic;
							--reset   	: in std_logic;
					 		sw_0_in 	: in std_logic_vector(mpr-1 downto 0);
					 		sw_1_in 	: in std_logic_vector(mpr-1 downto 0);
					 		sw_2_in 	: in std_logic_vector(mpr-1 downto 0);
					 		sw_3_in 	: in std_logic_vector(mpr-1 downto 0);
					 		ram_sel  	: in std_logic_vector(1 downto 0);
					 	  sw_0_out 	: out std_logic_vector(mpr-1 downto 0);
					 	  sw_1_out 	: out std_logic_vector(mpr-1 downto 0);
					 	  sw_2_out 	: out std_logic_vector(mpr-1 downto 0);
					 	  sw_3_out 	: out std_logic_vector(mpr-1 downto 0)
					);
	end component;
	
	component asj_fft_cnt_ctrl 
	generic(
						nps : integer :=256;
						mpr : integer :=16;
						apr : integer :=6;
						abuspr : integer :=24; --4*apr
						rbuspr : integer :=64; --4*mpr
						cbuspr : integer :=128 --2*4*mpr
					);
	port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
						sel_anb_in 			: in std_logic;
						sel_anb_ram 		: in std_logic;
						sel_anb_addr 		: in std_logic;
						data_rdy        : in std_logic;
						wraddr_i0_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_i1_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_i2_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_i3_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr0_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr1_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr2_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr3_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr0_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr1_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr2_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr3_sw    : in std_logic_vector(apr-1 downto 0);
						ram_data_in0_sw  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in1_sw  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in2_sw  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in3_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in0_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in1_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in2_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in3_sw  : in std_logic_vector(2*mpr-1 downto 0);
						a_ram_data_out_bus  : in std_logic_vector(cbuspr-1 downto 0);
						b_ram_data_out_bus  : in std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_in_bus  : out std_logic_vector(cbuspr-1 downto 0);
						b_ram_data_in_bus  : out std_logic_vector(cbuspr-1 downto 0);
						--c_ram_data_in_bus  : out std_logic_vector(cbuspr-1 downto 0);
						--d_ram_data_in_bus  : out std_logic_vector(cbuspr-1 downto 0);
						wraddress_a_bus   : out std_logic_vector(abuspr-1 downto 0);
						wraddress_b_bus   : out std_logic_vector(abuspr-1 downto 0);
						--wraddress_c_bus   : out std_logic_vector(abuspr-1 downto 0);
						--wraddress_d_bus   : out std_logic_vector(abuspr-1 downto 0);
						rdaddress_a_bus   : out std_logic_vector(abuspr-1 downto 0);
						rdaddress_b_bus   : out std_logic_vector(abuspr-1 downto 0);
						ram_data_out0    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out1    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out2    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out3    : out std_logic_vector(2*mpr-1 downto 0)
						
			);
end component;

component asj_fft_unbburst_ctrl 
		generic(
						nps : integer :=256;
						mpr : integer :=16;
						apr : integer :=6;
						abuspr : integer :=24; --4*apr
						rbuspr : integer :=64; --4*mpr
						cbuspr : integer :=128 --2*4*mpr
					);
	port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
						sel_wraddr_in 	: in std_logic;
						sel_ram_in 			: in std_logic;
						sel_lpp         : in std_logic;
						data_rdy        : in std_logic;
						wraddr_i0_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_i1_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_i2_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_i3_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr0_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr1_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr2_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr3_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr0_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr1_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr2_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr3_sw    : in std_logic_vector(apr-1 downto 0);
						lpp_rdaddr0_sw    : in std_logic_vector(apr-1 downto 0);
						lpp_rdaddr1_sw    : in std_logic_vector(apr-1 downto 0);
						lpp_rdaddr2_sw    : in std_logic_vector(apr-1 downto 0);
						lpp_rdaddr3_sw    : in std_logic_vector(apr-1 downto 0);
						ram_data_in0_sw  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in1_sw  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in2_sw  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in3_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in0_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in1_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in2_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in3_sw  : in std_logic_vector(2*mpr-1 downto 0);
						a_ram_data_out_bus  : in std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_in_bus  : out std_logic_vector(cbuspr-1 downto 0);
						wraddress_a_bus   : out std_logic_vector(abuspr-1 downto 0);
						rdaddress_a_bus   : out std_logic_vector(abuspr-1 downto 0);
						ram_data_out0    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out1    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out2    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out3    : out std_logic_vector(2*mpr-1 downto 0)
						
			);
			
			
end component;




component asj_fft_unbburst_ctrl_de 
	generic(
						nps : integer :=256;
						mpr : integer :=16;
						apr : integer :=6;
						abuspr : integer :=24; --4*apr
						rbuspr : integer :=64; --4*mpr
						cbuspr : integer :=128 --2*4*mpr
					);
	port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
						sel_wraddr_in 	: in std_logic;
						sel_ram_in 			: in std_logic;
						sel_lpp         : in std_logic;
						data_rdy        : in std_logic;
						wraddr_i0_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_i1_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_i2_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_i3_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr0_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr1_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr2_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr3_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr0_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr1_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr2_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr3_sw    : in std_logic_vector(apr-1 downto 0);
						lpp_rdaddr0_sw    : in std_logic_vector(apr-1 downto 0);
						lpp_rdaddr1_sw    : in std_logic_vector(apr-1 downto 0);
						lpp_rdaddr2_sw    : in std_logic_vector(apr-1 downto 0);
						lpp_rdaddr3_sw    : in std_logic_vector(apr-1 downto 0);
						ram_data_in0_sw_x  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in1_sw_x  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in2_sw_x  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in3_sw_x  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in0_sw_y  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in1_sw_y  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in2_sw_y  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in3_sw_y  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in0_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in1_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in2_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in3_sw  : in std_logic_vector(2*mpr-1 downto 0);
						a_ram_data_out_bus_x  : in std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_out_bus_y  : in std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_in_bus_x  : out std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_in_bus_y  : out std_logic_vector(cbuspr-1 downto 0);
						wraddress_a_bus   : out std_logic_vector(abuspr-1 downto 0);
						rdaddress_a_bus   : out std_logic_vector(abuspr-1 downto 0);
						ram_data_out0_x    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out1_x    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out2_x    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out3_x    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out0_y    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out1_y    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out2_y    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out3_y    : out std_logic_vector(2*mpr-1 downto 0)
			);
end component;

component asj_fft_unbburst_ctrl_qe 
	generic(
						nps : integer :=256;
						mpr : integer :=16;
						apr : integer :=6;
						abuspr : integer :=24; --4*apr
						rbuspr : integer :=64; --4*mpr
						cbuspr : integer :=128 --2*4*mpr
					);
	port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
						sel_ram_in 			: in std_logic;
						sel_wraddr_in 		: in std_logic;
						sel_lpp					: in std_logic;
						sel_lpp_m1      : in std_logic;
						data_rdy        : in std_logic;
						wraddr_i0_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_i1_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_i2_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_i3_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr0_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr1_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr2_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr3_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr0_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr1_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr2_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr3_sw    : in std_logic_vector(apr-1 downto 0);
						lpp_rdaddr0_sw    : in std_logic_vector(apr-1 downto 0);
						lpp_rdaddr1_sw    : in std_logic_vector(apr-1 downto 0);
						lpp_rdaddr2_sw    : in std_logic_vector(apr-1 downto 0);
						lpp_rdaddr3_sw    : in std_logic_vector(apr-1 downto 0);
						ram_data_in0_sw_w  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in1_sw_w  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in2_sw_w  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in3_sw_w  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in0_sw_x  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in1_sw_x  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in2_sw_x  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in3_sw_x  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in0_sw_y  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in1_sw_y  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in2_sw_y  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in3_sw_y  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in0_sw_z  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in1_sw_z  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in2_sw_z  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in3_sw_z  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in0_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in1_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in2_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in3_sw  : in std_logic_vector(2*mpr-1 downto 0);
						a_ram_data_out_bus_w  : in std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_out_bus_x  : in std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_out_bus_y  : in std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_out_bus_z  : in std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_in_bus_w  : out std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_in_bus_x  : out std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_in_bus_y  : out std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_in_bus_z  : out std_logic_vector(cbuspr-1 downto 0);
						wraddress_a_bus   : out std_logic_vector(abuspr-1 downto 0);
						rdaddress_a_bus_0   : out std_logic_vector(abuspr-1 downto 0);
						rdaddress_a_bus_1   : out std_logic_vector(abuspr-1 downto 0);
						ram_data_out0_w    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out1_w    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out2_w    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out3_w    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out0_x    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out1_x    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out2_x    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out3_x    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out0_y    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out1_y    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out2_y    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out3_y    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out0_z    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out1_z    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out2_z    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out3_z    : out std_logic_vector(2*mpr-1 downto 0)
			);
end component;


component asj_fft_unbburst_sose_ctrl 
	generic(
						nps : integer :=256;
						mpr : integer :=16;
						apr : integer :=6;
						nume : integer :=1;
						abuspr : integer :=24; --4*apr
						rbuspr : integer :=64; --4*mpr
						cbuspr : integer :=128 --2*4*mpr
					);
	port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
						sel_wraddr_in 	: in std_logic;
						sel_ram_in 			: in std_logic;
						sel_lpp         : in std_logic;
						sel_lpp_nm1     : in std_logic;
						data_rdy        : in std_logic;
						wraddr_i_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_sw    : in std_logic_vector(nume*apr-1 downto 0);
						rdaddr_sw    : in std_logic_vector(nume*apr-1 downto 0);
						lpp_rdaddr_sw    : in std_logic_vector(apr-1 downto 0);
						ram_data_in_sw  : in std_logic_vector(2*nume*mpr-1 downto 0);
						i_ram_data_in_sw  : in std_logic_vector(2*mpr-1 downto 0);
						a_ram_data_out_bus  : in std_logic_vector(2*nume*mpr-1 downto 0);
						a_ram_data_in_bus  : out std_logic_vector(2*nume*mpr-1 downto 0);
						wraddress_a_bus   : out std_logic_vector(nume*apr-1 downto 0);
						rdaddress_a_bus   : out std_logic_vector(nume*apr-1 downto 0);
						ram_data_out    : out std_logic_vector(2*nume*mpr-1 downto 0)
			);
end component;

component asj_fft_burst_ctrl 
	generic(
						nps : integer :=256;
						mpr : integer :=16;
						apr : integer :=6;
						abuspr : integer :=24; --4*apr
						rbuspr : integer :=64; --4*mpr
						cbuspr : integer :=128 --2*4*mpr
					);
	port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
						sel_anb_in 			: in std_logic;
						sel_anb_ram 		: in std_logic;
						sel_anb_addr 		: in std_logic;
						data_rdy        : in std_logic;
						wraddr_i0_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_i1_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_i2_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_i3_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr0_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr1_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr2_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr3_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr0_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr1_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr2_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr3_sw    : in std_logic_vector(apr-1 downto 0);
						ram_data_in0_sw  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in1_sw  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in2_sw  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in3_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in0_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in1_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in2_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in3_sw  : in std_logic_vector(2*mpr-1 downto 0);
						a_ram_data_out_bus  : in std_logic_vector(cbuspr-1 downto 0);
						b_ram_data_out_bus  : in std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_in_bus  : out std_logic_vector(cbuspr-1 downto 0);
						b_ram_data_in_bus  : out std_logic_vector(cbuspr-1 downto 0);
						--c_ram_data_in_bus  : out std_logic_vector(cbuspr-1 downto 0);
						--d_ram_data_in_bus  : out std_logic_vector(cbuspr-1 downto 0);
						wraddress_a_bus   : out std_logic_vector(abuspr-1 downto 0);
						wraddress_b_bus   : out std_logic_vector(abuspr-1 downto 0);
						--wraddress_c_bus   : out std_logic_vector(abuspr-1 downto 0);
						--wraddress_d_bus   : out std_logic_vector(abuspr-1 downto 0);
						rdaddress_a_bus   : out std_logic_vector(abuspr-1 downto 0);
						rdaddress_b_bus   : out std_logic_vector(abuspr-1 downto 0);
						ram_data_out0    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out1    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out2    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out3    : out std_logic_vector(2*mpr-1 downto 0)
						
			);
end component;

component asj_fft_burst_ctrl_de 
	generic(
						nps : integer :=256;
						mpr : integer :=16;
						apr : integer :=6;
						abuspr : integer :=24; --4*apr
						rbuspr : integer :=64; --4*mpr
						cbuspr : integer :=128 --2*4*mpr
					);
	port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
						sel_anb_in 			: in std_logic;
						sel_anb_ram 		: in std_logic;
						sel_anb_addr 		: in std_logic;
						data_rdy        : in std_logic;
						wraddr_i0_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_i1_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_i2_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_i3_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr0_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr1_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr2_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr3_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr0_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr1_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr2_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr3_sw    : in std_logic_vector(apr-1 downto 0);
						ram_data_in0_sw_x  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in1_sw_x  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in2_sw_x  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in3_sw_x  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in0_sw_y  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in1_sw_y  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in2_sw_y  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in3_sw_y  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in0_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in1_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in2_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in3_sw  : in std_logic_vector(2*mpr-1 downto 0);
						a_ram_data_out_bus_x  : in std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_out_bus_y  : in std_logic_vector(cbuspr-1 downto 0);
						b_ram_data_out_bus_x  : in std_logic_vector(cbuspr-1 downto 0);
						b_ram_data_out_bus_y  : in std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_in_bus_x  : out std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_in_bus_y  : out std_logic_vector(cbuspr-1 downto 0);
						b_ram_data_in_bus_x  : out std_logic_vector(cbuspr-1 downto 0);
						b_ram_data_in_bus_y  : out std_logic_vector(cbuspr-1 downto 0);
						wraddress_a_bus   : out std_logic_vector(abuspr-1 downto 0);
						wraddress_b_bus   : out std_logic_vector(abuspr-1 downto 0);
						rdaddress_a_bus   : out std_logic_vector(abuspr-1 downto 0);
						rdaddress_b_bus   : out std_logic_vector(abuspr-1 downto 0);
						ram_data_out0_x    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out1_x    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out2_x    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out3_x    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out0_y    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out1_y    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out2_y    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out3_y    : out std_logic_vector(2*mpr-1 downto 0)
			);
end component;

component asj_fft_burst_ctrl_qe 
	generic(
						nps : integer :=256;
						mpr : integer :=16;
						apr : integer :=6;
						abuspr : integer :=24; --4*apr
						rbuspr : integer :=64; --4*mpr
						cbuspr : integer :=128 --2*4*mpr
					);
	port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
						sel_anb_in 			: in std_logic;
						sel_anb_ram 		: in std_logic;
						sel_anb_addr 		: in std_logic;
						sel_lpp_m1      : in std_logic;
						data_rdy        : in std_logic;
						wraddr_i0_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_i1_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_i2_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_i3_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr0_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr1_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr2_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr3_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr0_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr1_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr2_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr3_sw    : in std_logic_vector(apr-1 downto 0);
						ram_data_in0_sw_w  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in1_sw_w  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in2_sw_w  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in3_sw_w  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in0_sw_x  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in1_sw_x  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in2_sw_x  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in3_sw_x  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in0_sw_y  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in1_sw_y  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in2_sw_y  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in3_sw_y  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in0_sw_z  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in1_sw_z  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in2_sw_z  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in3_sw_z  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in0_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in1_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in2_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in3_sw  : in std_logic_vector(2*mpr-1 downto 0);
						a_ram_data_out_bus_w  : in std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_out_bus_x  : in std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_out_bus_y  : in std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_out_bus_z  : in std_logic_vector(cbuspr-1 downto 0);
						b_ram_data_out_bus_w  : in std_logic_vector(cbuspr-1 downto 0);
						b_ram_data_out_bus_x  : in std_logic_vector(cbuspr-1 downto 0);
						b_ram_data_out_bus_y  : in std_logic_vector(cbuspr-1 downto 0);
						b_ram_data_out_bus_z  : in std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_in_bus_w  : out std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_in_bus_x  : out std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_in_bus_y  : out std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_in_bus_z  : out std_logic_vector(cbuspr-1 downto 0);
						b_ram_data_in_bus_w  : out std_logic_vector(cbuspr-1 downto 0);
						b_ram_data_in_bus_x  : out std_logic_vector(cbuspr-1 downto 0);
						b_ram_data_in_bus_y  : out std_logic_vector(cbuspr-1 downto 0);
						b_ram_data_in_bus_z  : out std_logic_vector(cbuspr-1 downto 0);
						wraddress_a_bus   : out std_logic_vector(abuspr-1 downto 0);
						wraddress_b_bus   : out std_logic_vector(abuspr-1 downto 0);
						rdaddress_a_bus   : out std_logic_vector(abuspr-1 downto 0);
						rdaddress_b_bus   : out std_logic_vector(abuspr-1 downto 0);
						ram_data_out0_w    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out1_w    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out2_w    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out3_w    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out0_x    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out1_x    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out2_x    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out3_x    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out0_y    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out1_y    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out2_y    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out3_y    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out0_z    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out1_z    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out2_z    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out3_z    : out std_logic_vector(2*mpr-1 downto 0)
			);
end component;

component asj_fft_cnt_ctrl_de 
	generic(            
						nps : integer :=256;
						mpr : integer :=16;
						apr : integer :=6;
						abuspr : integer :=24; --4*apr
						rbuspr : integer :=64; --4*mpr
						cbuspr : integer :=128 --2*4*mpr
					);          
	port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
						sel_anb_in 			: in std_logic;
						sel_anb_ram 		: in std_logic;
						sel_anb_addr 		: in std_logic;
						data_rdy        : in std_logic;
						wraddr_i0_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_i1_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_i2_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr_i3_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr0_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr1_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr2_sw    : in std_logic_vector(apr-1 downto 0);
						wraddr3_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr0_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr1_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr2_sw    : in std_logic_vector(apr-1 downto 0);
						rdaddr3_sw    : in std_logic_vector(apr-1 downto 0);
						ram_data_in0_sw_x  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in1_sw_x  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in2_sw_x  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in3_sw_x  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in0_sw_y  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in1_sw_y  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in2_sw_y  : in std_logic_vector(2*mpr-1 downto 0);
						ram_data_in3_sw_y  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in0_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in1_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in2_sw  : in std_logic_vector(2*mpr-1 downto 0);
						i_ram_data_in3_sw  : in std_logic_vector(2*mpr-1 downto 0);
						a_ram_data_out_bus_x  : in std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_out_bus_y  : in std_logic_vector(cbuspr-1 downto 0);
						b_ram_data_out_bus_x  : in std_logic_vector(cbuspr-1 downto 0);
						b_ram_data_out_bus_y  : in std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_in_bus_x  : out std_logic_vector(cbuspr-1 downto 0);
						a_ram_data_in_bus_y  : out std_logic_vector(cbuspr-1 downto 0);
						b_ram_data_in_bus_x  : out std_logic_vector(cbuspr-1 downto 0);
						b_ram_data_in_bus_y  : out std_logic_vector(cbuspr-1 downto 0);
						wraddress_a_bus   : out std_logic_vector(abuspr-1 downto 0);
						wraddress_b_bus   : out std_logic_vector(abuspr-1 downto 0);
						rdaddress_a_bus   : out std_logic_vector(abuspr-1 downto 0);
						rdaddress_b_bus   : out std_logic_vector(abuspr-1 downto 0);
						ram_data_out0_x    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out1_x    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out2_x    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out3_x    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out0_y    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out1_y    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out2_y    : out std_logic_vector(2*mpr-1 downto 0);
						ram_data_out3_y    : out std_logic_vector(2*mpr-1 downto 0)
			);
	end component;

	
	component asj_fft_twiddle_ctrl_qe 
	generic(
						nps : integer :=256;
						log2_n_passes : integer :=3;
						X1   : integer :=23170;
						X2   : integer :=32767;
						apr : integer :=6;
						twr : integer :=16;
						twa : integer :=6
						
					);
	port(			clk 					: in std_logic;
global_clock_enable : in std_logic;
						reset    			: in std_logic;
						k_count_d1    : in std_logic_vector(apr-1 downto 0);
						k_count_d2    : in std_logic_vector(apr-1 downto 0);
						p_count_d1       : in std_logic_vector(2 downto 0);
						p_count_d2       : in std_logic_vector(2 downto 0);
						t1w_i  				: in std_logic_vector(2*twr-1 downto 0);
						t2w_i  				: in std_logic_vector(2*twr-1 downto 0);
						t3w_i  				: in std_logic_vector(2*twr-1 downto 0);
						t1x_i  				: in std_logic_vector(2*twr-1 downto 0);
						t2x_i  				: in std_logic_vector(2*twr-1 downto 0);
						t3x_i  				: in std_logic_vector(2*twr-1 downto 0);
						t1y_i  				: in std_logic_vector(2*twr-1 downto 0);
						t2y_i  				: in std_logic_vector(2*twr-1 downto 0);
						t3y_i  				: in std_logic_vector(2*twr-1 downto 0);
						t1z_i  				: in std_logic_vector(2*twr-1 downto 0);
						t2z_i  				: in std_logic_vector(2*twr-1 downto 0);
						t3z_i  				: in std_logic_vector(2*twr-1 downto 0);
						twade_0_i     : in std_logic_vector(twa-1 downto 0);
						twade_1_i     : in std_logic_vector(twa-1 downto 0);
						t1w_o  				: out std_logic_vector(2*twr-1 downto 0);
						t2w_o  				: out std_logic_vector(2*twr-1 downto 0);
						t3w_o  				: out std_logic_vector(2*twr-1 downto 0);
						t1x_o  				: out std_logic_vector(2*twr-1 downto 0);
						t2x_o  				: out std_logic_vector(2*twr-1 downto 0);
						t3x_o  				: out std_logic_vector(2*twr-1 downto 0);
						t1y_o  				: out std_logic_vector(2*twr-1 downto 0);
						t2y_o  				: out std_logic_vector(2*twr-1 downto 0);
						t3y_o  				: out std_logic_vector(2*twr-1 downto 0);
						t1z_o  				: out std_logic_vector(2*twr-1 downto 0);
						t2z_o  				: out std_logic_vector(2*twr-1 downto 0);
						t3z_o  				: out std_logic_vector(2*twr-1 downto 0);
						twade_0_o     : out std_logic_vector(twa-1 downto 0);
						twade_1_o     : out std_logic_vector(twa-1 downto 0)
			);
end component;
	
	
	component asj_fft_lpp 
    generic (
    				 mpr : integer := 16;  
    				 apr : integer := 16;  
             twr : integer := 16;
             nstages: integer := 6;
             pipe: integer := 1
		);
    port (
global_clock_enable : in std_logic;
         clk   		: in std_logic;
         reset 		: in std_logic;
			   data_1_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_2_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_3_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_4_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_1_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_2_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_3_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_4_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_1_real_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_2_real_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_3_real_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_4_real_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_1_imag_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_2_imag_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_3_imag_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_4_imag_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0')
		     );
	end component;
	
	component asj_fft_lpp_serial 
    generic (
    				 mpr : integer := 16;  
    				 arch : integer :=1;
    				 nume : integer :=1;
    				 apr : integer := 16;  
             del : integer := 5
		);
    port (
global_clock_enable : in std_logic;
         clk   		: in std_logic;
         reset    : in std_logic;
         --clken   : in std_logic;
         lpp_en   : in std_logic;
			   data_1_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_2_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_3_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_4_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_1_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_2_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_3_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_4_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_real_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_imag_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_val    : out std_logic
		 );
	end component;
	component asj_fft_lpp_serial_r2 
    generic (
    				 mpr : integer := 16;
    				 arch : integer :=1;
    				 nume : integer :=1;  
    				 apr : integer := 6;  
             del : integer :=4
		);
    port (
global_clock_enable : in std_logic;
         clk   		: in std_logic;
         reset    : in std_logic;
         --clken   : in std_logic;
         lpp_en   : in std_logic;
         data_1_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_2_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_1_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_2_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_real_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_imag_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_val    : out std_logic := '0'
		 );
	end component;


component asj_fft_bfp_ctrl 
    generic (
    				 nps : integer :=1024;
    				 nume : integer :=1;
    				 fpr : integer := 4;
    				 cont : integer :=0;
    				 arch : integer :=0
		);
    port (
global_clock_enable : in std_logic;
         clk   				 : in std_logic;
         clken         : in std_logic;
         reset 				 : in std_logic;
         next_pass 		 : in std_logic;
         next_blk 	   : in std_logic;
         exp_en	 	     : in std_logic;
				 alt_slb_i       : in std_logic_vector(3*nume-1 downto 0);
         alt_slb_o       : out std_logic_vector(2 downto 0);
		     blk_exp_o     : out std_logic_vector(fpr+1 downto 0):=(others=>'0')  
		     );
end component;


component asj_fft_dft_bfp_cont 
    generic (mpr : integer := 16;  
    				 nume : integer :=1;
    				 bfp  : integer :=1;
    				 fpr : integer := 5;  
    				 rbuspr : integer := 64; -- 4*mpr
             twr : integer := 16;
             nstages: integer := 7; -- pipe + 7
             pipe: integer := 1
		);
    port (
global_clock_enable : in std_logic;
         clk   				 : in std_logic;
         clken         : in std_logic;
         reset 				 : in std_logic;
         next_pass 		 : in std_logic;
         blk_done 		 : in std_logic;
         data_1_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_2_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_3_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_4_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_1_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_2_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_3_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_4_imag_i : in std_logic_vector(mpr-1 downto 0);
		     twid_1_real	 : in std_logic_vector(twr-1 downto 0);
		     twid_2_real	 : in std_logic_vector(twr-1 downto 0);
		     twid_3_real	 : in std_logic_vector(twr-1 downto 0);
		     twid_1_imag	 : in std_logic_vector(twr-1 downto 0);
		     twid_2_imag	 : in std_logic_vector(twr-1 downto 0);
		     twid_3_imag	 : in std_logic_vector(twr-1 downto 0);
		     data_1_real_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_2_real_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_3_real_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_4_real_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_1_imag_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_2_imag_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_3_imag_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_4_imag_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     blk_exp_o     : out std_logic_vector(3 downto 0):=(others=>'0')  
		     );
end component;


component asj_fft_dft_bfp 
    generic (
    				 device_family : string;
    				 nps : integer :=1024;
    				 bfp  : integer :=1;
    				 nume : integer :=1;
    				 mpr : integer := 16;  
    				 arch : integer := 0;  
    				 fpr : integer :=5;
    				 mult_type : integer:=0;				 
    				 mult_imp  : integer:=0;
    				 dsp_arch  : integer:=0;
    				 rbuspr : integer := 64; -- 4*mpr
             twr : integer := 16;
             nstages: integer := 8; -- pipe + 7
             pipe: integer := 1;
             cont : integer :=1
		);
    port (
global_clock_enable : in std_logic;
         clk   				 : in std_logic;
         clken         : in std_logic;
         reset 				 : in std_logic;
         next_pass     : in std_logic;
         next_blk      : in std_logic;
         blk_done      : in std_logic;
         alt_slb_i     : in std_logic_vector(2 downto 0);
         alt_slb_o     : out std_logic_vector(2 downto 0);
         data_1_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_2_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_3_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_4_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_1_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_2_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_3_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_4_imag_i : in std_logic_vector(mpr-1 downto 0);
		     twid_1_real	 : in std_logic_vector(twr-1 downto 0);
		     twid_2_real	 : in std_logic_vector(twr-1 downto 0);
		     twid_3_real	 : in std_logic_vector(twr-1 downto 0);
		     twid_1_imag	 : in std_logic_vector(twr-1 downto 0);
		     twid_2_imag	 : in std_logic_vector(twr-1 downto 0);
		     twid_3_imag	 : in std_logic_vector(twr-1 downto 0);
		     data_1_real_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_2_real_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_3_real_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_4_real_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_1_imag_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_2_imag_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_3_imag_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_4_imag_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0')
		     );
end component;


component asj_fft_dft_bfp_sgl 
    generic (
    				 device_family : string;
    				 nps : integer :=1024;
    				 nume : integer :=1;
    				 bfp  : integer :=1;
    				 mpr : integer := 16;  
					 	 fpr : integer := 5;  
					 	 mult_type : integer:=0;	
						 mult_imp : integer:=0;						 	 			 
    				 dsp_arch : integer :=0;
    				 rbuspr : integer := 64; -- 4*mpr
             twr : integer := 16;
             nstages: integer := 7; -- pipe + 7
             pipe: integer := 1;
             rev: integer := 1;
             cont : integer :=1
		);
    port (
global_clock_enable : in std_logic;
         clk   				 : in std_logic;
         clken         : in std_logic;
         reset 				 : in std_logic;
         next_pass     : in std_logic;
         next_blk      : in std_logic;
         sel_lpp       : in std_logic;
         sel       		 : in std_logic_vector(1 downto 0);
         alt_slb_i     : in std_logic_vector(2 downto 0);
         data_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_imag_i : in std_logic_vector(mpr-1 downto 0);
		     twid_real	 : in std_logic_vector(twr-1 downto 0);
		     twid_imag	 : in std_logic_vector(twr-1 downto 0);
		     data_real_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_imag_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     alt_slb_o       : out std_logic_vector(2 downto 0)
		     );
end component;

	component butterfly_r4 
    generic (mpr : integer := 18;  
             twr : integer := 18;
             nstages: integer := 5;
             pipe : integer := 0
		);
    port (
global_clock_enable : in std_logic;
         clk   		: in std_logic;
         reset 		: in std_logic;
			   data_1_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_2_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_3_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_4_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_1_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_2_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_3_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_4_imag_i : in std_logic_vector(mpr-1 downto 0);
		     twid_1_real	 : in std_logic_vector(twr-1 downto 0);
		     twid_2_real	 : in std_logic_vector(twr-1 downto 0);
		     twid_3_real	 : in std_logic_vector(twr-1 downto 0);
		     twid_1_imag	 : in std_logic_vector(twr-1 downto 0);
		     twid_2_imag	 : in std_logic_vector(twr-1 downto 0);
		     twid_3_imag	 : in std_logic_vector(twr-1 downto 0);
		     pre_data_1_real_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     pre_data_2_real_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     pre_data_3_real_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     pre_data_4_real_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     pre_data_1_imag_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     pre_data_2_imag_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     pre_data_3_imag_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     pre_data_4_imag_o : out std_logic_vector(mpr-1 downto 0):=(others=>'0');
		     data_1_real_o : out std_logic_vector(mpr-1 downto 0);
		     data_2_real_o : out std_logic_vector(mpr-1 downto 0);
		     data_3_real_o : out std_logic_vector(mpr-1 downto 0);
		     data_4_real_o : out std_logic_vector(mpr-1 downto 0);
		     data_1_imag_o : out std_logic_vector(mpr-1 downto 0);
		     data_2_imag_o : out std_logic_vector(mpr-1 downto 0);
		     data_3_imag_o : out std_logic_vector(mpr-1 downto 0);
		     data_4_imag_o : out std_logic_vector(mpr-1 downto 0)
		     );
	end component;
	
	
   	component asj_fft_4dp_ram 
		generic(
						device_family : string;
						apr : integer :=4;
						mpr : integer :=16;
						abuspr : integer :=16; --4*apr
						cbuspr : integer :=128; -- 4 * 2 * mpr
						rfd  : string :="AUTO"
					);
		port(			
global_clock_enable : in std_logic;
						clk 						: in std_logic;
						rdaddress   	  : in std_logic_vector(abuspr-1 downto 0);
						wraddress				: in std_logic_vector(abuspr-1 downto 0);
						data_in				  : in std_logic_vector(cbuspr-1 downto 0);
						wren            : in std_logic_vector(3 downto 0);
						rden            : in std_logic_vector(3 downto 0);
						data_out				: out std_logic_vector(cbuspr-1 downto 0)
			);
		end component;
		
	component asj_fft_1dp_ram 
		generic(
						device_family : string;
						apr : integer :=4;
						mpr : integer :=16;
						rfd  : string :="AUTO"
						
					);
		port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
						rdaddress   	  : in std_logic_vector(apr-1 downto 0);
						wraddress				: in std_logic_vector(apr-1 downto 0);
						data_in				  : in std_logic_vector(2*mpr-1 downto 0);
						wren            : in std_logic;
						rden            : in std_logic;
						data_out				: out std_logic_vector(2*mpr-1 downto 0):=(others=>'0')
			);
		end component;
    
    component asj_fft_bfp_i 
    generic (
    	mpr : integer := 16;
    	fpr : integer :=5;
    	arch : integer :=5;
    	rbuspr : integer :=64 -- 4*mpr
		);
    port (
global_clock_enable : in std_logic;
         clk   		: in std_logic;
         --reset 		: in std_logic;
         real_bfp_0_in : in std_logic_vector(mpr-1 downto 0); 
         real_bfp_1_in : in std_logic_vector(mpr-1 downto 0); 
         real_bfp_2_in : in std_logic_vector(mpr-1 downto 0); 
         real_bfp_3_in : in std_logic_vector(mpr-1 downto 0); 
         imag_bfp_0_in : in std_logic_vector(mpr-1 downto 0); 
         imag_bfp_1_in : in std_logic_vector(mpr-1 downto 0); 
         imag_bfp_2_in : in std_logic_vector(mpr-1 downto 0); 
         imag_bfp_3_in : in std_logic_vector(mpr-1 downto 0); 
         bfp_factor : in std_logic_vector(2 downto 0):=(others=>'0');
         real_bfp_0_out : out std_logic_vector(mpr-1 downto 0):=(others=>'0'); 
         real_bfp_1_out : out std_logic_vector(mpr-1 downto 0):=(others=>'0'); 
         real_bfp_2_out : out std_logic_vector(mpr-1 downto 0):=(others=>'0'); 
         real_bfp_3_out : out std_logic_vector(mpr-1 downto 0):=(others=>'0'); 
         imag_bfp_0_out : out std_logic_vector(mpr-1 downto 0):=(others=>'0'); 
         imag_bfp_1_out : out std_logic_vector(mpr-1 downto 0):=(others=>'0'); 
         imag_bfp_2_out : out std_logic_vector(mpr-1 downto 0):=(others=>'0'); 
         imag_bfp_3_out : out std_logic_vector(mpr-1 downto 0):=(others=>'0')
		     );
		end component;
		
		component asj_fft_bfp_o
		generic (
						nps    : integer :=4096;
						bfp  : integer :=1;
						nume   : integer :=1;
    				mpr 	 : integer :=16;
    				arch   : integer :=0;
    				fpr 	 : integer :=5;
    				rbuspr : integer :=64 -- 4*mpr
		);
    port (
global_clock_enable : in std_logic;
         clk   		: in std_logic;
         reset 		: in std_logic;
         next_pass : in std_logic;
         data_rdy : in std_logic;
         next_blk : in std_logic;
         blk_done : in std_logic;
         gain_in_1pt	 : in std_logic_vector(3 downto 0);
			   real_bfp_0_in : in std_logic_vector(mpr-1 downto 0); 
         real_bfp_1_in : in std_logic_vector(mpr-1 downto 0); 
         real_bfp_2_in : in std_logic_vector(mpr-1 downto 0); 
         real_bfp_3_in : in std_logic_vector(mpr-1 downto 0); 
         imag_bfp_0_in : in std_logic_vector(mpr-1 downto 0); 
         imag_bfp_1_in : in std_logic_vector(mpr-1 downto 0); 
         imag_bfp_2_in : in std_logic_vector(mpr-1 downto 0); 
         imag_bfp_3_in : in std_logic_vector(mpr-1 downto 0); 
         lut_out : out std_logic_vector(2 downto 0):=(others=>'0')
		     );
    end component;
    
    component asj_fft_bfp_o_cont 
    generic (
    				mpr 	 : integer :=16;
    				bfp  : integer :=1;
    				fpr 	 : integer :=5;
    				rbuspr : integer :=64 -- 4*mpr
		);
    port (
global_clock_enable : in std_logic;
         clk   		: in std_logic;
         reset 		: in std_logic;
         next_pass : in std_logic;
         data_rdy : in std_logic;
         gain_in_1pt	 : in std_logic_vector(3 downto 0);
			   real_bfp_0_in : in std_logic_vector(mpr-1 downto 0); 
         real_bfp_1_in : in std_logic_vector(mpr-1 downto 0); 
         real_bfp_2_in : in std_logic_vector(mpr-1 downto 0); 
         real_bfp_3_in : in std_logic_vector(mpr-1 downto 0); 
         imag_bfp_0_in : in std_logic_vector(mpr-1 downto 0); 
         imag_bfp_1_in : in std_logic_vector(mpr-1 downto 0); 
         imag_bfp_2_in : in std_logic_vector(mpr-1 downto 0); 
         imag_bfp_3_in : in std_logic_vector(mpr-1 downto 0); 
         lut_out : out std_logic_vector(2 downto 0):=(others=>'0')
		     );
		end component;
    
    
    component asj_fft_bfp_o_1pt
		generic (
    				mpr 	 : integer :=16;
    				bfp  : integer :=1;
    				fpr 	 : integer :=5;
    				rbuspr : integer :=64 -- 4*mpr
		);
    port (
global_clock_enable : in std_logic;
         clk   		: in std_logic;
         reset 		: in std_logic;
         next_pass : in std_logic;
         data_rdy : in std_logic;
         real_bfp_0_in : in std_logic_vector(mpr-1 downto 0); 
         real_bfp_1_in : in std_logic_vector(mpr-1 downto 0); 
         real_bfp_2_in : in std_logic_vector(mpr-1 downto 0); 
         real_bfp_3_in : in std_logic_vector(mpr-1 downto 0); 
         imag_bfp_0_in : in std_logic_vector(mpr-1 downto 0); 
         imag_bfp_1_in : in std_logic_vector(mpr-1 downto 0); 
         imag_bfp_2_in : in std_logic_vector(mpr-1 downto 0); 
         imag_bfp_3_in : in std_logic_vector(mpr-1 downto 0); 
         gain_out : out std_logic_vector(3 downto 0):=(others=>'0')
         
		     );
    end component;
    component asj_fft_3dp_rom 
			generic(
								device_family : string;
								twr : integer :=16;
								twa : integer :=4;
								m512 : integer:=0;
								rfc1 : string :="rm.hex";
								rfc2 : string :="rm.hex";
								rfc3 : string :="rm.hex";
								rfs1 : string :="rm.hex";
								rfs2 : string :="rm.hex";
								rfs3 : string :="rm.hex"
							);
			port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
								twad   	  : in std_logic_vector(twa-1 downto 0);
								t1r				: out std_logic_vector(twr-1 downto 0):=(others=>'0');
								t2r				: out std_logic_vector(twr-1 downto 0):=(others=>'0');
								t3r				: out std_logic_vector(twr-1 downto 0):=(others=>'0');
								t1i				: out std_logic_vector(twr-1 downto 0):=(others=>'0');
								t2i				: out std_logic_vector(twr-1 downto 0):=(others=>'0');
								t3i				: out std_logic_vector(twr-1 downto 0):=(others=>'0')
					);
		end component;
		
	component	asj_fft_1tdp_rom 
	generic(
						device_family : string;
						twr : integer :=24;
						twa : integer :=8;
						m512 : integer :=3;
						rfc1 : string :="rm.hex";
						rfc2 : string :="rm.hex";
						rfc3 : string :="rm.hex";
						rfs1 : string :="rm.hex";
						rfs2 : string :="rm.hex";
						rfs3 : string :="rm.hex"
					);
	port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
						twade   	  : in std_logic_vector(twa-1 downto 0);
						twado   	  : in std_logic_vector(twa-1 downto 0);
						t1r				: out std_logic_vector(twr-1 downto 0):=(others=>'0');
						t1i				: out std_logic_vector(twr-1 downto 0):=(others=>'0')
			);
	end component;
		
		component asj_fft_3tdp_rom 
		generic(
						device_family : string;
						twr : integer :=16;
						twa : integer :=4;
						m512: integer :=0;
						rfc1 : string :="rm.hex";
						rfc2 : string :="rm.hex";
						rfc3 : string :="rm.hex";
						rfs1 : string :="rm.hex";
						rfs2 : string :="rm.hex";
						rfs3 : string :="rm.hex"
					);
		port(		clk 						: in std_logic;
global_clock_enable : in std_logic;
						twade   	  : in std_logic_vector(twa-1 downto 0);
						twado   	  : in std_logic_vector(twa-1 downto 0);
						t1re				: out std_logic_vector(twr-1 downto 0):=(others=>'0');
						t2re				: out std_logic_vector(twr-1 downto 0):=(others=>'0');
						t3re				: out std_logic_vector(twr-1 downto 0):=(others=>'0');
						t1ie				: out std_logic_vector(twr-1 downto 0):=(others=>'0');
						t2ie				: out std_logic_vector(twr-1 downto 0):=(others=>'0');
						t3ie				: out std_logic_vector(twr-1 downto 0):=(others=>'0');
						t1ro				: out std_logic_vector(twr-1 downto 0):=(others=>'0');
						t2ro				: out std_logic_vector(twr-1 downto 0):=(others=>'0');
						t3ro				: out std_logic_vector(twr-1 downto 0):=(others=>'0');
						t1io				: out std_logic_vector(twr-1 downto 0):=(others=>'0');
						t2io				: out std_logic_vector(twr-1 downto 0):=(others=>'0');
						t3io				: out std_logic_vector(twr-1 downto 0):=(others=>'0')
			);
	end component;
	
	component asj_fft_6tdp_rom 
	generic(
						device_family : string;
						twr : integer :=16;
						twa : integer :=5;
						m512 : integer:=0;
						rfc1e : string :="test_1ne256cos.hex";
						rfc2e : string :="test_2ne256cos.hex";
						rfc3e : string :="test_3ne256cos.hex";
						rfs1e : string :="test_1ne256sin.hex";
						rfs2e : string :="test_2ne256sin.hex";
						rfs3e : string :="test_3ne256sin.hex";
						rfc1o : string :="test_1ne256cos.hex";
						rfc2o : string :="test_2no256cos.hex";
						rfc3o : string :="test_3no256cos.hex";
						rfs1o : string :="test_1no256sin.hex";
						rfs2o : string :="test_2no256sin.hex";
						rfs3o : string :="test_3no256sin.hex"
					);
	port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
						twade_0   	  : in std_logic_vector(twa-1 downto 0);
						twade_1   	  : in std_logic_vector(twa-1 downto 0);
						twado_0   	  : in std_logic_vector(twa-1 downto 0);
						twado_1   	  : in std_logic_vector(twa-1 downto 0);
						t1w				: out std_logic_vector(2*twr-1 downto 0):=(others=>'0');
						t2w				: out std_logic_vector(2*twr-1 downto 0):=(others=>'0');
						t3w				: out std_logic_vector(2*twr-1 downto 0):=(others=>'0');
						t1x				: out std_logic_vector(2*twr-1 downto 0):=(others=>'0');
						t2x				: out std_logic_vector(2*twr-1 downto 0):=(others=>'0');
						t3x				: out std_logic_vector(2*twr-1 downto 0):=(others=>'0');
						t1y				: out std_logic_vector(2*twr-1 downto 0):=(others=>'0');
						t2y				: out std_logic_vector(2*twr-1 downto 0):=(others=>'0');
						t3y				: out std_logic_vector(2*twr-1 downto 0):=(others=>'0');
						t1z				: out std_logic_vector(2*twr-1 downto 0):=(others=>'0');
						t2z				: out std_logic_vector(2*twr-1 downto 0):=(others=>'0');
						t3z				: out std_logic_vector(2*twr-1 downto 0):=(others=>'0')
			);
	end component;

	
	component asj_fft_dp_mram is
		generic(
					device_family : string;
					dpr : integer :=128;
					apr : integer :=9
					);
		port
		(
global_clock_enable : in std_logic;
					data		: in std_logic_vector (dpr-1 downto 0);
					wren		: in std_logic  := '1';
					wraddress		: in std_logic_vector (apr-1 downto 0);
					rdaddress		: in std_logic_vector (apr-1 downto 0);
					clock		: in std_logic ;
					q		: out std_logic_vector (dpr-1 downto 0)
		);
	end component;
	
	component asj_fft_dpi_mram 
	generic(
					device_family : string; 
					dpr : integer :=128; 
					apr : integer :=8;
					bytesize : integer :=8;
					bpr : integer :=16
	);
	port
	(
global_clock_enable : in std_logic;
		data		: in std_logic_vector (dpr-1 downto 0);
		wren		: in std_logic  := '1';
		wraddress		: in std_logic_vector (apr-1 downto 0);
		rdaddress		: in std_logic_vector (apr-1 downto 0);
		byteena_a		: in std_logic_vector (bpr-1 downto 0) :=  (others => '1');
		clock		: in std_logic ;
		q		: out std_logic_vector (dpr-1 downto 0)
	);
	end component;
	
	
	component asj_fft_3pi_mram 
	generic(
					device_family : string; 
					dpr : integer :=192; 
					apr : integer :=12;
					bytesize : integer :=8;
					bpr : integer :=24
	);
	port
	(
global_clock_enable : in std_logic;
		data_a		: in std_logic_vector (dpr-1 downto 0);
		wren_a		: in std_logic  := '1';
		address_a		: in std_logic_vector (apr-1 downto 0);
		data_b		: in std_logic_vector (dpr-1 downto 0):=  (others => '0');
		address_b		: in std_logic_vector (apr-1 downto 0);
		wren_b		: in std_logic  := '1';
		byteena_a		: in std_logic_vector (bpr-1 downto 0) :=  (others => '1');
		clock		: in std_logic ;
		q_a		: out std_logic_vector (dpr-1 downto 0);
		q_b		: out std_logic_vector (dpr-1 downto 0)
	);
	end component;
	
	component asj_fft_1tdp_ram 
	generic(
						apr : integer :=4;
						mpr : integer :=16;
						rfd  : string :="AUTO"
						
					);
	port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
						rdaddress   	  : in std_logic_vector(apr-1 downto 0);
						wraddress				: in std_logic_vector(apr-1 downto 0);
						data_in				  : in std_logic_vector(2*mpr-1 downto 0);
						wren            : in std_logic;
						rden            : in std_logic;
						data_out				: out std_logic_vector(4*mpr-1 downto 0)
			);
	end component;
	
	
  component asj_fft_data_ram 
		generic(	device_family : string;
               dpr : integer :=16;
					apr : integer :=8;
					rfd : string :="init.hex"
		);
		port
		(
global_clock_enable : in std_logic;
			data		: in std_logic_vector (dpr-1 downto 0);
			wren		: in std_logic  := '1';
			rden		: in std_logic  := '1';
			wraddress		: in std_logic_vector (apr-1 downto 0);
			rdaddress		: in std_logic_vector (apr-1 downto 0);
			clock		: in std_logic ;
			q		: out std_logic_vector (dpr-1 downto 0)
		);
	end component;
	
	component asj_fft_data_ram_dp 
		generic(
						device_family : string;
						dpr : integer :=32;-- 2*mpr
						apr : integer :=8;-- 2*mpr
						rfd : string :="auto" -- ram resource
						);
		port
		(
global_clock_enable : in std_logic;
			data_a		: in std_logic_vector (dpr-1 downto 0);
			wren_a		: in std_logic  := '1';
			address_a		: in std_logic_vector (apr-1 downto 0);
			data_b		: in std_logic_vector (dpr-1 downto 0);
			address_b		: in std_logic_vector (apr-1 downto 0);
			wren_b		: in std_logic  := '1';
			clock		: in std_logic ;
			q_a		: out std_logic_vector (dpr-1 downto 0);
			q_b		: out std_logic_vector (dpr-1 downto 0)
		);
	end component;
		
	component twid_rom 
		generic(
						device_family : string;
						twa : integer :=8;
						twr : integer :=16;
						m512 : integer:=0;
						rf  : string  :="rom.hex"
		);
		port(
global_clock_enable : in std_logic;
						address		: IN STD_LOGIC_VECTOR (twa-1 DOWNTO 0);
						clock		: IN STD_LOGIC ;
						q		: OUT STD_LOGIC_VECTOR (twr-1 DOWNTO 0)
		);
	end component;
		
	component asj_fft_twid_rom_tdp 
		generic(
						device_family : string;
						twr : integer := 16;
						twa : integer := 8;
						m512 : integer:=0;
						rf  : string  :="rf.hex"
			);
		port
			(
global_clock_enable : in std_logic;
			clock		: IN STD_LOGIC ;
			address_a		: IN STD_LOGIC_VECTOR (twa-1 DOWNTO 0);
			address_b		: IN STD_LOGIC_VECTOR (twa-1 DOWNTO 0);
			q_a		: OUT STD_LOGIC_VECTOR (twr-1 DOWNTO 0);
			q_b		: OUT STD_LOGIC_VECTOR (twr-1 DOWNTO 0)
		);
	end component;

end fft_pack;



package body fft_pack is

	function sgn_ex(inval : std_logic_vector; w : integer; b : integer) return std_logic_vector is
	-- sign extend input std_logic_vector of width w by b bits
	variable temp :   std_logic_vector(w+b-1 downto 0);
	begin
		temp(w+b-1 downto w-1):=(w+b-1 downto w-1 => inval(w-1));
		temp(w-2 downto 0) := inval(w-2 downto 0);
	return temp;
	end	sgn_ex;
	
	function int2ustd(value : integer; width : integer) return std_logic_vector is 
	-- convert integer to unsigned std_logicvector
		variable temp :   std_logic_vector(width-1 downto 0);
		begin
			if (width>0) then 
				temp:=conv_std_logic_vector(conv_unsigned(value, width ), width);
			end if ;
		return temp;
	end int2ustd;
	
	function int2bit(value : integer) return std_logic is 
	-- convert integer to std_logic
		variable temp :   std_logic;
		begin
			if (value=0) then 
				temp:='0';
			else
				temp:='1';
		end if ;
		return temp;
	end int2bit;

    function GET_BYTE_SIZE(dpr : in integer) return integer is
      variable temp : integer;
    	begin
        if (dpr=144) then
        	temp := 9;
        else
        	temp := 8;
        end if;
      return temp;
    end GET_BYTE_SIZE;

    function LOG2_CEIL(a : in integer) return integer is
        variable y : integer;
    begin
        y := 0;
        for i in 0 to 30 loop
            if (a > (2**i)) then
                y := i+1;
            end if;
        end loop;  -- i
        return y;
    end LOG2_CEIL;

    function LOG10_CEIL(a : in integer) return integer is
        variable y : integer;
    begin
        y := 0;
        for i in 0 to 30 loop
            if (a > (10**i)) then
                y := i+1;
            end if;
        end loop;  -- i
        return y;
    end LOG10_CEIL;

    
    function LOG4_CEIL(a : in integer) return integer is
        variable y : integer;
    begin
        y := 0;
        for i in 0 to 15 loop            
            if (a > (4**i)) then
                y := i+1;
            end if;
        end loop;  -- i
        return y;
    end LOG4_CEIL;
    

    function LOG2_FLOOR(a : in integer) return integer is
        variable y : integer;
    begin
        y := 0;
        for i in 0 to 30 loop            
            if (a >= (2**i)) then
                y := i;
            end if;
        end loop;  -- i
        return y;
    end LOG2_FLOOR;

    function LOG4_FLOOR(a : in integer) return integer is
        variable y : integer;
    begin
        y := 0;
        for i in 0 to 15 loop            
            if (a >= (4**i)) then
                y := i;
            end if;
        end loop;  -- i
        return y;
    end LOG4_FLOOR;

    function max(L, R: INTEGER) return INTEGER is
    begin
	if L > R then
	    return L;
	else
	    return R;
	end if;
    end;
    
    function minimum(L, R: INTEGER) return INTEGER is
    begin
	if L > R then
	    return R;
	else
	    return L;
	end if;
    end;
    
    function abs_aminusb(L, R: INTEGER) return INTEGER is
    begin
	if L > R then
	    return L-R;
	else
	    return R-L;
	end if;
    end;

end fft_pack;
