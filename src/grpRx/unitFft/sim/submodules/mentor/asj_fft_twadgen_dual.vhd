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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_twadgen_dual.vhd#1 $
--  $log$
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Twiddle address permutation is fixed for each N
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.fft_pack.all;

entity asj_fft_twadgen_dual is
	generic(
						nps : integer :=4096;
						nume : integer :=2;
						n_passes : integer :=5;
						log2_n_passes : integer :=3;
						apr : integer :=10;
						tw_delay : integer:=8
					);
	port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
						k_count   	  : in std_logic_vector(apr-2 downto 0);
						p_count   	  : in std_logic_vector(log2_n_passes-1 downto 0);
						tw_addre				  : out std_logic_vector((nume/2)*apr-1 downto 0);
						tw_addro				  : out std_logic_vector((nume/2)*apr-1 downto 0)
			);
end asj_fft_twadgen_dual;

architecture gen_all of asj_fft_twadgen_dual is

signal twad_tempe,twad_tempo        : std_logic_vector(apr-1 downto 0);
signal twad_tempe_0,twad_tempo_0        : std_logic_vector(apr-1 downto 0);
signal twad_tempe_1,twad_tempo_1        : std_logic_vector(apr-1 downto 0);
type twad_arr is array (0 to tw_delay-1) of std_logic_vector((nume/2)*apr-1 downto 0);
signal twad_tdlo : twad_arr;
signal twad_tdle : twad_arr;




signal k_int : std_logic_vector(apr-1 downto 0);

begin


-----------------------------------------------------------------------------------------------
-- Dual Engine
-----------------------------------------------------------------------------------------------
gen_de : if(nume=2) generate

	k_int <= '0' & k_count;
	
	-- delay twiddle address output to sync with data output from BFP
	tw_addre <= twad_tdle(tw_delay-1);
	tw_addro <= twad_tdlo(tw_delay-1);
	
tdl_twe:process(clk,global_clock_enable,twad_tempe,twad_tdle)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				for i in tw_delay-1 downto 1 loop
					twad_tdle(i)<=twad_tdle(i-1);
				end loop;
				twad_tdle(0)<= twad_tempe;
			end if;
	end process tdl_twe;
	
tdl_two:process(clk,global_clock_enable,twad_tempo,twad_tdlo)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				for i in tw_delay-1 downto 1 loop
					twad_tdlo(i)<=twad_tdlo(i-1);
				end loop;
				twad_tdlo(0)<= twad_tempo ;
			end if;
	end process tdl_two;
	
	
	
	gen_tw_64 : if(nps = 64) generate
get_tw_64:process(clk,global_clock_enable,p_count,k_int)is
		variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					a := (k_int(1 downto 0) & "00") +
		     ('0' & k_int(3 downto 2) & '0');
				if(p_count(0)='1') then
			  --twiddle_addr=mod(m*(4*mod((m*k),4) + floor(k/4)),n_by_4)
					twad_tempe <= a;
					twad_tempo <= a(3 downto 0) + int2ustd(1,apr);
				else
					twad_tempe <= (a(1 downto 0) & "00");
					twad_tempo <= (a(1 downto 0) & "00") + int2ustd(4,apr);
				end if;
			end if;
	  end process get_tw_64;
	end generate gen_tw_64;
	
	gen_tw_128 : if(nps = 128) generate
get_tw_128:process(clk,global_clock_enable,p_count,k_int)is
			variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					a := (k_int(1 downto 0) & "000") +
		     ("00" & k_int(3 downto 2) & '0');
		     case p_count(1 downto 0) is
					--twiddle_addr2(1)=mod(m*(128*mod(m*k,8)+32*floor(mod(k,16)/4)+8*floor(mod(k,64)/16)+2*floor(mod(k,256)/64)),n_by_4);
					  when "01" =>
								twad_tempe <= a(4 downto 0);
								twad_tempo <= a(4 downto 0) + int2ustd(1,apr);
						when "10" =>
								twad_tempe <= a(2 downto 0) & "00";
								twad_tempo <= (a(2 downto 0) & "00") + int2ustd(4,apr);
						when "11" =>
								twad_tempe <= '0' & a(0) & "000";
								twad_tempo <= ('0' & a(0) & "000")+ int2ustd(16,apr);					
						when others =>
							twad_tempe <= (others=>'0');
							twad_tempo <= (others=>'0');
					end case;
				end if;
			end process get_tw_128;
		end generate gen_tw_128;
	
	gen_tw_256 : if(nps = 256) generate
	
	
get_tw_256:process(clk,global_clock_enable,p_count,k_int)is
		variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
			--twiddle_addr2(1)=mod(m*(16*mod(m*k,4)+4*mod(floor(k/4),4)+2*floor(k/16)),n_by_4);
				a := (k_int(1 downto 0) & "0000") + ("00" & k_int(3 downto 2) & "00") + ("000" & k_int(5 downto 4) & '0');
				case p_count(1 downto 0) is
				  --twiddle_addr2(1)=mod(m*(16*mod(m*k,4)+4*mod(floor(k/4),4)+2*floor(k/16)),n_by_4);
					when "01" =>
						twad_tempe <= a;
						twad_tempo <= a + int2ustd(1,apr);
					when "10" =>
						twad_tempe <= a(3 downto 0) & "00";
						twad_tempo <= (a(3 downto 0) & "00") + int2ustd(4,apr);
					when "11" =>
						twad_tempe <= a(1 downto 0) & "0000";
						twad_tempo <= (a(1 downto 0) & "0000")+ int2ustd(16,apr);					
				  when others =>
						twad_tempe <= (others=>'0');
						twad_tempo <= (others=>'0');
				end case;
			end if;
	 end process get_tw_256;
	
	end generate gen_tw_256;
	
	gen_tw_512 : if(nps = 512) generate
	
get_tw_512:process(clk,global_clock_enable,p_count,k_int)is
		variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				a := (k_int(1 downto 0) & "00000") +
	     ("00" & k_int(3 downto 2) & "000") +
	     ("00" & k_int(5 downto 4) & '0');
	     case p_count(2 downto 0) is
				--twiddle_addr2(1)=mod(m*(128*mod(m*k,8)+32*floor(mod(k,16)/4)+8*floor(mod(k,64)/16)+2*floor(mod(k,256)/64)),n_by_4);
				  when "001" =>
							twad_tempe <= a(6 downto 0);
							twad_tempo <= a(6 downto 0) + int2ustd(1,apr);
					when "010" =>
							twad_tempe <= a(4 downto 0) & "00";
							twad_tempo <= (a(4 downto 0) & "00") + int2ustd(4,apr);
					when "011" =>
							twad_tempe <= a(2 downto 0) & "0000";
							twad_tempo <= (a(2 downto 0) & "0000")+ int2ustd(16,apr);
					when "100" =>
							twad_tempe <= '0' & a(0) & "00000";
						twad_tempo <= ('0' & a(0) & "00000")+ int2ustd(64,apr);					
					when others =>
						twad_tempe <= (others=>'0');
						twad_tempo <= (others=>'0');
				end case;
			end if;
		end process get_tw_512;
	end generate gen_tw_512;
	
	
	gen_tw_1024 : if(nps = 1024) generate
	
	
