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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_twadgen.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
-- Twiddle address permutation is fixed for each N
-- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all; 
use work.fft_pack.all;

entity asj_fft_twadgen is
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
						k_count   	  : in std_logic_vector(apr-1 downto 0);
						p_count   	  : in std_logic_vector(log2_n_passes-1 downto 0);
						tw_addr				  : out std_logic_vector(apr-1 downto 0)
			);
end asj_fft_twadgen;

architecture gen_all of asj_fft_twadgen is

signal twad_temp        : std_logic_vector(apr-1 downto 0);            
type twad_arr is array (0 to tw_delay-1) of std_logic_vector(apr-1 downto 0);
signal twad_tdl : twad_arr;

--debug
signal test: std_logic_vector(apr-1 downto 0);            

begin

-- delay twiddle address output to sync with data output from BFP
tw_addr <= twad_tdl(tw_delay-1);

tdl_tw:process(clk,global_clock_enable,twad_temp,twad_tdl)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			for i in tw_delay-1 downto 1 loop
				twad_tdl(i)<=twad_tdl(i-1);
			end loop;
			twad_tdl(0)<= twad_temp;
		end if;
end process tdl_tw;
	
gen_tw_32 : if(nps = 32) generate

get_tw_32:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(1 downto 0) is
				when "01" =>
					twad_temp <= (k_count(1 downto 0) & k_count(2));
				when "10" =>	
					twad_temp <= k_count(2) & "00";
			  when others =>
					twad_temp <= (others=>'0');
			end case;
		end if;
 end process get_tw_32;

end generate gen_tw_32;


gen_tw_64 : if(nps = 64) generate

get_tw_64:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			if(p_count(0)='1') then
			  twad_temp <= k_count(1 downto 0) & k_count(3 downto 2);
			else
				twad_temp <= k_count(3 downto 2) & "00";
			end if;
		end if;
 end process get_tw_64;

end generate gen_tw_64;
 
gen_tw_128 : if(nps = 128) generate


get_tw_128:process(clk,global_clock_enable,p_count,k_count)is
	variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(1 downto 0) is
				when "01" =>
					a := (k_count(1 downto 0) & "000") + ("00" & k_count(3 downto 2) & '0') + ("0000" & k_count(4));
					twad_temp <= a;
				when "10" =>	
					a := (k_count(1 downto 0) & "000") + ("00" & k_count(3 downto 2) & '0') + ("0000" & k_count(4));
					twad_temp <= a(2 downto 0) & "00";
				when "11" =>		
					a := (k_count(1 downto 0) & "000") + ("00" & k_count(3 downto 2) & '0') + ("0000" & k_count(4));
					twad_temp <= a(0) & "0000";
			  when others =>
					a :=  (others=>'0');
					twad_temp <= (others=>'0');
			end case;
		end if;
 end process get_tw_128;
 
end generate gen_tw_128; 



gen_tw_256 : if(nps = 256) generate


get_tw_256:process(clk,global_clock_enable,p_count,k_count)is
	variable a : std_logic_vector(apr-1 downto 0);
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(1 downto 0) is
			  --twiddle_addr=mod(m*(16*mod(m*k,4)+4*mod(floor(k/4),4)+floor(k/16)),n_by_4);
				when "01" =>
					a := (k_count(1 downto 0) & "0000") + ("00" & k_count(3 downto 2) & "00") + ("0000" & k_count(5 downto 4));
					twad_temp <= a;
				when "10" =>	
					a :=  ("00" & k_count(3 downto 2) & "00") + ("0000" & k_count(5 downto 4));
					twad_temp <= a(3 downto 0) & "00";
				when "11" =>		
					a :=  ("00" & k_count(3 downto 2) & "00") + ("0000" & k_count(5 downto 4));
					twad_temp <= a(1 downto 0) & "0000";
			  when others =>
					a :=  (others=>'0');
					twad_temp <= (others=>'0');
			end case;
		end if;
 end process get_tw_256;
 
end generate gen_tw_256; 


gen_tw_512 : if(nps = 512) generate


