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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_twadsogen_q.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
-- Twiddle address permutation is fixed for each N
-- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all; 
use work.fft_pack.all;
entity asj_fft_twadsogen_q is

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
						tw_addr				  : out std_logic_vector(2*(apr-3)+1 downto 0);
						quad            : out std_logic_vector(2 downto 0)
			);
end asj_fft_twadsogen_q;

architecture gen_all of asj_fft_twadsogen_q is

signal data_addr_held        : std_logic_vector(apr-nume downto 0);  
signal data_addr_held_by1        : std_logic_vector(apr-3 downto 0);            
signal data_addr_held_by2        : std_logic_vector(apr-3 downto 0);            
-----------------------------------------------------------------------------------------------
-- Single Output Temporary Storage
-----------------------------------------------------------------------------------------------
signal twad_temp         : std_logic_vector(apr-3 downto 0);
signal twad_temp_ref : std_logic_vector(apr-1 downto 0);
signal quad_reg : std_logic_vector(2 downto 0);

------------------------------------------------------------------------------------------390
-----
-- Dual Output Temporary Storage
-----------------------------------------------------------------------------------------------
signal twad_tempe        : std_logic_vector(apr-3 downto 0);
signal twad_tempo        : std_logic_vector(apr-3 downto 0);            



type data_arr is array (0 to tw_delay-1) of std_logic_vector(apr-nume downto 0);
signal addr_tdl : data_arr;

signal perm_addr : std_logic_vector(apr-1 downto 0);
--signal p_count_int : std_logic_vector(2 downto 0);
signal p_count_int : std_logic_vector(3 downto 0);


begin
	
gen_4bits_1 : if(log2_n_passes=2) generate
	p_count_int <= "00" & p_count;
end generate;

gen_4bits_2 : if(log2_n_passes=3) generate
	p_count_int <= '0' & p_count;
end generate;

is_4bits : if(log2_n_passes=4) generate
	p_count_int <= p_count;
end generate;

		
	




-----------------------------------------------------------------------------------------------
-- Single Output
-----------------------------------------------------------------------------------------------
gen_se : if(nume=1) generate


		-- delay twiddle address output to sync with data output from BFP
reg_addr:process(clk,global_clock_enable,data_addr)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			data_addr_held_by1(apr-3 downto 0) <= data_addr(apr-1 downto 2) and (apr-1 downto 2=> data_addr(0));
			data_addr_held_by2(apr-3 downto 0) <= data_addr(apr-1 downto 2) and (apr-1 downto 2=> data_addr(1));
		end if;
	end process reg_addr;

		tw_addr <= twad_tempo & twad_tempe;
		quad    <= quad_reg;
		-----------------------------------------------------------------------------------------------
		-- Use Quadrant information from permuted address perm_addr to allow for single N/4 Sine ROM
		-----------------------------------------------------------------------------------------------
quad_mem_select:process(clk,global_clock_enable,perm_addr)is
			begin			
if((rising_edge(clk) and global_clock_enable='1'))then
					if(perm_addr(apr-3 downto 0)=(apr-3 downto 0 => '0')) then
						quad_reg(0) <= '1';
					else
						quad_reg(0) <= '0';
					end if;
					quad_reg(2 downto 1) <= perm_addr(apr-1 downto apr-2);
					if(perm_addr(apr-2)='1') then
						twad_tempe <= not(perm_addr(apr-3 downto 0)) + int2ustd(1,apr-3);
					else
						twad_tempe <= perm_addr(apr-3 downto 0);
					end if;
					if(perm_addr(apr-2)='0') then
						twad_tempo <= not(perm_addr(apr-3 downto 0)) + int2ustd(1,apr-3);
					else
						twad_tempo <= perm_addr(apr-3 downto 0);
					end if;					
				end if;
			end process quad_mem_select;				
		-----------------------------------------------------------------------------------------------
		-- Generate Permuted Memory Address
		-----------------------------------------------------------------------------------------------
		-----------------------------------------------------------------------------------------------
		-- N=64
		-----------------------------------------------------------------------------------------------			
		gen_tw_64 : if(nps = 64) generate
		
get_tw_64:process(clk,global_clock_enable,p_count_int,data_addr_held)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count_int(2 downto 0) is
						  when "001" =>
						  	perm_addr<=("00" & data_addr_held_by1(apr-3 downto 0))
						  		 +('0' & data_addr_held_by2(apr-3 downto 0) & '0');
							when "010" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-5 downto 0) & "00")
						  		 +('0' & data_addr_held_by2(apr-5 downto 0) & "000");
						when others=>
							perm_addr <= (others=>'0');
					end case;
				end if;
		 end process get_tw_64;
		end generate gen_tw_64;
		-----------------------------------------------------------------------------------------------
		-- N=128
		-----------------------------------------------------------------------------------------------			
		gen_tw_128 : if(nps = 128) generate
