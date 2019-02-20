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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_wrswgen.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
-- generate address and data switch select lines for writing butterfly outputs to RAM
-- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all; 
use work.fft_pack.all;

entity asj_fft_wrswgen is
	generic(
						nps : integer :=4096;
						cont : integer:=0;
						arch : integer:=0;
						nume : integer :=1;
						n_passes : integer :=5;
						log2_n_passes : integer:= 3;
						apr : integer :=10;
						del : integer :=17
					);
	port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
						k_count   	  : in std_logic_vector(apr-1 downto 0);
						p_count       : in std_logic_vector(log2_n_passes-1 downto 0);
						sw_data_write : out std_logic_vector(1 downto 0); -- swd
						sw_addr_write : out std_logic_vector(1 downto 0) --swa
			);
end asj_fft_wrswgen;

architecture gen_all of asj_fft_wrswgen is


type sw_array is array (0 to del-1) of std_logic_vector(1 downto 0);
signal swd_tdl : sw_array;
signal swa_tdl : sw_array;
signal swd : std_logic_vector(1 downto 0);
signal swa : std_logic_vector(1 downto 0);

begin


sw_data_write <= swd_tdl(del-1);
sw_addr_write <= swa_tdl(del-1);

-- Output delayed version of siwtches to sync with RAM-bound data
tdl_sw:process(clk,global_clock_enable,swd,swa,swd_tdl,swa_tdl)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			for i in del-1 downto 1 loop
				swd_tdl(i)<=swd_tdl(i-1);
				swa_tdl(i)<=swa_tdl(i-1);
			end loop;
			swd_tdl(0)<=swd;
			swa_tdl(0)<=swa;
		end if;
	end process tdl_sw;
			
	
-----------------------------------------------------------------------------------------
--Streaming 512,1024
-----------------------------------------------------------------------------------------
gen_streaming : if(arch=0) generate

gen_cont : if(cont=1) generate

gen_512_addr : if(nps=512) generate

swa<=swd;

get_512_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(2 downto 0) is
				when "001" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
				when "010" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = floor(k/4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				when "011" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4);
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
				when "100" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
					--    swa = mod(floor(k/64),4);
         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + ('0' & k_count(6));
				when others =>
				 	swd <=(others=>'0');
			end case;
		end if;
	end process get_512_sw;
	
	 
		
end generate gen_512_addr;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

gen_1024_addr : if(nps=1024) generate

swa <= swd;

get_1024_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(2 downto 0) is
				when "001" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
				when "010" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = floor(k/4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				when "011" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4);
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
				when "100" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
					--    swa = mod(floor(k/64),4);
         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
				when others =>
				 	swd <=(others=>'0');
			end case;
		end if;
	end process get_1024_sw;
end generate gen_1024_addr;

end generate gen_cont;

-----------------------------------------------------------------------------------------------
-- Non-Continous : All Streaming architectures except 512 and 1024
-----------------------------------------------------------------------------------------------
gen_non_cont:if(cont=0) generate


gen_32_addr : if(nps=32) generate
get_32_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(1 downto 0) is
				when "01" =>
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = floor(k/4);
				 	swd <= k_count(1 downto 0) + ('0' & k_count(2));
				 	swa <= '0' & k_count(2);
				when others =>
				 	 	swd <=(others=>'0');
				 	 	swa <=(others=>'0');
			end case;
		end if;
	end process get_32_sw;
	
	 
end generate gen_32_addr;



gen_64_addr : if(nps=64) generate

get_64_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(1 downto 0) is
				when "01" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = floor(k/4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when others =>
				 	 	swd <=(others=>'0');
				 	 	swa <=(others=>'0');
			end case;
		end if;
	end process get_64_sw;
	
	 
end generate gen_64_addr;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
gen_128_addr : if(nps=128) generate
--
get_128_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(1 downto 0) is
				when "01" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = mod(floor(k/4),4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "11" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4)
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + ('0' & k_count(4));
				 	swa <= '0' & k_count(4);
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_128_sw;
	
	 
end generate gen_128_addr;
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

gen_256_addr : if(nps=256) generate
--
get_256_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(1 downto 0) is
				when "01" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = mod(floor(k/4),4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "11" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4)
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
				 	swa <= k_count(5 downto 4);
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_256_sw;
	
	 
end generate gen_256_addr;

-----------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------
	gen_2048_addr : if(nps=2048) generate
	
		swa <= swd;
get_2048_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							--    swd = mod(k,4);
		        	--    swa = mod(k,4)
		         	swd <= k_count(1 downto 0);
		         	--swa <= k_count(1 downto 0);
						when "010" =>
							--    swd = mod(floor(k/1)+floor(k/4),4);
		        	--    swa = floor(k/4);
						 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	--swa <= k_count(3 downto 2);
						when "011" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
		        	--    swa = mod(floor(k/16),4);
						 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	--swa <= k_count(5 downto 4);
						when "100" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
							--    swa = mod(floor(k/64),4);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	--swa <= k_count(7 downto 6);
						when "101" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/256);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	--swa <= "00";
						when others =>
						 	swd <=(others=>'0');
						 	--swa <=(others=>'0');
					end case;
				end if;
			end process get_2048_sw;
	end generate gen_2048_addr;
	
	gen_4096_addr : if(nps=4096) generate
		swa <= swd;
