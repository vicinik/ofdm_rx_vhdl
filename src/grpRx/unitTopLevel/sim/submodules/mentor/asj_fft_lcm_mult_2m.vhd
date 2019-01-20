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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_lcm_mult_2m.vhd#1 $ 
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



-- Used when only mpr >18

entity asj_fft_lcm_mult_2m is
    generic (mpr : integer :=18;
    				 twr : integer := 16;
    				 use_dedicated_for_all : integer := 0;
    				 -- additional pipeline for std implementation
    				 -- if pipe = 1 overall latency = 5
    				 -- else overall latency = 3
    				 -- take away 2 delay stages on std output
    				 pipe : integer :=1
		);
    port (
global_clock_enable : in std_logic;
         clk   				 : in std_logic;
         dataa : in std_logic_vector(mpr-1 downto 0);
		     datab : in std_logic_vector(twr-1 downto 0);
		     result : out std_logic_vector(mpr+twr-1 downto 0)
		     );
end asj_fft_lcm_mult_2m;

architecture mult of asj_fft_lcm_mult_2m is

	constant num_lsbs_dat : integer := mpr-18;
	constant num_lsbs_coef : integer := twr-18;
	constant m_p : integer :=2+pipe;
	

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
	
	
  signal hahb_full  : std_logic_vector(mpr+twr-1 downto 0);
  signal lahb_full  : std_logic_vector(mpr+twr-1 downto 0);
  signal lalb_full  : std_logic_vector(mpr+twr-1 downto 0);
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
  signal sgn0 : std_logic ;
  signal sgn1 : std_logic ;
  signal sgn2 : std_logic ;
  
  begin
  	
  vcc <='1';
  	
  
		higha <= dataa(mpr-1 downto mpr-18);
		highb2 <= datab(twr-1 downto 0);
		
		lowa  <= '0' & (dataa(mpr-19 downto 0));-- xor (mpr-19 downto 0 => dataa(mpr-1));-- + int2ustd(conv_integer(dataa(mpr-1)),num_lsbs_dat);
		
		m_hahb : 	lpm_mult
		generic map(lpm_widtha=>18,
								lpm_widthb=>twr,
								lpm_widthp=>twr+18,
								lpm_widths=>1,
								LPM_REPRESENTATION => "SIGNED",
								LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",
								LPM_PIPELINE=>m_p
					)
		port map (	clock =>clk,
clken => global_clock_enable,
								dataa =>higha,
								datab =>highb2,
								result =>resulthahb2
				);
		
		gen_le_based : if(use_dedicated_for_all=0) generate
		
			m_lahb : 	lpm_mult
			generic map(lpm_widtha=>num_lsbs_dat+1,
									lpm_widthb=>twr,
									lpm_widthp=>twr+num_lsbs_dat+1,
									lpm_widths=>1,
									LPM_REPRESENTATION => "SIGNED",
									LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=NO,MAXIMIZE_SPEED=9",
									LPM_PIPELINE=>m_p
						)
			port map (	clock =>clk,
clken => global_clock_enable,
						dataa =>lowa,
						datab =>highb2,
						result =>resultlahb2
					);
		end generate gen_le_based;
				
		gen_ded : if(use_dedicated_for_all=1) generate
		
			m_lahb : 	lpm_mult
			generic map(lpm_widtha=>num_lsbs_dat+1,
									lpm_widthb=>twr,
									lpm_widthp=>twr+num_lsbs_dat+1,
									lpm_widths=>1,
									LPM_REPRESENTATION => "SIGNED",
									LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",
									LPM_PIPELINE=>m_p
						)
			port map (	clock =>clk,
clken => global_clock_enable,
						dataa =>lowa,
						datab =>highb2,
						result =>resultlahb2
					);
		end generate gen_ded;
				
			
		--hahb_full(mpr+twr-1 downto 0) <= resulthahb2(18+twr-1 downto 0) & (mpr-1-18 downto 0 => '0');
		--lahb_full(mpr+twr-1 downto 0) <=(mpr+twr-1-(num_lsbs_dat+twr+1) downto 0 => resultlahb2(twr+num_lsbs_dat)) & (resultlahb2(twr+num_lsbs_dat downto 0)) ;
		--add_1 : 	lpm_add_sub
		--	generic map(lpm_width=> mpr+twr,
		--						--lpm_pipeline => 1+pipe,
		--						lpm_pipeline => 0+pipe,
		--						lpm_representation=>"SIGNED"
		--						)
		--	port map( clock=>clk,
		--						add_sub => vcc,
		--						dataa=>hahb_full,
		--						datab=>lahb_full,
		--						result=>hahblahb
		--	);
		--result <= hahblahb;
		
		
		
reg_mult_out:process(clk,global_clock_enable)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					hahb_full(mpr+twr-1 downto 0) <= resulthahb2(18+twr-1 downto 0) & (mpr-1-18 downto 0 => '0');
					lahb_full(mpr+twr-1 downto 0) <=(mpr+twr-1-(num_lsbs_dat+twr+1) downto 0 => resultlahb2(twr+num_lsbs_dat)) & (resultlahb2(twr+num_lsbs_dat downto 0)) ;
				end if;
			end process reg_mult_out;
				
					
			result <= hahb_full + lahb_full;
				
 
end mult;