get_tw_128:process(clk,global_clock_enable,p_count_int,data_addr_held)is
			variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count_int(2 downto 0) is
						  when "001" =>
						  	perm_addr<=("00" & data_addr_held_by1(apr-3 downto 0))
						  		 +('0' & data_addr_held_by2(apr-3 downto 0) & '0');
							when "010" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-5 downto 0) & "00")
						  		 +('0' & data_addr_held_by2(apr-5 downto 0) & "000");
							when "011" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-7 downto 0) & "0000")
						  		 +('0' & data_addr_held_by2(apr-7 downto 0) & "00000");
							when others=>
								perm_addr <= (others=>'0');
					end case;
				end if;
		 end process get_tw_128;
		end generate gen_tw_128; 
		-----------------------------------------------------------------------------------------------
		-- N=256
		-----------------------------------------------------------------------------------------------			
		gen_tw_256 : if(nps = 256) generate
get_tw_256:process(clk,global_clock_enable,p_count_int,data_addr_held)is
			variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case p_count_int(2 downto 0) is
						  when "001" =>
						  	perm_addr<=("00" & data_addr_held_by1(apr-3 downto 0))
						  		 +('0' & data_addr_held_by2(apr-3 downto 0) & '0');
							when "010" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-5 downto 0) & "00")
						  		 +('0' & data_addr_held_by2(apr-5 downto 0) & "000");
							when "011" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-7 downto 0) & "0000")
						  		 +('0' & data_addr_held_by2(apr-7 downto 0) & "00000");
						when others=>
							perm_addr <= (others=>'0');
					end case;
				end if;
		 end process get_tw_256;
		end generate gen_tw_256; 
		-----------------------------------------------------------------------------------------------
		-- N=512
		-----------------------------------------------------------------------------------------------			
		gen_tw_512 : if(nps = 512) generate
get_tw_512:process(clk,global_clock_enable,p_count_int,data_addr_held)is
			variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case p_count_int(2 downto 0) is
						  when "001" =>
						  	perm_addr<=("00" & data_addr_held_by1(apr-3 downto 0))
						  		 +('0' & data_addr_held_by2(apr-3 downto 0) & '0');
							when "010" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-5 downto 0) & "00")
						  		 +('0' & data_addr_held_by2(apr-5 downto 0) & "000");
							when "011" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-7 downto 0) & "0000")
						  		 +('0' & data_addr_held_by2(apr-7 downto 0) & "00000");
							when "100" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-9 downto 0) & "000000")
						  		 +('0' & data_addr_held_by2(apr-9 downto 0) & "0000000");
							when others=>
								perm_addr <= (others=>'0');
					 end case;
				end if;
		 end process get_tw_512;
		end generate gen_tw_512; 
		-----------------------------------------------------------------------------------------------
		-- N=1024
		-----------------------------------------------------------------------------------------------			
		gen_tw_1024 : if(nps = 1024) generate
get_tw_1024:process(clk,global_clock_enable,p_count_int,data_addr_held)is
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case p_count_int(2 downto 0) is
						  when "001" =>
						  	perm_addr<=("00" & data_addr_held_by1(apr-3 downto 0))
						  		 +('0' & data_addr_held_by2(apr-3 downto 0) & '0');
							when "010" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-5 downto 0) & "00")
						  		 +('0' & data_addr_held_by2(apr-5 downto 0) & "000");
							when "011" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-7 downto 0) & "0000")
						  		 +('0' & data_addr_held_by2(apr-7 downto 0) & "00000");
							when "100" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-9 downto 0) & "000000")
						  		 +('0' & data_addr_held_by2(apr-9 downto 0) & "0000000");
							when others=>
								perm_addr <= (others=>'0');
					 end case;
				 end if;
			 end process get_tw_1024;
		end generate gen_tw_1024; 
		-----------------------------------------------------------------------------------------------
		-- N=2048
		-----------------------------------------------------------------------------------------------			
		gen_tw_2048 : if(nps = 2048) generate