get_4096_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							--    swd = mod(k,4);
		        	--    swa = mod(k,4)
		         	swd <= k_count(1 downto 0);
		         	--swa <= k_count(1 downto 0);
						when "010" =>
							--    swd = mod(floor(k/1)+floor(k/4),4);
		        	--    swa = floor(k/4);
						 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	--swa <= k_count(3 downto 2);
						when "011" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
		        	--    swa = mod(floor(k/16),4);
						 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	--swa <= k_count(5 downto 4);
						when "100" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
							--    swa = mod(floor(k/64),4);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	--swa <= k_count(7 downto 6);
						when "101" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/256);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ ('0' & k_count(8));
						 	--swa <= '0' & k_count(8);
						when others =>
						 	swd <=(others=>'0');
						 	--swa <=(others=>'0');
					end case;
				end if;
			end process get_4096_sw;
	end generate gen_4096_addr;
	
	gen_8192_addr : if(nps=8192) generate
		swa <=swd;
get_8192_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							--    swd = mod(k,4);
		        	--    swa = mod(k,4)
		         	swd <= k_count(1 downto 0);
		         	--swa <= k_count(1 downto 0);
						when "010" =>
							--    swd = mod(floor(k/1)+floor(k/4),4);
		        	--    swa = floor(k/4);
						 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	--swa <= k_count(3 downto 2);
						when "011" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
		        	--    swa = mod(floor(k/16),4);
						 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	--swa <= k_count(5 downto 4);
						when "100" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
							--    swa = mod(floor(k/64),4);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	--swa <= k_count(7 downto 6);
						when "101" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/256);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8);
						 	--swa <= k_count(9 downto 8);
						when "110" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/1024);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8) ;
						 	--swa <= "00";
						when others =>
						 	swd <=(others=>'0');
						 	--swa <=(others=>'0');
					end case;
				end if;
			end process get_8192_sw;
	end generate gen_8192_addr;
	
	gen_16384_addr : if(nps=16384) generate
	swa <=swd; 
get_16384_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							--    swd = mod(k,4);
		        	--    swa = mod(k,4)
		         	swd <= k_count(1 downto 0);
		         	--swa <= k_count(1 downto 0);
						when "010" =>
							--    swd = mod(floor(k/1)+floor(k/4),4);
		        	--    swa = floor(k/4);
						 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	--swa <= k_count(3 downto 2);
						when "011" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
		        	--    swa = mod(floor(k/16),4);
						 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	--swa <= k_count(5 downto 4);
						when "100" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
							--    swa = mod(floor(k/64),4);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	--swa <= k_count(7 downto 6);
						when "101" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/256);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8);
						 	--swa <= k_count(9 downto 8);
						when "110" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/1024);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8) + ('0' & k_count(10));
						 	--swa <= '0' & k_count(10);
						when others =>
						 	swd <=(others=>'0');
						 	--swa <=(others=>'0');
					end case;
				end if;
			end process get_16384_sw;
	end generate gen_16384_addr;

gen_32768_addr : if(nps=32768) generate
swa <=swd; 
get_32768_sw:process(clk,global_clock_enable,p_count,k_count)is
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
	    case p_count(2 downto 0) is
            when "001" =>
                swd <= k_count(1 downto 0);
            when "010" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2);
            when "011" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4);
            when "100" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6);
            when "101" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8);
            when "110" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8) + k_count(11 downto 10);
            when "111" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8) + k_count(11 downto 10);
            when others =>
                swd <=(others=>'0');
            end case;
		end if;
	end process get_32768_sw;
end generate gen_32768_addr;

gen_65536_addr : if(nps=65536) generate
swa <=swd; 
get_65536_sw:process(clk,global_clock_enable,p_count,k_count)is
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
	    case p_count(2 downto 0) is
            when "001" =>
                swd <= k_count(1 downto 0);
            when "010" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2);
            when "011" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4);
            when "100" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6);
            when "101" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8);
            when "110" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8) + k_count(11 downto 10);
            when "111" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8) + k_count(11 downto 10) + ('0' & k_count(12));
            when others =>
                swd <=(others=>'0');
            end case;
		end if;
	end process get_65536_sw;
