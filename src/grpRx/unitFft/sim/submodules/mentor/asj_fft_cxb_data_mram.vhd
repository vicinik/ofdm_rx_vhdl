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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_cxb_data_mram.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

library ieee;                              
use ieee.std_logic_1164.all;               
use ieee.std_logic_arith.all; 
use ieee.std_logic_unsigned.all;
use work.fft_pack.all;

-- cross bar switch control of RAM selection for MRAM Input

entity asj_fft_cxb_data_mram is 
generic( mpr  	: integer :=16;
				 xbw    : integer :=4;
				 pipe   : integer :=1
				);
port( 	clk 			: in std_logic;
global_clock_enable : in std_logic;
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

end asj_fft_cxb_data_mram;


architecture syn of asj_fft_cxb_data_mram is 

	 
signal vcc : std_logic;
signal gnd : std_logic;
signal ram_sel_int : std_logic;

type ram_input_array is array (0 to 15) of std_logic_vector(mpr-1 downto 0);
signal ram_in_reg : ram_input_array;

begin
	gnd <= '0';
	vcc <= '1';

	ram_sel_int <= ram_sel;
	
	
  
  gen_crossbar_registered_dual_mux : if(pipe=1) generate
  
  sw_0_out <= ram_in_reg(0) & ram_in_reg(8);
	sw_1_out <= ram_in_reg(1) & ram_in_reg(9);
	sw_2_out <= ram_in_reg(2) & ram_in_reg(10);
	sw_3_out <= ram_in_reg(3) & ram_in_reg(11);
	sw_4_out <= ram_in_reg(4) & ram_in_reg(12);
	sw_5_out <= ram_in_reg(5) & ram_in_reg(13);
	sw_6_out <= ram_in_reg(6) & ram_in_reg(14);
	sw_7_out <= ram_in_reg(7) & ram_in_reg(15);
	
	
	
  
reg_cxb_r:process(clk,global_clock_enable,ram_sel_int,sw_0_in,sw_1_in,sw_2_in,sw_3_in,sw_4_in,sw_5_in,sw_6_in,sw_7_in)is
  begin
if((rising_edge(clk) and global_clock_enable='1'))then
  			if(ram_sel_int='0') then
  	  		ram_in_reg(0) <= sw_0_in(2*mpr-1 downto mpr);
  	  		ram_in_reg(1) <= sw_4_in(2*mpr-1 downto mpr);
  	  		ram_in_reg(2) <= sw_1_in(2*mpr-1 downto mpr);
  	  		ram_in_reg(3) <= sw_5_in(2*mpr-1 downto mpr);
  	  		ram_in_reg(4) <= sw_2_in(2*mpr-1 downto mpr);
  	  		ram_in_reg(5) <= sw_6_in(2*mpr-1 downto mpr);
  	  		ram_in_reg(6) <= sw_3_in(2*mpr-1 downto mpr);
  	  		ram_in_reg(7) <= sw_7_in(2*mpr-1 downto mpr);
				else
  	  		ram_in_reg(0) <= sw_2_in(2*mpr-1 downto mpr);
  	  		ram_in_reg(1) <= sw_6_in(2*mpr-1 downto mpr);
  	  		ram_in_reg(2) <= sw_3_in(2*mpr-1 downto mpr);
  	  		ram_in_reg(3) <= sw_7_in(2*mpr-1 downto mpr);
  	  		ram_in_reg(4) <= sw_0_in(2*mpr-1 downto mpr);
  	  		ram_in_reg(5) <= sw_4_in(2*mpr-1 downto mpr);
  	  		ram_in_reg(6) <= sw_1_in(2*mpr-1 downto mpr);
  	  		ram_in_reg(7) <= sw_5_in(2*mpr-1 downto mpr);
				end if;
		end if;
	end process reg_cxb_r;	  	  	
	
reg_cxb_i:process(clk,global_clock_enable,ram_sel_int,sw_0_in,sw_1_in,sw_2_in,sw_3_in,sw_4_in,sw_5_in,sw_6_in,sw_7_in)is
  begin
if((rising_edge(clk) and global_clock_enable='1'))then
  		if(ram_sel_int='0') then
  	  	ram_in_reg(8)  <= sw_0_in(mpr-1 downto 0);
  	  	ram_in_reg(9)  <= sw_4_in(mpr-1 downto 0);
  	  	ram_in_reg(10) <= sw_1_in(mpr-1 downto 0);
  	  	ram_in_reg(11) <= sw_5_in(mpr-1 downto 0);
  	  	ram_in_reg(12) <= sw_2_in(mpr-1 downto 0);
  	  	ram_in_reg(13) <= sw_6_in(mpr-1 downto 0);
  	  	ram_in_reg(14) <= sw_3_in(mpr-1 downto 0);
  	  	ram_in_reg(15) <= sw_7_in(mpr-1 downto 0);
  	  else                    
  	  	ram_in_reg(8)  <= sw_2_in(mpr-1 downto 0);
  	  	ram_in_reg(9)  <= sw_6_in(mpr-1 downto 0);
  	  	ram_in_reg(10) <= sw_3_in(mpr-1 downto 0);
  	  	ram_in_reg(11) <= sw_7_in(mpr-1 downto 0);
  	  	ram_in_reg(12) <= sw_0_in(mpr-1 downto 0);
  	  	ram_in_reg(13) <= sw_4_in(mpr-1 downto 0);
  	  	ram_in_reg(14) <= sw_1_in(mpr-1 downto 0);
  	  	ram_in_reg(15) <= sw_5_in(mpr-1 downto 0);
  	  end if;
		end if;
	end process reg_cxb_i;	  	  	

	
  end generate gen_crossbar_registered_dual_mux;

  
  

end syn;