get_tw_2048:process(clk,global_clock_enable,p_count_int,data_addr_held)is
				variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case p_count_int(2 downto 0) is
						  when "001" =>
						  	perm_addr<=("00" & data_addr_held_by1(apr-3 downto 0))
						  		 +('0' & data_addr_held_by2(apr-3 downto 0) & '0');
							when "010" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-5 downto 0) & "00")
						  		 +('0' & data_addr_held_by2(apr-5 downto 0) & "000");
							when "011" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-7 downto 0) & "0000")
						  		 +('0' & data_addr_held_by2(apr-7 downto 0) & "00000");
							when "100" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-9 downto 0) & "000000")
						  		 +('0' & data_addr_held_by2(apr-9 downto 0) & "0000000");
							when "101" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-11 downto 0) & "00000000")
						  		 +('0' & data_addr_held_by2(apr-11 downto 0) & "000000000");
							when others=>
								perm_addr <= (others=>'0');
					 end case;
					end if;
				end process get_tw_2048;
		end generate gen_tw_2048;		
		-----------------------------------------------------------------------------------------------
		-- N=4096
		-----------------------------------------------------------------------------------------------			
		gen_tw_4096 : if(nps = 4096) generate
get_tw_4096:process(clk,global_clock_enable,p_count_int,data_addr_held)is
				variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case p_count_int(2 downto 0) is
						  when "001" =>
						  	perm_addr<=("00" & data_addr_held_by1(apr-3 downto 0))
						  		 +('0' & data_addr_held_by2(apr-3 downto 0) & '0');
							when "010" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-5 downto 0) & "00")
						  		 +('0' & data_addr_held_by2(apr-5 downto 0) & "000");
							when "011" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-7 downto 0) & "0000")
						  		 +('0' & data_addr_held_by2(apr-7 downto 0) & "00000");
							when "100" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-9 downto 0) & "000000")
						  		 +('0' & data_addr_held_by2(apr-9 downto 0) & "0000000");
							when "101" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-11 downto 0) & "00000000")
						  		 +('0' & data_addr_held_by2(apr-11 downto 0) & "000000000");
							when others=>
								perm_addr <= (others=>'0');
					 end case;
					end if;
				end process get_tw_4096;
		end generate gen_tw_4096; 
		-----------------------------------------------------------------------------------------------
		-- N=8192
		-----------------------------------------------------------------------------------------------			
		gen_tw_8192 : if(nps = 8192) generate
get_tw_8192:process(clk,global_clock_enable,p_count_int,data_addr_held)is
				variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case p_count_int(2 downto 0) is
						  when "001" =>
						  	perm_addr<=("00" & data_addr_held_by1(apr-3 downto 0))
						  		 +('0' & data_addr_held_by2(apr-3 downto 0) & '0');
							when "010" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-5 downto 0) & "00")
						  		 +('0' & data_addr_held_by2(apr-5 downto 0) & "000");
							when "011" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-7 downto 0) & "0000")
						  		 +('0' & data_addr_held_by2(apr-7 downto 0) & "00000");
							when "100" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-9 downto 0) & "000000")
						  		 +('0' & data_addr_held_by2(apr-9 downto 0) & "0000000");
							when "101" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-11 downto 0) & "00000000")
						  		 +('0' & data_addr_held_by2(apr-11 downto 0) & "000000000");
							when "110" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-13 downto 0) & "0000000000")
						  		 +('0' & data_addr_held_by2(apr-13 downto 0) & "00000000000");
							when others=>
								perm_addr <= (others=>'0');
					 end case;
					end if;
				end process get_tw_8192;
		end generate gen_tw_8192;		
		-----------------------------------------------------------------------------------------------
		-- N=16384
		-----------------------------------------------------------------------------------------------
		gen_tw_16384 : if(nps = 16384) generate
get_tw_16384:process(clk,global_clock_enable,p_count_int,data_addr_held)is
				variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case p_count_int(2 downto 0) is
						  when "001" =>
						  	perm_addr<=("00" & data_addr_held_by1(apr-3 downto 0))
						  		 +('0' & data_addr_held_by2(apr-3 downto 0) & '0');
							when "010" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-5 downto 0) & "00")
						  		 +('0' & data_addr_held_by2(apr-5 downto 0) & "000");
							when "011" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-7 downto 0) & "0000")
						  		 +('0' & data_addr_held_by2(apr-7 downto 0) & "00000");
							when "100" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-9 downto 0) & "000000")
						  		 +('0' & data_addr_held_by2(apr-9 downto 0) & "0000000");
							when "101" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-11 downto 0) & "00000000")
						  		 +('0' & data_addr_held_by2(apr-11 downto 0) & "000000000");
							when "110" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-13 downto 0) & "0000000000")
						  		 +('0' & data_addr_held_by2(apr-13 downto 0) & "00000000000");
							when others=>
								perm_addr <= (others=>'0');
					 end case;
					end if;
				end process get_tw_16384;
		end generate gen_tw_16384;

		-----------------------------------------------------------------------------------------------
		-- N=32768
		-----------------------------------------------------------------------------------------------			
		gen_tw_32768 : if(nps = 32768) generate