end generate gen_65536_addr;

gen_131072_addr : if(nps=131072) generate
swa <=swd; 
get_131072_sw:process(clk,global_clock_enable,p_count,k_count)is
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
	    case p_count(3 downto 0) is
            when "0001" =>
                swd <= k_count(1 downto 0);
            when "0010" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2);
            when "0011" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4);
            when "0100" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6);
            when "0101" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8);
            when "0110" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8) + k_count(11 downto 10);
            when "0111" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8) + k_count(11 downto 10) + k_count(12 downto 11);
            when "1000" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8) + k_count(11 downto 10) + k_count(12 downto 11);
            when others =>
                swd <=(others=>'0');
            end case;
		end if;
	end process get_131072_sw;
end generate gen_131072_addr;

end generate gen_non_cont;

end generate gen_streaming;


-----------------------------------------------------------------------------------------------
-- Burst and Buffered Burst
-----------------------------------------------------------------------------------------------
gen_b : if(arch=1 or arch=2) generate

gen_se_addr : if(nume=1) generate 

gen_64_addr : if(nps=64) generate

get_64_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(1 downto 0) is
				when "01" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = floor(k/4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when others =>
				 	 	swd <=(others=>'0');
				 	 	swa <=(others=>'0');
			end case;
		end if;
	end process get_64_sw;
	
	 
end generate gen_64_addr;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
gen_128_addr : if(nps=128) generate
--
get_128_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(1 downto 0) is
				when "01" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = mod(floor(k/4),4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "11" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4)
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + ('0' & k_count(4));
				 	swa <= '0' & k_count(4);
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_128_sw;
	
	 
end generate gen_128_addr;
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

gen_256_addr : if(nps=256) generate
--
get_256_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(1 downto 0) is
				when "01" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = mod(floor(k/4),4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "11" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4)
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
				 	swa <= k_count(5 downto 4);
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_256_sw;
	
	 
end generate gen_256_addr;
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
gen_512_addr : if(nps=512) generate

get_512_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(2 downto 0) is
				when "001" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "010" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = floor(k/4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "011" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4);
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
				 	swa <= k_count(5 downto 4);
				when "100" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
					--    swa = mod(floor(k/64),4);
         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + ('0' & k_count(6));
				 	swa <= '0' & k_count(6);
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_512_sw;
	
	 
		
end generate gen_512_addr;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

gen_1024_addr : if(nps=1024) generate

get_1024_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(2 downto 0) is
				when "001" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "010" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = floor(k/4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "011" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4);
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
				 	swa <= k_count(5 downto 4);
				when "100" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
					--    swa = mod(floor(k/64),4);
         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
				 	swa <= k_count(7 downto 6);
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_1024_sw;
	
	 
		
end generate gen_1024_addr;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
gen_2048_addr : if(nps=2048) generate

get_2048_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(2 downto 0) is
				when "001" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "010" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = floor(k/4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "011" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4);
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
				 	swa <= k_count(5 downto 4);
				when "100" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
					--    swa = mod(floor(k/64),4);
         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
				 	swa <= k_count(7 downto 6);
				when "101" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
					--    swa = mod(floor(k/64),4);
         	swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + ('0' & k_count(8));
				 	swa <= '0' & k_count(8);
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_2048_sw;
	
	 
		
end generate gen_2048_addr;


	gen_4096_addr : if(nps=4096) generate

get_4096_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							--    swd = mod(k,4);
		        	--    swa = mod(k,4)
		         	swd <= k_count(1 downto 0);
		         	swa <= k_count(1 downto 0);
						when "010" =>
							--    swd = mod(floor(k/1)+floor(k/4),4);
		        	--    swa = floor(k/4);
						 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	swa <= k_count(3 downto 2);
						when "011" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
		        	--    swa = mod(floor(k/16),4);
						 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	swa <= k_count(5 downto 4);
						when "100" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
							--    swa = mod(floor(k/64),4);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	swa <= k_count(7 downto 6);
						when "101" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/256);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8);
						 	swa <= k_count(9 downto 8);
						when others =>
						 	swd <=(others=>'0');
						 	swa <=(others=>'0');
					end case;
				end if;
			end process get_4096_sw;
	end generate gen_4096_addr;