get_tw_1024:process(clk,global_clock_enable,p_count,k_int)is
		variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
			  a := (k_int(1 downto 0) & "000000") + ("00" & k_int(3 downto 2) & "0000") + ("0000" & k_int(5 downto 4) & "00") + ("000000" & k_int(6) & '0');
				case p_count(2 downto 0) is
				--twiddle_addr2(1)=mod(m*(64*mod(m*k,4)+16*mod(floor(k/4),4)+mod(4*floor(k/16),16)+2*floor(k/64)),n_by_4);
				  when "001" =>
						twad_tempe <= a(7 downto 0);
						twad_tempo <= a(7 downto 0)+int2ustd(1,apr);
					when "010" =>
						twad_tempe <= a(5 downto 0) & "00";
						twad_tempo <= (a(5 downto 0) & "00")+int2ustd(4,apr);
					when "011" =>
						twad_tempe <= a(3 downto 0) & "0000";
						twad_tempo <= (a(3 downto 0) & "0000")+int2ustd(16,apr);
					when "100" =>
						twad_tempe <= a(1 downto 0) & "000000";
						twad_tempo <= (a(1 downto 0) & "000000")+int2ustd(64,apr);
					when others =>
						twad_tempe <= (others=>'0');
						twad_tempo <= (others=>'0');
				end case;
			end if;
	 end process get_tw_1024;
	
	end generate gen_tw_1024;
	
	
	gen_tw_2048 : if(nps = 2048) generate
	
get_tw_2048:process(clk,global_clock_enable,p_count,k_int)is
		variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count(2 downto 0) is
				--twiddle_addr2(1)=mod(m*(128*mod(m*k,8)+32*floor(mod(k,16)/4)+8*floor(mod(k,64)/16)+2*floor(mod(k,256)/64)),n_by_4);
				  when "001" =>
							a := (k_int(1 downto 0) & "0000000") +
						     ("00" & k_int(3 downto 2) & "00000") +
						     ("00" & k_int(5 downto 4) & "000") +
						     ("00000" & k_int(7 downto 6) & '0');
							twad_tempe <= a(8 downto 0);
							twad_tempo <= a(8 downto 0) + int2ustd(1,apr);
					when "010" =>
							a := (k_int(1 downto 0) & "0000000") +
						     ("00" & k_int(3 downto 2) & "00000") +
						     ("00" & k_int(5 downto 4) & "000") +
						     ("00000" & k_int(7 downto 6) & '0');
							twad_tempe <= a(6 downto 0) & "00";
							twad_tempo <= (a(6 downto 0) & "00") + int2ustd(4,apr);
					when "011" =>
							a := (k_int(1 downto 0) & "0000000") +
						     ("00" & k_int(3 downto 2) & "00000") +
						     ("00" & k_int(5 downto 4) & "000") +
						     ("00000" & k_int(7 downto 6) & '0');
							twad_tempe <= a(4 downto 0) & "0000";
							twad_tempo <= (a(4 downto 0) & "0000")+ int2ustd(16,apr);
					when "100" =>
							a := (k_int(1 downto 0) & "0000000") +
						     ("00" & k_int(3 downto 2) & "00000") +
						     ("00" & k_int(5 downto 4) & "000") +
						     ("00000" & k_int(7 downto 6) & '0');
						twad_tempe <= a(2 downto 0) & "000000";
						twad_tempo <= (a(2 downto 0) & "000000")+ int2ustd(64,apr);
					when "101" =>
						a := "0000000" & k_int(7) & '0';     
						twad_tempe <= '0' & a(0) & "0000000";
						twad_tempo <= ('0' & a(0) & "0000000")+ int2ustd(256,apr);					
					when others =>
						a :=  (others=>'0');
						twad_tempe <= (others=>'0');
						twad_tempo <= (others=>'0');
				end case;
			end if;
		end process get_tw_2048;
	end generate gen_tw_2048;
	
	
	
	gen_tw_4096 : if(nps = 4096) generate
	
get_tw_4096:process(clk,global_clock_enable,p_count,k_int)is
		variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count(2 downto 0) is
				--twiddle_addr(1)=mod(m*(256*mod(m*k,4)+64*mod(floor(k/4),4)+mod(16*floor(k/16),64)+mod(4*floor(k/64),16)+2*floor(k/256)),n_by_4);
				  when "001" =>
							a := (k_int(1 downto 0) & "00000000") +
						     ("00" & k_int(3 downto 2) & "000000") +
						     ("00" & k_int(5 downto 4) & "0000") +
						     ("000000" & k_int(7 downto 6) & "00")+
						     ("0000000" & k_int(9 downto 8) & '0');
							twad_tempe <= a(9 downto 0);
							twad_tempo <= a(9 downto 0) + int2ustd(1,apr);
					when "010" =>
							a := (k_int(1 downto 0) & "00000000") +
						     ("00" & k_int(3 downto 2) & "000000") +
						     ("00" & k_int(5 downto 4) & "0000") +
						     ("000000" & k_int(7 downto 6) & "00")+
						     ("0000000" & k_int(9 downto 8) & '0');
							twad_tempe <= a(7 downto 0) & "00";
							twad_tempo <= (a(7 downto 0) & "00") + int2ustd(4,apr);
					when "011" =>
							a := (k_int(1 downto 0) & "00000000") +
						     ("00" & k_int(3 downto 2) & "000000") +
						     ("00" & k_int(5 downto 4) & "0000") +
						     ("000000" & k_int(7 downto 6) & "00")+
						     ("0000000" & k_int(9 downto 8) & '0');
							twad_tempe <= a(5 downto 0) & "0000";
							twad_tempo <= (a(5 downto 0) & "0000")+ int2ustd(16,apr);
					when "100" =>
							a := (k_int(1 downto 0) & "00000000") +
						     ("00" & k_int(3 downto 2) & "000000") +
						     ("00" & k_int(5 downto 4) & "0000") +
						     ("000000" & k_int(7 downto 6) & "00")+
						     ("0000000" & k_int(9 downto 8) & '0');
						twad_tempe <= a(3 downto 0) & "000000";
						twad_tempo <= (a(3 downto 0) & "000000")+ int2ustd(64,apr);
					when "101" =>
						--	a := (k_int(1 downto 0) & "00000000") +
						--     ("00" & k_int(3 downto 2) & "000000") +
						--     ("00" & k_int(5 downto 4) & "0000") +
						--     ("000000" & k_int(7 downto 6) & "00")+
						--     ("0000000" & k_int(9 downto 8) & '0');
						a := "00000000" & k_int(8) & '0';     
						twad_tempe <= a(1 downto 0) & "00000000";
						twad_tempo <= (a(1 downto 0) & "00000000")+ int2ustd(256,apr);					
					when others =>
						a :=  (others=>'0');
						twad_tempe <= (others=>'0');
						twad_tempo <= (others=>'0');
				end case;
			end if;
		end process get_tw_4096;
	end generate gen_tw_4096;
	
	gen_tw_8192 : if(nps = 8192) generate                                                                                      
	                                                                                                                           