get_tw_32768:process(clk,global_clock_enable,p_count_int,data_addr_held)is
				variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case p_count_int(2 downto 0) is
						  when "001" =>
						  	perm_addr<=("00" & data_addr_held_by1(apr-3 downto 0))
						  		 +('0' & data_addr_held_by2(apr-3 downto 0) & '0');
							when "010" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-5 downto 0) & "00")
						  		 +('0' & data_addr_held_by2(apr-5 downto 0) & "000");
							when "011" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-7 downto 0) & "0000")
						  		 +('0' & data_addr_held_by2(apr-7 downto 0) & "00000");
							when "100" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-9 downto 0) & "000000")
						  		 +('0' & data_addr_held_by2(apr-9 downto 0) & "0000000");
							when "101" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-11 downto 0) & "00000000")
						  		 +('0' & data_addr_held_by2(apr-11 downto 0) & "000000000");
							when "110" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-13 downto 0) & "0000000000")
						  		 +('0' & data_addr_held_by2(apr-13 downto 0) & "00000000000");
							when "111" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-15 downto 0) & "000000000000")
						  		 +('0' & data_addr_held_by2(apr-15 downto 0) & "0000000000000");
							when others=>
								perm_addr <= (others=>'0');
					 end case;
					end if;
				end process get_tw_32768;
		end generate gen_tw_32768;

		-----------------------------------------------------------------------------------------------
		-- N=65536
		-----------------------------------------------------------------------------------------------
		gen_tw_65536 : if(nps = 65536) generate
get_tw_65536:process(clk,global_clock_enable,p_count_int,data_addr_held)is
				variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case p_count_int(2 downto 0) is
						  when "001" =>
						  	perm_addr<=("00" & data_addr_held_by1(apr-3 downto 0))
						  		 +('0' & data_addr_held_by2(apr-3 downto 0) & '0');
							when "010" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-5 downto 0) & "00")
						  		 +('0' & data_addr_held_by2(apr-5 downto 0) & "000");
							when "011" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-7 downto 0) & "0000")
						  		 +('0' & data_addr_held_by2(apr-7 downto 0) & "00000");
							when "100" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-9 downto 0) & "000000")
						  		 +('0' & data_addr_held_by2(apr-9 downto 0) & "0000000");
							when "101" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-11 downto 0) & "00000000")
						  		 +('0' & data_addr_held_by2(apr-11 downto 0) & "000000000");
							when "110" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-13 downto 0) & "0000000000")
						  		 +('0' & data_addr_held_by2(apr-13 downto 0) & "00000000000");
							when "111" =>	
						  	perm_addr<=("00" & data_addr_held_by1(apr-15 downto 0) & "000000000000")
						  		 +('0' & data_addr_held_by2(apr-15 downto 0) & "0000000000000");
							when others=>
								perm_addr <= (others=>'0');
					 end case;
					end if;
				end process get_tw_65536;
		end generate gen_tw_65536;

end generate gen_se;	

-----------------------------------------------------------------------------------------------
--  Dual Output
-----------------------------------------------------------------------------------------------
gen_de : if(nume=2) generate

		data_addr_held <= data_addr;
	
reg_twad:process(clk,global_clock_enable,twad_temp)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
						tw_addr(nume*(apr-3)+nume-1 downto apr-2) <= twad_tempe;
						tw_addr(apr-3 downto 0) 		<= twad_tempo;
				end if;
		end process reg_twad;
		
tdl_tw:process(clk,global_clock_enable,data_addr,addr_tdl)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					for i in tw_delay-1 downto 1 loop
						addr_tdl(i)<=addr_tdl(i-1);
					end loop;
					addr_tdl(0)<= data_addr;
				end if;
		end process tdl_tw;
			
		--twiddle_addr = m*mod(offset(sel+1)-1,(n_by_4/m));
		--m={1,4,16.....4^5}	
		-----------------------------------------------------------------------------------------------
		-- N=64
		-----------------------------------------------------------------------------------------------			
		gen_tw_64 : if(nps = 64) generate