-----------------------------------------------------------------------------------------------
--N-8192
-----------------------------------------------------------------------------------------------
gen_8192_addr : if(nps=8192) generate
get_8192_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(2 downto 0) is
				when "001" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "010" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = floor(k/4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "011" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4);
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
				 	swa <= k_count(5 downto 4);
				when "100" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
					--    swa = mod(floor(k/64),4);
         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
				 	swa <= k_count(7 downto 6);
				when "101" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
					--    swa = mod(floor(k/64),4);
         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+k_count(9 downto 8);
				 	swa <= k_count(9 downto 8);
				when "110" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
					--    swa = mod(floor(k/64),4);
         	swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) +k_count(9 downto 8) + ('0' & k_count(10));
				 	swa <= '0' & k_count(10);
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_8192_sw;
end generate gen_8192_addr;
	
-----------------------------------------------------------------------------------------------
--N=16384
-----------------------------------------------------------------------------------------------
	gen_16384_addr : if(nps=16384) generate

get_16384_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							--    swd = mod(k,4);
		        	--    swa = mod(k,4)
		         	swd <= k_count(1 downto 0);
		         	swa <= k_count(1 downto 0);
						when "010" =>
							--    swd = mod(floor(k/1)+floor(k/4),4);
		        	--    swa = floor(k/4);
						 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	swa <= k_count(3 downto 2);
						when "011" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
		        	--    swa = mod(floor(k/16),4);
						 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	swa <= k_count(5 downto 4);
						when "100" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
							--    swa = mod(floor(k/64),4);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	swa <= k_count(7 downto 6);
						when "101" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/256);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8);
						 	swa <= k_count(9 downto 8);
						when "110" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/256);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8)+ k_count(11 downto 10);
						 	swa <= k_count(11 downto 10);
						when others =>
						 	swd <=(others=>'0');
						 	swa <=(others=>'0');
					end case;
				end if;
			end process get_16384_sw;
	end generate gen_16384_addr;

-----------------------------------------------------------------------------------------------
--N=32768
-----------------------------------------------------------------------------------------------
gen_32768_addr : if(nps=32768) generate

get_32768_sw:process(clk,global_clock_enable,p_count,k_count)is
begin
if((rising_edge(clk) and global_clock_enable='1'))then
    case p_count(2 downto 0) is
        when "001" =>
            swd <= k_count(1 downto 0);
		    swa <= k_count(1 downto 0);
		when "010" =>
            swd <= k_count(1 downto 0) + k_count(3 downto 2);
            swa <= k_count(3 downto 2);
        when "011" =>
            swd <= k_count(1 downto 0)+ k_count(3 downto 2) + k_count(5 downto 4);
            swa <= k_count(5 downto 4);
		when "100" =>
            swd <= k_count(1 downto 0)+ k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6);
            swa <= k_count(7 downto 6);
        when "101" =>
            swd <= k_count(1 downto 0)+ k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8);
            swa <= k_count(9 downto 8);
        when "110" =>
            swd <= k_count(1 downto 0)+ k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10);
            swa <= k_count(11 downto 10);
        when "111" =>
            swd <= k_count(1 downto 0)+ k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10) + ('0' & k_count(12));
            swa <= '0' & k_count(12);
        when others =>
            swd <=(others=>'0');
            swa <=(others=>'0');
        end case;
	end if;
end process get_32768_sw;
end generate gen_32768_addr;

-----------------------------------------------------------------------------------------------
--N=65536
-----------------------------------------------------------------------------------------------
gen_65536_addr : if(nps=65536) generate

get_65536_sw:process(clk,global_clock_enable,p_count,k_count)is
begin
if((rising_edge(clk) and global_clock_enable='1'))then
    case p_count(2 downto 0) is
        when "001" =>
            swd <= k_count(1 downto 0);
		    swa <= k_count(1 downto 0);
		when "010" =>
            swd <= k_count(1 downto 0) + k_count(3 downto 2);
            swa <= k_count(3 downto 2);
        when "011" =>
            swd <= k_count(1 downto 0)+ k_count(3 downto 2) + k_count(5 downto 4);
            swa <= k_count(5 downto 4);
		when "100" =>
            swd <= k_count(1 downto 0)+ k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6);
            swa <= k_count(7 downto 6);
        when "101" =>
            swd <= k_count(1 downto 0)+ k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8);
            swa <= k_count(9 downto 8);
        when "110" =>
            swd <= k_count(1 downto 0)+ k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10);
            swa <= k_count(11 downto 10);
        when "111" =>
            swd <= k_count(1 downto 0)+ k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10) + k_count(13 downto 12) ;
            swa <= k_count(13 downto 12);
        when others =>
            swd <=(others=>'0');
            swa <=(others=>'0');
        end case;
	end if;