get_tw_8192:process(clk,global_clock_enable,p_count,k_int)is
		variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');                                                   
		begin                                                                                                                    
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count(2 downto 0) is                                                                                          
				--      twiddle_addr2(1)=mod(m*(512*mod(m*k,8)+128*floor(mod(k,16)/4)+32*floor(mod(k,64)/16)+8*floor(mod(k,256)/64)+2*floor(mod(k,1024)/256)+floor(k/1024)),n_by_4)
				  when "001" =>                                                                                                      
							a := (k_int(1 downto 0) & "000000000") +                                                                         
						     ("00" & k_int(3 downto 2) & "0000000") +                                                                      
						     ("00" & k_int(5 downto 4) & "00000") +                                                                        
						     ("00000" & k_int(7 downto 6) & "000") +
						     ("0000000" & k_int(9 downto 8) & '0');                                                                        
							twad_tempe <= a(10 downto 0);                                                                                   
							twad_tempo <= a(10 downto 0) + int2ustd(1,apr);                                                                 
					when "010" =>                                                                                                      
						a := (k_int(1 downto 0) & "000000000") +                                                                         
						     ("00" & k_int(3 downto 2) & "0000000") +                                                                      
						     ("00" & k_int(5 downto 4) & "00000") +                                                                        
						     ("00000" & k_int(7 downto 6) & "000") +
						     ("0000000" & k_int(9 downto 8) & '0');                                                                        
							twad_tempe <= a(8 downto 0) & "00";                                                                                
							twad_tempo <= (a(8 downto 0) & "00") + int2ustd(4,apr);                                                        
					when "011" =>                                                                                                      
						a := (k_int(1 downto 0) & "000000000") +                                                                         
						     ("00" & k_int(3 downto 2) & "0000000") +                                                                      
						     ("00" & k_int(5 downto 4) & "00000") +                                                                        
						     ("00000" & k_int(7 downto 6) & "000") +
						     ("0000000" & k_int(9 downto 8) & '0');                                                                        
							twad_tempe <= a(6 downto 0) & "0000";                                                                          
							twad_tempo <= (a(6 downto 0) & "0000")+ int2ustd(16,apr);                                                      
					when "100" =>                                                                                                      
						a := (k_int(1 downto 0) & "000000000") +                                                                         
						     ("00" & k_int(3 downto 2) & "0000000") +                                                                      
						     ("00" & k_int(5 downto 4) & "00000") +                                                                        
						     ("00000" & k_int(7 downto 6) & "000") +
						     ("0000000" & k_int(9 downto 8) & '0');                                                                        
						twad_tempe <= a(4 downto 0) & "000000";                                                                          
						twad_tempo <= (a(4 downto 0) & "000000")+ int2ustd(64,apr);                                                      
					when "101" =>                                                                                                      
						a := (k_int(1 downto 0) & "000000000") +                                                                         
						     ("00" & k_int(3 downto 2) & "0000000") +                                                                      
						     ("00" & k_int(5 downto 4) & "00000") +                                                                        
						     ("00000" & k_int(7 downto 6) & "000") +
						     ("0000000" & k_int(9 downto 8) & '0');                                                                        
						twad_tempe <= a(2 downto 0) & "00000000";                                                                          
						twad_tempo <= (a(2 downto 0) & "00000000")+ int2ustd(256,apr);                                                      
					when "110" =>                                                                                                      
						a := (k_int(1 downto 0) & "000000000") +                                                                         
						     ("00" & k_int(3 downto 2) & "0000000") +                                                                      
						     ("00" & k_int(5 downto 4) & "00000") +                                                                        
						     ("00000" & k_int(7 downto 6) & "000") +
						     ("0000000" & k_int(9 downto 8) & '0');                                                                        
						twad_tempe <= '0' & a(0) & "000000000";                                                                            
						twad_tempo <= ('0' & a(0) & "000000000")+ int2ustd(1024,apr);					                                             
					when others =>                                                                                                     
						a :=  (others=>'0');                                                                                             
						twad_tempe <= (others=>'0');                                                                                     
						twad_tempo <= (others=>'0');                                                                                     
				end case;                                                                                                            
			end if;                                                                                                                
		end process get_tw_8192;                                                                                                 
	end generate gen_tw_8192;            
	
	gen_tw_16384 : if(nps = 16384) generate
	
