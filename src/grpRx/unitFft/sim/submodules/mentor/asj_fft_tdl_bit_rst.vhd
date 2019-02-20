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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_tdl_bit_rst.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

library ieee;                              
use ieee.std_logic_1164.all;               
use ieee.std_logic_arith.all; 
use ieee.std_logic_unsigned.all;
use work.fft_pack.all;
-- TDL For single-bit delay register chains

entity asj_fft_tdl_bit_rst is 
generic( 
				 del    : integer :=2
				);
port( 	clk 			: in std_logic;
global_clock_enable : in std_logic;
				reset   	: in std_logic;
		 		data_in 	: in std_logic;
		 		data_out 	: out std_logic
		);

end asj_fft_tdl_bit_rst;


architecture syn of asj_fft_tdl_bit_rst is 

constant counter_based 	: integer := 1;
constant log2_del 			: integer := LOG2_CEIL(del);

signal tdl_bit 	: std_logic;
signal tdl_arr 	: std_logic_vector(del-1 downto 0);


begin

	gen_no_del : if(del=0) generate
		data_out <= data_in;
	end generate gen_no_del;
	
	gen_del : if(del>0) generate
	
	data_out <= tdl_arr(del-1);
	
tdl:process(clk,global_clock_enable,data_in,tdl_arr)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				if(reset='1') then
					for i in del-1 downto 0 loop
						tdl_arr(i)<='0';
					end loop;
				else
					for i in del-1 downto 1 loop
						tdl_arr(i)<=tdl_arr(i-1);
					end loop;
					tdl_arr(0) <= data_in;
				end if;
			end if;
		end process tdl;
	
	end generate gen_del;



	
  
end syn;