end process get_65536_sw;
end generate gen_65536_addr;

-----------------------------------------------------------------------------------------------
--N=131072
-----------------------------------------------------------------------------------------------
gen_131072_addr : if(nps=131072) generate

get_131072_sw:process(clk,global_clock_enable,p_count,k_count)is
begin
if((rising_edge(clk) and global_clock_enable='1'))then
    case p_count(3 downto 0) is
        when "0001" =>
            swd <= k_count(1 downto 0);
		    swa <= k_count(1 downto 0);
		when "0010" =>
            swd <= k_count(1 downto 0) + k_count(3 downto 2);
            swa <= k_count(3 downto 2);
        when "0011" =>
            swd <= k_count(1 downto 0)+ k_count(3 downto 2) + k_count(5 downto 4);
            swa <= k_count(5 downto 4);
		when "0100" =>
            swd <= k_count(1 downto 0)+ k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6);
            swa <= k_count(7 downto 6);
        when "0101" =>
            swd <= k_count(1 downto 0)+ k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8);
            swa <= k_count(9 downto 8);
        when "0110" =>
            swd <= k_count(1 downto 0)+ k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10);
            swa <= k_count(11 downto 10);
        when "0111" =>
            swd <= k_count(1 downto 0)+ k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10) + k_count(13 downto 12) ;
            swa <= k_count(11 downto 10);
        when "1000" =>
            swd <= k_count(1 downto 0)+ k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10) + k_count(13 downto 12) + ('0' & k_count(14));
            swa <= '0' & k_count(14);
        when others =>
            swd <=(others=>'0');
            swa <=(others=>'0');
        end case;
	end if;
end process get_131072_sw;
end generate gen_131072_addr;

end generate gen_se_addr;

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- Dual Engine Switch Generator
-----------------------------------------------------------------------------------------------

gen_de_addr : if(nume=2) generate 
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
gen_64_addr : if(nps=64) generate

get_64_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(1 downto 0) is
				when "01" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = floor(k/4);
				 	swd <= k_count(1 downto 0) + ('0' & k_count(2));
				 	swa <= '0' & k_count(2);
				when others =>
				 	 	swd <=(others=>'0');
				 	 	swa <=(others=>'0');
			end case;
		end if;
	end process get_64_sw;
	
	 
end generate gen_64_addr;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
gen_128_addr : if(nps=128) generate
--
get_128_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(1 downto 0) is
				when "01" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = mod(floor(k/4),4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "11" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4)
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2);
				 	swa <= "00";
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_128_sw;
	
	 
end generate gen_128_addr;
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

gen_256_addr : if(nps=256) generate
--
get_256_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(1 downto 0) is
				when "01" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = mod(floor(k/4),4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "11" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4)
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + ('0' & k_count(4));
				 	swa <= '0' & k_count(4);
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_256_sw;
	
	 
end generate gen_256_addr;
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
gen_512_addr : if(nps=512) generate

get_512_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(2 downto 0) is
				when "001" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "010" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = floor(k/4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "011" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4);
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
				 	swa <= k_count(5 downto 4);
				when "100" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
					--    swa = mod(floor(k/64),4);
         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) ;
				 	swa <= "00";
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_512_sw;
	
	 
		
end generate gen_512_addr;
-----------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------
gen_1024_addr : if(nps=1024) generate

get_1024_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(2 downto 0) is
				when "001" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "010" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = floor(k/4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "011" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4);
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
				 	swa <= k_count(5 downto 4);
				when "100" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
					--    swa = mod(floor(k/64),4);
         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + ('0' & k_count(6));
				 	swa <= '0' & k_count(6);
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_1024_sw;
	
	 
		
end generate gen_1024_addr;


	gen_2048_addr : if(nps=2048) generate
get_2048_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							--    swd = mod(k,4);
		        	--    swa = mod(k,4)
		         	swd <= k_count(1 downto 0);
		         	swa <= k_count(1 downto 0);
						when "010" =>
							--    swd = mod(floor(k/1)+floor(k/4),4);
		        	--    swa = floor(k/4);
						 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	swa <= k_count(3 downto 2);
						when "011" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
		        	--    swa = mod(floor(k/16),4);
						 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	swa <= k_count(5 downto 4);
						when "100" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
							--    swa = mod(floor(k/64),4);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	swa <= k_count(7 downto 6);
						when "101" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/256);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	swa <= "00";
						when others =>
						 	swd <=(others=>'0');
						 	swa <=(others=>'0');
					end case;
				end if;
			end process get_2048_sw;
	end generate gen_2048_addr;
	
	gen_4096_addr : if(nps=4096) generate