get_tw_16384:process(clk,global_clock_enable,p_count,k_int)is
		variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count(2 downto 0) is
				--twiddle_addr2(1)=mod(m*(1024*mod(m*k,4)+256*mod(floor(k/4),4)+mod(64*floor(k/16),256)+mod(16*floor(k/64),64)+mod(4*floor(k/256),16)+2*floor(k/1024)),n_by_4);
				--twiddle_addr2(1)=mod(m*(1024*mod(m*k,4)
				--                 +256*mod(floor(k/4),4)
				--                 +mod(64*floor(k/16),256)
				--                 +mod(16*floor(k/64),64)
				--                 +mod(4*floor(k/256),16)
				--                 +2*floor(k/1024)),n_by_4);
				  when "001" =>
							a := (k_int(1 downto 0) & "0000000000") +
						     ("00" & k_int(3 downto 2) & "00000000") +
						     ("0000" & k_int(5 downto 4) & "000000") +
						     ("000000" & k_int(7 downto 6) & "0000")+
						     ("00000000" & k_int(9 downto 8) & "00") +
						     ("0000000000" & k_int(10) & '0') ;
							twad_tempe <= a(11 downto 0);
							twad_tempo <= a(11 downto 0) + int2ustd(1,apr);
					when "010" =>
							a := (k_int(1 downto 0) & "0000000000") +
						     ("00" & k_int(3 downto 2) & "00000000") +
						     ("0000" & k_int(5 downto 4) & "000000") +
						     ("000000" & k_int(7 downto 6) & "0000")+
						     ("00000000" & k_int(9 downto 8) & "00") +
						     ("0000000000" & k_int(10) & '0') ;
							twad_tempe <= a(9 downto 0) & "00";
							twad_tempo <= (a(9 downto 0) & "00") + int2ustd(4,apr);
					when "011" =>
							a := (k_int(1 downto 0) & "0000000000") +
						     ("00" & k_int(3 downto 2) & "00000000") +
						     ("0000" & k_int(5 downto 4) & "000000") +
						     ("000000" & k_int(7 downto 6) & "0000")+
						     ("00000000" & k_int(9 downto 8) & "00") +
						     ("0000000000" & k_int(10) & '0') ;
							twad_tempe <= a(7 downto 0) & "0000";
							twad_tempo <= (a(7 downto 0) & "0000")+ int2ustd(16,apr);
					when "100" =>
							a := (k_int(1 downto 0) & "0000000000") +
						     ("00" & k_int(3 downto 2) & "00000000") +
						     ("0000" & k_int(5 downto 4) & "000000") +
						     ("000000" & k_int(7 downto 6) & "0000")+
						     ("00000000" & k_int(9 downto 8) & "00") +
						     ("0000000000" & k_int(10) & '0') ;
						twad_tempe <= a(5 downto 0) & "000000";
						twad_tempo <= (a(5 downto 0) & "000000")+ int2ustd(64,apr);
					when "101" =>
							a := (k_int(1 downto 0) & "0000000000") +
						     ("00" & k_int(3 downto 2) & "00000000") +
						     ("0000" & k_int(5 downto 4) & "000000") +
						     ("000000" & k_int(7 downto 6) & "0000")+
						     ("00000000" & k_int(9 downto 8) & "00") +
						     ("0000000000" & k_int(10) & '0') ;
						twad_tempe <= a(3 downto 0) & "00000000";
						twad_tempo <= (a(3 downto 0) & "00000000")+ int2ustd(256,apr);					
					when "110" =>
							a := (k_int(1 downto 0) & "0000000000") +
						     ("00" & k_int(3 downto 2) & "00000000") +
						     ("0000" & k_int(5 downto 4) & "000000") +
						     ("000000" & k_int(7 downto 6) & "0000")+
						     ("00000000" & k_int(9 downto 8) & "00") +
						     ("0000000000" & k_int(10) & '0') ;
						twad_tempe <= a(1 downto 0) & "0000000000";
						twad_tempo <= (a(1 downto 0) & "0000000000")+ int2ustd(1024,apr);					
					when others =>
						a :=  (others=>'0');
						twad_tempe <= (others=>'0');
						twad_tempo <= (others=>'0');
				end case;
			end if;
		end process get_tw_16384;
	end generate gen_tw_16384;        

gen_tw_32768 : if(nps = 32768) generate
	
get_tw_32768:process(clk,global_clock_enable,p_count,k_int)is
variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
        a := (k_int(1 downto 0) & k_int(3 downto 2) & k_int(5 downto 4) & k_int(7 downto 6) & k_int(9 downto 8) & k_int(11 downto 10) & '0');
	    case p_count(2 downto 0) is
            when "001" =>
				twad_tempe <= a(12 downto 0);
				twad_tempo <= a(12 downto 0) + int2ustd(1,apr);
			when "010" =>
                twad_tempe <= a(10 downto 0) & "00";
                twad_tempo <= (a(10 downto 0) & "00") + int2ustd(4,apr);
            when "011" =>
                twad_tempe <= a(8 downto 0) & "0000";
                twad_tempo <= (a(8 downto 0) & "0000")+ int2ustd(16,apr);
            when "100" =>
                twad_tempe <= a(6 downto 0) & "000000";
                twad_tempo <= (a(6 downto 0) & "000000")+ int2ustd(64,apr);
            when "101" =>
                twad_tempe <= a(4 downto 0) & "00000000";
                twad_tempo <= (a(4 downto 0) & "00000000")+ int2ustd(256,apr);
            when "110" =>
                twad_tempe <= a(2 downto 0) & "0000000000";
                twad_tempo <= (a(2 downto 0) & "0000000000")+ int2ustd(1024,apr);
            when "111" =>
                twad_tempe <= '0' & a(0) & "00000000000";
                twad_tempo <= ('0' & a(0) & "00000000000")+ int2ustd(4096,apr);
            when others =>
                twad_tempe <= (others=>'0');
                twad_tempo <= (others=>'0');
    		end case;
        end if;
    end process get_tw_32768;
end generate gen_tw_32768;

gen_tw_65536 : if(nps = 65536) generate
	
get_tw_65536:process(clk,global_clock_enable,p_count,k_int)is
variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
        a := (k_int(1 downto 0) & k_int(3 downto 2) & k_int(5 downto 4) & k_int(7 downto 6) & k_int(9 downto 8) & k_int(11 downto 10) & k_int(12) & '0') ;
	    case p_count(2 downto 0) is
            when "001" =>
				twad_tempe <= a(13 downto 0);
				twad_tempo <= a(13 downto 0) + int2ustd(1,apr);
			when "010" =>
                twad_tempe <= a(11 downto 0) & "00";
                twad_tempo <= (a(11 downto 0) & "00") + int2ustd(4,apr);
            when "011" =>
                twad_tempe <= a(9 downto 0) & "0000";
                twad_tempo <= (a(9 downto 0) & "0000")+ int2ustd(16,apr);
            when "100" =>
                twad_tempe <= a(7 downto 0) & "000000";
                twad_tempo <= (a(7 downto 0) & "000000")+ int2ustd(64,apr);
            when "101" =>
                twad_tempe <= a(5 downto 0) & "00000000";
                twad_tempo <= (a(5 downto 0) & "00000000")+ int2ustd(256,apr);
            when "110" =>
                twad_tempe <= a(3 downto 0) & "0000000000";
                twad_tempo <= (a(3 downto 0) & "0000000000")+ int2ustd(1024,apr);
            when "111" =>
                twad_tempe <= a(1 downto 0) & "000000000000";
                twad_tempo <= (a(1 downto 0) & "000000000000")+ int2ustd(4096,apr);
            when others =>
                twad_tempe <= (others=>'0');
                twad_tempo <= (others=>'0');
    		end case;
        end if;
    end process get_tw_65536;
end generate gen_tw_65536;

gen_tw_131072 : if(nps = 131072) generate
	
