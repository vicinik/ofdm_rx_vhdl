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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_cnt_ctrl_de.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all; 
use work.fft_pack.all;

entity asj_fft_cnt_ctrl_de is
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
end asj_fft_cnt_ctrl_de;

architecture cnt_sw of asj_fft_cnt_ctrl_de is


begin
	
sel_input_ab:process(clk,global_clock_enable,sel_anb_in,wraddr_i0_sw,wraddr_i1_sw,wraddr_i2_sw,wraddr_i3_sw,
wraddr0_sw,wraddr1_sw,wraddr2_sw,wraddr3_sw) is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				if (sel_anb_in='1') then
				   	wraddress_a_bus <= wraddr_i0_sw & wraddr_i1_sw & wraddr_i2_sw & wraddr_i3_sw;
				    wraddress_b_bus <= wraddr0_sw & wraddr1_sw & wraddr2_sw & wraddr3_sw;
				else
					  wraddress_b_bus <= wraddr_i0_sw & wraddr_i1_sw & wraddr_i2_sw & wraddr_i3_sw;
  					wraddress_a_bus <= wraddr0_sw & wraddr1_sw & wraddr2_sw & wraddr3_sw;
				end if;  	  	
			end if;
		end process sel_input_ab;
		
--sel_ram_cd:process(clk,global_clock_enable,sel_cna(1))is
--		begin
--if((rising_edge(clk) and global_clock_enable='1'))then
--				if(sel_cna(1)='1') then
--  					d_ram_data_in_bus <= ram_data_in0_sw & ram_data_in1_sw & ram_data_in2_sw & ram_data_in3_sw;
--	  		else
--	  				c_ram_data_in_bus <= ram_data_in0_sw & ram_data_in1_sw & ram_data_in2_sw & ram_data_in3_sw;
--  			end if;  	  	
--  		end if;
--		end process sel_ram_cd;
		
sel_ram_ab:process(clk,global_clock_enable,sel_anb_in,i_ram_data_in0_sw,ram_data_in0_sw_x,i_ram_data_in1_sw,ram_data_in1_sw_x,i_ram_data_in2_sw,ram_data_in2_sw_x,i_ram_data_in3_sw,ram_data_in3_sw_x,ram_data_in0_sw_y,ram_data_in1_sw_y,ram_data_in2_sw_y,ram_data_in3_sw_y)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				if(sel_anb_in='1') then
  					a_ram_data_in_bus_x <= i_ram_data_in0_sw & i_ram_data_in1_sw & i_ram_data_in2_sw & i_ram_data_in3_sw;
  					b_ram_data_in_bus_x <= ram_data_in0_sw_x & ram_data_in1_sw_x & ram_data_in2_sw_x & ram_data_in3_sw_x;
  					a_ram_data_in_bus_y <= i_ram_data_in0_sw & i_ram_data_in1_sw & i_ram_data_in2_sw & i_ram_data_in3_sw;
  					b_ram_data_in_bus_y <= ram_data_in0_sw_y & ram_data_in1_sw_y & ram_data_in2_sw_y & ram_data_in3_sw_y;
	  		else
	  				b_ram_data_in_bus_x <= i_ram_data_in0_sw & i_ram_data_in1_sw & i_ram_data_in2_sw & i_ram_data_in3_sw;
	  				a_ram_data_in_bus_x <= ram_data_in0_sw_x & ram_data_in1_sw_x & ram_data_in2_sw_x & ram_data_in3_sw_x;
	  				b_ram_data_in_bus_y <= i_ram_data_in0_sw & i_ram_data_in1_sw & i_ram_data_in2_sw & i_ram_data_in3_sw;
	  				a_ram_data_in_bus_y <= ram_data_in0_sw_y & ram_data_in1_sw_y & ram_data_in2_sw_y & ram_data_in3_sw_y;
  			end if;  	  	
  		end if;
		end process sel_ram_ab;
		
		
sel_ram_data:process(clk,global_clock_enable,sel_anb_addr,a_ram_data_out_bus_x,a_ram_data_out_bus_y,b_ram_data_out_bus_x,b_ram_data_out_bus_y)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				if(sel_anb_addr='1') then
	  				ram_data_out0_x <= b_ram_data_out_bus_x(8*mpr-1 downto 6*mpr);
	  				ram_data_out1_x <= b_ram_data_out_bus_x(6*mpr-1 downto 4*mpr);
	  				ram_data_out2_x <= b_ram_data_out_bus_x(4*mpr-1 downto 2*mpr);
	  				ram_data_out3_x <= b_ram_data_out_bus_x(2*mpr-1 downto 0);
	  				ram_data_out0_y <= b_ram_data_out_bus_y(8*mpr-1 downto 6*mpr);
	  				ram_data_out1_y <= b_ram_data_out_bus_y(6*mpr-1 downto 4*mpr);
	  				ram_data_out2_y <= b_ram_data_out_bus_y(4*mpr-1 downto 2*mpr);
	  				ram_data_out3_y <= b_ram_data_out_bus_y(2*mpr-1 downto 0);
	  		else
  					ram_data_out0_x <= a_ram_data_out_bus_x(8*mpr-1 downto 6*mpr);
  					ram_data_out1_x <= a_ram_data_out_bus_x(6*mpr-1 downto 4*mpr);
  					ram_data_out2_x <= a_ram_data_out_bus_x(4*mpr-1 downto 2*mpr);
  					ram_data_out3_x <= a_ram_data_out_bus_x(2*mpr-1 downto 0);
  					ram_data_out0_y <= a_ram_data_out_bus_y(8*mpr-1 downto 6*mpr);
  					ram_data_out1_y <= a_ram_data_out_bus_y(6*mpr-1 downto 4*mpr);
  					ram_data_out2_y <= a_ram_data_out_bus_y(4*mpr-1 downto 2*mpr);
  					ram_data_out3_y <= a_ram_data_out_bus_y(2*mpr-1 downto 0);
  			end if;  	  	
  		end if;
		end process sel_ram_data;
		
sel_ram_addr:process(clk,global_clock_enable,sel_anb_addr,rdaddr0_sw,rdaddr1_sw,rdaddr2_sw,rdaddr3_sw)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				if(sel_anb_addr='1') then
						rdaddress_b_bus <= rdaddr0_sw & rdaddr1_sw & rdaddr2_sw & rdaddr3_sw;
						rdaddress_a_bus <= (others=>'0');
	  		else
  			  	rdaddress_a_bus <= rdaddr0_sw & rdaddr1_sw & rdaddr2_sw & rdaddr3_sw;
  			  	rdaddress_b_bus <= (others=>'0');
  			end if;  	  	
  		end if;
		end process sel_ram_addr;

  
end cnt_sw;