get_4096_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							--    swd = mod(k,4);
		        	--    swa = mod(k,4)
		         	swd <= k_count(1 downto 0);
		         	swa <= k_count(1 downto 0);
						when "010" =>
							--    swd = mod(floor(k/1)+floor(k/4),4);
		        	--    swa = floor(k/4);
						 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	swa <= k_count(3 downto 2);
						when "011" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
		        	--    swa = mod(floor(k/16),4);
						 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	swa <= k_count(5 downto 4);
						when "100" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
							--    swa = mod(floor(k/64),4);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	swa <= k_count(7 downto 6);
						when "101" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/256);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ ('0' & k_count(8));
						 	swa <= '0' & k_count(8);
						when others =>
						 	swd <=(others=>'0');
						 	swa <=(others=>'0');
					end case;
				end if;
			end process get_4096_sw;
	end generate gen_4096_addr;
	
	gen_8192_addr : if(nps=8192) generate
get_8192_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							--    swd = mod(k,4);
		        	--    swa = mod(k,4)
		         	swd <= k_count(1 downto 0);
		         	swa <= k_count(1 downto 0);
						when "010" =>
							--    swd = mod(floor(k/1)+floor(k/4),4);
		        	--    swa = floor(k/4);
						 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	swa <= k_count(3 downto 2);
						when "011" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
		        	--    swa = mod(floor(k/16),4);
						 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	swa <= k_count(5 downto 4);
						when "100" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
							--    swa = mod(floor(k/64),4);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	swa <= k_count(7 downto 6);
						when "101" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/256);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8);
						 	swa <= k_count(9 downto 8);
						when "110" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/1024);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8) ;
						 	swa <= "00";
						when others =>
						 	swd <=(others=>'0');
						 	swa <=(others=>'0');
					end case;
				end if;
			end process get_8192_sw;
	end generate gen_8192_addr;
	
	gen_16384_addr : if(nps=16384) generate
get_16384_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							--    swd = mod(k,4);
		        	--    swa = mod(k,4)
		         	swd <= k_count(1 downto 0);
		         	swa <= k_count(1 downto 0);
						when "010" =>
							--    swd = mod(floor(k/1)+floor(k/4),4);
		        	--    swa = floor(k/4);
						 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	swa <= k_count(3 downto 2);
						when "011" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
		        	--    swa = mod(floor(k/16),4);
						 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	swa <= k_count(5 downto 4);
						when "100" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
							--    swa = mod(floor(k/64),4);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	swa <= k_count(7 downto 6);
						when "101" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/256);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8);
						 	swa <= k_count(9 downto 8);
						when "110" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/1024);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8) + ('0' & k_count(10));
						 	swa <= '0' & k_count(10);
						when others =>
						 	swd <=(others=>'0');
						 	swa <=(others=>'0');
					end case;
				end if;
			end process get_16384_sw;
	end generate gen_16384_addr;

gen_32768_addr : if(nps=32768) generate
get_32768_sw:process(clk,global_clock_enable,p_count,k_count)is
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
	    case p_count(2 downto 0) is
            when "001" =>
                swd <= k_count(1 downto 0);
                swa <= k_count(1 downto 0);
            when "010" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2);
                swa <= k_count(3 downto 2);
            when "011" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4);
                swa <= k_count(5 downto 4);
            when "100" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6);
                swa <= k_count(7 downto 6);
            when "101" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8);
                swa <= k_count(9 downto 8);
            when "110" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10);
                swa <= k_count(11 downto 10);
            when "111" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10);
                swa <= "00";
            when others =>
                swd <=(others=>'0');
                swa <=(others=>'0');
            end case;
		end if;
	end process get_32768_sw;
end generate gen_32768_addr;

gen_65536_addr : if(nps=65536) generate
get_65536_sw:process(clk,global_clock_enable,p_count,k_count)is
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
	    case p_count(2 downto 0) is
            when "001" =>
                swd <= k_count(1 downto 0);
                swa <= k_count(1 downto 0);
            when "010" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2);
                swa <= k_count(3 downto 2);
            when "011" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4);
                swa <= k_count(5 downto 4);
            when "100" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6);
                swa <= k_count(7 downto 6);
            when "101" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8);
                swa <= k_count(9 downto 8);
            when "110" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10);
                swa <= k_count(11 downto 10);
            when "111" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10) + ('0' & k_count(12));
                swa <= '0' & k_count(12);
            when others =>
                swd <=(others=>'0');
                swa <=(others=>'0');
            end case;
		end if;
	end process get_65536_sw;