get_tw_131072:process(clk,global_clock_enable,p_count,k_int)is
variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
        a := (k_int(1 downto 0) & k_int(3 downto 2) & k_int(5 downto 4) & k_int(7 downto 6) & k_int(9 downto 8) & k_int(11 downto 10) & k_int(13 downto 12) & '0') ;
	    case p_count(3 downto 0) is
            when "0001" =>
				twad_tempe <= a(14 downto 0);
				twad_tempo <= a(14 downto 0) + int2ustd(1,apr);
			when "0010" =>
                twad_tempe <= a(12 downto 0) & "00";
                twad_tempo <= (a(12 downto 0) & "00") + int2ustd(4,apr);
            when "0011" =>
                twad_tempe <= a(10 downto 0) & "0000";
                twad_tempo <= (a(10 downto 0) & "0000")+ int2ustd(16,apr);
            when "0100" =>
                twad_tempe <= a(8 downto 0) & "000000";
                twad_tempo <= (a(8 downto 0) & "000000")+ int2ustd(64,apr);
            when "0101" =>
                twad_tempe <= a(6 downto 0) & "00000000";
                twad_tempo <= (a(6 downto 0) & "00000000")+ int2ustd(256,apr);
            when "0110" =>
                twad_tempe <= a(4 downto 0) & "0000000000";
                twad_tempo <= (a(4 downto 0) & "0000000000")+ int2ustd(1024,apr);
            when "0111" =>
                twad_tempe <= a(2 downto 0) & "000000000000";
                twad_tempo <= (a(2 downto 0) & "000000000000")+ int2ustd(4096,apr);
            when "1000" =>
                twad_tempe <= '0' & a(0) & "0000000000000";
                twad_tempo <= ('0' & a(0) & "0000000000000")+ int2ustd(16384,apr);
            when others =>
                twad_tempe <= (others=>'0');
                twad_tempo <= (others=>'0');
    		end case;
        end if;
    end process get_tw_131072;
end generate gen_tw_131072;

end generate gen_de;
-----------------------------------------------------------------------------------------------
-- Dual Engine
-----------------------------------------------------------------------------------------------
gen_qe : if(nume=4) generate

	k_int <= '0' & k_count;
	
	-- delay twiddle address output to sync with data output from BFP
	tw_addre <= twad_tdle(tw_delay-1);   
	tw_addro <= (others=>'0');	
	--tw_addro <= twad_tdlo(tw_delay-1);
	
tdl_twe:process(clk,global_clock_enable,twad_tempe,twad_tdle)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				for i in tw_delay-1 downto 1 loop
					twad_tdle(i)<=twad_tdle(i-1);
				end loop;
				twad_tdle(0)<= twad_tempe_0 & twad_tempe_1;
			end if;
	end process tdl_twe;
	
--tdl_two:process(clk,global_clock_enable,twad_tempo,twad_tdlo)is
	--	begin
--if((rising_edge(clk) and global_clock_enable='1'))then
	--			for i in tw_delay-1 downto 1 loop
	--				twad_tdlo(i)<=twad_tdlo(i-1);
	--			end loop;
	--			twad_tdlo(0)<= twad_tempo_0 & twad_tempo_1;
	--		end if;
	--end process tdl_two;
	
	
	
	gen_tw_64 : if(nps = 64) generate
	
	
get_tw_64:process(clk,global_clock_enable,p_count,k_int)is
		variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				if(p_count(0)='1') then
				  --twiddle_addr=mod(m*(4*mod((m*k),4) + floor(k/4)),n_by_4)
					a := k_int(1 downto 0) & k_int(3 downto 2);
					twad_tempe <= a;
				else
					a := k_int(3 downto 2) & "00";
					twad_tempe <= a;
				end if;
			end if;
	 end process get_tw_64;
	
	end generate gen_tw_64;
	
	gen_tw_128 : if(nps = 128) generate
	
get_tw_128:process(clk,global_clock_enable,p_count,k_int)is
		variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				a := (k_int(1 downto 0) & "000") +
	     ("00" & k_int(3 downto 2) & '0');
	     case p_count(1 downto 0) is
				--twiddle_addr2(1)=mod(m*(128*mod(m*k,8)+32*floor(mod(k,16)/4)+8*floor(mod(k,64)/16)+2*floor(mod(k,256)/64)),n_by_4);
				  when "01" =>
							twad_tempe <= a(4 downto 0);
							twad_tempo <= a(4 downto 0) + int2ustd(1,apr);
					when "10" =>
							twad_tempe <= a(2 downto 0) & "00";
							twad_tempo <= (a(2 downto 0) & "00") + int2ustd(4,apr);
					when "11" =>
							twad_tempe <= '0' & a(0) & "000";
							twad_tempo <= ('0' & a(0) & "000")+ int2ustd(16,apr);					
					when others =>
						twad_tempe <= (others=>'0');
						twad_tempo <= (others=>'0');
				end case;
			end if;
		end process get_tw_128;
	end generate gen_tw_128;
	-----------------------------------------------------------------------------------------------
	gen_tw_256 : if(nps = 256) generate
get_tw_256:process(clk,global_clock_enable,p_count,k_int)is
		--apr=5;
		variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				a := (k_int(1 downto 0) & k_int(3 downto 2) & k_int(4));
				case p_count(1 downto 0) is
					when "01" =>
						twad_tempe_0 <= a;
						twad_tempe_1 <= a+int2ustd(1,apr);
						twad_tempo_0 <= a;
						twad_tempo_1 <= a + int2ustd(1,apr);
					when "10" =>
						twad_tempe_0 <= (k_int(3 downto 2) & "000");
						twad_tempe_1 <= (k_int(3 downto 2) & "000") + int2ustd(4,apr);
						twad_tempo_0 <= (a(2 downto 0) & "00") + int2ustd(1,apr);
						twad_tempo_1 <= (a(2 downto 0) & "00") + int2ustd(4,apr);
					when "11" =>
						twad_tempe_0 <= (a(0) & "0000");
						twad_tempe_1 <= (a(0) & "0000")+ int2ustd(16,apr);					
						twad_tempo_0 <= (a(0) & "0000")+ int2ustd(4,apr);					
						twad_tempo_1 <= (a(0) & "0000")+ int2ustd(16,apr);					
						
				  when others =>
						twad_tempe_0 <= (others=>'0');
						twad_tempo_1 <= (others=>'0');
						twad_tempe_1 <= (others=>'0');
						twad_tempo_0 <= (others=>'0');
				end case;
			end if;
	 end process get_tw_256;
	
	end generate gen_tw_256;
-----------------------------------------------------------------------------------------------	
	gen_tw_512 : if(nps = 512) generate
	
		twad_tempo_0 <= (others=>'0');
		twad_tempo_1 <= (others=>'0');
	
get_tw_512:process(clk,global_clock_enable,p_count,k_int)is
		--apr=6;
		variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
			 case p_count(2 downto 0) is
					when "001" =>
						a := (k_int(1 downto 0) & k_int(3 downto 2)& k_int(5 downto 4));
						twad_tempe_0 <= a;
						twad_tempe_1 <= a+int2ustd(2,apr);
					when "010" =>
						a := k_int(1 downto 0) & k_int(3 downto 2)& k_int(5) & '0';
						twad_tempe_0 <= (k_int(3 downto 2) & k_int(5) & '0' & k_int(4) & '0');
						twad_tempe_1 <= (k_int(3 downto 2) & k_int(5) & '0' & k_int(4) & '0') + int2ustd(8,apr);
					when "011" =>
						twad_tempe_0 <= ("00" & k_int(4) & "000");
						twad_tempe_1 <= ("00" & k_int(4) & "000")+ int2ustd(32,apr);					
					when "100" =>
						twad_tempe_0 <= int2ustd(0,apr);					
						twad_tempe_1 <= int2ustd(0,apr);					
					when others =>
						twad_tempe_0 <= (others=>'0');
						twad_tempe_1 <= (others=>'0');
				end case;
			end if;
		end process get_tw_512;
	end generate gen_tw_512;
	
	
	gen_tw_1024 : if(nps = 1024) generate
	
	