get_tw_512:process(clk,global_clock_enable,p_count,k_count)is
	variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(2 downto 0) is
			--twiddle_addr=mod(m*(32*mod(m*k,8)+8*floor(mod(k,16)/4)+2*floor(mod(k,64)/16)+floor(k/64)),n_by_4);
			-- k_count is 7 bits
			  when "001" =>                                                                                                                                                                 
					a := (k_count(1 downto 0) & "00000") + ("00" & k_count(3 downto 2) & "000") + ("0000" & k_count(5 downto 4) & '0') + ("000000" & k_count(6));   
					twad_temp <= a(6 downto 0);                                                                                                                                              
				when "010" =>	                                                                                                                                                               
					a :=  ('0' & k_count(2) & "00000") + ("00" & k_count(3 downto 2) & "000") + ("0000" & k_count(5 downto 4) & '0') + ("000000" & k_count(6));   
					twad_temp <= a(4 downto 0) & "00";                                                                                                                                       
				when "011" =>		                                                                                                                                                             
					a :=  ("00" & k_count(3 downto 2) & "000") + ("0000" & k_count(5 downto 4) & '0') + ("000000" & k_count(6));   
					twad_temp <= a(2 downto 0) & "0000";                                                                                                                                     
				when "100" =>		                                                                                                                                                             
					a :=  ("00" & k_count(3 downto 2) & "000") + ("0000" & k_count(5 downto 4) & '0') + ("000000" & k_count(6));   
					twad_temp <= a(0) & "000000";                                                                                                                                   
				when others =>
					a :=  (others=>'0');
					twad_temp <= (others=>'0');
			end case;
		end if;
 end process get_tw_512;
 
end generate gen_tw_512; 
						
gen_tw_1024 : if(nps = 1024) generate


get_tw_1024:process(clk,global_clock_enable,p_count,k_count)is
	variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(2 downto 0) is
			--twiddle_addr=mod(m*(64*mod(m*k,4)+16*mod(floor(k/4),4)+mod(4*floor(k/16),16)+floor(k/64)),n_by_4);
			  when "001" =>                                                                                                                                                                 
					a := (k_count(1 downto 0) & "000000") + ("00" & k_count(3 downto 2) & "0000") + ("0000" & k_count(5 downto 4) & "00") + ("000000" & k_count(7 downto 6));   
					twad_temp <= a(7 downto 0);                                                                                                                                              
				when "010" =>	                                                                                                                                                               
					a :=  ("00" & k_count(3 downto 2) & "0000") + ("0000" & k_count(5 downto 4) & "00") + ("000000" & k_count(7 downto 6));                                            
					twad_temp <= a(5 downto 0) & "00";                                                                                                                                       
				when "011" =>		                                                                                                                                                             
					a :=  ("00" & k_count(3 downto 2) & "0000") + ("0000" & k_count(5 downto 4) & "00") + ("000000" & k_count(7 downto 6));                                                
					twad_temp <= a(3 downto 0) & "0000";                                                                                                                                     
				when "100" =>		                                                                                                                                                             
					a :=  ("00" & k_count(3 downto 2) & "0000") + ("0000" & k_count(5 downto 4) & "00") + ("000000" & k_count(7 downto 6));                                                
					twad_temp <= a(1 downto 0) & "000000";                                                                                                                                   
				when others =>
					a :=  (others=>'0');
					twad_temp <= (others=>'0');
			end case;
		end if;
 end process get_tw_1024;
 
end generate gen_tw_1024; 




gen_tw_2048 : if(nps = 2048) generate


get_tw_2048:process(clk,global_clock_enable,p_count,k_count)is
		variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--twiddle_addr=mod(m*(128*mod(m*k,8)
				--             +32*floor(mod(k,16)/4)
				--             +8*floor(mod(k,64)/16)
				--             +2*floor(mod(k,256)/64)
				--             +floor(k/256)),n_by_4);
				a := (k_count(1 downto 0) & "0000000") + 
				   ("00" & k_count(3 downto 2) & "00000") + 
				   ("00" & k_count(5 downto 4) & "000") + 
				   ("000000" & k_count(7 downto 6) & '0')+
				   ("00000000" & k_count(8));   
				case p_count(2 downto 0) is
				  when "001" =>                                                                                                                                                                 
							twad_temp <= a(8 downto 0);                                                                                                                                              
					when "010" =>	                                                                                                                                                               
							twad_temp <= a(6 downto 0) & "00";                                                                                                                                       
					when "011" =>		                                                                                                                                                             
							twad_temp <= a(4 downto 0) & "0000";                                                                                                                                     
					when "100" =>		                                                                                                                                                             
							twad_temp <= a(2 downto 0) & "000000";                                                                                                                                   
					when "101" =>		                                                                                                                                                             
							twad_temp <= a(0) & "00000000";                                                                                                                                   
					when others =>
						twad_temp <= (others=>'0');
				end case;
			end if;
		end process get_tw_2048;

end generate gen_tw_2048;		

