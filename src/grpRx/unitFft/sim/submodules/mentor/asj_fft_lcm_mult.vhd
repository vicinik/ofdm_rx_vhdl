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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_lcm_mult.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all; 
use work.fft_pack.all;
library lpm;
use lpm.lpm_components.all;
library altera_mf;
use altera_mf.altera_mf_components.all;



entity asj_fft_lcm_mult is
    generic (mpr : integer :=24;
    				 twr : integer := 24;
    				 -- additional pipeline for std implementation
    				 -- if pipe = 1 overall latency = 5
    				 -- else overall latency = 3
    				 -- take away 2 delay stages on std output
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
end asj_fft_lcm_mult;

architecture mult of asj_fft_lcm_mult is

	constant num_lsbs_dat : integer := mpr-18;
	constant num_lsbs_coef : integer := twr-18;
	constant m_p : integer :=2+pipe;
	-------------------------------------------------------------------------------------------------
	-- 0 : To use dedicated resources only for single 18*18
	-- 1 : To use dedicated resources only for extended multiplier
	--constant use_dedicated_for_all : integer :=1;
	

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
	



	 

	
	signal higha : std_logic_vector(17 downto 0);
	signal highb : std_logic_vector(17 downto 0);        
	signal highb2 : std_logic_vector(twr-1 downto 0);        
	signal lowa : std_logic_vector(mpr-18 downto 0);
	signal lowb : std_logic_vector(twr-18 downto 0);
	
	signal resultlalb : std_logic_vector(num_lsbs_dat+1+ num_lsbs_coef+1-1  downto 0);
  signal resulthalb : std_logic_vector(18+num_lsbs_coef+1-1 downto 0);	
  signal resultlahb : std_logic_vector(18+num_lsbs_dat+1-1 downto 0);	
  signal resulthahb : std_logic_vector(35 downto 0);
  
  signal hahb_full  : std_logic_vector(mpr+twr-1 downto 0);
  signal halb_full  : std_logic_vector(mpr+twr-1 downto 0);
  signal lahb_full  : std_logic_vector(mpr+twr-1 downto 0);
  signal lalb_full  : std_logic_vector(mpr+twr-1 downto 0);
  signal halb_full_2m  : std_logic_vector(mpr+twr-1 downto 0);
  signal lalb_full_2m  : std_logic_vector(mpr+twr-1 downto 0);
  
  signal halblahb   : std_logic_vector(mpr+twr-1 downto 0);
  signal hahblalb   : std_logic_vector(mpr+twr-1 downto 0);
  signal hahblahb   : std_logic_vector(mpr+twr-1 downto 0);
  
  signal halblahb_full   : std_logic_vector(mpr+twr-1 downto 0);
  signal hahblalb_full   : std_logic_vector(mpr+twr-1 downto 0);     
  
  signal resulthahb2 : std_logic_vector(18+twr-1 downto 0);
  signal resultlahb2 : std_logic_vector(twr+num_lsbs_dat downto 0);
  
  
  
  signal result_int : std_logic_vector(mpr+twr-1 downto 0);
  signal result_p2 : std_logic_vector(mpr+1 downto 0);
  signal vcc : std_logic;
  signal sgn0 : std_logic;
  signal sgn1 : std_logic;
  signal sgn2 : std_logic;
  
  begin
  	
  vcc <='1';
  	
  
		higha <= dataa(mpr-1 downto mpr-18);-- xor (17 downto 0 => dataa(mpr-1));
		highb <= datab(twr-1 downto twr-18);-- xor (17 downto 0 => dataa(mpr-1));
		
		lowa  <= '0' & (dataa(mpr-19 downto 0));-- xor (mpr-19 downto 0 => dataa(mpr-1));-- + int2ustd(conv_integer(dataa(mpr-1)),num_lsbs_dat);
		lowb  <= '0' & (datab(twr-19 downto 0));-- xor (twr-19 downto 0 => datab(twr-1));-- + int2ustd(conv_integer(datab(twr-1)),num_lsbs_coef);
				
		gen_single_dedicated : if(use_dedicated_for_all=0) generate
			
			m_hahb : 	lpm_mult
			generic map(lpm_widtha=>18,
									lpm_widthb=>18,
									lpm_widthp=>36,
									lpm_widths=>1,
									LPM_REPRESENTATION => "SIGNED",
									LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",
									LPM_PIPELINE=>m_p
						)
			port map (	clock =>clk,
clken => global_clock_enable,
									dataa =>higha,
									datab =>highb,
									result =>resulthahb
					);
					
			m_lahb : 	lpm_mult
			generic map(lpm_widtha=>num_lsbs_dat+1,
									lpm_widthb=>18,
									lpm_widthp=>18+num_lsbs_dat+1,
									lpm_widths=>1,
									LPM_REPRESENTATION => "SIGNED",
									LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=NO,MAXIMIZE_SPEED=9",
									LPM_PIPELINE=>m_p
						)
			port map (	clock =>clk,
clken => global_clock_enable,
						dataa =>lowa,
						datab =>highb,
						result =>resultlahb
					);
					
			m_halb : 	lpm_mult
			generic map(lpm_widtha=>18,
									lpm_widthb=>num_lsbs_coef+1,
									lpm_widthp=>18+num_lsbs_coef+1,
									lpm_widths=>1,
									LPM_REPRESENTATION => "SIGNED",
									LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=NO,MAXIMIZE_SPEED=9",
									LPM_PIPELINE=>m_p
						)
			port map (	clock =>clk,
clken => global_clock_enable,
						dataa =>higha,
						datab =>lowb,
						result =>resulthalb
					);
			m_lalb : 	lpm_mult
			generic map(
			            lpm_widtha=>num_lsbs_dat+1,
									lpm_widthb=>num_lsbs_coef+1,
									lpm_widths=>1,
									lpm_widthp=>num_lsbs_coef + num_lsbs_dat + 2,
									LPM_REPRESENTATION => "UNSIGNED",
									LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=NO,MAXIMIZE_SPEED=9",
									LPM_PIPELINE=>m_p
						)
			port map (	clock =>clk,
clken => global_clock_enable,
						dataa =>lowa,
						datab =>lowb,
						result =>resultlalb
					);	
		end generate gen_single_dedicated;
		
		gen_dedicated_for_all : if(use_dedicated_for_all=1) generate
			
			m_hahb : 	lpm_mult
			generic map(lpm_widtha=>18,
									lpm_widthb=>18,
									lpm_widthp=>36,
									lpm_widths=>1,
									LPM_REPRESENTATION => "SIGNED",
									LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=6",
									LPM_PIPELINE=>m_p
						)
			port map (	clock =>clk,
clken => global_clock_enable,
									dataa =>higha,
									datab =>highb,
									result =>resulthahb
					);
					
			m_lahb : 	lpm_mult
			generic map(lpm_widtha=>num_lsbs_dat+1,
									lpm_widthb=>18,
									lpm_widthp=>18+num_lsbs_dat+1,
									lpm_widths=>1,
									LPM_REPRESENTATION => "SIGNED",
									LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=6",
									LPM_PIPELINE=>m_p
						)
			port map (	clock =>clk,
clken => global_clock_enable,
						dataa =>lowa,
						datab =>highb,
						result =>resultlahb
					);
					
			m_halb : 	lpm_mult
			generic map(lpm_widtha=>18,
									lpm_widthb=>num_lsbs_coef+1,
									lpm_widthp=>18+num_lsbs_coef+1,
									lpm_widths=>1,
									LPM_REPRESENTATION => "SIGNED",
									LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=6",
									LPM_PIPELINE=>m_p
						)
			port map (	clock =>clk,
clken => global_clock_enable,
						dataa =>higha,
						datab =>lowb,
						result =>resulthalb
					);
			m_lalb : 	lpm_mult
			generic map(
			            lpm_widtha=>num_lsbs_dat+1,
									lpm_widthb=>num_lsbs_coef+1,
									lpm_widths=>1,
									lpm_widthp=>num_lsbs_coef + num_lsbs_dat + 2,
									LPM_REPRESENTATION => "UNSIGNED",
									LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=6",
									LPM_PIPELINE=>m_p
						)
			port map (	clock =>clk,
clken => global_clock_enable,
						dataa =>lowa,
						datab =>lowb,
						result =>resultlalb
					);	
		end generate gen_dedicated_for_all;
		
		
				
							
		gen_eq : if(mpr=twr) generate
				hahb_full(mpr+twr-1 downto 0) <= resulthahb(35 downto 0) & (mpr+twr-1-36 downto 0 => '0');
				lahb_full(mpr+twr-1 downto 0) <=((mpr+twr-18-num_lsbs_coef-num_lsbs_dat-1 downto 0 => resultlahb(18+num_lsbs_dat)) & (resultlahb(18+num_lsbs_dat-1 downto 0) & (num_lsbs_dat-1 downto 0=>'0'))) ;
				halb_full(mpr+twr-1 downto 0) <=((mpr+twr-18-num_lsbs_coef-num_lsbs_dat-1 downto 0 => resulthalb(18+num_lsbs_coef)) & (resulthalb(18+num_lsbs_coef-1 downto 0) & (num_lsbs_coef-1 downto 0=>'0')));	
				lalb_full(mpr+twr-1 downto 0) <= sgn_ex(resultlalb,num_lsbs_coef + num_lsbs_dat + 2 ,mpr+twr-num_lsbs_coef-num_lsbs_dat-2);				
		end generate gen_eq;
			
		gen_neq : if(mpr/=twr) generate
				hahb_full(mpr+twr-1 downto 0) <= resulthahb(35 downto 0) & (mpr+twr-1-36 downto 0 => '0');
				lahb_full(mpr+twr-1 downto 0) <=((mpr+twr-18-num_lsbs_coef-num_lsbs_dat-1 downto 0 => resultlahb(18+num_lsbs_dat)) & (resultlahb(18+num_lsbs_dat-1 downto 0) & (num_lsbs_coef-1 downto 0=>'0'))) ;
				halb_full(mpr+twr-1 downto 0) <=((mpr+twr-18-num_lsbs_coef-num_lsbs_dat-1 downto 0 => resulthalb(18+num_lsbs_coef)) & (resulthalb(18+num_lsbs_coef-1 downto 0) & (num_lsbs_dat-1 downto 0=>'0')));	
				lalb_full(mpr+twr-1 downto 0) <= sgn_ex(resultlalb,num_lsbs_coef + num_lsbs_dat + 2 ,mpr+twr-num_lsbs_coef-num_lsbs_dat-2);				
		end generate gen_neq;
			
		
		
			
-- 		add_1 : 	lpm_add_sub
-- 			generic map(lpm_width=> mpr+twr,
-- 						lpm_pipeline => 1,
-- 						lpm_representation=>"SIGNED"
-- 						)
-- 			port map( clock=>clk,
-- 						add_sub => vcc,
-- 						dataa=>halb_full,
-- 						datab=>lahb_full,
-- 						result=>halblahb
-- 					);
add_1:process(clk,global_clock_enable)is
  begin  -- process add_1
if(rising_edge(clk) and global_clock_enable='1')then--risingclockedge
          halblahb <= halb_full + lahb_full;
      end if;
  end process add_1;
					
-- 		add_2 : 	lpm_add_sub
-- 			generic map(lpm_width=> mpr+twr,
-- 						lpm_pipeline => 1,
-- 						lpm_representation=>"SIGNED"
-- 						)
-- 			port map( 	clock=>clk,
-- 						dataa=>hahb_full,
-- 						add_sub => vcc,
-- 						datab=>lalb_full,
-- 						result=>hahblalb
-- 					);
add_2:process(clk,global_clock_enable)is
    begin  -- process add_2
if(rising_edge(clk) and global_clock_enable='1')then--risingclockedge
            hahblalb <= hahb_full + lalb_full;
        end if;
    end process add_2;
		
				result <= hahblalb + halblahb;						
			--	add_3 : 	lpm_add_sub
			--generic map(lpm_width=> mpr+twr,
			--			lpm_pipeline => 1,
			--			lpm_representation=>"SIGNED"
			--			)
			--port map( 	clock=>clk,
			--			dataa=>halblahb,
			--			add_sub => vcc,
			--			datab=>hahblalb,
			--			result=>result
			--		);
					
end mult;