get_tw_1024:process(clk,global_clock_enable,p_count,k_int)is
		-- apr=7
		variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
			  a := (k_int(1 downto 0) & k_int(3 downto 2) & k_int(5 downto 4) & k_int(6));
				case p_count(2 downto 0) is
					when "001" =>
						twad_tempe_0 <= a;
						twad_tempe_1 <= a+int2ustd(1,apr);
						twad_tempo_0 <= a;
						twad_tempo_1 <= a + int2ustd(1,apr);
					when "010" =>
						twad_tempe_0 <= (a(4 downto 0) & "00");
						twad_tempe_1 <= (a(4 downto 0) & "00") + int2ustd(4,apr);
						twad_tempo_0 <= (a(4 downto 0) & "00") + int2ustd(1,apr);
						twad_tempo_1 <= (a(4 downto 0) & "00") + int2ustd(4,apr);
					when "011" =>
						twad_tempe_0 <= (a(2 downto 0) & "0000");
						twad_tempe_1 <= (a(2 downto 0) & "0000")+ int2ustd(16,apr);					
						twad_tempo_0 <= (a(2 downto 0) & "0000")+ int2ustd(4,apr);					
						twad_tempo_1 <= (a(2 downto 0) & "0000")+ int2ustd(16,apr);					
					when "100" =>
						twad_tempe_0 <= (a(0) & "000000");
						twad_tempe_1 <= (a(0) & "000000")+ int2ustd(64,apr);					
						twad_tempo_0 <= (a(0) & "000000")+ int2ustd(16,apr);					
						twad_tempo_1 <= (a(0) & "000000")+ int2ustd(64,apr);					
					when others =>
						twad_tempe_0 <= (others=>'0');
						twad_tempo_1 <= (others=>'0');
						twad_tempe_1 <= (others=>'0');
						twad_tempo_0 <= (others=>'0');
				end case;
			end if;
	 end process get_tw_1024;
	
	end generate gen_tw_1024;
	
	
	gen_tw_2048 : if(nps = 2048) generate
	
get_tw_2048:process(clk,global_clock_enable,p_count,k_int)is
		variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count(2 downto 0) is
					when "001" =>
						a := (k_int(1 downto 0) & k_int(3 downto 2)& k_int(5 downto 4) & k_int(7 downto 6));
						twad_tempe_0 <= a;
						twad_tempe_1 <= a+int2ustd(2,apr);
					when "010" =>
						twad_tempe_0 <= (k_int(3 downto 2) & k_int(5 downto 4) & "00" & k_int(6) & '0');
						twad_tempe_1 <= (k_int(3 downto 2) & k_int(5 downto 4) & "00" & k_int(6) & '0') + int2ustd(8,apr);
					when "011" =>
						--twad_tempe_0 <= (k_int(5 downto 4) & "000000") + ("0000" & k_count(6) & "000");
						twad_tempe_0 <= (k_int(5 downto 4) & "00" & k_count(6) & "000");
						twad_tempe_1 <= (k_int(5 downto 4) & "00" & k_count(6) & "000")+ int2ustd(32,apr);					
					when "100" =>
						twad_tempe_0 <= ("00" & k_int(6) & "00000");
						twad_tempe_1 <= ("00" & k_int(6) & "00000")+ int2ustd(128,apr);					
					when "101" =>
						twad_tempe_0 <= int2ustd(0,apr);					
						twad_tempe_1 <= int2ustd(0,apr);				
					when others =>
						twad_tempe_0 <= (others=>'0');
						twad_tempe_1 <= (others=>'0');
				end case;
			end if;
		end process get_tw_2048;
	end generate gen_tw_2048;
	
	
	
	gen_tw_4096 : if(nps = 4096) generate
	
get_tw_4096:process(clk,global_clock_enable,p_count,k_int)is
		variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
			  a := (k_int(1 downto 0) & k_int(3 downto 2) & k_int(5 downto 4) & k_int(7 downto 6) & k_int(8));
				case p_count(2 downto 0) is
					when "001" =>
						twad_tempe_0 <= a;
						twad_tempe_1 <= a+int2ustd(1,apr);
						twad_tempo_0 <= a;
						twad_tempo_1 <= a + int2ustd(1,apr);
					when "010" =>
						twad_tempe_0 <= (a(6 downto 0) & "00");
						twad_tempe_1 <= (a(6 downto 0) & "00") + int2ustd(4,apr);
						twad_tempo_0 <= (a(6 downto 0) & "00") + int2ustd(1,apr);
						twad_tempo_1 <= (a(6 downto 0) & "00") + int2ustd(4,apr);
					when "011" =>
						twad_tempe_0 <= (a(4 downto 0) & "0000");
						twad_tempe_1 <= (a(4 downto 0) & "0000")+ int2ustd(16,apr);					
						twad_tempo_0 <= (a(4 downto 0) & "0000")+ int2ustd(4,apr);					
						twad_tempo_1 <= (a(4 downto 0) & "0000")+ int2ustd(16,apr);					
					when "100" =>
						twad_tempe_0 <= (a(2 downto 0) & "000000");
						twad_tempe_1 <= (a(2 downto 0) & "000000")+ int2ustd(64,apr);					
						twad_tempo_0 <= (a(2 downto 0) & "000000")+ int2ustd(16,apr);					
						twad_tempo_1 <= (a(2 downto 0) & "000000")+ int2ustd(64,apr);					
					when "101" =>
						twad_tempe_0 <= (a(0) & "00000000");
						twad_tempe_1 <= (a(0) & "00000000")+ int2ustd(256,apr);					
						twad_tempo_0 <= (a(0) & "00000000")+ int2ustd(64,apr);					
						twad_tempo_1 <= (a(0) & "00000000")+ int2ustd(256,apr);					
					when others =>
						twad_tempe_0 <= (others=>'0');
						twad_tempo_1 <= (others=>'0');
						twad_tempe_1 <= (others=>'0');
						twad_tempo_0 <= (others=>'0');
				end case;
			end if;
		end process get_tw_4096;
	end generate gen_tw_4096;
	
	gen_tw_8192 : if(nps = 8192) generate                                                                                      
	                                                                                                                           