gen_tw_4096 : if(nps = 4096) generate
	
get_tw_4096:process(clk,global_clock_enable,p_count,k_count)is
		variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--twiddle_addr=mod(m*(256*mod(m*k,4)
				--                    +64*mod(floor(k/4),4)
				--                    +mod(16*floor(k/16),64)
				--                    +mod(4*floor(k/64),16)
				--                    +floor(k/256)),n_by_4);
				a := (k_count(1 downto 0) & "00000000") + 
				("00" & k_count(3 downto 2) & "000000") + 
				("0000" & k_count(5 downto 4) & "0000") + 
				("000000" & k_count(7 downto 6) & "00")+
				("00000000" & k_count(9 downto 8));   
				case p_count(2 downto 0) is
				  when "001" =>                                                                                                                                                                 
						twad_temp <= a(9 downto 0);                                                                                                                                              
					when "010" =>	                                                                                                                                                               
						twad_temp <= a(7 downto 0) & "00";                                                                                                                                       
					when "011" =>		                                                                                                                                                             
						twad_temp <= a(5 downto 0) & "0000";                                                                                                                                     
					when "100" =>		                                                                                                                                                             
						twad_temp <= a(3 downto 0) & "000000";                                                                                                                                   
					when "101" =>		                                                                                                                                                             
						twad_temp <= a(1 downto 0) & "00000000";                                                                                                                                   
					when others =>
						twad_temp <= (others=>'0');
				end case;
			end if;
		end process get_tw_4096;
end generate gen_tw_4096; 
	
-----------------------------------------------------------------------------------------------
--N=8192
-----------------------------------------------------------------------------------------------
gen_tw_8192 : if(nps = 8192) generate
get_tw_8192:process(clk,global_clock_enable,p_count,k_count)is
		variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--twiddle_addr=mod(m*(512*mod(m*k,8)
				--+128*floor(mod(k,16)/4)
				--+32*floor(mod(k,64)/16)
				--+8*floor(mod(k,256)/64)
				--+2*floor(mod(k,1024)/256) 
				--+ floor(k/1024)),n_by_4);
	      
				a := (k_count(1 downto 0) & "000000000") + 
				("00" & k_count(3 downto 2) & "0000000") + 
				("0000" & k_count(5 downto 4) & "00000") + 
				("000000" & k_count(7 downto 6) & "000")+
				("00000000" & k_count(9 downto 8) & '0')+
				("0000000000" & k_count(10));   
				
				case p_count(2 downto 0) is
				  when "001" =>                                                                                                                                                                 
							twad_temp <= a(10 downto 0);                                                                                                                                              
					when "010" =>	                                                                                                                                                               
							twad_temp <= a(8 downto 0) & "00";                                                                                                                                       
					when "011" =>		                                                                                                                                                             
							twad_temp <= a(6 downto 0) & "0000";                                                                                                                                     
					when "100" =>		                                                                                                                                                             
							twad_temp <= a(4 downto 0) & "000000";                                                                                                                                   
					when "101" =>		                                                                                                                                                             
							twad_temp <= a(2 downto 0) & "00000000"; 
					when "110" =>		                                                                                                                                                             
							twad_temp <= a(0) & "0000000000"; 
					when others =>
							twad_temp <= (others=>'0');
				end case;
			end if;
		end process get_tw_8192;

end generate gen_tw_8192;		

-----------------------------------------------------------------------------------------------
-- N=16384
-----------------------------------------------------------------------------------------------
gen_tw_16384 : if(nps = 16384) generate
	
get_tw_16384:process(clk,global_clock_enable,p_count,k_count)is
		variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--twiddle_addr=mod(m*(1024*mod(m*k,4)
				--+256*mod(floor(k/4),4)
				--+mod(64*floor(k/16),256)
				--+mod(16*floor(k/64),64)
				--+mod(4*floor(k/256),16)
				--+floor(k/1024)),n_by_4);
				a := (k_count(1 downto 0) & "0000000000") + 
				("00" & k_count(3 downto 2) & "00000000") + 
				("0000" & k_count(5 downto 4) & "000000") + 
				("000000" & k_count(7 downto 6) & "0000") +
				("00000000" & k_count(9 downto 8) & "00") +   
				("0000000000" & k_count(11 downto 10));   
				case p_count(2 downto 0) is
				  when "001" =>                                                                                                                                                                 
						twad_temp <= a(11 downto 0);                                                                                                                                              
					when "010" =>	                                                                                                                                                               
						twad_temp <= a(9 downto 0) & "00";                                                                                                                                       
					when "011" =>		                                                                                                                                                             
						twad_temp <= a(7 downto 0) & "0000";                                                                                                                                     
					when "100" =>		                                                                                                                                                             
						twad_temp <= a(5 downto 0) & "000000";                                                                                                                                   
					when "101" =>		                                                                                                                                                             
						twad_temp <= a(3 downto 0) & "00000000";                                                                                                                                   					
					when "110" =>		                                                                                                                                                             
						twad_temp <= a(1 downto 0) & "0000000000";                                                                                                                                   					
					when others =>
						twad_temp <= (others=>'0');
				end case;
			end if;
		end process get_tw_16384;
