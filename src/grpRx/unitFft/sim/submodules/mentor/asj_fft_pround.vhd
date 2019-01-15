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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_pround.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all; 

use work.fft_pack.all;
library lpm;
use lpm.lpm_components.all;
library altera_mf;
use altera_mf.altera_mf_components.all;



entity asj_fft_pround is
	generic (     
			widthin		: natural :=8;
			widthout	: natural :=4; 
			pipe	: natural :=1			
			);
	port 	( 
global_clock_enable : in std_logic;
			clk	: in std_logic;
			clken	: in std_logic;
			xin		: in std_logic_vector(widthin-1 downto 0);
			yout	: out std_logic_vector(widthout-1 downto 0)
			);	
end asj_fft_pround;

architecture AROUNDPIPE_SYNTH of asj_fft_pround is
constant lpm_representation: string := "SIGNED";
constant bround		: natural :=1;
signal absxin		: std_logic_vector(widthout downto 0) ;
signal absyout	: std_logic_vector(widthout-1 downto 0) ;


signal ADDOFIVE		: std_logic_vector(widthin downto 0) ;
signal XINEXT		: std_logic_vector(widthin downto 0) ;
signal YOUTEXT		: std_logic_vector(widthin downto 0);
signal notsigned	: std_logic ;
signal vcc       : std_logic ;

begin
		
	vcc <= '1';

	ev:if widthin=widthout generate
		yout <= xin;
	end generate ev;

	gnrd: if (bround=0) generate

		gnp:if (0=pipe) generate
			gy:for i in 0 to widthout-1 generate
				yout(i) <= xin(i+widthin-widthout) ;
			end generate gy;
		end generate gnp;

		gp:if (pipe>0) generate
process(clk,global_clock_enable,clken,xin)
				begin	
if(rising_edge(clk) and global_clock_enable='1')then
					if clken='1' then	
						for i in 0 to widthout-1 loop
							yout(i) <= xin(i+widthin-widthout) ;
						end loop;
					end if;				
				end if;		
			end process;
		end generate gp;			

	end generate gnrd;
	
	
	gbrnd:if (bround=1) generate

		nev:if (widthin>widthout) generate	
			ad5:if (widthin-widthout>1) generate
				lo:for i in 0 to widthin-widthout-2 generate
					ADDOFIVE(i) <= '1';
				end generate lo;	
				hi:for i in widthin-widthout-1 to widthin generate
					ADDOFIVE(i) <= '0';
				end generate hi;
			end generate ad5;
	
			adn:if (widthin-widthout=1) generate
				ADDOFIVE <= (others=>'0');				
			end generate adn;
			
			XINEXT(widthin-1 downto 0) <= xin(widthin-1 downto 0);
			XINEXT(widthin) <= xin(widthin-1);

			gs: if lpm_representation="SIGNED" generate
				notsigned <= not(XINEXT(widthin-1));
			end generate gs;

			
			gnp:if (0=pipe) generate
				lpm_add_sub_component : lpm_add_sub
				GENERIC MAP (
					lpm_width => widthin+1,
					--lpm_type => "LPM_ADD_SUB",
					lpm_representation => lpm_representation,
					lpm_hint => "ONE_INPUT_IS_CONSTANT=NO",
					lpm_pipeline => 0
				)
				PORT MAP (
clken => global_clock_enable,
					dataa => XINEXT,
					datab => ADDOFIVE,
					add_sub => vcc,
					cin => notsigned,
					result => YOUTEXT
				);
			end generate gnp;
			
			gp:if (pipe>0) generate
				lpm_add_sub_component : lpm_add_sub
				GENERIC MAP (
					lpm_width => widthin+1,
					lpm_representation => lpm_representation,
					--lpm_type => "LPM_ADD_SUB",
					lpm_hint => "ONE_INPUT_IS_CONSTANT=NO",
					lpm_pipeline => pipe
				)
				PORT MAP (
clken => global_clock_enable,
					dataa => XINEXT,
					datab => ADDOFIVE,
					add_sub => vcc,
					cin => notsigned,
					clock => clk,
					result => YOUTEXT
				);
			end generate gp;
	
			gy:for i in 0 to widthout-1 generate
				yout(i) <= YOUTEXT(i+widthin-widthout) ;
			end generate gy;
			
		end generate nev;
	end generate gbrnd;
	
	gabsrnd : if(bround=2) generate
	
		--gen_absx : for i in widthout downto 0 generate
		--	absxin(i) <= xin(widthin-1) xor xin(i);
		--end generate gen_absx;
	absxin <= (widthout downto 0 => xin(widthin-1)) xor xin(widthin-1 downto widthin-widthout-1);	

	
absval:process(clk,global_clock_enable,absxin)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				yout <= (widthout-1 downto 0 => xin(widthin-1)) xor (absxin(widthout downto 1) + ((widthout-1 downto 1 => '0') & absxin(0)));
			end if;
		end process;
			
		
	
	end generate gabsrnd;
	
	

end AROUNDPIPE_SYNTH;
