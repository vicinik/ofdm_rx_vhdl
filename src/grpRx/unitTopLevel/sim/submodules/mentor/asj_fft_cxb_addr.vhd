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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_cxb_addr.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

library ieee;                              
use ieee.std_logic_1164.all;               
use ieee.std_logic_arith.all; 
use ieee.std_logic_unsigned.all;
use work.fft_pack.all;
-- cross bar switch control of RAM selection for butterfly inputs/outputs

entity asj_fft_cxb_addr is 
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

end asj_fft_cxb_addr;


architecture syn of asj_fft_cxb_addr is 

	 
signal vcc : std_logic;
signal gnd : std_logic;
signal ram_sel_int : std_logic_vector(1 downto 0);

type ram_input_array is array (0 to 3) of std_logic_vector(mpr-1 downto 0);
signal ram_in_reg : ram_input_array;

type wr_addr_delay  is array (0 to del-1) of std_logic_vector(mpr-1 downto 0);
signal sw_0_arr,sw_1_arr,sw_2_arr,sw_3_arr : wr_addr_delay;
signal sw_0_in_d : std_logic_vector(mpr-1 downto 0);
signal sw_1_in_d : std_logic_vector(mpr-1 downto 0);
signal sw_2_in_d : std_logic_vector(mpr-1 downto 0);
signal sw_3_in_d : std_logic_vector(mpr-1 downto 0);


begin
	gnd <= '0';
	vcc <= '1';

	ram_sel_int <= ram_sel;
	
	sw_0_out <= ram_in_reg(0);
	sw_1_out <= ram_in_reg(1);
	sw_2_out <= ram_in_reg(2);
	sw_3_out <= ram_in_reg(3);
	
	gen_no_tdl_output : if(del=0) generate
	
		sw_0_in_d <= sw_0_in;
		sw_1_in_d <= sw_1_in;
		sw_2_in_d <= sw_2_in;
		sw_3_in_d <= sw_3_in;
	
	end generate gen_no_tdl_output;
	
	gen_tdl_output : if(del/=0) generate
	
	sw_0_in_d <= sw_0_arr(del-1);
	sw_1_in_d <= sw_1_arr(del-1);
	sw_2_in_d <= sw_2_arr(del-1);
	sw_3_in_d <= sw_3_arr(del-1);

tdl:process(clk,global_clock_enable,ram_in_reg)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				for i in del-1 downto 1 loop
					sw_0_arr(i)<=sw_0_arr(i-1);
					sw_1_arr(i)<=sw_1_arr(i-1);
					sw_2_arr(i)<=sw_2_arr(i-1);
					sw_3_arr(i)<=sw_3_arr(i-1);
				end loop;
				sw_0_arr(0) <= sw_0_in;
				sw_1_arr(0) <= sw_1_in;
				sw_2_arr(0) <= sw_2_in;
				sw_3_arr(0) <= sw_3_in;
			end if;
		end process tdl;
	
	end generate gen_tdl_output;
	
	
  gen_crossbar_registered : if(pipe=1) generate
  -- output
	
  
reg_cxb:process(clk,global_clock_enable,ram_sel_int,sw_0_in,sw_1_in,sw_2_in,sw_3_in)is
  begin
if((rising_edge(clk) and global_clock_enable='1'))then
  			case ram_sel_int is
  	  		when "00"=>
  	  			ram_in_reg(0) <= sw_0_in_d;
  	  			ram_in_reg(1) <= sw_1_in_d;
  	  			ram_in_reg(2) <= sw_2_in_d;
  	  			ram_in_reg(3) <= sw_3_in_d;
  	  		when "01"=>               
  	  			ram_in_reg(0) <= sw_3_in_d;
  	  			ram_in_reg(1) <= sw_0_in_d;
  	  			ram_in_reg(2) <= sw_1_in_d;
  	  			ram_in_reg(3) <= sw_2_in_d;
  	  		when "10"=>               
  	  			ram_in_reg(0) <= sw_2_in_d;
  	  			ram_in_reg(1) <= sw_3_in_d;
  	  			ram_in_reg(2) <= sw_0_in_d;
  	  			ram_in_reg(3) <= sw_1_in_d;
  	  		when "11"=>               
  	  			ram_in_reg(0) <= sw_1_in_d;
  	  			ram_in_reg(1) <= sw_2_in_d;
  	  			ram_in_reg(2) <= sw_3_in_d;
  	  			ram_in_reg(3) <= sw_0_in_d;
  	  		when others =>            
  	  			ram_in_reg(1) <= sw_0_in_d;
  	  			ram_in_reg(2) <= sw_1_in_d;
  	  			ram_in_reg(3) <= sw_2_in_d;
  	  			ram_in_reg(0) <= sw_3_in_d;
  	  	end case;
		end if;
	end process reg_cxb;	  	  	
	end generate gen_crossbar_registered;

  gen_crossbar_unregistered : if(pipe=0) generate
  
  
  
  reg_cxb : process(ram_sel_int,sw_0_in,sw_1_in,sw_2_in,sw_3_in) is
  begin
  	case ram_sel_int is
  		when "00"=>
  			ram_in_reg(0) <= sw_0_in_d;
  			ram_in_reg(1) <= sw_1_in_d;
  			ram_in_reg(2) <= sw_2_in_d;
  			ram_in_reg(3) <= sw_3_in_d;
  		when "01"=>
  			ram_in_reg(0) <= sw_3_in_d;
  			ram_in_reg(1) <= sw_0_in_d;
  			ram_in_reg(2) <= sw_1_in_d;
  			ram_in_reg(3) <= sw_2_in_d;
  		when "10"=>
  			ram_in_reg(0) <= sw_2_in_d;
  			ram_in_reg(1) <= sw_3_in_d;
  			ram_in_reg(2) <= sw_0_in_d;
  			ram_in_reg(3) <= sw_1_in_d;
  		when "11"=>
  			ram_in_reg(0) <= sw_1_in_d;
  			ram_in_reg(1) <= sw_2_in_d;
  			ram_in_reg(2) <= sw_3_in_d;
  			ram_in_reg(3) <= sw_0_in_d;
  		when others => 
  			ram_in_reg(1) <= sw_0_in_d;
  			ram_in_reg(2) <= sw_1_in_d;
  			ram_in_reg(3) <= sw_2_in_d;
  			ram_in_reg(0) <= sw_3_in_d;
  	end case;
	end process reg_cxb;	  	  	
  end generate gen_crossbar_unregistered;
  

end syn;