get_tw_8192:process(clk,global_clock_enable,p_count,k_int)is
		variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');                                                   
		begin                                                                                                                    
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count(2 downto 0) is
					when "001" =>
						a := (k_int(1 downto 0) & k_int(3 downto 2)& k_int(5 downto 4) & k_int(7 downto 6) & k_int(9 downto 8));
						twad_tempe_0 <= a;
						twad_tempe_1 <= a+int2ustd(2,apr);
					when "010" =>
						twad_tempe_0 <= (k_int(3 downto 2) & k_int(5 downto 4) & k_count(7 downto 6) & "00" & k_int(8) & '0');
						twad_tempe_1 <= (k_int(3 downto 2) & k_int(5 downto 4) & k_count(7 downto 6) & "00" & k_int(8) & '0') + int2ustd(8,apr);
					when "011" =>
						twad_tempe_0 <= (k_int(5 downto 4) & k_int(7 downto 6) & "00" & k_count(8) & "000");
						twad_tempe_1 <= (k_int(5 downto 4) & k_int(7 downto 6) & "00" & k_count(8) & "000")+ int2ustd(32,apr);					
					when "100" =>
						twad_tempe_0 <= (k_int(7 downto 6) & "00" & k_count(8) & "00000");
						twad_tempe_1 <= (k_int(7 downto 6) & "00" & k_count(8) & "00000")+ int2ustd(128,apr);					
					when "101" =>
						twad_tempe_0 <= ("00" & k_int(8) & "0000000");
						twad_tempe_1 <= ("00" & k_int(8) & "0000000")+ int2ustd(512,apr);					
					when "110" =>
						twad_tempe_0 <= int2ustd(0,apr);					
						twad_tempe_1 <= int2ustd(0,apr);				
					when others =>
						twad_tempe_0 <= (others=>'0');
						twad_tempe_1 <= (others=>'0');
				end case;                                                                                           
			end if;                                                                                                                
		end process get_tw_8192;                                                                                                 
	end generate gen_tw_8192;            
	
	gen_tw_16384 : if(nps = 16384) generate
	
get_tw_16384:process(clk,global_clock_enable,p_count,k_int)is
		variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				a := (k_int(1 downto 0) & k_int(3 downto 2) & k_int(5 downto 4) & k_int(7 downto 6) & k_int(9 downto 8) & k_int(10));
				case p_count(2 downto 0) is
					when "001" =>
						twad_tempe_0 <= a;
						twad_tempe_1 <= a+int2ustd(1,apr);
						twad_tempo_0 <= a;
						twad_tempo_1 <= a + int2ustd(1,apr);
					when "010" =>
						twad_tempe_0 <= (a(8 downto 0) & "00");
						twad_tempe_1 <= (a(8 downto 0) & "00") + int2ustd(4,apr);
						twad_tempo_0 <= (a(8 downto 0) & "00") + int2ustd(1,apr);
						twad_tempo_1 <= (a(8 downto 0) & "00") + int2ustd(4,apr);
					when "011" =>
						twad_tempe_0 <= (a(6 downto 0) & "0000");
						twad_tempe_1 <= (a(6 downto 0) & "0000")+ int2ustd(16,apr);					
						twad_tempo_0 <= (a(6 downto 0) & "0000")+ int2ustd(4,apr);					
						twad_tempo_1 <= (a(6 downto 0) & "0000")+ int2ustd(16,apr);					
					when "100" =>
						twad_tempe_0 <= (a(4 downto 0) & "000000");
						twad_tempe_1 <= (a(4 downto 0) & "000000")+ int2ustd(64,apr);					
						twad_tempo_0 <= (a(4 downto 0) & "000000")+ int2ustd(16,apr);					
						twad_tempo_1 <= (a(4 downto 0) & "000000")+ int2ustd(64,apr);					
					when "101" =>
						twad_tempe_0 <= (a(2 downto 0) & "00000000");
						twad_tempe_1 <= (a(2 downto 0) & "00000000")+ int2ustd(256,apr);					
						twad_tempo_0 <= (a(2 downto 0) & "00000000")+ int2ustd(64,apr);					
						twad_tempo_1 <= (a(2 downto 0) & "00000000")+ int2ustd(256,apr);					
 					when "110" =>
						twad_tempe_0 <= (a(0) & "0000000000");
						twad_tempe_1 <= (a(0) & "0000000000")+ int2ustd(1024,apr);					
						twad_tempo_0 <= (a(0) & "0000000000")+ int2ustd(256,apr);					
						twad_tempo_1 <= (a(0) & "0000000000")+ int2ustd(1024,apr);					
					when others =>
						twad_tempe_0 <= (others=>'0');
						twad_tempo_1 <= (others=>'0');
						twad_tempe_1 <= (others=>'0');
						twad_tempo_0 <= (others=>'0');
				end case;
			end if;
		end process get_tw_16384;
	end generate gen_tw_16384;                                                                                      

gen_tw_32768 : if(nps = 32768) generate                                                                                      
	                                                                                                                           
get_tw_32768:process(clk,global_clock_enable,p_count,k_int)is
variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');                                                   
begin                                                                                                                    
    if((rising_edge(clk) and global_clock_enable='1'))then
	    case p_count(2 downto 0) is
            when "001" =>
                a := (k_int(1 downto 0) & k_int(3 downto 2)& k_int(5 downto 4) & k_int(7 downto 6) & k_int(9 downto 8) & k_int(11 downto 10));
                twad_tempe_0 <= a;
                twad_tempe_1 <= a+int2ustd(2,apr);
            when "010" =>
                twad_tempe_0 <= (k_int(3 downto 2) & k_int(5 downto 4) & k_count(7 downto 6) & k_count(9 downto 8) & "00" & k_int(10) & '0');
                twad_tempe_1 <= (k_int(3 downto 2) & k_int(5 downto 4) & k_count(7 downto 6) & k_count(9 downto 8) & "00" & k_int(10) & '0') + int2ustd(8,apr);
            when "011" =>
                twad_tempe_0 <= (k_int(5 downto 4) & k_int(7 downto 6) & k_count(9 downto 8) & "00" & k_count(10) & "000");
                twad_tempe_1 <= (k_int(5 downto 4) & k_int(7 downto 6) & k_count(9 downto 8) & "00" & k_count(10) & "000")+ int2ustd(32,apr);
            when "100" =>
                twad_tempe_0 <= (k_int(7 downto 6) & k_count(9 downto 8) & "00" & k_count(10) & "00000");
                twad_tempe_1 <= (k_int(7 downto 6) & k_count(9 downto 8) & "00" & k_count(10) & "00000")+ int2ustd(128,apr);
            when "101" =>
                twad_tempe_0 <= (k_count(9 downto 8) & "00" & k_int(10) & "0000000");
                twad_tempe_1 <= (k_count(9 downto 8) & "00" & k_int(10) & "0000000")+ int2ustd(512,apr);
            when "110" =>
                twad_tempe_0 <= ("00" & k_int(10) & "000000000");
                twad_tempe_1 <= ("00" & k_int(10) & "000000000")+ int2ustd(2048,apr);
            when "111" =>
                twad_tempe_0 <= int2ustd(0,apr);
                twad_tempe_1 <= int2ustd(0,apr);
            when others =>
                twad_tempe_0 <= (others=>'0');
                twad_tempe_1 <= (others=>'0');
            end case;
        end if;
	end process get_tw_32768;
