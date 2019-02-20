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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_unbburst_ctrl_de.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all; 
use work.fft_pack.all;
entity asj_fft_unbburst_ctrl_de is
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
end asj_fft_unbburst_ctrl_de;

architecture cnt_sw of asj_fft_unbburst_ctrl_de is

constant last_pass_radix : integer :=(LOG4_CEIL(nps))-(LOG4_FLOOR(nps));

begin
	
input_address:process(clk,global_clock_enable,sel_wraddr_in,wraddr0_sw,wraddr1_sw,wraddr2_sw,wraddr3_sw,wraddr_i0_sw,wraddr_i1_sw,wraddr_i2_sw,wraddr_i3_sw)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				if(sel_wraddr_in='0') then
				  wraddress_a_bus <= wraddr_i0_sw & wraddr_i1_sw & wraddr_i2_sw & wraddr_i3_sw;
				else
				  wraddress_a_bus <= wraddr0_sw & wraddr1_sw & wraddr2_sw & wraddr3_sw; 
				end if;
			end if;
		end process input_address;
		
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
		

input_data:process(clk,global_clock_enable,sel_ram_in)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				if(sel_ram_in='0') then
	  			a_ram_data_in_bus_x <= i_ram_data_in0_sw & i_ram_data_in1_sw & i_ram_data_in2_sw & i_ram_data_in3_sw;
  				a_ram_data_in_bus_y <= i_ram_data_in0_sw & i_ram_data_in1_sw & i_ram_data_in2_sw & i_ram_data_in3_sw;
				else
  				a_ram_data_in_bus_x <= ram_data_in0_sw_x & ram_data_in1_sw_x & ram_data_in2_sw_x & ram_data_in3_sw_x;
  				a_ram_data_in_bus_y <= ram_data_in0_sw_y & ram_data_in1_sw_y & ram_data_in2_sw_y & ram_data_in3_sw_y;
				end if;
  		end if;
		end process input_data;		

		
		
sel_ram_data:process(clk,global_clock_enable)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
  			ram_data_out0_x <= a_ram_data_out_bus_x(8*mpr-1 downto 6*mpr);
  			ram_data_out1_x <= a_ram_data_out_bus_x(6*mpr-1 downto 4*mpr);
  			ram_data_out2_x <= a_ram_data_out_bus_x(4*mpr-1 downto 2*mpr);
  			ram_data_out3_x <= a_ram_data_out_bus_x(2*mpr-1 downto 0);
  			ram_data_out0_y <= a_ram_data_out_bus_y(8*mpr-1 downto 6*mpr);
  			ram_data_out1_y <= a_ram_data_out_bus_y(6*mpr-1 downto 4*mpr);
  			ram_data_out2_y <= a_ram_data_out_bus_y(4*mpr-1 downto 2*mpr);
  			ram_data_out3_y <= a_ram_data_out_bus_y(2*mpr-1 downto 0);
  		end if;
		end process sel_ram_data;
		
	gen_r4lpp : if(last_pass_radix=0) generate
		
sel_ram_addr:process(clk,global_clock_enable,sel_lpp)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				if(sel_lpp='0') then
  		 		rdaddress_a_bus <= rdaddr0_sw & rdaddr1_sw & rdaddr2_sw & rdaddr3_sw;
  		 	else
  		 		rdaddress_a_bus <= lpp_rdaddr0_sw & lpp_rdaddr1_sw & lpp_rdaddr2_sw & lpp_rdaddr3_sw;
  		 	end if;
  		end if;
		end process sel_ram_addr;
		
	end generate gen_r4lpp;
	
	gen_r2lpp : if(last_pass_radix=1) generate
		
sel_ram_addr:process(clk,global_clock_enable,sel_lpp)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				if(sel_lpp='0') then
  		 		rdaddress_a_bus <= rdaddr0_sw & rdaddr1_sw & rdaddr2_sw & rdaddr3_sw;
  		 	else
  		 		rdaddress_a_bus <= lpp_rdaddr0_sw & lpp_rdaddr0_sw & lpp_rdaddr0_sw & lpp_rdaddr0_sw;
  		 	end if;
  		end if;
		end process sel_ram_addr;
		
	end generate gen_r2lpp;
	


  
end cnt_sw;