end generate gen_65536_addr;

gen_131072_addr : if(nps=131072) generate
get_131072_sw:process(clk,global_clock_enable,p_count,k_count)is
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
	    case p_count(3 downto 0) is
            when "0001" =>
                swd <= k_count(1 downto 0);
                swa <= k_count(1 downto 0);
            when "0010" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2);
                swa <= k_count(3 downto 2);
            when "0011" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4);
                swa <= k_count(5 downto 4);
            when "0100" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6);
                swa <= k_count(7 downto 6);
            when "0101" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8);
                swa <= k_count(9 downto 8);
            when "0110" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10);
                swa <= k_count(11 downto 10);
            when "0111" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10) + k_count(13 downto 12);
                swa <= k_count(13 downto 12);
            when "1000" =>
                swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10) + k_count(13 downto 12);
                swa <= "00";
            when others =>
                swd <=(others=>'0');
                swa <=(others=>'0');
            end case;
		end if;
	end process get_131072_sw;
end generate gen_131072_addr;

end generate gen_de_addr;

-----------------------------------------------------------------------------------------------
-- QUAD Engine Switch Generator
-----------------------------------------------------------------------------------------------

gen_qe_addr : if(nume=4) generate 
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
gen_64_addr : if(nps=64) generate

get_64_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(1 downto 0) is
				when "01" =>
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
				 	swd <= k_count(1 downto 0) + ('0' & k_count(2));
				 	swa <= '0' & k_count(2);
				when others =>
				 	 	swd <=(others=>'0');
				 	 	swa <=(others=>'0');
			end case;
		end if;
	end process get_64_sw;
	
	 
end generate gen_64_addr;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
gen_128_addr : if(nps=128) generate
--
get_128_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(1 downto 0) is
				when "01" =>
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "11" => 	
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2);
				 	swa <= "00";
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_128_sw;
	
	 
end generate gen_128_addr;
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

gen_256_addr : if(nps=256) generate
--
get_256_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(1 downto 0) is
				when "01" =>
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "11" => 	
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2);
				 	--swd <= "00";
				 	swa <= "00";
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_256_sw;
	
	 
end generate gen_256_addr;
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
gen_512_addr : if(nps=512) generate

get_512_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(2 downto 0) is
				when "001" =>
					swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "010" =>
					swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "011" => 	
					swd <= k_count(1 downto 0)+k_count(3 downto 2) + ('0' & k_count(4));
				 	swa <= '0' & k_count(4);
				when "100" => 	
				 	swd <= "00";
				 	swa <= "00";
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_512_sw;
	
	 
		
end generate gen_512_addr;
-----------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------
gen_1024_addr : if(nps=1024) generate

get_1024_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(2 downto 0) is
				when "001" =>
					swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "010" =>
					swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "011" => 	
					swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
				 	swa <= k_count(5 downto 4);
				when "100" => 	
					swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) ;
				 	swa <= "00";
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_1024_sw;
	
	 
		
end generate gen_1024_addr;


	gen_2048_addr : if(nps=2048) generate
get_2048_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							swd <= k_count(1 downto 0);
		         	swa <= k_count(1 downto 0);
						when "010" =>
							swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	swa <= k_count(3 downto 2);
						when "011" => 	
							swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	swa <= k_count(5 downto 4);
						when "100" => 	
							swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4) + ('0' & k_count(6));
						 	swa <= ('0' & k_count(6));
						when "101" => 	
						 	swd <= "00";
						 	swa <= "00";
						when others =>
						 	swd <=(others=>'0');
						 	swa <=(others=>'0');
					end case;
				end if;
			end process get_2048_sw;
	end generate gen_2048_addr;
	
	gen_4096_addr : if(nps=4096) generate
get_4096_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							swd <= k_count(1 downto 0);
		         	swa <= k_count(1 downto 0);
						when "010" =>
							swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	swa <= k_count(3 downto 2);
						when "011" => 	
							swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	swa <= k_count(5 downto 4);
						when "100" => 	
							swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6);
						 	swa <= k_count(7 downto 6);
						when "101" => 	
							swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4)  + k_count(7 downto 6);
						 	swa <= "00";
						when others =>
						 	swd <=(others=>'0');
						 	swa <=(others=>'0');
					end case;
				end if;
			end process get_4096_sw;
	end generate gen_4096_addr;
	
	gen_8192_addr : if(nps=8192) generate