end generate gen_tw_32768;

gen_tw_65536 : if(nps = 65536) generate

get_tw_65536:process(clk,global_clock_enable,p_count,k_int)is
variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
        a := (k_int(1 downto 0) & k_int(3 downto 2) & k_int(5 downto 4) & k_int(7 downto 6) & k_int(9 downto 8) & k_int(11 downto 10) & k_int(12));
		case p_count(2 downto 0) is
            when "001" =>
                twad_tempe_0 <= a;
                twad_tempe_1 <= a + int2ustd(1,apr);
                twad_tempo_0 <= a;
                twad_tempo_1 <= a + int2ustd(1,apr);
            when "010" =>
                twad_tempe_0 <= (a(10 downto 0) & "00");
                twad_tempe_1 <= (a(10 downto 0) & "00") + int2ustd(4,apr);
                twad_tempo_0 <= (a(10 downto 0) & "00") + int2ustd(1,apr);
                twad_tempo_1 <= (a(10 downto 0) & "00") + int2ustd(4,apr);
            when "011" =>
                twad_tempe_0 <= (a(8 downto 0) & "0000");
                twad_tempe_1 <= (a(8 downto 0) & "0000")+ int2ustd(16,apr);
                twad_tempo_0 <= (a(8 downto 0) & "0000")+ int2ustd(4,apr);
                twad_tempo_1 <= (a(8 downto 0) & "0000")+ int2ustd(16,apr);
            when "100" =>
                twad_tempe_0 <= (a(6 downto 0) & "000000");
                twad_tempe_1 <= (a(6 downto 0) & "000000")+ int2ustd(64,apr);
                twad_tempo_0 <= (a(6 downto 0) & "000000")+ int2ustd(16,apr);
                twad_tempo_1 <= (a(6 downto 0) & "000000")+ int2ustd(64,apr);
			when "101" =>
                twad_tempe_0 <= (a(4 downto 0) & "00000000");
                twad_tempe_1 <= (a(4 downto 0) & "00000000")+ int2ustd(256,apr);
                twad_tempo_0 <= (a(4 downto 0) & "00000000")+ int2ustd(64,apr);
				twad_tempo_1 <= (a(4 downto 0) & "00000000")+ int2ustd(256,apr);
            when "110" =>
            	twad_tempe_0 <= (a(2 downto 0) & "0000000000");
                twad_tempe_1 <= (a(2 downto 0) & "0000000000")+ int2ustd(1024,apr);
                twad_tempo_0 <= (a(2 downto 0) & "0000000000")+ int2ustd(256,apr);
				twad_tempo_1 <= (a(2 downto 0) & "0000000000")+ int2ustd(1024,apr);
            when "111" =>
            	twad_tempe_0 <= (a(0) & "000000000000");
                twad_tempe_1 <= (a(0) & "000000000000")+ int2ustd(4096,apr);
                twad_tempo_0 <= (a(0) & "000000000000")+ int2ustd(1024,apr);
				twad_tempo_1 <= (a(0) & "000000000000")+ int2ustd(4096,apr);
            when others =>
				twad_tempe_0 <= (others=>'0');
				twad_tempo_1 <= (others=>'0');
				twad_tempe_1 <= (others=>'0');
				twad_tempo_0 <= (others=>'0');
			end case;
		end if;
	end process get_tw_65536;
end generate gen_tw_65536;

gen_tw_131072 : if(nps = 131072) generate
	                                                                                                                           
get_tw_131072:process(clk,global_clock_enable,p_count,k_int)is
variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');                                                   
begin                                                                                                                    
    if((rising_edge(clk) and global_clock_enable='1'))then
	    case p_count(3 downto 0) is
            when "0001" =>
                a := (k_int(1 downto 0) & k_int(3 downto 2)& k_int(5 downto 4) & k_int(7 downto 6) & k_int(9 downto 8) & k_int(11 downto 10) & k_int(13 downto 12));
                twad_tempe_0 <= a;
                twad_tempe_1 <= a+int2ustd(2,apr);
            when "0010" =>
                twad_tempe_0 <= (k_int(3 downto 2) & k_int(5 downto 4) & k_count(7 downto 6) & k_count(9 downto 8) & k_count(11 downto 10) & "00" & k_int(12) & '0');
                twad_tempe_1 <= (k_int(3 downto 2) & k_int(5 downto 4) & k_count(7 downto 6) & k_count(9 downto 8) & k_count(11 downto 10) & "00" & k_int(12) & '0') + int2ustd(8,apr);
            when "0011" =>
                twad_tempe_0 <= (k_int(5 downto 4) & k_int(7 downto 6) & k_count(9 downto 8) & k_count(11 downto 10) & "00" & k_count(12) & "000");
                twad_tempe_1 <= (k_int(5 downto 4) & k_int(7 downto 6) & k_count(9 downto 8) & k_count(11 downto 10) & "00" & k_count(12) & "000")+ int2ustd(32,apr);
            when "0100" =>
                twad_tempe_0 <= (k_int(7 downto 6) & k_count(9 downto 8) & k_count(11 downto 10) & "00" & k_count(12) & "00000");
                twad_tempe_1 <= (k_int(7 downto 6) & k_count(9 downto 8) & k_count(11 downto 10) & "00" & k_count(12) & "00000")+ int2ustd(128,apr);
            when "0101" =>
                twad_tempe_0 <= (k_count(9 downto 8) & k_count(11 downto 10) & "00" & k_int(12) & "0000000");
                twad_tempe_1 <= (k_count(9 downto 8) & k_count(11 downto 10) & "00" & k_int(12) & "0000000")+ int2ustd(512,apr);
            when "0110" =>
                twad_tempe_0 <= (k_count(11 downto 10) & "00" & k_int(12) & "0000000");
                twad_tempe_1 <= (k_count(11 downto 10) & "00" & k_int(12) & "0000000")+ int2ustd(2048,apr);
            when "0111" =>
                twad_tempe_0 <= ("00" & k_int(12) & "0000000");
                twad_tempe_1 <= ("00" & k_int(12) & "0000000")+ int2ustd(8192,apr);
            when "1000" =>
                twad_tempe_0 <= int2ustd(0,apr);
                twad_tempe_1 <= int2ustd(0,apr);
            when others =>
                twad_tempe_0 <= (others=>'0');
                twad_tempe_1 <= (others=>'0');
            end case;
        end if;
	end process get_tw_131072;
end generate gen_tw_131072;

end generate gen_qe;



end architecture gen_all;