get_tw_64:process(clk,global_clock_enable,p_count_int,data_addr_held)is
			variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count_int(2 downto 0) is
					  when "001" =>
							twad_tempe <= data_addr_held(apr-4 downto 0) & '0';
							twad_tempo <= (data_addr_held(apr-4 downto 0) & '0')+int2ustd(1,apr-3);
						when "010" =>	
							twad_tempe <= data_addr_held(apr-6 downto 0) & (2 downto 0 => '0') ;
							twad_tempo <= (data_addr_held(apr-6 downto 0) & (2 downto 0 => '0')) + int2ustd(4,apr-3);
					  when others =>
							twad_tempe <= (others=>'0');
							twad_tempo <= (others=>'0');
					end case;
				end if;
		 end process get_tw_64;
		end generate gen_tw_64;
		-----------------------------------------------------------------------------------------------
		-- N=128
		-----------------------------------------------------------------------------------------------			
		gen_tw_128 : if(nps = 128) generate
get_tw_128:process(clk,global_clock_enable,p_count_int,data_addr_held)is
			variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count_int(2 downto 0) is
					  when "001" =>
							twad_tempe <= data_addr_held(apr-4 downto 0) & '0';
							twad_tempo <= (data_addr_held(apr-4 downto 0) & '0')+int2ustd(1,apr-3);
						when "010" =>	
							twad_tempe <= data_addr_held(apr-6 downto 0) & (2 downto 0 => '0') ;
							twad_tempo <= (data_addr_held(apr-6 downto 0) & (2 downto 0 => '0')) + int2ustd(4,apr-3);
						when "011" =>		
							twad_tempe <= data_addr_held(apr-8 downto 0) & (4 downto 0 => '0');
							--twad_tempo <= data_addr_held(apr-8 downto 0) & (4 downto 0 => '0') + int2ustd(16,apr-3);
							twad_tempo <= int2ustd(16,apr-2);
					  when others =>
							twad_tempe <= (others=>'0');
							twad_tempo <= (others=>'0');
					end case;
				end if;
		 end process get_tw_128;
		end generate gen_tw_128; 
		-----------------------------------------------------------------------------------------------
		-- N=256
		-----------------------------------------------------------------------------------------------			
		gen_tw_256 : if(nps = 256) generate
get_tw_256:process(clk,global_clock_enable,p_count_int,data_addr_held)is
			variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count_int(2 downto 0) is
					  when "001" =>
							twad_tempe <= data_addr_held(apr-4 downto 0) & '0';
							twad_tempo <= (data_addr_held(apr-4 downto 0) & '0')+int2ustd(1,apr-3);
						when "010" =>	
							twad_tempe <= data_addr_held(apr-6 downto 0) & (2 downto 0 => '0') ;
							twad_tempo <= (data_addr_held(apr-6 downto 0) & (2 downto 0 => '0')) + int2ustd(4,apr-3);
						when "011" =>		
							twad_tempe <= data_addr_held(apr-8 downto 0) & (4 downto 0 => '0');
							twad_tempo <= data_addr_held(apr-8 downto 0) & (4 downto 0 => '0') + int2ustd(16,apr-3);
					  when others =>
							twad_tempe <= (others=>'0');
							twad_tempo <= (others=>'0');
					end case;
				end if;
		 end process get_tw_256;
		end generate gen_tw_256; 
		-----------------------------------------------------------------------------------------------
		-- N=512
		-----------------------------------------------------------------------------------------------			
		gen_tw_512 : if(nps = 512) generate
get_tw_512:process(clk,global_clock_enable,p_count_int,data_addr_held)is
			variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count_int(2 downto 0) is
					  when "001" =>
							twad_tempe <= data_addr_held(apr-4 downto 0) & '0';
							twad_tempo <= (data_addr_held(apr-4 downto 0) & '0')+int2ustd(1,apr-3);
						when "010" =>	
							twad_tempe <= data_addr_held(apr-6 downto 0) & (2 downto 0 => '0') ;
							twad_tempo <= (data_addr_held(apr-6 downto 0) & (2 downto 0 => '0')) + int2ustd(4,apr-3);
						when "011" =>		
							twad_tempe <= data_addr_held(apr-8 downto 0) & (4 downto 0 => '0');
							twad_tempo <= data_addr_held(apr-8 downto 0) & (4 downto 0 => '0') + int2ustd(16,apr-3);
						when "100" =>		
							twad_tempe <= data_addr_held(apr-10 downto 0) & (6 downto 0 => '0');
							twad_tempo <= int2ustd(64,apr-2);
					  when others =>
							twad_tempe <= (others=>'0');
							twad_tempo <= (others=>'0');
					end case;
				end if;
		 end process get_tw_512;
		end generate gen_tw_512; 
		-----------------------------------------------------------------------------------------------
		-- N=1024
		-----------------------------------------------------------------------------------------------			
		gen_tw_1024 : if(nps = 1024) generate