end generate gen_tw_16384; 
	
-----------------------------------------------------------------------------------------------
-- N=32768
-----------------------------------------------------------------------------------------------
gen_tw_32768 : if(nps = 32768) generate
	
get_tw_32768:process(clk,global_clock_enable,p_count,k_count)is
variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
        a := (k_count(1 downto 0) & k_count(3 downto 2) & k_count(5 downto 4) & k_count(7 downto 6) & k_count(9 downto 8) & k_count(11 downto 10) & k_count(12));   
        case p_count(2 downto 0) is
		    when "001" =>
                twad_temp <= a(12 downto 0);
            when "010" =>
                twad_temp <= a(10 downto 0) & "00";
            when "011" =>
                twad_temp <= a(8 downto 0) & "0000";
            when "100" =>
                twad_temp <= a(6 downto 0) & "000000";
            when "101" =>
                twad_temp <= a(4 downto 0) & "00000000";
            when "110" =>
                twad_temp <= a(2 downto 0) & "0000000000";
            when "111" =>
                twad_temp <= a(0) & "000000000000";
            when others =>
                twad_temp <= (others=>'0');
            end case;
		end if;
	end process get_tw_32768;
end generate gen_tw_32768;
	
-----------------------------------------------------------------------------------------------
-- N=65536
-----------------------------------------------------------------------------------------------
gen_tw_65536 : if(nps = 65536) generate
	
get_tw_65536:process(clk,global_clock_enable,p_count,k_count)is
variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
        a := (k_count(1 downto 0) & k_count(3 downto 2) & k_count(5 downto 4) & k_count(7 downto 6) & k_count(9 downto 8) & k_count(11 downto 10) & k_count(13 downto 12));
        case p_count(2 downto 0) is
		    when "001" =>
                twad_temp <= a(13 downto 0);
            when "010" =>
                twad_temp <= a(11 downto 0) & "00";
            when "011" =>
                twad_temp <= a(9 downto 0) & "0000";
            when "100" =>
                twad_temp <= a(7 downto 0) & "000000";
            when "101" =>
                twad_temp <= a(5 downto 0) & "00000000";
            when "110" =>
                twad_temp <= a(3 downto 0) & "0000000000";
            when "111" =>
                twad_temp <= a(1 downto 0) & "000000000000";
            when others =>
                twad_temp <= (others=>'0');
            end case;
		end if;
	end process get_tw_65536;
end generate gen_tw_65536;

-----------------------------------------------------------------------------------------------
-- N=131072
-----------------------------------------------------------------------------------------------
gen_tw_131072 : if(nps = 131072) generate
	
get_tw_131072:process(clk,global_clock_enable,p_count,k_count)is
variable a : std_logic_vector(apr-1 downto 0) :=(apr-1 downto 0=>'0');
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
        a := (k_count(1 downto 0) & k_count(3 downto 2) & k_count(5 downto 4) & k_count(7 downto 6) & k_count(9 downto 8) & k_count(11 downto 10) & k_count(13 downto 12) & k_count(14));
        case p_count(3 downto 0) is
		    when "0001" =>
                twad_temp <= a(14 downto 0);
            when "0010" =>
                twad_temp <= a(12 downto 0) & "00";
            when "0011" =>
                twad_temp <= a(10 downto 0) & "0000";
            when "0100" =>
                twad_temp <= a(8 downto 0) & "000000";
            when "0101" =>
                twad_temp <= a(6 downto 0) & "00000000";
            when "0110" =>
                twad_temp <= a(4 downto 0) & "0000000000";
            when "0111" =>
                twad_temp <= a(2 downto 0) & "000000000000";
            when "1000" =>
                twad_temp <= a(0) & "00000000000000";
            when others =>
                twad_temp <= (others=>'0');
            end case;
		end if;
	end process get_tw_131072;
end generate gen_tw_131072;



end;

			