get_8192_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
		         	swd <= k_count(1 downto 0);
		         	swa <= k_count(1 downto 0);
						when "010" =>
						 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	swa <= k_count(3 downto 2);
						when "011" => 	
						 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	swa <= k_count(5 downto 4);
						when "100" => 	
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	swa <= k_count(7 downto 6);
						when "101" => 	 	
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ ('0' & k_count(8));
						 	swa <= '0' & k_count(8);
						when "110" => 	 	
		         	swd <= "00";
						 	swa <= "00";
						when others =>
						 	swd <=(others=>'0');
						 	swa <=(others=>'0');
					end case;
				end if;
			end process get_8192_sw;
	end generate gen_8192_addr;
	
	gen_16384_addr : if(nps=16384) generate
get_16384_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							swd <= k_count(1 downto 0);
		         	swa <= k_count(1 downto 0);
						when "010" =>
							swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	swa <= k_count(3 downto 2);
						when "011" => 	
							swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	swa <= k_count(5 downto 4);
						when "100" => 	
							swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	swa <= k_count(7 downto 6);
						when "101" => 	 	
							swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8);
						 	swa <= k_count(9 downto 8);
						when "110" => 	 	
							swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8);
						 	swa <= "00";
						when others =>
						 	swd <=(others=>'0');
						 	swa <=(others=>'0');
					end case;
				end if;
			end process get_16384_sw;
	end generate gen_16384_addr;

gen_32768_addr : if(nps=32768) generate
get_32768_sw:process(clk,global_clock_enable,p_count,k_count)is
begin
if((rising_edge(clk) and global_clock_enable='1'))then
    case p_count(2 downto 0) is
        when "001" =>
            swd <= k_count(1 downto 0);
            swa <= k_count(1 downto 0);
        when "010" =>
            swd <= k_count(1 downto 0) + k_count(3 downto 2);
            swa <= k_count(3 downto 2);
        when "011" =>
            swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4);
            swa <= k_count(5 downto 4);
        when "100" => 	
            swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6);
            swa <= k_count(7 downto 6);
        when "101" => 	 	
            swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8);
            swa <= k_count(9 downto 8);
        when "110" => 	 	
            swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + ('0' & k_count(10));
            swa <= '0' & k_count(10);
        when "111" => 	 	
            swd <= "00";
            swa <= "00";
        when others =>
            swd <=(others=>'0');
            swa <=(others=>'0');
        end case;
    end if;
end process get_32768_sw;
end generate gen_32768_addr;

gen_65536_addr : if(nps=65536) generate
get_65536_sw:process(clk,global_clock_enable,p_count,k_count)is
begin
if((rising_edge(clk) and global_clock_enable='1'))then
    case p_count(2 downto 0) is
        when "001" =>
            swd <= k_count(1 downto 0);
            swa <= k_count(1 downto 0);
        when "010" =>
            swd <= k_count(1 downto 0) + k_count(3 downto 2);
            swa <= k_count(3 downto 2);
        when "011" =>
            swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4);
            swa <= k_count(5 downto 4);
        when "100" =>
            swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6);
            swa <= k_count(7 downto 6);
        when "101" =>
            swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8);
            swa <= k_count(9 downto 8);
        when "110" =>
            swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10);
            swa <= k_count(11 downto 10);
        when "111" =>
            swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10);
            swa <= "00";
        when others =>
            swd <=(others=>'0');
            swa <=(others=>'0');
        end case;
    end if;
end process get_65536_sw;
end generate gen_65536_addr;

gen_131072_addr : if(nps=131072) generate
get_131072_sw:process(clk,global_clock_enable,p_count,k_count)is
begin
if((rising_edge(clk) and global_clock_enable='1'))then
    case p_count(3 downto 0) is
        when "0001" =>
            swd <= k_count(1 downto 0);
            swa <= k_count(1 downto 0);
        when "0010" =>
            swd <= k_count(1 downto 0) + k_count(3 downto 2);
            swa <= k_count(3 downto 2);
        when "0011" =>
            swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4);
            swa <= k_count(5 downto 4);
        when "0100" => 	
            swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6);
            swa <= k_count(7 downto 6);
        when "0101" => 	 	
            swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8);
            swa <= k_count(9 downto 8);
        when "0110" => 	 	
            swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10);
            swa <= k_count(11 downto 10);
        when "0111" => 	 	
            swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10) + ('0' & k_count(12));
            swa <= '0' & k_count(12);
        when "1000" => 	 	
            swd <= "00";
            swa <= "00";
        when others =>
            swd <=(others=>'0');
            swa <=(others=>'0');
        end case;
    end if;
end process get_131072_sw;
end generate gen_131072_addr;

end generate gen_qe_addr;

end generate gen_b;

end;