get_tw_1024:process(clk,global_clock_enable,p_count_int,data_addr_held)is
			variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count_int(2 downto 0) is
					  when "001" =>
							twad_tempe <= data_addr_held(apr-4 downto 0) & '0';
							twad_tempo <= (data_addr_held(apr-4 downto 0) & '0')+int2ustd(1,apr-3);
						when "010" =>	
							twad_tempe <= data_addr_held(apr-6 downto 0) & (2 downto 0 => '0') ;
							twad_tempo <= (data_addr_held(apr-6 downto 0) & (2 downto 0 => '0')) + int2ustd(4,apr-3);
						when "011" =>		
							twad_tempe <= data_addr_held(apr-8 downto 0) & (4 downto 0 => '0');
							twad_tempo <= data_addr_held(apr-8 downto 0) & (4 downto 0 => '0') + int2ustd(16,apr-3);
						when "100" =>		
							twad_tempe <= data_addr_held(apr-10 downto 0) & (6 downto 0 => '0');
							twad_tempo <= data_addr_held(apr-10 downto 0) & (6 downto 0 => '0') + int2ustd(64,apr-3);
						when others =>
							twad_tempe <= (others=>'0');
							twad_tempo <= (others=>'0');
					end case;		end if;
		 end process get_tw_1024;
		end generate gen_tw_1024; 
		-----------------------------------------------------------------------------------------------
		-- N=2048
		-----------------------------------------------------------------------------------------------			
		gen_tw_2048 : if(nps = 2048) generate
get_tw_2048:process(clk,global_clock_enable,p_count_int,data_addr_held)is
				variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case p_count_int(2 downto 0) is
						  when "001" =>
								twad_tempe <= data_addr_held(apr-4 downto 0) & '0';
								twad_tempo <= (data_addr_held(apr-4 downto 0) & '0')+int2ustd(1,apr-3);
							when "010" =>	
								twad_tempe <= data_addr_held(apr-6 downto 0) & (2 downto 0 => '0') ;
								twad_tempo <= (data_addr_held(apr-6 downto 0) & (2 downto 0 => '0')) + int2ustd(4,apr-3);
							when "011" =>		
								twad_tempe <= data_addr_held(apr-8 downto 0) & (4 downto 0 => '0');
								twad_tempo <= data_addr_held(apr-8 downto 0) & (4 downto 0 => '0') + int2ustd(16,apr-3);
							when "100" =>		
								twad_tempe <= data_addr_held(apr-10 downto 0) & (6 downto 0 => '0');
								twad_tempo <= data_addr_held(apr-10 downto 0) & (6 downto 0 => '0') + int2ustd(64,apr-3);
							when "101" =>		
								twad_tempe <= data_addr_held(apr-12 downto 0) & (8 downto 0 => '0');
								twad_tempo <= int2ustd(256,apr-2);
						  when others =>
								twad_tempe <= (others=>'0');
								twad_tempo <= (others=>'0');
						end case;
					end if;
				end process get_tw_2048;
		end generate gen_tw_2048;		
		-----------------------------------------------------------------------------------------------
		-- N=4096
		-----------------------------------------------------------------------------------------------			
		gen_tw_4096 : if(nps = 4096) generate
get_tw_4096:process(clk,global_clock_enable,p_count_int,data_addr_held)is
				variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case p_count_int(2 downto 0) is
				  		when "001" =>
								twad_tempe <= data_addr_held(apr-4 downto 0) & '0';
								twad_tempo <= (data_addr_held(apr-4 downto 0) & '0')+int2ustd(1,apr-3);
							when "010" =>	
								twad_tempe <= data_addr_held(apr-6 downto 0) & (2 downto 0 => '0') ;
								twad_tempo <= (data_addr_held(apr-6 downto 0) & (2 downto 0 => '0')) + int2ustd(4,apr-3);
							when "011" =>		
								twad_tempe <= data_addr_held(apr-8 downto 0) & (4 downto 0 => '0');
								twad_tempo <= data_addr_held(apr-8 downto 0) & (4 downto 0 => '0') + int2ustd(16,apr-3);
							when "100" =>		
								twad_tempe <= data_addr_held(apr-10 downto 0) & (6 downto 0 => '0');
								twad_tempo <= data_addr_held(apr-10 downto 0) & (6 downto 0 => '0') + int2ustd(64,apr-3);
							when "101" =>		
								twad_tempe <= data_addr_held(apr-12 downto 0) & (8 downto 0 => '0');
								twad_tempo <= data_addr_held(apr-12 downto 0) & (8 downto 0 => '0') + int2ustd(256,apr-3);
							when others =>
								twad_tempe <= (others=>'0');
								twad_tempo <= (others=>'0');
						end case;
					end if;
				end process get_tw_4096;
		end generate gen_tw_4096; 
		-----------------------------------------------------------------------------------------------
		-- N=8192
		-----------------------------------------------------------------------------------------------			
		gen_tw_8192 : if(nps = 8192) generate
get_tw_8192:process(clk,global_clock_enable,p_count_int,data_addr_held)is
				variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case p_count_int(2 downto 0) is
						  when "001" =>
								twad_tempe <= data_addr_held(apr-4 downto 0) & '0';
								twad_tempo <= (data_addr_held(apr-4 downto 0) & '0')+int2ustd(1,apr-3);
							when "010" =>	
								twad_tempe <= data_addr_held(apr-6 downto 0) & (2 downto 0 => '0') ;
								twad_tempo <= (data_addr_held(apr-6 downto 0) & (2 downto 0 => '0')) + int2ustd(4,apr-3);
							when "011" =>		
								twad_tempe <= data_addr_held(apr-8 downto 0) & (4 downto 0 => '0');
								twad_tempo <= data_addr_held(apr-8 downto 0) & (4 downto 0 => '0') + int2ustd(16,apr-3);
							when "100" =>		
								twad_tempe <= data_addr_held(apr-10 downto 0) & (6 downto 0 => '0');
								twad_tempo <= data_addr_held(apr-10 downto 0) & (6 downto 0 => '0') + int2ustd(64,apr-3);
							when "101" =>
								twad_tempe <= data_addr_held(apr-12 downto 0) & (8 downto 0 => '0');
								twad_tempo <= data_addr_held(apr-12 downto 0) & (8 downto 0 => '0') + int2ustd(256,apr-3);
							when "110" =>
								twad_tempe <= data_addr_held(apr-14 downto 0) & (10 downto 0 => '0');
								twad_tempo <= int2ustd(1024,apr-2);
						  when others =>
								twad_tempe <= (others=>'0');
								twad_tempo <= (others=>'0');
						end case;
					end if;
				end process get_tw_8192;
		end generate gen_tw_8192;		
		-----------------------------------------------------------------------------------------------
		-- N=16384
		-----------------------------------------------------------------------------------------------
		gen_tw_16384 : if(nps = 16384) generate
get_tw_16384:process(clk,global_clock_enable,p_count_int,data_addr_held)is
				variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case p_count_int(2 downto 0) is
						when "001" =>
								twad_tempe <= data_addr_held(apr-4 downto 0) & '0';
								twad_tempo <= (data_addr_held(apr-4 downto 0) & '0')+int2ustd(1,apr-3);
							when "010" =>	
								twad_tempe <= data_addr_held(apr-6 downto 0) & (2 downto 0 => '0') ;
								twad_tempo <= (data_addr_held(apr-6 downto 0) & (2 downto 0 => '0')) + int2ustd(4,apr-3);
							when "011" =>		
								twad_tempe <= data_addr_held(apr-8 downto 0) & (4 downto 0 => '0');
								twad_tempo <= data_addr_held(apr-8 downto 0) & (4 downto 0 => '0') + int2ustd(16,apr-3);
							when "100" =>		
								twad_tempe <= data_addr_held(apr-10 downto 0) & (6 downto 0 => '0');
								twad_tempo <= data_addr_held(apr-10 downto 0) & (6 downto 0 => '0') + int2ustd(64,apr-3);
							when "101" =>		
								twad_tempe <= data_addr_held(apr-12 downto 0) & (8 downto 0 => '0');
								twad_tempo <= data_addr_held(apr-12 downto 0) & (8 downto 0 => '0') + int2ustd(256,apr-3);
							when "110" =>		
								twad_tempe <= data_addr_held(apr-14 downto 0) & (10 downto 0 => '0');
								twad_tempo <= data_addr_held(apr-14 downto 0) & (10 downto 0 => '0') + int2ustd(1024,apr-3);
							when others =>
								twad_tempe <= (others=>'0');
								twad_tempo <= (others=>'0');
						end case;
					end if;
				end process get_tw_16384;
		end generate gen_tw_16384;

		-----------------------------------------------------------------------------------------------
		-- N=32768
		-----------------------------------------------------------------------------------------------			
		gen_tw_32768 : if(nps = 32768) generate
get_tw_32768:process(clk,global_clock_enable,p_count_int,data_addr_held)is
				variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case p_count_int(2 downto 0) is
						  when "001" =>
								twad_tempe <= data_addr_held(apr-4 downto 0) & '0';
								twad_tempo <= (data_addr_held(apr-4 downto 0) & '0')+int2ustd(1,apr-3);
							when "010" =>	
								twad_tempe <= data_addr_held(apr-6 downto 0) & (2 downto 0 => '0') ;
								twad_tempo <= (data_addr_held(apr-6 downto 0) & (2 downto 0 => '0')) + int2ustd(4,apr-3);
							when "011" =>		
								twad_tempe <= data_addr_held(apr-8 downto 0) & (4 downto 0 => '0');
								twad_tempo <= data_addr_held(apr-8 downto 0) & (4 downto 0 => '0') + int2ustd(16,apr-3);
							when "100" =>		
								twad_tempe <= data_addr_held(apr-10 downto 0) & (6 downto 0 => '0');
								twad_tempo <= data_addr_held(apr-10 downto 0) & (6 downto 0 => '0') + int2ustd(64,apr-3);
							when "101" =>
								twad_tempe <= data_addr_held(apr-12 downto 0) & (8 downto 0 => '0');
								twad_tempo <= data_addr_held(apr-12 downto 0) & (8 downto 0 => '0') + int2ustd(256,apr-3);
							when "110" =>
								twad_tempe <= data_addr_held(apr-14 downto 0) & (10 downto 0 => '0');
								twad_tempo <= data_addr_held(apr-14 downto 0) & (10 downto 0 => '0') + int2ustd(1024,apr-3);
							when "111" =>
								twad_tempe <= data_addr_held(apr-16 downto 0) & (12 downto 0 => '0');
								twad_tempo <= int2ustd(4096,apr-2);
						  when others =>
								twad_tempe <= (others=>'0');
								twad_tempo <= (others=>'0');
						end case;
					end if;
				end process get_tw_32768;
		end generate gen_tw_32768;

		-----------------------------------------------------------------------------------------------
		-- N=65536
		-----------------------------------------------------------------------------------------------
		gen_tw_65536 : if(nps = 65536) generate
get_tw_65536:process(clk,global_clock_enable,p_count_int,data_addr_held)is
				variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case p_count_int(2 downto 0) is
						when "001" =>
								twad_tempe <= data_addr_held(apr-4 downto 0) & '0';
								twad_tempo <= (data_addr_held(apr-4 downto 0) & '0')+int2ustd(1,apr-3);
							when "010" =>	
								twad_tempe <= data_addr_held(apr-6 downto 0) & (2 downto 0 => '0') ;
								twad_tempo <= (data_addr_held(apr-6 downto 0) & (2 downto 0 => '0')) + int2ustd(4,apr-3);
							when "011" =>		
								twad_tempe <= data_addr_held(apr-8 downto 0) & (4 downto 0 => '0');
								twad_tempo <= data_addr_held(apr-8 downto 0) & (4 downto 0 => '0') + int2ustd(16,apr-3);
							when "100" =>		
								twad_tempe <= data_addr_held(apr-10 downto 0) & (6 downto 0 => '0');
								twad_tempo <= data_addr_held(apr-10 downto 0) & (6 downto 0 => '0') + int2ustd(64,apr-3);
							when "101" =>		
								twad_tempe <= data_addr_held(apr-12 downto 0) & (8 downto 0 => '0');
								twad_tempo <= data_addr_held(apr-12 downto 0) & (8 downto 0 => '0') + int2ustd(256,apr-3);
							when "110" =>		
								twad_tempe <= data_addr_held(apr-14 downto 0) & (10 downto 0 => '0');
								twad_tempo <= data_addr_held(apr-14 downto 0) & (10 downto 0 => '0') + int2ustd(1024,apr-3);
							when "111" =>		
								twad_tempe <= data_addr_held(apr-16 downto 0) & (12 downto 0 => '0');
								twad_tempo <= data_addr_held(apr-16 downto 0) & (12 downto 0 => '0') + int2ustd(4096,apr-3);
							when others =>
								twad_tempe <= (others=>'0');
								twad_tempo <= (others=>'0');
						end case;
					end if;
				end process get_tw_65536;
		end generate gen_tw_65536;

end generate gen_de;	
	






end;

			


