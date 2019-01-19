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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_dataadgen.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
-- Read address permutation is fixed for each N
-- No discernable general relationship
library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all; 
use work.fft_pack.all;

entity asj_fft_dataadgen is
	generic(
						nps : integer :=512;
						nume : integer :=1;
						arch : integer :=3;
						n_passes : integer :=4;
						log2_n_passes : integer:= 3;
						apr : integer :=9
					);
	port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
						k_count   	  : in std_logic_vector(apr-1 downto 0);
						p_count       : in std_logic_vector(log2_n_passes-1 downto 0);
						rd_addr_a				  : out std_logic_vector(apr-1 downto 0);
						rd_addr_b				  : out std_logic_vector(apr-1 downto 0);
						rd_addr_c				  : out std_logic_vector(apr-1 downto 0);
						rd_addr_d				  : out std_logic_vector(apr-1 downto 0);
						sw_data_read      : out std_logic_vector(1 downto 0)
						
			);
end asj_fft_dataadgen;

architecture gen_all of asj_fft_dataadgen is
signal do_count : std_logic_vector(apr downto 0);
-- Delay Counter for 2 Engine 128 points
signal lp_cnt_en : std_logic;
signal sw : std_logic_vector(1 downto 0);

begin


-----------------------------------------------------------------------------------------------
-- Quad Output Engine Architecture Address Generation
-----------------------------------------------------------------------------------------------
gen_quad_output : if(arch<3) generate

sw_data_read <= sw;
-----------------------------------------------------------------------------------------
--
-- Single Engine
--
-----------------------------------------------------------------------------------------
gen_se_addr : if(nume=1) generate

-----------------------------------------------------------------------------------------------
gen_32_addr : if(nps=32) generate
--
get_32_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(1 downto 0) is
				when "01" =>
				 	sw <= k_count(1 downto 0) + (k_count(2) & '0');
				when "10" =>
				 	sw <= k_count(1 downto 0);
				when others =>
				 	sw <=(others=>'0');
			end case;
		end if;
	end process get_32_sw;
	
get_32_addr:process(clk,global_clock_enable,p_count,k_count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(1 downto 0) is
						when "01" =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
						when "10" =>
						-- offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
							rd_addr_a <=  (k_count(2) & "00");
							rd_addr_b <=  (k_count(2) & "00") + int2ustd(1,apr);
							rd_addr_c <=  (k_count(2) & "00") + int2ustd(2,apr);
							rd_addr_d <=  (k_count(2) & "00") + int2ustd(3,apr);
				 		when others =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
					end case;
		end if;
	end process get_32_addr;
	
end generate gen_32_addr;
-----------------------------------------------------------------------------------------------


gen_64_addr : if(nps=64) generate

get_64_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(1 downto 0) is
				when "01" =>
				 --sw = floor(k/n_by_16)
				 	sw <= k_count(3 downto 2);
				when "10" =>
				 	sw <= k_count(1 downto 0);
				when others =>
				 	 	sw <=(others=>'0');
			end case;
		end if;
	end process get_64_sw;
	
get_64_addr:process(clk,global_clock_enable,p_count,k_count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(1 downto 0) is
						when "01" =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
						when "10" =>
						--          offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
							rd_addr_a <= k_count(3 downto 2) & "00";
							rd_addr_b <= (k_count(3 downto 2) & "00") + int2ustd(1,apr);
							rd_addr_c <= (k_count(3 downto 2) & "00") + int2ustd(2,apr);
							rd_addr_d <= (k_count(3 downto 2) & "00") + int2ustd(3,apr);
				 		when others =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
					end case;
		end if;
		end process get_64_addr;
		
end generate gen_64_addr;

-----------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------

gen_128_addr : if(nps=128) generate
--
get_128_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(1 downto 0) is
				when "01" =>
				 --sw = mod(floor(k/n_by_32) + 2*floor(k/n_by_8) , 4);
				 	sw <= k_count(3 downto 2) + (k_count(4) & '0');
				when "10" =>
				--sw = mod(k,4);
				 	sw <= k_count(1 downto 0);
				when "11" => 	
				--sw = mod(mod(k,4)+floor(k/4),4);
				 	sw <= k_count(1 downto 0)+k_count(3 downto 2);
				when others =>
				 	sw <=(others=>'0');
			end case;
		end if;
	end process get_128_sw;
	
get_128_addr:process(clk,global_clock_enable,p_count,k_count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(1 downto 0) is
						when "01" =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
						when "10" =>
						-- offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
							rd_addr_a <=  (k_count(4 downto 2) & "00");
							rd_addr_b <=  (k_count(4 downto 2) & "00") + int2ustd(1,apr);
							rd_addr_c <=  (k_count(4 downto 2) & "00") + int2ustd(2,apr);
							rd_addr_d <=  (k_count(4 downto 2) & "00") + int2ustd(3,apr);
						when "11" =>
						-- offset = mod((0:3)*4+ floor(mod(k,16)/4)+16*floor(k/16),n_by_4)+1;
							rd_addr_a <= ("000" & k_count(3 downto 2)) + (k_count(4) & "0000");
							rd_addr_b <= ("000" & k_count(3 downto 2)) + (k_count(4) & "0000")+ int2ustd(4,apr);
							rd_addr_c <= ("000" & k_count(3 downto 2)) + (k_count(4) & "0000")+ int2ustd(8,apr);
							rd_addr_d <= ("000" & k_count(3 downto 2)) + (k_count(4) & "0000")+ int2ustd(12,apr);
				 		when others =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
					end case;
		end if;
	end process get_128_addr;

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
				 --sw = floor(k/n_by_16)
				 	sw <= k_count(5 downto 4);
				when "10" =>
				--sw = mod(k,4);
				 	sw <= k_count(1 downto 0);
				when "11" => 	
				--sw = mod(mod(k,4)+floor(k/4),4);
				 	sw <= k_count(1 downto 0)+k_count(3 downto 2);
				when others =>
				 	sw <=(others=>'0');
			end case;
		end if;
	end process get_256_sw;
	
get_256_addr:process(clk,global_clock_enable,p_count,k_count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(1 downto 0) is
						when "01" =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
						when "10" =>
						-- offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
							rd_addr_a <=  (k_count(5 downto 2) & "00");
							rd_addr_b <=  (k_count(5 downto 2) & "00") + int2ustd(1,apr);
							rd_addr_c <=  (k_count(5 downto 2) & "00") + int2ustd(2,apr);
							rd_addr_d <=  (k_count(5 downto 2) & "00") + int2ustd(3,apr);
						when "11" =>
						-- offset = mod((0:3)*4+ floor(mod(k,16)/4)+16*floor(k/16),n_by_4)+1;
							rd_addr_a <= ("0000" & k_count(3 downto 2)) + (k_count(5 downto 4) & "0000");
							rd_addr_b <= ("0000" & k_count(3 downto 2)) + (k_count(5 downto 4) & "0000")+ int2ustd(4,apr);
							rd_addr_c <= ("0000" & k_count(3 downto 2)) + (k_count(5 downto 4) & "0000")+ int2ustd(8,apr);
							rd_addr_d <= ("0000" & k_count(3 downto 2)) + (k_count(5 downto 4) & "0000")+ int2ustd(12,apr);
				 		when others =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
					end case;
		end if;
	end process get_256_addr;

end generate gen_256_addr;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

gen_512_addr : if(nps=512) generate
--addr output is 9 bits
-- k count  is 7 bits
get_512_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(2 downto 0) is
				when "001" =>
				 --sw = mod(floor(k/n_by_32) + 2*floor(k/n_by_8) , 4);
				 	sw <= k_count(5 downto 4) + (k_count(6) & '0');
				when "010" =>
				 --sw = mod(k,4);
				 	sw <= k_count(1 downto 0);
				when "011" => 	
				--sw = mod(mod(k,4)+floor(k/4),4);
				 	sw <= k_count(1 downto 0)+k_count(3 downto 2);
				when "100" => 	
					-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16),4);
				 	sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) ;
				when others =>
				 	sw <=(others=>'0');
			end case;
		end if;
	end process get_512_sw;
	
get_512_addr:process(clk,global_clock_enable,p_count,k_count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
						when "010" =>
						-- offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
							rd_addr_a <=  k_count(6 downto 2) & "00";
							rd_addr_b <= (k_count(6 downto 2) & "00") + int2ustd(1,apr);
							rd_addr_c <= (k_count(6 downto 2) & "00") + int2ustd(2,apr);
							rd_addr_d <= (k_count(6 downto 2) & "00") + int2ustd(3,apr);
						when "011" =>
						-- offset = mod((0:3)*4+ floor(mod(k,16)/4)+16*floor(k/16),n_by_4)+1;
							rd_addr_a <= ("00000" & k_count(3 downto 2)) + (k_count(6 downto 4) & "0000");
							rd_addr_b <= ("00000" & k_count(3 downto 2)) + (k_count(6 downto 4) & "0000")+ int2ustd(4,apr);
							rd_addr_c <= ("00000" & k_count(3 downto 2)) + (k_count(6 downto 4) & "0000")+ int2ustd(8,apr);
							rd_addr_d <= ("00000" & k_count(3 downto 2)) + (k_count(6 downto 4) & "0000")+ int2ustd(12,apr);
						when "100" =>	
						  --offset = mod((0:3)*16+ floor(mod(k,16)/4)+mod(4*floor(k/16),16) + 64*floor(k/64),n_by_4)+1;
				 			rd_addr_a <= ("00000" & k_count(3 downto 2)) + ("000" & k_count(5 downto 4) & "00") + (k_count(6) & "000000");
							rd_addr_b <= ("00000" & k_count(3 downto 2)) + ("000" & k_count(5 downto 4) & "00") + (k_count(6) & "000000") + int2ustd(16,apr);
							rd_addr_c <= ("00000" & k_count(3 downto 2)) + ("000" & k_count(5 downto 4) & "00") + (k_count(6) & "000000") + int2ustd(32,apr);
							rd_addr_d <= ("00000" & k_count(3 downto 2)) + ("000" & k_count(5 downto 4) & "00") + (k_count(6) & "000000") + int2ustd(48,apr);
						when others =>	
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
					end case;
		end if;
	end process get_512_addr;

		
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
				 --sw = floor(k/n_by_16)
				 	sw <= k_count(7 downto 6);
				when "010" =>
				 --sw = mod(k,4);
				 	sw <= k_count(1 downto 0);
				when "011" => 	
				--sw = mod(mod(k,4)+floor(k/4),4);
				 	sw <= k_count(1 downto 0)+k_count(3 downto 2);
				when "100" => 	
					-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16),4);
				 	sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) ;
				when others =>
				 	sw <=(others=>'0');
			end case;
		end if;
	end process get_1024_sw;
	
get_1024_addr:process(clk,global_clock_enable,p_count,k_count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
						when "010" =>
						-- offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
							rd_addr_a <=  k_count(7 downto 2) & "00";
							rd_addr_b <= (k_count(7 downto 2) & "00") + int2ustd(1,apr);
							rd_addr_c <= (k_count(7 downto 2) & "00") + int2ustd(2,apr);
							rd_addr_d <= (k_count(7 downto 2) & "00") + int2ustd(3,apr);
						when "011" =>
						-- offset = mod((0:3)*4+ floor(mod(k,16)/4)+16*floor(k/16),n_by_4)+1;
							rd_addr_a <= ("000000" & k_count(3 downto 2)) + (k_count(7 downto 4) & "0000");
							rd_addr_b <= ("000000" & k_count(3 downto 2)) + (k_count(7 downto 4) & "0000")+ int2ustd(4,apr);
							rd_addr_c <= ("000000" & k_count(3 downto 2)) + (k_count(7 downto 4) & "0000")+ int2ustd(8,apr);
							rd_addr_d <= ("000000" & k_count(3 downto 2)) + (k_count(7 downto 4) & "0000")+ int2ustd(12,apr);
						when "100" =>	
						  --offset = mod((0:3)*16+ floor(mod(k,16)/4)+mod(4*floor(k/16),16) + 64*floor(k/64),n_by_4)+1;
				 			rd_addr_a <= ("000000" & k_count(3 downto 2)) + ("0000" & k_count(5 downto 4) & "00") + (k_count(7 downto 6) & "000000");
							rd_addr_b <= ("000000" & k_count(3 downto 2)) + ("0000" & k_count(5 downto 4) & "00") + (k_count(7 downto 6) & "000000") + int2ustd(16,apr);
							rd_addr_c <= ("000000" & k_count(3 downto 2)) + ("0000" & k_count(5 downto 4) & "00") + (k_count(7 downto 6) & "000000") + int2ustd(32,apr);
							rd_addr_d <= ("000000" & k_count(3 downto 2)) + ("0000" & k_count(5 downto 4) & "00") + (k_count(7 downto 6) & "000000") + int2ustd(48,apr);
						when others =>	
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
					end case;
		end if;
	end process get_1024_addr;

		
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
						 --sw = mod(floor(k/n_by_32) + 2*floor(k/n_by_8) , 4);
						 	sw <= (k_count(8) & '0') + k_count(7 downto 6);
						when "010" =>
						 --sw = mod(k,4);
						 	sw <= k_count(1 downto 0);
						when "011" => 	
						--sw = mod(mod(k,4)+floor(k/4),4);
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2);
						when "100" => 	
							-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16),4);
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) ;
						when "101" => 	 	
							-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16)+floor(k/64),4);
							sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						when others =>
						 	sw <=(others=>'0');
					end case;
				end if;
			end process get_2048_sw;
			
get_2048_addr:process(clk,global_clock_enable,p_count,k_count)
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
							case p_count(2 downto 0) is
								when "001" =>
									rd_addr_a <= k_count;
									rd_addr_b <= k_count;
									rd_addr_c <= k_count;
									rd_addr_d <= k_count;
								when "010" =>
								-- offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
									rd_addr_a <=  k_count(8 downto 2) & "00";
									rd_addr_b <= (k_count(8 downto 2) & "00") + int2ustd(1,apr);
									rd_addr_c <= (k_count(8 downto 2) & "00") + int2ustd(2,apr);
									rd_addr_d <= (k_count(8 downto 2) & "00") + int2ustd(3,apr);
								when "011" =>
								-- offset = mod((0:3)*4+ floor(mod(k,16)/4)+16*floor(k/16),n_by_4)+1;
									rd_addr_a <= ("0000000" & k_count(3 downto 2)) + (k_count(8 downto 4) & "0000");
									rd_addr_b <= ("0000000" & k_count(3 downto 2)) + (k_count(8 downto 4) & "0000")+ int2ustd(4,apr);
									rd_addr_c <= ("0000000" & k_count(3 downto 2)) + (k_count(8 downto 4) & "0000")+ int2ustd(8,apr);
									rd_addr_d <= ("0000000" & k_count(3 downto 2)) + (k_count(8 downto 4) & "0000")+ int2ustd(12,apr);
								when "100" =>	
								  --offset = mod((0:3)*16+ floor(mod(k,16)/4)+mod(4*floor(k/16),16) + 64*floor(k/64),n_by_4)+1;
						 			rd_addr_a <= ("0000000" & k_count(3 downto 2)) + ("00000" & k_count(5 downto 4) & "00") + (k_count(8 downto 6) & "000000");
									rd_addr_b <= ("0000000" & k_count(3 downto 2)) + ("00000" & k_count(5 downto 4) & "00") + (k_count(8 downto 6) & "000000") + int2ustd(16,apr);
									rd_addr_c <= ("0000000" & k_count(3 downto 2)) + ("00000" & k_count(5 downto 4) & "00") + (k_count(8 downto 6) & "000000") + int2ustd(32,apr);
									rd_addr_d <= ("0000000" & k_count(3 downto 2)) + ("00000" & k_count(5 downto 4) & "00") + (k_count(8 downto 6) & "000000") + int2ustd(48,apr);
								when "101" =>	
									--offset = mod((0:3)*64+ floor(mod(k,16)/4)+mod(4*floor(k/16),16) + mod(16*floor(k/64),64)+256*floor(k/256),n_by_4)+1;
								  rd_addr_a <= ("0000000" & k_count(3 downto 2)) + ("00000" & k_count(5 downto 4) & "00") + ("000" & k_count(7 downto 6) & "0000") + (k_count(8) & "00000000");
									rd_addr_b <= ("0000000" & k_count(3 downto 2)) + ("00000" & k_count(5 downto 4) & "00") + ("000" & k_count(7 downto 6) & "0000") + (k_count(8) & "00000000") + int2ustd(64,apr);
									rd_addr_c <= ("0000000" & k_count(3 downto 2)) + ("00000" & k_count(5 downto 4) & "00") + ("000" & k_count(7 downto 6) & "0000") + (k_count(8) & "00000000") + int2ustd(128,apr);
									rd_addr_d <= ("0000000" & k_count(3 downto 2)) + ("00000" & k_count(5 downto 4) & "00") + ("000" & k_count(7 downto 6) & "0000") + (k_count(8) & "00000000") + int2ustd(192,apr);
								when others =>	
									rd_addr_a <= k_count;
									rd_addr_b <= k_count;
									rd_addr_c <= k_count;
									rd_addr_d <= k_count;
							end case;
				end if;
			end process get_2048_addr;
		
		end generate gen_2048_addr;

-----------------------------------------------------------------------------------------
--N=4096
-----------------------------------------------------------------------------------------
	gen_4096_addr : if(nps=4096) generate
get_4096_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
						 --sw = floor(k/n_by_16)
						 	sw <= k_count(9 downto 8);
						when "010" =>
						 --sw = mod(k,4);
						 	sw <= k_count(1 downto 0);
						when "011" => 	
						--sw = mod(mod(k,4)+floor(k/4),4);
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2);
						when "100" => 	
							-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16),4);
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) ;
						when "101" => 	 	
							-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16)+floor(k/64),4);
							sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						when others =>
						 	sw <=(others=>'0');
					end case;
				end if;
			end process get_4096_sw;
			
get_4096_addr:process(clk,global_clock_enable,p_count,k_count)
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
							case p_count(2 downto 0) is
								when "001" =>
									rd_addr_a <= k_count;
									rd_addr_b <= k_count;
									rd_addr_c <= k_count;
									rd_addr_d <= k_count;
								when "010" =>
								-- offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
									rd_addr_a <=  k_count(9 downto 2) & "00";
									rd_addr_b <= (k_count(9 downto 2) & "00") + int2ustd(1,apr);
									rd_addr_c <= (k_count(9 downto 2) & "00") + int2ustd(2,apr);
									rd_addr_d <= (k_count(9 downto 2) & "00") + int2ustd(3,apr);
								when "011" =>
								-- offset = mod((0:3)*4+ floor(mod(k,16)/4)+16*floor(k/16),n_by_4)+1;
									rd_addr_a <= ("00000000" & k_count(3 downto 2)) + (k_count(9 downto 4) & "0000");
									rd_addr_b <= ("00000000" & k_count(3 downto 2)) + (k_count(9 downto 4) & "0000")+ int2ustd(4,apr);
									rd_addr_c <= ("00000000" & k_count(3 downto 2)) + (k_count(9 downto 4) & "0000")+ int2ustd(8,apr);
									rd_addr_d <= ("00000000" & k_count(3 downto 2)) + (k_count(9 downto 4) & "0000")+ int2ustd(12,apr);
								when "100" =>	
								  --offset = mod((0:3)*16+ floor(mod(k,16)/4)+mod(4*floor(k/16),16) + 64*floor(k/64),n_by_4)+1;
						 			rd_addr_a <= ("00000000" & k_count(3 downto 2)) + ("000000" & k_count(5 downto 4) & "00") + (k_count(9 downto 6) & "000000");
									rd_addr_b <= ("00000000" & k_count(3 downto 2)) + ("000000" & k_count(5 downto 4) & "00") + (k_count(9 downto 6) & "000000") + int2ustd(16,apr);
									rd_addr_c <= ("00000000" & k_count(3 downto 2)) + ("000000" & k_count(5 downto 4) & "00") + (k_count(9 downto 6) & "000000") + int2ustd(32,apr);
									rd_addr_d <= ("00000000" & k_count(3 downto 2)) + ("000000" & k_count(5 downto 4) & "00") + (k_count(9 downto 6) & "000000") + int2ustd(48,apr);
								when "101" =>	
									--offset = mod((0:3)*64+ floor(mod(k,16)/4)+mod(4*floor(k/16),16) + mod(16*floor(k/64),64)+256*floor(k/256),n_by_4)+1;
								  rd_addr_a <= ("00000000" & k_count(3 downto 2)) + ("000000" & k_count(5 downto 4) & "00") + ("0000" & k_count(7 downto 6) & "0000") + (k_count(9 downto 8) & "00000000");
									rd_addr_b <= ("00000000" & k_count(3 downto 2)) + ("000000" & k_count(5 downto 4) & "00") + ("0000" & k_count(7 downto 6) & "0000") + (k_count(9 downto 8) & "00000000") + int2ustd(64,apr);
									rd_addr_c <= ("00000000" & k_count(3 downto 2)) + ("000000" & k_count(5 downto 4) & "00") + ("0000" & k_count(7 downto 6) & "0000") + (k_count(9 downto 8) & "00000000") + int2ustd(128,apr);
									rd_addr_d <= ("00000000" & k_count(3 downto 2)) + ("000000" & k_count(5 downto 4) & "00") + ("0000" & k_count(7 downto 6) & "0000") + (k_count(9 downto 8) & "00000000") + int2ustd(192,apr);
								when others =>	
									rd_addr_a <= k_count;
									rd_addr_b <= k_count;
									rd_addr_c <= k_count;
									rd_addr_d <= k_count;
							end case;
				end if;
			end process get_4096_addr;
		
		end generate gen_4096_addr;
		
-----------------------------------------------------------------------------------------------
-- N=8192
-----------------------------------------------------------------------------------------------
	gen_8192_addr : if(nps=8192) generate
get_8192_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
						 --sw = mod(floor(k/n_by_32) + 2*floor(k/n_by_8) , 4);
						 	sw <= (k_count(10) & '0') + k_count(9 downto 8);
						when "010" =>
						 --sw = mod(k,4);
						 	sw <= k_count(1 downto 0);
						when "011" => 	
						--sw = mod(mod(k,4)+floor(k/4),4);
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2);
						when "100" => 	
							-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16),4);
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) ;
						when "101" => 	 	
							-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16)+floor(k/64),4);
							sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						when "110" => 	 	
							-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
							sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8);
						when others =>
						 	sw <=(others=>'0');
					end case;
				end if;
			end process get_8192_sw;
			
get_8192_addr:process(clk,global_clock_enable,p_count,k_count)
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
							case p_count(2 downto 0) is
								when "001" =>
									rd_addr_a <= k_count;
									rd_addr_b <= k_count;
									rd_addr_c <= k_count;
									rd_addr_d <= k_count;
								when "010" =>
								-- offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
									rd_addr_a <=  k_count(10 downto 2) & "00";
									rd_addr_b <= (k_count(10 downto 2) & "00") + int2ustd(1,apr);
									rd_addr_c <= (k_count(10 downto 2) & "00") + int2ustd(2,apr);
									rd_addr_d <= (k_count(10 downto 2) & "00") + int2ustd(3,apr);
								when "011" =>
								-- offset = mod((0:3)*4+ floor(mod(k,16)/4)+16*floor(k/16),n_by_4)+1;
									rd_addr_a <= ("000000000" & k_count(3 downto 2)) + (k_count(10 downto 4) & "0000");
									rd_addr_b <= ("000000000" & k_count(3 downto 2)) + (k_count(10 downto 4) & "0000")+ int2ustd(4,apr);
									rd_addr_c <= ("000000000" & k_count(3 downto 2)) + (k_count(10 downto 4) & "0000")+ int2ustd(8,apr);
									rd_addr_d <= ("000000000" & k_count(3 downto 2)) + (k_count(10 downto 4) & "0000")+ int2ustd(12,apr);
								when "100" =>	
								  --offset = mod((0:3)*16+ floor(mod(k,16)/4)+mod(4*floor(k/16),16) + 64*floor(k/64),n_by_4)+1;
						 			rd_addr_a <= ("000000000" & k_count(3 downto 2)) + ("0000000" & k_count(5 downto 4) & "00") + (k_count(10 downto 6) & "000000");
									rd_addr_b <= ("000000000" & k_count(3 downto 2)) + ("0000000" & k_count(5 downto 4) & "00") + (k_count(10 downto 6) & "000000") + int2ustd(16,apr);
									rd_addr_c <= ("000000000" & k_count(3 downto 2)) + ("0000000" & k_count(5 downto 4) & "00") + (k_count(10 downto 6) & "000000") + int2ustd(32,apr);
									rd_addr_d <= ("000000000" & k_count(3 downto 2)) + ("0000000" & k_count(5 downto 4) & "00") + (k_count(10 downto 6) & "000000") + int2ustd(48,apr);
								when "101" =>	
									--offset = mod((0:3)*64+ floor(mod(k,16)/4)+mod(4*floor(k/16),16) + mod(16*floor(k/64),64)+256*floor(k/256),n_by_4)+1;
								  rd_addr_a <= ("000000000" & k_count(3 downto 2)) + ("0000000" & k_count(5 downto 4) & "00") + ("00000" & k_count(7 downto 6) & "0000") + (k_count(10 downto 8) & "00000000");
									rd_addr_b <= ("000000000" & k_count(3 downto 2)) + ("0000000" & k_count(5 downto 4) & "00") + ("00000" & k_count(7 downto 6) & "0000") + (k_count(10 downto 8) & "00000000") + int2ustd(64,apr);
									rd_addr_c <= ("000000000" & k_count(3 downto 2)) + ("0000000" & k_count(5 downto 4) & "00") + ("00000" & k_count(7 downto 6) & "0000") + (k_count(10 downto 8) & "00000000") + int2ustd(128,apr);
									rd_addr_d <= ("000000000" & k_count(3 downto 2)) + ("0000000" & k_count(5 downto 4) & "00") + ("00000" & k_count(7 downto 6) & "0000") + (k_count(10 downto 8) & "00000000") + int2ustd(192,apr);
								when "110" =>	
									--offset = mod((0:3)*256+ floor(mod(k,16)/4)+mod(4*floor(k/16),16) + mod(16*floor(k/64),64)+mod(64*floor(k/256),256)+1024*floor(k/1024),n_by_4)+1;
								  rd_addr_a <= ("000000000" & k_count(3 downto 2)) + ("00000" & k_count(5 downto 4) & "00") + ("00000" & k_count(7 downto 6) & "0000") + ("000" & k_count(9 downto 8) & "000000") + (k_count(10) & "0000000000");
									rd_addr_b <= ("000000000" & k_count(3 downto 2)) + ("00000" & k_count(5 downto 4) & "00") + ("00000" & k_count(7 downto 6) & "0000") + ("000" & k_count(9 downto 8) & "000000") + (k_count(10) & "0000000000") + int2ustd(256,apr);
									rd_addr_c <= ("000000000" & k_count(3 downto 2)) + ("00000" & k_count(5 downto 4) & "00") + ("00000" & k_count(7 downto 6) & "0000") + ("000" & k_count(9 downto 8) & "000000") + (k_count(10) & "0000000000") + int2ustd(512,apr);
									rd_addr_d <= ("000000000" & k_count(3 downto 2)) + ("00000" & k_count(5 downto 4) & "00") + ("00000" & k_count(7 downto 6) & "0000") + ("000" & k_count(9 downto 8) & "000000") + (k_count(10) & "0000000000") + int2ustd(768,apr);
								when others =>	
									rd_addr_a <= k_count;
									rd_addr_b <= k_count;
									rd_addr_c <= k_count;
									rd_addr_d <= k_count;
							end case;
				end if;
			end process get_8192_addr;
		
		end generate gen_8192_addr;
-----------------------------------------------------------------------------------------------
-- N=16384
-----------------------------------------------------------------------------------------------
	gen_16384_addr : if(nps=16384) generate
get_16384_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
						 --sw = floor(k/n_by_16)
						 --	sw <= k_count(8 downto 7);
						 sw <= k_count(11 downto 10);
						when "010" =>
						 --sw = mod(k,4);
						 	sw <= k_count(1 downto 0);
						when "011" => 	
						--sw = mod(mod(k,4)+floor(k/4),4);
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2);
						when "100" => 	
							-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16),4);
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) ;
						when "101" => 	 	
							-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16)+floor(k/64),4);
							sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						when "110" => 	 	
							--sw = mod(mod(k,4)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
							sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8);
						when others =>
						 	sw <=(others=>'0');
					end case;
				end if;
			end process get_16384_sw;
			
get_16384_addr:process(clk,global_clock_enable,p_count,k_count)
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
							case p_count(2 downto 0) is
								when "001" =>
									rd_addr_a <= k_count;
									rd_addr_b <= k_count;
									rd_addr_c <= k_count;
									rd_addr_d <= k_count;
								when "010" =>
								-- offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
									rd_addr_a <=  k_count(11 downto 2) & "00";
									rd_addr_b <= (k_count(11 downto 2) & "00") + int2ustd(1,apr);
									rd_addr_c <= (k_count(11 downto 2) & "00") + int2ustd(2,apr);
									rd_addr_d <= (k_count(11 downto 2) & "00") + int2ustd(3,apr);
								when "011" =>
								-- offset = mod((0:3)*4+ floor(mod(k,16)/4)+16*floor(k/16),n_by_4)+1;
									rd_addr_a <= ("0000000000" & k_count(3 downto 2)) + (k_count(11 downto 4) & "0000");
									rd_addr_b <= ("0000000000" & k_count(3 downto 2)) + (k_count(11 downto 4) & "0000")+ int2ustd(4,apr);
									rd_addr_c <= ("0000000000" & k_count(3 downto 2)) + (k_count(11 downto 4) & "0000")+ int2ustd(8,apr);
									rd_addr_d <= ("0000000000" & k_count(3 downto 2)) + (k_count(11 downto 4) & "0000")+ int2ustd(12,apr);
								when "100" =>	
								  --offset = mod((0:3)*16+ floor(mod(k,16)/4)+mod(4*floor(k/16),16) + 64*floor(k/64),n_by_4)+1;
						 			rd_addr_a <= ("0000000000" & k_count(3 downto 2)) + ("00000000" & k_count(5 downto 4) & "00") + (k_count(11 downto 6) & "000000");
									rd_addr_b <= ("0000000000" & k_count(3 downto 2)) + ("00000000" & k_count(5 downto 4) & "00") + (k_count(11 downto 6) & "000000") + int2ustd(16,apr);
									rd_addr_c <= ("0000000000" & k_count(3 downto 2)) + ("00000000" & k_count(5 downto 4) & "00") + (k_count(11 downto 6) & "000000") + int2ustd(32,apr);
									rd_addr_d <= ("0000000000" & k_count(3 downto 2)) + ("00000000" & k_count(5 downto 4) & "00") + (k_count(11 downto 6) & "000000") + int2ustd(48,apr);
								when "101" =>	
									--offset = mod((0:3)*64+ floor(mod(k,16)/4)+mod(4*floor(k/16),16) + mod(16*floor(k/64),64)+256*floor(k/256),n_by_4)+1;
								  rd_addr_a <= ("0000000000" & k_count(3 downto 2)) + ("00000000" & k_count(5 downto 4) & "00") + ("000000" & k_count(7 downto 6) & "0000") + ( k_count(11 downto 8) & "00000000");
									rd_addr_b <= ("0000000000" & k_count(3 downto 2)) + ("00000000" & k_count(5 downto 4) & "00") + ("000000" & k_count(7 downto 6) & "0000") + ( k_count(11 downto 8) & "00000000") + int2ustd(64,apr);
									rd_addr_c <= ("0000000000" & k_count(3 downto 2)) + ("00000000" & k_count(5 downto 4) & "00") + ("000000" & k_count(7 downto 6) & "0000") + ( k_count(11 downto 8) & "00000000") + int2ustd(128,apr);
									rd_addr_d <= ("0000000000" & k_count(3 downto 2)) + ("00000000" & k_count(5 downto 4) & "00") + ("000000" & k_count(7 downto 6) & "0000") + ( k_count(11 downto 8) & "00000000") + int2ustd(192,apr);
								when "110" =>	
									--offset = mod((0:3)*256+ floor(mod(k,16)/4)      +mod(4*floor(k/16),16)                    + mod(16*floor(k/64),64)                   +mod(64*floor(k/256),256)+1024*floor(k/1024),n_by_4)+1;
                  rd_addr_a <= ("0000000000" & k_count(3 downto 2)) + ("00000000" & k_count(5 downto 4) & "00") + ("000000" & k_count(7 downto 6) & "0000") + ("0000" & k_count(9 downto 8) & "000000") + (k_count(11 downto 10) & "0000000000");
									rd_addr_b <= ("0000000000" & k_count(3 downto 2)) + ("00000000" & k_count(5 downto 4) & "00") + ("000000" & k_count(7 downto 6) & "0000") + ("0000" & k_count(9 downto 8) & "000000") + (k_count(11 downto 10) & "0000000000")+ int2ustd(256,apr);
									rd_addr_c <= ("0000000000" & k_count(3 downto 2)) + ("00000000" & k_count(5 downto 4) & "00") + ("000000" & k_count(7 downto 6) & "0000") + ("0000" & k_count(9 downto 8) & "000000") + (k_count(11 downto 10) & "0000000000")+ int2ustd(512,apr);
									rd_addr_d <= ("0000000000" & k_count(3 downto 2)) + ("00000000" & k_count(5 downto 4) & "00") + ("000000" & k_count(7 downto 6) & "0000") + ("0000" & k_count(9 downto 8) & "000000") + (k_count(11 downto 10) & "0000000000")+ int2ustd(768,apr);									
								when others =>	                                                                                                                                                                                      
									rd_addr_a <= k_count;                                                                                                                                                                                
									rd_addr_b <= k_count;                                                                                                                                                                                 
									rd_addr_c <= k_count;                                                                                                                                                                                  
									rd_addr_d <= k_count;
							end case;
				end if;
			end process get_16384_addr;
		
		end generate gen_16384_addr;

-----------------------------------------------------------------------------------------------
-- N=32768
-----------------------------------------------------------------------------------------------
gen_32768_addr : if(nps=32768) generate

    get_32768_sw:process(clk,global_clock_enable,p_count,k_count)is
    begin
        if((rising_edge(clk) and global_clock_enable='1'))then
            case p_count(2 downto 0) is
                when "001" =>   sw <= (k_count(12) & '0') + k_count(11 downto 10);
                when "010" =>   sw <= k_count(1 downto 0);
                when "011" =>   sw <= k_count(1 downto 0) + k_count(3 downto 2);
                when "100" =>   sw <= k_count(1 downto 0) + k_count(3 downto 2) +k_count(5 downto 4) ;
                when "101" =>   sw <= k_count(1 downto 0) + k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6); 
                when "110" => 	sw <= k_count(1 downto 0) + k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8); 
                when "111" => 	sw <= k_count(1 downto 0) + k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10); 
                when others =>  sw <=(others=>'0');
            end case;
        end if;
	end process get_32768_sw;

    get_32768_addr:process(clk,global_clock_enable,p_count,k_count)
	begin
        if((rising_edge(clk) and global_clock_enable='1'))then
		    case p_count(2 downto 0) is
                when "001" =>   
                    rd_addr_a <= k_count;
                    rd_addr_b <= k_count;
                    rd_addr_c <= k_count;
                    rd_addr_d <= k_count;
				when "010" =>   
                    rd_addr_a <=  k_count(12 downto 2) & "00";
					rd_addr_b <= (k_count(12 downto 2) & "00") + int2ustd(1,apr);
                    rd_addr_c <= (k_count(12 downto 2) & "00") + int2ustd(2,apr);
                    rd_addr_d <= (k_count(12 downto 2) & "00") + int2ustd(3,apr);
                when "011" =>
                    rd_addr_a <= k_count(12 downto 4) & "00" & k_count(3 downto 2);
                    rd_addr_b <= (k_count(12 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(4,apr);
                    rd_addr_c <= (k_count(12 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(8,apr);
                    rd_addr_d <= (k_count(12 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(12,apr);
				when "100" =>
                    rd_addr_a <= k_count(12 downto 6) & "00" & k_count(5 downto 2);
                    rd_addr_b <= (k_count(12 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(16,apr);
                    rd_addr_c <= (k_count(12 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(32,apr);
                    rd_addr_d <= (k_count(12 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(48,apr);
                when "101" =>
                    rd_addr_a <= k_count(12 downto 8) & "00" & k_count(7 downto 2);
                    rd_addr_b <= (k_count(12 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(64,apr);
                    rd_addr_c <= (k_count(12 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(128,apr);
                    rd_addr_d <= (k_count(12 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(192,apr);
				when "110" =>
                    rd_addr_a <= k_count(12 downto 10) & "00" & k_count(9 downto 2);
                    rd_addr_b <= (k_count(12 downto 10) & "00" & k_count(9 downto 2)) + int2ustd(256,apr);
                    rd_addr_c <= (k_count(12 downto 10) & "00" & k_count(9 downto 2)) + int2ustd(512,apr);
                    rd_addr_d <= (k_count(12 downto 10) & "00" & k_count(9 downto 2)) + int2ustd(768,apr);
				when "111" =>
                    rd_addr_a <= k_count(12) & "00" & k_count(11 downto 2);
                    rd_addr_b <= (k_count(12) & "00" & k_count(11 downto 2)) + int2ustd(1024,apr);
                    rd_addr_c <= (k_count(12) & "00" & k_count(11 downto 2)) + int2ustd(2048,apr);
                    rd_addr_d <= (k_count(12) & "00" & k_count(11 downto 2)) + int2ustd(3072,apr);
                when others => 
                    rd_addr_a <= k_count; 
                    rd_addr_b <= k_count; 
                    rd_addr_c <= k_count;
                    rd_addr_d <= k_count;
			end case;
		end if;
	end process get_32768_addr;
		
end generate gen_32768_addr;

-----------------------------------------------------------------------------------------------
-- N=65536
-----------------------------------------------------------------------------------------------
gen_65536_addr : if(nps=65536) generate

    get_65536_sw:process(clk,global_clock_enable,p_count,k_count)is
    begin
        if((rising_edge(clk) and global_clock_enable='1'))then
            case p_count(2 downto 0) is
                when "001" =>   sw <= k_count(13 downto 12);
                when "010" =>   sw <= k_count(1 downto 0);
                when "011" =>   sw <= k_count(1 downto 0) + k_count(3 downto 2);
                when "100" =>   sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) ;
                when "101" =>   sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6); 
                when "110" => 	sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8); 
                when "111" => 	sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10); 
                when others =>  sw <=(others=>'0');
            end case;
        end if;
	end process get_65536_sw;

    get_65536_addr:process(clk,global_clock_enable,p_count,k_count)
	begin
        if((rising_edge(clk) and global_clock_enable='1'))then
		    case p_count(2 downto 0) is
                when "001" =>   
                    rd_addr_a <= k_count;
                    rd_addr_b <= k_count;
                    rd_addr_c <= k_count;
                    rd_addr_d <= k_count;
				when "010" =>   
                    rd_addr_a <=  k_count(13 downto 2) & "00";
					rd_addr_b <= (k_count(13 downto 2) & "00") + int2ustd(1,apr);
                    rd_addr_c <= (k_count(13 downto 2) & "00") + int2ustd(2,apr);
                    rd_addr_d <= (k_count(13 downto 2) & "00") + int2ustd(3,apr);
                when "011" =>
                    rd_addr_a <= k_count(13 downto 4) & "00" & k_count(3 downto 2);
                    rd_addr_b <= (k_count(13 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(4,apr);
                    rd_addr_c <= (k_count(13 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(8,apr);
                    rd_addr_d <= (k_count(13 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(12,apr);
				when "100" =>
                    rd_addr_a <= k_count(13 downto 6) & "00" & k_count(5 downto 2);
                    rd_addr_b <= (k_count(13 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(16,apr);
                    rd_addr_c <= (k_count(13 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(32,apr);
                    rd_addr_d <= (k_count(13 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(48,apr);
                when "101" =>
                    rd_addr_a <= k_count(13 downto 8) & "00" & k_count(7 downto 2);
                    rd_addr_b <= (k_count(13 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(64,apr);
                    rd_addr_c <= (k_count(13 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(128,apr);
                    rd_addr_d <= (k_count(13 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(192,apr);
				when "110" =>
                    rd_addr_a <= k_count(13 downto 10) & "00" & k_count(9 downto 2);
                    rd_addr_b <= (k_count(13 downto 10) & "00" & k_count(9 downto 2)) + int2ustd(256,apr);
                    rd_addr_c <= (k_count(13 downto 10) & "00" & k_count(9 downto 2)) + int2ustd(512,apr);
                    rd_addr_d <= (k_count(13 downto 10) & "00" & k_count(9 downto 2)) + int2ustd(768,apr);
				when "111" =>
                    rd_addr_a <= k_count(13 downto 12) & "00" & k_count(11 downto 2);
                    rd_addr_b <= (k_count(13 downto 12) & "00" & k_count(11 downto 2)) + int2ustd(1024,apr);
                    rd_addr_c <= (k_count(13 downto 12) & "00" & k_count(11 downto 2)) + int2ustd(2048,apr);
                    rd_addr_d <= (k_count(13 downto 12) & "00" & k_count(11 downto 2)) + int2ustd(3072,apr);
                when others => 
                    rd_addr_a <= k_count; 
                    rd_addr_b <= k_count; 
                    rd_addr_c <= k_count;
                    rd_addr_d <= k_count;
			end case;
		end if;
	end process get_65536_addr;
		
end generate gen_65536_addr;

-----------------------------------------------------------------------------------------------
-- N=131072
-----------------------------------------------------------------------------------------------
gen_131072_addr : if(nps=131072) generate

    get_131072_sw:process(clk,global_clock_enable,p_count,k_count)is
    begin
        if((rising_edge(clk) and global_clock_enable='1'))then
            case p_count(3 downto 0) is
                when "0001" =>  sw <= (k_count(14) & '0') + k_count(13 downto 12);
                when "0010" =>  sw <= k_count(1 downto 0);
                when "0011" =>  sw <= k_count(1 downto 0) + k_count(3 downto 2);
                when "0100" =>  sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) ;
                when "0101" =>  sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6); 
                when "0110" => 	sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8); 
                when "0111" => 	sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10);
                when "1000" => 	sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10) + k_count(13 downto 12);
                when others =>  sw <=(others=>'0');
            end case;
        end if;
	end process get_131072_sw;

    get_131072_addr:process(clk,global_clock_enable,p_count,k_count)
	begin
        if((rising_edge(clk) and global_clock_enable='1'))then
		    case p_count(3 downto 0) is
                when "0001" =>   
                    rd_addr_a <= k_count;
                    rd_addr_b <= k_count;
                    rd_addr_c <= k_count;
                    rd_addr_d <= k_count;
				when "0010" =>   
                    rd_addr_a <= k_count(14 downto 2) & "00";
					rd_addr_b <= (k_count(14 downto 2) & "00") + int2ustd(1,apr);
                    rd_addr_c <= (k_count(14 downto 2) & "00") + int2ustd(2,apr);
                    rd_addr_d <= (k_count(14 downto 2) & "00") + int2ustd(3,apr);
                when "0011" =>
                    rd_addr_a <= k_count(14 downto 4) & "00" & k_count(3 downto 2);
                    rd_addr_b <= (k_count(14 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(4,apr);
                    rd_addr_c <= (k_count(14 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(8,apr);
                    rd_addr_d <= (k_count(14 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(12,apr);
				when "0100" =>
                    rd_addr_a <= k_count(14 downto 6) & "00" & k_count(5 downto 2);
                    rd_addr_b <= (k_count(14 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(16,apr);
                    rd_addr_c <= (k_count(14 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(32,apr);
                    rd_addr_d <= (k_count(14 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(48,apr);
                when "0101" =>
                    rd_addr_a <= k_count(14 downto 8) & "00" & k_count(7 downto 2);
                    rd_addr_b <= (k_count(14 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(64,apr);
                    rd_addr_c <= (k_count(14 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(128,apr);
                    rd_addr_d <= (k_count(14 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(192,apr);
				when "0110" =>
                    rd_addr_a <= k_count(14 downto 10) & "00" & k_count(9 downto 2);
                    rd_addr_b <= (k_count(14 downto 10) & "00" & k_count(9 downto 2)) + int2ustd(256,apr);
                    rd_addr_c <= (k_count(14 downto 10) & "00" & k_count(9 downto 2)) + int2ustd(512,apr);
                    rd_addr_d <= (k_count(14 downto 10) & "00" & k_count(9 downto 2)) + int2ustd(768,apr);
				when "0111" =>
                    rd_addr_a <= k_count(14 downto 12) & "00" & k_count(11 downto 2);
                    rd_addr_b <= (k_count(14 downto 12) & "00" & k_count(11 downto 2)) + int2ustd(1024,apr);
                    rd_addr_c <= (k_count(14 downto 12) & "00" & k_count(11 downto 2)) + int2ustd(2048,apr);
                    rd_addr_d <= (k_count(14 downto 12) & "00" & k_count(11 downto 2)) + int2ustd(3072,apr);
				when "1000" =>
                    rd_addr_a <= k_count(14) & "00" & k_count(13 downto 2);
                    rd_addr_b <= (k_count(14) & "00" & k_count(13 downto 2)) + int2ustd(4096,apr);
                    rd_addr_c <= (k_count(14) & "00" & k_count(13 downto 2)) + int2ustd(8192,apr);
                    rd_addr_d <= (k_count(14) & "00" & k_count(13 downto 2)) + int2ustd(12288,apr);
                when others => 
                    rd_addr_a <= k_count; 
                    rd_addr_b <= k_count; 
                    rd_addr_c <= k_count;
                    rd_addr_d <= k_count;
			end case;
		end if;
	end process get_131072_addr;
		
end generate gen_131072_addr;

end generate gen_se_addr;

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- Dual Engine
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

gen_de_addr : if(nume=2) generate



gen_64_addr : if(nps=64) generate

get_64_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(1 downto 0) is
				when "01" =>
				 --sw = floor(k/n_by_16)
				 	sw <= '0' & k_count(2);
				when "10" =>
				 	sw <= k_count(1 downto 0);
				when others =>
				 	 	sw <=(others=>'0');
			end case;
		end if;
	end process get_64_sw;
	
get_64_addr:process(clk,global_clock_enable,p_count,k_count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(1 downto 0) is
						when "01" =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
						when "10" =>
						--          offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
							rd_addr_a <= k_count(2) & "00";
							rd_addr_b <= (k_count(2) & "00") + int2ustd(1,apr);
							rd_addr_c <= (k_count(2) & "00") + int2ustd(2,apr);
							rd_addr_d <= (k_count(2) & "00") + int2ustd(3,apr);
				 		when others =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
					end case;
		end if;
		end process get_64_addr;
		
end generate gen_64_addr;

-----------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------

gen_128_addr : if(nps=128) generate
--
get_128_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(1 downto 0) is
				when "01" =>
				 --sw = mod(floor(k/n_by_32) + 2*floor(k/n_by_8) , 4);
				 	sw <= '0' & k_count(2);
				when "10" =>
				--sw = mod(k,4);
				 	sw <= k_count(1 downto 0);
				when "11" => 	
				--sw = mod(mod(k,4)+floor(k/4),4);
				 	sw <= k_count(1 downto 0)+k_count(3 downto 2);
				when others =>
				 	sw <=(others=>'0');
			end case;
		end if;
	end process get_128_sw;
	
get_128_addr:process(clk,global_clock_enable,p_count,k_count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(1 downto 0) is
						when "01" =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
						when "10" =>
						-- offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
							rd_addr_a <=  (k_count(3 downto 2) & "00");
							rd_addr_b <=  (k_count(3 downto 2) & "00") + int2ustd(1,apr);
							rd_addr_c <=  (k_count(3 downto 2) & "00") + int2ustd(2,apr);
							rd_addr_d <=  (k_count(3 downto 2) & "00") + int2ustd(3,apr);
						when "11" =>
						-- offset = mod((0:3)*4+ floor(mod(k,16)/4)+16*floor(k/16),n_by_4)+1;
							rd_addr_a <= ("00" & k_count(3 downto 2)) ;
							rd_addr_b <= ("00" & k_count(3 downto 2)) + int2ustd(4,apr);
							rd_addr_c <= ("00" & k_count(3 downto 2)) + int2ustd(8,apr);
							rd_addr_d <= ("00" & k_count(3 downto 2)) + int2ustd(12,apr);
				 		when others =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
					end case;
		end if;
	end process get_128_addr;

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
				 --sw = floor(k/n_by_16)
				 	sw <= '0' & k_count(4);
				when "10" =>
				--sw = mod(k,4);
				 	sw <= k_count(1 downto 0);
				when "11" => 	
				--sw = mod(mod(k,4)+floor(k/4),4);
				 	sw <= k_count(1 downto 0)+k_count(3 downto 2);
				when others =>
				 	sw <=(others=>'0');
			end case;
		end if;
	end process get_256_sw;
	
get_256_addr:process(clk,global_clock_enable,p_count,k_count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(1 downto 0) is
						when "01" =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
						when "10" =>
						-- offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
							rd_addr_a <=  (k_count(4 downto 2) & "00");
							rd_addr_b <=  (k_count(4 downto 2) & "00") + int2ustd(1,apr);
							rd_addr_c <=  (k_count(4 downto 2) & "00") + int2ustd(2,apr);
							rd_addr_d <=  (k_count(4 downto 2) & "00") + int2ustd(3,apr);
						when "11" =>
						-- offset = mod((0:3)*4+ floor(mod(k,16)/4)+16*floor(k/16),n_by_4)+1;
							rd_addr_a <= ("000" & k_count(3 downto 2)) + (k_count(4) & "0000");
							rd_addr_b <= ("000" & k_count(3 downto 2)) + (k_count(4) & "0000")+ int2ustd(4,apr);
							rd_addr_c <= ("000" & k_count(3 downto 2)) + (k_count(4) & "0000")+ int2ustd(8,apr);
							rd_addr_d <= ("000" & k_count(3 downto 2)) + (k_count(4) & "0000")+ int2ustd(12,apr);
				 		when others =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
					end case;
		end if;
	end process get_256_addr;

end generate gen_256_addr;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

gen_512_addr : if(nps=512) generate
--addr output is 9 bits
-- k count  is 7 bits
get_512_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(2 downto 0) is
				when "001" =>
				 	sw <= '0' & k_count(4);
				when "010" =>
				 --sw = mod(k,4);
				 	sw <= k_count(1 downto 0);
				when "011" => 	
				--sw = mod(mod(k,4)+floor(k/4),4);
				 	sw <= k_count(1 downto 0)+k_count(3 downto 2);
				when "100" => 	
					-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16),4);
				 	sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) ;
				when others =>
				 	sw <=(others=>'0');
			end case;
		end if;
	end process get_512_sw;
	
get_512_addr:process(clk,global_clock_enable,p_count,k_count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
						when "010" =>
						-- offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
							rd_addr_a <=  k_count(5 downto 2) & "00";
							rd_addr_b <= (k_count(5 downto 2) & "00") + int2ustd(1,apr);
							rd_addr_c <= (k_count(5 downto 2) & "00") + int2ustd(2,apr);
							rd_addr_d <= (k_count(5 downto 2) & "00") + int2ustd(3,apr);
						when "011" =>
						-- offset = mod((0:3)*4+ floor(mod(k,16)/4)+16*floor(k/16),n_by_4)+1;
							rd_addr_a <= ("0000" & k_count(3 downto 2)) + (k_count(5 downto 4) & "0000");
							rd_addr_b <= ("0000" & k_count(3 downto 2)) + (k_count(5 downto 4) & "0000")+ int2ustd(4,apr);
							rd_addr_c <= ("0000" & k_count(3 downto 2)) + (k_count(5 downto 4) & "0000")+ int2ustd(8,apr);
							rd_addr_d <= ("0000" & k_count(3 downto 2)) + (k_count(5 downto 4) & "0000")+ int2ustd(12,apr);
						when "100" =>	
						  --offset = mod((0:3)*16+ floor(mod(k,16)/4)+mod(4*floor(k/16),16) + 64*floor(k/64),n_by_4)+1;
				 			rd_addr_a <= ("0000" & k_count(3 downto 2)) + ("00" & k_count(5 downto 4) & "00") ;
							rd_addr_b <= ("0000" & k_count(3 downto 2)) + ("00" & k_count(5 downto 4) & "00")  + int2ustd(16,apr);
							rd_addr_c <= ("0000" & k_count(3 downto 2)) + ("00" & k_count(5 downto 4) & "00")  + int2ustd(32,apr);
							rd_addr_d <= ("0000" & k_count(3 downto 2)) + ("00" & k_count(5 downto 4) & "00")  + int2ustd(48,apr);
						when others =>	
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
					end case;
		end if;
	end process get_512_addr;

		
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
				 --sw = floor(k/n_by_16)
				 	sw <= '0' & k_count(6);
				when "010" =>
				 --sw = mod(k,4);
				 	sw <= k_count(1 downto 0);
				when "011" => 	
				--sw = mod(mod(k,4)+floor(k/4),4);
				 	sw <= k_count(1 downto 0)+k_count(3 downto 2);
				when "100" => 	
					-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16),4);
				 	sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) ;
				when others =>
				 	sw <=(others=>'0');
			end case;
		end if;
	end process get_1024_sw;
	
get_1024_addr:process(clk,global_clock_enable,p_count,k_count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
						when "010" =>
						-- offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
							rd_addr_a <=  k_count(6 downto 2) & "00";
							rd_addr_b <= (k_count(6 downto 2) & "00") + int2ustd(1,apr);
							rd_addr_c <= (k_count(6 downto 2) & "00") + int2ustd(2,apr);
							rd_addr_d <= (k_count(6 downto 2) & "00") + int2ustd(3,apr);
						when "011" =>
						-- offset = mod((0:3)*4+ floor(mod(k,16)/4)+16*floor(k/16),n_by_4)+1;
							rd_addr_a <= ("00000" & k_count(3 downto 2)) + ( k_count(6 downto 4) & "0000");
							rd_addr_b <= ("00000" & k_count(3 downto 2)) + ( k_count(6 downto 4) & "0000")+ int2ustd(4,apr);
							rd_addr_c <= ("00000" & k_count(3 downto 2)) + ( k_count(6 downto 4) & "0000")+ int2ustd(8,apr);
							rd_addr_d <= ("00000" & k_count(3 downto 2)) + ( k_count(6 downto 4) & "0000")+ int2ustd(12,apr);
						when "100" =>	
						  --offset = mod((0:3)*16+ floor(mod(k,16)/4)+mod(4*floor(k/16),16) + 64*floor(k/64),n_by_4)+1;
				 			rd_addr_a <= ("00000" & k_count(3 downto 2)) + ("00" & k_count(5 downto 4) & "00") + (k_count(6) & "000000");
							rd_addr_b <= ("00000" & k_count(3 downto 2)) + ("00" & k_count(5 downto 4) & "00") + (k_count(6) & "000000")+ int2ustd(16,apr);
							rd_addr_c <= ("00000" & k_count(3 downto 2)) + ("00" & k_count(5 downto 4) & "00") + (k_count(6) & "000000")+ int2ustd(32,apr);
							rd_addr_d <= ("00000" & k_count(3 downto 2)) + ("00" & k_count(5 downto 4) & "00") + (k_count(6) & "000000")+ int2ustd(48,apr);
						when others =>	
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
					end case;
		end if;
	end process get_1024_addr;
end generate gen_1024_addr;

	gen_2048_addr : if(nps=2048) generate
get_2048_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
						 --sw = floor(k/n_by_32);
						 sw <= '0' & k_count(6);
						when "010" =>
						 --sw = mod(k,4);
						 	sw <= k_count(1 downto 0);
						when "011" => 	
						--sw = mod(mod(k,4)+floor(k/4),4);
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2);
						when "100" => 	
							-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16),4);
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) ;
						when "101" => 	 	
							-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16)+floor(k/64),4);
							sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						when others =>
						 	sw <=(others=>'0');
					end case;
				end if;
			end process get_2048_sw;
			
get_2048_addr:process(clk,global_clock_enable,p_count,k_count)
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
							case p_count(2 downto 0) is
								when "001" =>
									rd_addr_a <= k_count;
									rd_addr_b <= k_count;
									rd_addr_c <= k_count;
									rd_addr_d <= k_count;
								when "010" =>
								-- offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
									rd_addr_a <=  k_count(7 downto 2) & "00";
									rd_addr_b <= (k_count(7 downto 2) & "00") + int2ustd(1,apr);
									rd_addr_c <= (k_count(7 downto 2) & "00") + int2ustd(2,apr);
									rd_addr_d <= (k_count(7 downto 2) & "00") + int2ustd(3,apr);
								when "011" =>
								-- offset = mod((0:3)*4+ floor(mod(k,16)/4)+16*floor(k/16),n_by_4)+1;
									rd_addr_a <= ("000000" & k_count(3 downto 2)) + (k_count(7 downto 4) & "0000");
									rd_addr_b <= ("000000" & k_count(3 downto 2)) + (k_count(7 downto 4) & "0000")+ int2ustd(4,apr);
									rd_addr_c <= ("000000" & k_count(3 downto 2)) + (k_count(7 downto 4) & "0000")+ int2ustd(8,apr);
									rd_addr_d <= ("000000" & k_count(3 downto 2)) + (k_count(7 downto 4) & "0000")+ int2ustd(12,apr);
								when "100" =>	
								  --offset = mod((0:3)*16+ floor(mod(k,16)/4)+mod(4*floor(k/16),16) + 64*floor(k/64),n_by_4)+1;
						 			rd_addr_a <= ("000000" & k_count(3 downto 2)) + ("0000" & k_count(5 downto 4) & "00") + (k_count(7 downto 6) & "000000");
									rd_addr_b <= ("000000" & k_count(3 downto 2)) + ("0000" & k_count(5 downto 4) & "00") + (k_count(7 downto 6) & "000000") + int2ustd(16,apr);
									rd_addr_c <= ("000000" & k_count(3 downto 2)) + ("0000" & k_count(5 downto 4) & "00") + (k_count(7 downto 6) & "000000") + int2ustd(32,apr);
									rd_addr_d <= ("000000" & k_count(3 downto 2)) + ("0000" & k_count(5 downto 4) & "00") + (k_count(7 downto 6) & "000000") + int2ustd(48,apr);
								when "101" =>	
									--offset = mod((0:3)*64+ floor(mod(k,16)/4)+mod(4*floor(k/16),16) + mod(16*floor(k/64),64)+256*floor(k/256),n_by_4)+1;
								  rd_addr_a <= ("000000" & k_count(3 downto 2)) + ("0000" & k_count(5 downto 4) & "00") + ("00" & k_count(7 downto 6) & "0000") ;
									rd_addr_b <= ("000000" & k_count(3 downto 2)) + ("0000" & k_count(5 downto 4) & "00") + ("00" & k_count(7 downto 6) & "0000")  + int2ustd(64,apr);
									rd_addr_c <= ("000000" & k_count(3 downto 2)) + ("0000" & k_count(5 downto 4) & "00") + ("00" & k_count(7 downto 6) & "0000")  + int2ustd(128,apr);
									rd_addr_d <= ("000000" & k_count(3 downto 2)) + ("0000" & k_count(5 downto 4) & "00") + ("00" & k_count(7 downto 6) & "0000")  + int2ustd(192,apr);
								when others =>	
									rd_addr_a <= k_count;
									rd_addr_b <= k_count;
									rd_addr_c <= k_count;
									rd_addr_d <= k_count;
							end case;
				end if;
			end process get_2048_addr;
		
		end generate gen_2048_addr;



	gen_4096_addr : if(nps=4096) generate
get_4096_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
						 --sw = floor(k/n_by_16)
						 --	sw <= k_count(8 downto 7);
						 sw <= '0' & k_count(8);
						 	
						when "010" =>
						 --sw = mod(k,4);
						 	sw <= k_count(1 downto 0);
						when "011" => 	
						--sw = mod(mod(k,4)+floor(k/4),4);
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2);
						when "100" => 	
							-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16),4);
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) ;
						when "101" => 	 	
							-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16)+floor(k/64),4);
							sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						when others =>
						 	sw <=(others=>'0');
					end case;
				end if;
			end process get_4096_sw;
			
get_4096_addr:process(clk,global_clock_enable,p_count,k_count)
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
							case p_count(2 downto 0) is
								when "001" =>
									rd_addr_a <= k_count;
									rd_addr_b <= k_count;
									rd_addr_c <= k_count;
									rd_addr_d <= k_count;
								when "010" =>
								-- offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
									rd_addr_a <=  k_count(8 downto 2) & "00";
									rd_addr_b <= (k_count(8 downto 2) & "00") + int2ustd(1,apr);
									rd_addr_c <= (k_count(8 downto 2) & "00") + int2ustd(2,apr);
									rd_addr_d <= (k_count(8 downto 2) & "00") + int2ustd(3,apr);
								when "011" =>
								-- offset = mod((0:3)*4+ floor(mod(k,16)/4)+16*floor(k/16),n_by_4)+1;
									rd_addr_a <= ("0000000" & k_count(3 downto 2)) + (k_count(8 downto 4) & "0000");
									rd_addr_b <= ("0000000" & k_count(3 downto 2)) + (k_count(8 downto 4) & "0000")+ int2ustd(4,apr);
									rd_addr_c <= ("0000000" & k_count(3 downto 2)) + (k_count(8 downto 4) & "0000")+ int2ustd(8,apr);
									rd_addr_d <= ("0000000" & k_count(3 downto 2)) + (k_count(8 downto 4) & "0000")+ int2ustd(12,apr);
								when "100" =>	
								  --offset = mod((0:3)*16+ floor(mod(k,16)/4)+mod(4*floor(k/16),16) + 64*floor(k/64),n_by_4)+1;
						 			rd_addr_a <= ("0000000" & k_count(3 downto 2)) + ("00000" & k_count(5 downto 4) & "00") + (k_count(8 downto 6) & "000000");
									rd_addr_b <= ("0000000" & k_count(3 downto 2)) + ("00000" & k_count(5 downto 4) & "00") + (k_count(8 downto 6) & "000000") + int2ustd(16,apr);
									rd_addr_c <= ("0000000" & k_count(3 downto 2)) + ("00000" & k_count(5 downto 4) & "00") + (k_count(8 downto 6) & "000000") + int2ustd(32,apr);
									rd_addr_d <= ("0000000" & k_count(3 downto 2)) + ("00000" & k_count(5 downto 4) & "00") + (k_count(8 downto 6) & "000000") + int2ustd(48,apr);
								when "101" =>	
									--offset = mod((0:3)*64+ floor(mod(k,16)/4)+mod(4*floor(k/16),16) + mod(16*floor(k/64),64)+256*floor(k/256),n_by_4)+1;
								  rd_addr_a <= ("0000000" & k_count(3 downto 2)) + ("00000" & k_count(5 downto 4) & "00") + ("000" & k_count(7 downto 6) & "0000") + (k_count(8) & "00000000");
									rd_addr_b <= ("0000000" & k_count(3 downto 2)) + ("00000" & k_count(5 downto 4) & "00") + ("000" & k_count(7 downto 6) & "0000") + (k_count(8) & "00000000") + int2ustd(64,apr);
									rd_addr_c <= ("0000000" & k_count(3 downto 2)) + ("00000" & k_count(5 downto 4) & "00") + ("000" & k_count(7 downto 6) & "0000") + (k_count(8) & "00000000") + int2ustd(128,apr);
									rd_addr_d <= ("0000000" & k_count(3 downto 2)) + ("00000" & k_count(5 downto 4) & "00") + ("000" & k_count(7 downto 6) & "0000") + (k_count(8) & "00000000") + int2ustd(192,apr);
								when others =>	
									rd_addr_a <= k_count;
									rd_addr_b <= k_count;
									rd_addr_c <= k_count;
									rd_addr_d <= k_count;
							end case;
				end if;
			end process get_4096_addr;
		
		end generate gen_4096_addr;
		
	gen_8192_addr : if(nps=8192) generate
get_8192_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
						 --sw = floor(k/n_by_32)
						 --	sw <= k_count(8 downto 7);
						 sw <= '0' & k_count(8);
						when "010" =>
						 --sw = mod(k,4);
						 	sw <= k_count(1 downto 0);
						when "011" => 	
						--sw = mod(mod(k,4)+floor(k/4),4);
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2);
						when "100" => 	
							-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16),4);
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) ;
						when "101" => 	 	
							-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16)+floor(k/64),4);
							sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						when "110" => 	 	
							-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
							sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8);
							
						when others =>
						 	sw <=(others=>'0');
					end case;
				end if;
			end process get_8192_sw;
			
get_8192_addr:process(clk,global_clock_enable,p_count,k_count)
				begin
					-- addr is 10 bits
if((rising_edge(clk) and global_clock_enable='1'))then
							case p_count(2 downto 0) is
								when "001" =>
									rd_addr_a <= k_count;
									rd_addr_b <= k_count;
									rd_addr_c <= k_count;
									rd_addr_d <= k_count;
								when "010" =>
								-- offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
									rd_addr_a <=  k_count(9 downto 2) & "00";
									rd_addr_b <= (k_count(9 downto 2) & "00") + int2ustd(1,apr);
									rd_addr_c <= (k_count(9 downto 2) & "00") + int2ustd(2,apr);
									rd_addr_d <= (k_count(9 downto 2) & "00") + int2ustd(3,apr);
								when "011" =>
								-- offset = mod((0:3)*4+ floor(mod(k,16)/4)+16*floor(k/16),n_by_4)+1;
									rd_addr_a <= ("00000000" & k_count(3 downto 2)) + (k_count(9 downto 4) & "0000");
									rd_addr_b <= ("00000000" & k_count(3 downto 2)) + (k_count(9 downto 4) & "0000")+ int2ustd(4,apr);
									rd_addr_c <= ("00000000" & k_count(3 downto 2)) + (k_count(9 downto 4) & "0000")+ int2ustd(8,apr);
									rd_addr_d <= ("00000000" & k_count(3 downto 2)) + (k_count(9 downto 4) & "0000")+ int2ustd(12,apr);
								when "100" =>	
								  --offset = mod((0:3)*16+ floor(mod(k,16)/4)+mod(4*floor(k/16),16) + 64*floor(k/64),n_by_4)+1;
						 			rd_addr_a <= ("0000000" & k_count(3 downto 2)) + ("000000" & k_count(5 downto 4) & "00") + (k_count(9 downto 6) & "000000");
									rd_addr_b <= ("0000000" & k_count(3 downto 2)) + ("000000" & k_count(5 downto 4) & "00") + (k_count(9 downto 6) & "000000") + int2ustd(16,apr);
									rd_addr_c <= ("0000000" & k_count(3 downto 2)) + ("000000" & k_count(5 downto 4) & "00") + (k_count(9 downto 6) & "000000") + int2ustd(32,apr);
									rd_addr_d <= ("0000000" & k_count(3 downto 2)) + ("000000" & k_count(5 downto 4) & "00") + (k_count(9 downto 6) & "000000") + int2ustd(48,apr);
								when "101" =>	
									--offset = mod((0:3)*64+ floor(mod(k,16)/4)    +mod(4*floor(k/16),16)                    + mod(16*floor(k/64),64)                  +256*floor(k/256),n_by_4)+1;
								  rd_addr_a <= ("0000000" & k_count(3 downto 2)) + ("000000" & k_count(5 downto 4) & "00") + ("0000" & k_count(7 downto 6) & "0000") + (k_count(9 downto 8) & "00000000");
									rd_addr_b <= ("0000000" & k_count(3 downto 2)) + ("000000" & k_count(5 downto 4) & "00") + ("0000" & k_count(7 downto 6) & "0000") + (k_count(9 downto 8) & "00000000") + int2ustd(64,apr);
									rd_addr_c <= ("0000000" & k_count(3 downto 2)) + ("000000" & k_count(5 downto 4) & "00") + ("0000" & k_count(7 downto 6) & "0000") + (k_count(9 downto 8) & "00000000") + int2ustd(128,apr);
									rd_addr_d <= ("0000000" & k_count(3 downto 2)) + ("000000" & k_count(5 downto 4) & "00") + ("0000" & k_count(7 downto 6) & "0000") + (k_count(9 downto 8) & "00000000") + int2ustd(192,apr);
								when "110" =>
								  --offset = mod((0:3)*256+ floor(mod(k,16)/4)   +mod(4*floor(k/16),16)                    + mod(16*floor(k/64),64)                  +mod(64*floor(k/256),256)+1024*floor(k/1024),n_by_4)+1;	
								  rd_addr_a <= ("0000000" & k_count(3 downto 2)) + ("000000" & k_count(5 downto 4) & "00") + ("0000" & k_count(7 downto 6) & "0000") + ("00" & k_count(9 downto 8) & "000000") ;
									rd_addr_b <= ("0000000" & k_count(3 downto 2)) + ("000000" & k_count(5 downto 4) & "00") + ("0000" & k_count(7 downto 6) & "0000") + ("00" & k_count(9 downto 8) & "000000") + int2ustd(256,apr);
									rd_addr_c <= ("0000000" & k_count(3 downto 2)) + ("000000" & k_count(5 downto 4) & "00") + ("0000" & k_count(7 downto 6) & "0000") + ("00" & k_count(9 downto 8) & "000000") + int2ustd(512,apr);
									rd_addr_d <= ("0000000" & k_count(3 downto 2)) + ("000000" & k_count(5 downto 4) & "00") + ("0000" & k_count(7 downto 6) & "0000") + ("00" & k_count(9 downto 8) & "000000") + int2ustd(768,apr);
								when others =>	
									rd_addr_a <= k_count;
									rd_addr_b <= k_count;
									rd_addr_c <= k_count;
									rd_addr_d <= k_count;
							end case;
				end if;
			end process get_8192_addr;
		
		end generate gen_8192_addr;
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
	gen_16384_addr : if(nps=16384) generate
get_16384_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
						 --sw = floor(k/n_by_16)
						 --	sw <= k_count(8 downto 7);
						 sw <= '0' & k_count(10);
						when "010" =>
						 --sw = mod(k,4);
						 	sw <= k_count(1 downto 0);
						when "011" => 	
						--sw = mod(mod(k,4)+floor(k/4),4);
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2);
						when "100" => 	
							-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16),4);
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) ;
						when "101" => 	 	
							-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16)+floor(k/64),4);
							sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						when "110" => 	 	
							--sw = mod(mod(k,4)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
							sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8);
						when others =>
						 	sw <=(others=>'0');
					end case;
				end if;
			end process get_16384_sw;
			
get_16384_addr:process(clk,global_clock_enable,p_count,k_count)
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
							case p_count(2 downto 0) is
								when "001" =>
									rd_addr_a <= k_count;
									rd_addr_b <= k_count;
									rd_addr_c <= k_count;
									rd_addr_d <= k_count;
								when "010" =>
								-- offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
									rd_addr_a <=  k_count(10 downto 2) & "00";
									rd_addr_b <= (k_count(10 downto 2) & "00") + int2ustd(1,apr);
									rd_addr_c <= (k_count(10 downto 2) & "00") + int2ustd(2,apr);
									rd_addr_d <= (k_count(10 downto 2) & "00") + int2ustd(3,apr);
								when "011" =>
								-- offset = mod((0:3)*4+ floor(mod(k,16)/4)+16*floor(k/16),n_by_4)+1;
									rd_addr_a <= ("000000000" & k_count(3 downto 2)) + (k_count(10 downto 4) & "0000");
									rd_addr_b <= ("000000000" & k_count(3 downto 2)) + (k_count(10 downto 4) & "0000")+ int2ustd(4,apr);
									rd_addr_c <= ("000000000" & k_count(3 downto 2)) + (k_count(10 downto 4) & "0000")+ int2ustd(8,apr);
									rd_addr_d <= ("000000000" & k_count(3 downto 2)) + (k_count(10 downto 4) & "0000")+ int2ustd(12,apr);
								when "100" =>	
								  --offset = mod((0:3)*16+ floor(mod(k,16)/4)+mod(4*floor(k/16),16) + 64*floor(k/64),n_by_4)+1;
						 			rd_addr_a <= ("000000000" & k_count(3 downto 2)) + ("0000000" & k_count(5 downto 4) & "00") + (k_count(10 downto 6) & "000000");
									rd_addr_b <= ("000000000" & k_count(3 downto 2)) + ("0000000" & k_count(5 downto 4) & "00") + (k_count(10 downto 6) & "000000") + int2ustd(16,apr);
									rd_addr_c <= ("000000000" & k_count(3 downto 2)) + ("0000000" & k_count(5 downto 4) & "00") + (k_count(10 downto 6) & "000000") + int2ustd(32,apr);
									rd_addr_d <= ("000000000" & k_count(3 downto 2)) + ("0000000" & k_count(5 downto 4) & "00") + (k_count(10 downto 6) & "000000") + int2ustd(48,apr);
								when "101" =>	
									--offset = mod((0:3)*64+ floor(mod(k,16)/4)+mod(4*floor(k/16),16) + mod(16*floor(k/64),64)+256*floor(k/256),n_by_4)+1;
								  rd_addr_a <= ("000000000" & k_count(3 downto 2)) + ("0000000" & k_count(5 downto 4) & "00") + ("00000" & k_count(7 downto 6) & "0000") + ( k_count(10 downto 8) & "00000000");
									rd_addr_b <= ("000000000" & k_count(3 downto 2)) + ("0000000" & k_count(5 downto 4) & "00") + ("00000" & k_count(7 downto 6) & "0000") + ( k_count(10 downto 8) & "00000000") + int2ustd(64,apr);
									rd_addr_c <= ("000000000" & k_count(3 downto 2)) + ("0000000" & k_count(5 downto 4) & "00") + ("00000" & k_count(7 downto 6) & "0000") + ( k_count(10 downto 8) & "00000000") + int2ustd(128,apr);
									rd_addr_d <= ("000000000" & k_count(3 downto 2)) + ("0000000" & k_count(5 downto 4) & "00") + ("00000" & k_count(7 downto 6) & "0000") + ( k_count(10 downto 8) & "00000000") + int2ustd(192,apr);
								when "110" =>	
									--offset = mod((0:3)*256+ floor(mod(k,16)/4)      +mod(4*floor(k/16),16)                    + mod(16*floor(k/64),64)                   +mod(64*floor(k/256),256)+1024*floor(k/1024),n_by_4)+1;
                  rd_addr_a <= ("000000000" & k_count(3 downto 2)) + ("0000000" & k_count(5 downto 4) & "00") + ("00000" & k_count(7 downto 6) & "0000") + ("000" & k_count(9 downto 8) & "000000") + (k_count(10) & "0000000000");
									rd_addr_b <= ("000000000" & k_count(3 downto 2)) + ("0000000" & k_count(5 downto 4) & "00") + ("00000" & k_count(7 downto 6) & "0000") + ("000" & k_count(9 downto 8) & "000000") + (k_count(10) & "0000000000")+ int2ustd(256,apr);
									rd_addr_c <= ("000000000" & k_count(3 downto 2)) + ("0000000" & k_count(5 downto 4) & "00") + ("00000" & k_count(7 downto 6) & "0000") + ("000" & k_count(9 downto 8) & "000000") + (k_count(10) & "0000000000")+ int2ustd(512,apr);
									rd_addr_d <= ("000000000" & k_count(3 downto 2)) + ("0000000" & k_count(5 downto 4) & "00") + ("00000" & k_count(7 downto 6) & "0000") + ("000" & k_count(9 downto 8) & "000000") + (k_count(10) & "0000000000")+ int2ustd(768,apr);									
								when others =>	
									rd_addr_a <= k_count;
									rd_addr_b <= k_count;
									rd_addr_c <= k_count;
									rd_addr_d <= k_count;
							end case;
				end if;
			end process get_16384_addr;
		
		end generate gen_16384_addr;
		
-----------------------------------------------------------------------------------------------
-- N=32768
-----------------------------------------------------------------------------------------------

gen_32768_addr : if(nps=32768) generate

get_32768_sw:process(clk,global_clock_enable,p_count,k_count)is
begin
    if((rising_edge(clk) and global_clock_enable='1')) then 
        case p_count(2 downto 0) is 
            when "001" =>
                sw <= '0' & k_count(10);
            when "010" =>
                sw <= k_count(1 downto 0);
            when "011" =>
                sw <= k_count(1 downto 0) + k_count(3 downto 2);
            when "100" =>
                sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4);
            when "101" =>
                sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6);
            when "110" =>
                sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8);
            when "111" =>
                sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10);
            when others =>
                sw <=(others=>'0'); 
        end case;
	end if;
end process get_32768_sw;
			
get_32768_addr:process(clk,global_clock_enable,p_count,k_count)is
begin
    if((rising_edge(clk) and global_clock_enable='1')) then
        case p_count(2 downto 0) is
            when "001" =>
                rd_addr_a <= k_count;
                rd_addr_b <= k_count;
                rd_addr_c <= k_count;
                rd_addr_d <= k_count;
            when "010" =>
                rd_addr_a <=  k_count(11 downto 2) & "00";
                rd_addr_b <= (k_count(11 downto 2) & "00") + int2ustd(1,apr);
                rd_addr_c <= (k_count(11 downto 2) & "00") + int2ustd(2,apr);
                rd_addr_d <= (k_count(11 downto 2) & "00") + int2ustd(3,apr);
            when "011" =>
                rd_addr_a <= k_count(11 downto 4) & "00" & k_count(3 downto 2);
                rd_addr_b <= (k_count(11 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(4,apr);
                rd_addr_c <= (k_count(11 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(8,apr); 
                rd_addr_d <= (k_count(11 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(12,apr);
            when "100" =>
                rd_addr_a <= k_count(11 downto 6) & "00" & k_count(5 downto 2);
                rd_addr_b <= (k_count(11 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(16,apr);
                rd_addr_c <= (k_count(11 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(32,apr);
                rd_addr_d <= (k_count(11 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(48,apr);
            when "101" =>
                rd_addr_a <= k_count(11 downto 8) & "00" & k_count(7 downto 2);
                rd_addr_b <= (k_count(11 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(64,apr);
                rd_addr_c <= (k_count(11 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(128,apr);
                rd_addr_d <= (k_count(11 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(192,apr);
            when "110" =>
                rd_addr_a <= k_count(11 downto 10) & "00" & k_count(9 downto 2);
                rd_addr_b <= (k_count(11 downto 10) & "00" & k_count(9 downto 2)) + int2ustd(256,apr);
                rd_addr_c <= (k_count(11 downto 10) & "00" & k_count(9 downto 2)) + int2ustd(512,apr);
                rd_addr_d <= (k_count(11 downto 10) & "00" & k_count(9 downto 2)) + int2ustd(768,apr);
            when "111" =>
                rd_addr_a <= "00" & k_count(11 downto 2);
                rd_addr_b <= ("00" & k_count(11 downto 2)) + int2ustd(1024,apr);
                rd_addr_c <= ("00" & k_count(11 downto 2)) + int2ustd(2048,apr);
                rd_addr_d <= ("00" & k_count(11 downto 2)) + int2ustd(3072,apr);
            when others =>
                rd_addr_a <= k_count;
                rd_addr_b <= k_count;
                rd_addr_c <= k_count;
                rd_addr_d <= k_count;
            end case;
		end if;
	end process get_32768_addr;
		
end generate gen_32768_addr;

-----------------------------------------------------------------------------------------------
-- N=65536
-----------------------------------------------------------------------------------------------

gen_65536_addr : if(nps=65536) generate

get_65536_sw:process(clk,global_clock_enable,p_count,k_count)is
begin
    if((rising_edge(clk) and global_clock_enable='1')) then 
        case p_count(2 downto 0) is 
            when "001" =>   sw <= '0' & k_count(12);
            when "010" =>   sw <= k_count(1 downto 0);
            when "011" => 	sw <= k_count(1 downto 0) + k_count(3 downto 2);
            when "100" => 	sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4);
            when "101" =>   sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6);
            when "110" =>	sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8);
            when "111" =>	sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10);
            when others => 	sw <=(others=>'0'); 
        end case;
	end if;
end process get_65536_sw;
			
get_65536_addr:process(clk,global_clock_enable,p_count,k_count)
begin
    if((rising_edge(clk) and global_clock_enable='1')) then
        case p_count(2 downto 0) is
            when "001" =>
                rd_addr_a <= k_count;
                rd_addr_b <= k_count;
                rd_addr_c <= k_count;
                rd_addr_d <= k_count;
            when "010" =>
                rd_addr_a <= k_count(12 downto 2) & "00";
                rd_addr_b <= (k_count(12 downto 2) & "00") + int2ustd(1,apr);
                rd_addr_c <= (k_count(12 downto 2) & "00") + int2ustd(2,apr);
                rd_addr_d <= (k_count(12 downto 2) & "00") + int2ustd(3,apr);
            when "011" =>
                rd_addr_a <= k_count(12 downto 4) & "00" & k_count(3 downto 2);
                rd_addr_b <= (k_count(12 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(4,apr);
                rd_addr_c <= (k_count(12 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(8,apr); 
                rd_addr_d <= (k_count(12 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(12,apr);
            when "100" =>
                rd_addr_a <= k_count(12 downto 6) & "00" & k_count(5 downto 2);
                rd_addr_b <= (k_count(12 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(16,apr);
                rd_addr_c <= (k_count(12 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(32,apr);
                rd_addr_d <= (k_count(12 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(48,apr);
            when "101" =>
                rd_addr_a <= k_count(12 downto 8) & "00" & k_count(7 downto 2);
                rd_addr_b <= (k_count(12 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(64,apr);
                rd_addr_c <= (k_count(12 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(128,apr);
                rd_addr_d <= (k_count(12 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(192,apr);
            when "110" =>
                rd_addr_a <= k_count(12 downto 10) & "00" & k_count(9 downto 2);
                rd_addr_b <= (k_count(12 downto 10) & "00" & k_count(9 downto 2)) + int2ustd(256,apr);
                rd_addr_c <= (k_count(12 downto 10) & "00" & k_count(9 downto 2)) + int2ustd(512,apr);
                rd_addr_d <= (k_count(12 downto 10) & "00" & k_count(9 downto 2)) + int2ustd(768,apr);
            when "111" =>
                rd_addr_a <= k_count(12) & "00" & k_count(11 downto 2);
                rd_addr_b <= (k_count(12) & "00" & k_count(11 downto 2)) + int2ustd(1024,apr);
                rd_addr_c <= (k_count(12) & "00" & k_count(11 downto 2)) + int2ustd(2048,apr);
                rd_addr_d <= (k_count(12) & "00" & k_count(11 downto 2)) + int2ustd(3072,apr);
            when others =>
                rd_addr_a <= k_count;
                rd_addr_b <= k_count;
                rd_addr_c <= k_count;
                rd_addr_d <= k_count;
            end case;
		end if;
	end process get_65536_addr;
		
end generate gen_65536_addr;

-----------------------------------------------------------------------------------------------
-- N=131072
-----------------------------------------------------------------------------------------------

gen_131072_addr : if(nps=131072) generate

get_131072_sw:process(clk,global_clock_enable,p_count,k_count)is
begin
    if((rising_edge(clk) and global_clock_enable='1')) then 
        case p_count(3 downto 0) is 
            when "0001" =>  sw <= '0' & k_count(12);
            when "0010" =>  sw <= k_count(1 downto 0);
            when "0011" =>  sw <= k_count(1 downto 0) + k_count(3 downto 2);
            when "0100" =>  sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4);
            when "0101" =>  sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6);
            when "0110" =>	sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8);
            when "0111" =>	sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10);
            when "1000" =>	sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10) + k_count(13 downto 12);
            when others => 	sw <=(others=>'0'); 
        end case;
	end if;
end process get_131072_sw;
			
get_131072_addr:process(clk,global_clock_enable,p_count,k_count)
begin
    if((rising_edge(clk) and global_clock_enable='1')) then
        case p_count(3 downto 0) is
            when "0001" =>
                rd_addr_a <= k_count;
                rd_addr_b <= k_count;
                rd_addr_c <= k_count;
                rd_addr_d <= k_count;
            when "0010" =>
                rd_addr_a <= k_count(13 downto 2) & "00";
                rd_addr_b <= (k_count(13 downto 2) & "00") + int2ustd(1,apr);
                rd_addr_c <= (k_count(13 downto 2) & "00") + int2ustd(2,apr);
                rd_addr_d <= (k_count(13 downto 2) & "00") + int2ustd(3,apr);
            when "0011" =>
                rd_addr_a <= k_count(13 downto 4) & "00" & k_count(3 downto 2);
                rd_addr_b <= (k_count(13 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(4,apr);
                rd_addr_c <= (k_count(13 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(8,apr); 
                rd_addr_d <= (k_count(13 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(12,apr);
            when "0100" =>
                rd_addr_a <= k_count(13 downto 6) & "00" & k_count(5 downto 2);
                rd_addr_b <= (k_count(13 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(16,apr);
                rd_addr_c <= (k_count(13 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(32,apr);
                rd_addr_d <= (k_count(13 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(48,apr);
            when "0101" =>
                rd_addr_a <= k_count(13 downto 8) & "00" & k_count(7 downto 2);
                rd_addr_b <= (k_count(13 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(64,apr);
                rd_addr_c <= (k_count(13 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(128,apr);
                rd_addr_d <= (k_count(13 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(192,apr);
            when "0110" =>
                rd_addr_a <= k_count(13 downto 10) & "00" & k_count(9 downto 2);
                rd_addr_b <= (k_count(13 downto 10) & "00" & k_count(9 downto 2)) + int2ustd(256,apr);
                rd_addr_c <= (k_count(13 downto 10) & "00" & k_count(9 downto 2)) + int2ustd(512,apr);
                rd_addr_d <= (k_count(13 downto 10) & "00" & k_count(9 downto 2)) + int2ustd(768,apr);
            when "0111" =>
                rd_addr_a <= k_count(13 downto 12) & "00" & k_count(11 downto 2);
                rd_addr_b <= (k_count(13 downto 12) & "00" & k_count(11 downto 2)) + int2ustd(1024,apr);
                rd_addr_c <= (k_count(13 downto 12) & "00" & k_count(11 downto 2)) + int2ustd(2048,apr);
                rd_addr_d <= (k_count(13 downto 12) & "00" & k_count(11 downto 2)) + int2ustd(3072,apr);
            when "1000" =>
                rd_addr_a <= "00" & k_count(13 downto 2);
                rd_addr_b <= ("00" & k_count(13 downto 2)) + int2ustd(4096,apr);
                rd_addr_c <= ("00" & k_count(13 downto 2)) + int2ustd(8192,apr);
                rd_addr_d <= ("00" & k_count(13 downto 2)) + int2ustd(12288,apr);
            when others =>
                rd_addr_a <= k_count;
                rd_addr_b <= k_count;
                rd_addr_c <= k_count;
                rd_addr_d <= k_count;
            end case;
		end if;
	end process get_131072_addr;
		
end generate gen_131072_addr;

end generate gen_de_addr;

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- Quad Engine
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

gen_qe_addr : if(nume=4) generate



gen_64_addr : if(nps=64) generate

	
get_64_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(1 downto 0) is
				when "01" =>
				 --sw = floor(k/n_by_16)
				 	sw <= '0' & k_count(3);
				when "10" =>
				 	sw <= k_count(1 downto 0);
				when others =>
				 	 	sw <=(others=>'0');
			end case;
		end if;
	end process get_64_sw;
	
get_64_addr:process(clk,global_clock_enable,p_count,k_count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(1 downto 0) is
						when "01" =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
						when "10" =>
						--          offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
							rd_addr_a <= k_count(3 downto 2) & "00";
							rd_addr_b <= (k_count(3 downto 2) & "00") + int2ustd(1,apr);
							rd_addr_c <= (k_count(3 downto 2) & "00") + int2ustd(2,apr);
							rd_addr_d <= (k_count(3 downto 2) & "00") + int2ustd(3,apr);
				 		when others =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
					end case;
		end if;
		end process get_64_addr;
		
end generate gen_64_addr;

-----------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------

gen_128_addr : if(nps=128) generate
--
get_128_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(1 downto 0) is
				when "01" =>
				 --sw = mod(floor(k/n_by_32) + 2*floor(k/n_by_8) , 4);
				 	sw <= '0' & k_count(2);
				when "10" =>
				--sw = mod(k,4);
				 	sw <= k_count(1 downto 0);
				when "11" => 	
				--sw = mod(mod(k,4)+floor(k/4),4);
				 	sw <= k_count(1 downto 0)+k_count(3 downto 2);
				when others =>
				 	sw <=(others=>'0');
			end case;
		end if;
	end process get_128_sw;
	
get_128_addr:process(clk,global_clock_enable,p_count,k_count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(1 downto 0) is
						when "01" =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
						when "10" =>
						-- offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
							rd_addr_a <=  (k_count(3 downto 2) & "00");
							rd_addr_b <=  (k_count(3 downto 2) & "00") + int2ustd(1,apr);
							rd_addr_c <=  (k_count(3 downto 2) & "00") + int2ustd(2,apr);
							rd_addr_d <=  (k_count(3 downto 2) & "00") + int2ustd(3,apr);
						when "11" =>
						-- offset = mod((0:3)*4+ floor(mod(k,16)/4)+16*floor(k/16),n_by_4)+1;
							rd_addr_a <= ("00" & k_count(3 downto 2)) ;
							rd_addr_b <= ("00" & k_count(3 downto 2)) + int2ustd(4,apr);
							rd_addr_c <= ("00" & k_count(3 downto 2)) + int2ustd(8,apr);
							rd_addr_d <= ("00" & k_count(3 downto 2)) + int2ustd(12,apr);
				 		when others =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
					end case;
		end if;
	end process get_128_addr;

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
				 	sw <= "00";
				when "10" =>
				 	sw <= k_count(1 downto 0);
				when "11" => 	
				 	sw <= k_count(1 downto 0)+k_count(3 downto 2);
				when others =>
				 	sw <=(others=>'0');
			end case;
		end if;
	end process get_256_sw;
	 --apr=4
get_256_addr:process(clk,global_clock_enable,p_count,k_count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(1 downto 0) is
						when "01" =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
						when "10" =>
						-- offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
							rd_addr_a <=  (k_count(3 downto 2) & "00");
							rd_addr_b <=  (k_count(3 downto 2) & "00") + int2ustd(1,apr);
							rd_addr_c <=  (k_count(3 downto 2) & "00") + int2ustd(2,apr);
							rd_addr_d <=  (k_count(3 downto 2) & "00") + int2ustd(3,apr);
						when "11" =>
						-- offset = mod((0:3)*4+ floor(mod(k,16)/4)+16*floor(k/16),n_by_4)+1;
							rd_addr_a <= ("00" & k_count(3 downto 2)) ;
							rd_addr_b <= ("00" & k_count(3 downto 2)) + int2ustd(4,apr);
							rd_addr_c <= ("00" & k_count(3 downto 2)) + int2ustd(8,apr);
							rd_addr_d <= ("00" & k_count(3 downto 2)) + int2ustd(12,apr);
				 		when others =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
					end case;
		end if;
	end process get_256_addr;

end generate gen_256_addr;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

gen_512_addr : if(nps=512) generate

--apr=5

get_512_sw:process(clk,global_clock_enable,p_count,k_count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			case p_count(2 downto 0) is
				when "001" =>
				 	sw <= "00";
				when "010" =>
				 --sw = mod(k,4);
				 	sw <= k_count(1 downto 0);
				when "011" => 	
				--sw = mod(mod(k,4)+floor(k/4),4);
				 	sw <= k_count(1 downto 0)+k_count(3 downto 2);
				when "100" => 	
					-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16),4);
					
					sw <= "00";
					--sw <= k_count(1 downto 0)+k_count(3 downto 2) +('0' & k_count(4)) ;
				when others =>
				 	sw <=(others=>'0');
			end case;
		end if;
	end process get_512_sw;
	
get_512_addr:process(clk,global_clock_enable,p_count,k_count)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
						when "010" =>
						-- offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
							rd_addr_a <=  k_count(4 downto 2) & "00";
							rd_addr_b <= (k_count(4 downto 2) & "00") + int2ustd(1,apr);
							rd_addr_c <= (k_count(4 downto 2) & "00") + int2ustd(2,apr);
							rd_addr_d <= (k_count(4 downto 2) & "00") + int2ustd(3,apr);
						when "011" =>
							rd_addr_a <= ("000" & k_count(3 downto 2)) + (k_count(4) & "0000");
							rd_addr_b <= ("000" & k_count(3 downto 2)) + (k_count(4) & "0000")+ int2ustd(4,apr);
							rd_addr_c <= ("000" & k_count(3 downto 2)) + (k_count(4) & "0000")+ int2ustd(8,apr);
							rd_addr_d <= ("000" & k_count(3 downto 2)) + (k_count(4) & "0000")+ int2ustd(12,apr);
						when "100" =>	
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
						when others =>	
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
					end case;
		end if;
	end process get_512_addr;

		
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
				 --sw = floor(k/n_by_16)
				 	sw <= "00";
				when "010" =>
				 --sw = mod(k,4);
				 	sw <= k_count(1 downto 0);
				when "011" => 	
				--sw = mod(mod(k,4)+floor(k/4),4);
				 	sw <= k_count(1 downto 0)+k_count(3 downto 2);
				when "100" => 	
					-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16),4);
				 	sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) ;
				when others =>
				 	sw <=(others=>'0');
			end case;
		end if;
	end process get_1024_sw;
	
get_1024_addr:process(clk,global_clock_enable,p_count,k_count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
						when "010" =>
						-- offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
							rd_addr_a <=  k_count(5 downto 2) & "00";
							rd_addr_b <= (k_count(5 downto 2) & "00") + int2ustd(1,apr);
							rd_addr_c <= (k_count(5 downto 2) & "00") + int2ustd(2,apr);
							rd_addr_d <= (k_count(5 downto 2) & "00") + int2ustd(3,apr);
						when "011" =>
						-- offset = mod((0:3)*4+ floor(mod(k,16)/4)+16*floor(k/16),n_by_4)+1;
							rd_addr_a <=  (k_count(5 downto 4) & "00" & k_count(3 downto 2));
							rd_addr_b <=  (k_count(5 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(4,apr);
							rd_addr_c <=  (k_count(5 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(8,apr);
							rd_addr_d <=  (k_count(5 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(12,apr);
						when "100" =>	
						  --offset = mod((0:3)*16+ floor(mod(k,16)/4)+mod(4*floor(k/16),16) + 64*floor(k/64),n_by_4)+1;
				 			rd_addr_a <= ("00" & k_count(5 downto 2));
							rd_addr_b <= ("00" & k_count(5 downto 2))+ int2ustd(16,apr);
							rd_addr_c <= ("00" & k_count(5 downto 2))+ int2ustd(32,apr);
							rd_addr_d <= ("00" & k_count(5 downto 2))+ int2ustd(48,apr);
						when others =>	
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
					end case;
		end if;
	end process get_1024_addr;
end generate gen_1024_addr;
-----------------------------------------------------------------------------------------------
-- N=2048
-----------------------------------------------------------------------------------------------
gen_2048_addr : if(nps=2048) generate
get_2048_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
						 --sw = floor(k/n_by_32);
						 sw <= "00";
						when "010" =>
						 --sw = mod(k,4);
						 	sw <= k_count(1 downto 0);
						when "011" => 	
						--sw = mod(mod(k,4)+floor(k/4),4);
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2);
						when "100" => 	
							-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16),4);
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) ;
						when "101" => 	 	
							-- sw = mod(mod(k,4)+floor(k/4)+floor(k/16)+floor(k/64),4);
							sw <= "00";
						when others =>
						 	sw <=(others=>'0');
					end case;
				end if;
			end process get_2048_sw;
			
get_2048_addr:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					--apr=7
					case p_count(2 downto 0) is
						when "001" =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
						when "010" =>
						-- offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
							rd_addr_a <=  k_count(6 downto 2) & "00";
							rd_addr_b <= (k_count(6 downto 2) & "00") + int2ustd(1,apr);
							rd_addr_c <= (k_count(6 downto 2) & "00") + int2ustd(2,apr);
							rd_addr_d <= (k_count(6 downto 2) & "00") + int2ustd(3,apr);
						when "011" =>
							--rd_addr_a <= ("00000" & k_count(3 downto 2)) + ('0' & k_count(5 downto 4) & "0000")+ (k_count(6) & "000000");
							rd_addr_a <= (k_count(6 downto 4) & "00" & k_count(3 downto 2)) ;
							rd_addr_b <= (k_count(6 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(4,apr);
							rd_addr_c <= (k_count(6 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(8,apr);
							rd_addr_d <= (k_count(6 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(12,apr);
						when "100" =>
							--rd_addr_a <= ("000" & k_count(3 downto 2) & "00") + (k_count(5 downto 4) & "00000")+ (k_count(6) & "000000");
							rd_addr_a <=  ( k_count(6) & "00" & k_count(5 downto 4) & k_count(3 downto 2));
							rd_addr_b <=  ( k_count(6) & "00" & k_count(5 downto 4) & k_count(3 downto 2)) + int2ustd(16,apr);
							rd_addr_c <=  ( k_count(6) & "00" & k_count(5 downto 4) & k_count(3 downto 2)) + int2ustd(32,apr);
							rd_addr_d <=  ( k_count(6) & "00" & k_count(5 downto 4) & k_count(3 downto 2)) + int2ustd(48,apr);
						when "101" =>	
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
						when others =>	
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
					end case;
				end if;
			end process get_2048_addr;
		
		end generate gen_2048_addr;
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------


	gen_4096_addr : if(nps=4096) generate
get_4096_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
						 sw <= "00";
						when "010" =>
						 	sw <= k_count(1 downto 0);
						when "011" => 	
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2);
						when "100" => 	
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) ;
						when "101" => 	 	
							sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						when others =>
						 	sw <=(others=>'0');
					end case;
				end if;
			end process get_4096_sw;
			
get_4096_addr:process(clk,global_clock_enable,p_count,k_count)
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case p_count(2 downto 0) is
							when "001" =>
								rd_addr_a <= k_count;
								rd_addr_b <= k_count;
								rd_addr_c <= k_count;
								rd_addr_d <= k_count;
							when "010" =>
							-- offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
								rd_addr_a <=  k_count(7 downto 2) & "00";
								rd_addr_b <= (k_count(7 downto 2) & "00") + int2ustd(1,apr);
								rd_addr_c <= (k_count(7 downto 2) & "00") + int2ustd(2,apr);
								rd_addr_d <= (k_count(7 downto 2) & "00") + int2ustd(3,apr);
							when "011" =>
							-- offset = mod((0:3)*4+ floor(mod(k,16)/4)+16*floor(k/16),n_by_4)+1;
								rd_addr_a <=  (k_count(7 downto 4) & "00" & k_count(3 downto 2));
								rd_addr_b <=  (k_count(7 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(4,apr);
								rd_addr_c <=  (k_count(7 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(8,apr);
								rd_addr_d <=  (k_count(7 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(12,apr);
							when "100" =>
							-- offset = mod((0:3)*4+ floor(mod(k,16)/4)+16*floor(k/16),n_by_4)+1;
								rd_addr_a <=  (k_count(7 downto 6) & "00" & k_count(5 downto 2));
								rd_addr_b <=  (k_count(7 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(16,apr);
								rd_addr_c <=  (k_count(7 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(32,apr);
								rd_addr_d <=  (k_count(7 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(48,apr);
							when "101" =>	
							  --offset = mod((0:3)*16+ floor(mod(k,16)/4)+mod(4*floor(k/16),16) + 64*floor(k/64),n_by_4)+1;
								rd_addr_a <= ("00" & k_count(7 downto 2));
								rd_addr_b <= ("00" & k_count(7 downto 2))+ int2ustd(64,apr);
								rd_addr_c <= ("00" & k_count(7 downto 2))+ int2ustd(128,apr);
								rd_addr_d <= ("00" & k_count(7 downto 2))+ int2ustd(192,apr);
							when others =>	
								rd_addr_a <= k_count;
								rd_addr_b <= k_count;
								rd_addr_c <= k_count;
								rd_addr_d <= k_count;
						end case;
				end if;
			end process get_4096_addr;
		
		end generate gen_4096_addr;
	-----------------------------------------------------------------------------------------------
	-- N=8192
	-----------------------------------------------------------------------------------------------	
	gen_8192_addr : if(nps=8192) generate
get_8192_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
						  sw <= "00";
						when "010" =>
						 	sw <= k_count(1 downto 0);
						when "011" => 	
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2);
						when "100" => 	
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) ;
						when "101" => 	
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) +k_count(7 downto 6);
						when "110" => 	 	
							sw <= "00";
						when others =>
						 	sw <=(others=>'0');
					end case;
				end if;
			end process get_8192_sw;
			
get_8192_addr:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					--apr=9
					case p_count(2 downto 0) is
						when "001" =>
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
						when "010" =>
							rd_addr_a <=  k_count(8 downto 2) & "00";
							rd_addr_b <= (k_count(8 downto 2) & "00") + int2ustd(1,apr);
							rd_addr_c <= (k_count(8 downto 2) & "00") + int2ustd(2,apr);
							rd_addr_d <= (k_count(8 downto 2) & "00") + int2ustd(3,apr);
						when "011" =>
							rd_addr_a <= (k_count(8 downto 4) & "00" & k_count(3 downto 2)) ;
							rd_addr_b <= (k_count(8 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(4,apr);
							rd_addr_c <= (k_count(8 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(8,apr);
							rd_addr_d <= (k_count(8 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(12,apr);
						when "100" =>
							rd_addr_a <= (k_count(8 downto 6) & "00" & k_count(5 downto 2)) ;
							rd_addr_b <= (k_count(8 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(16,apr);
							rd_addr_c <= (k_count(8 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(32,apr);
							rd_addr_d <= (k_count(8 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(48,apr);
						when "101" =>
							rd_addr_a <=  ( k_count(8) & "00" & k_count(7 downto 2) );
							rd_addr_b <=  ( k_count(8) & "00" & k_count(7 downto 2) ) + int2ustd(64,apr);
							rd_addr_c <=  ( k_count(8) & "00" & k_count(7 downto 2) ) + int2ustd(128,apr);
							rd_addr_d <=  ( k_count(8) & "00" & k_count(7 downto 2) ) + int2ustd(192,apr);
						when "110" =>	
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
						when others =>	
							rd_addr_a <= k_count;
							rd_addr_b <= k_count;
							rd_addr_c <= k_count;
							rd_addr_d <= k_count;
					end case;
				end if;
			end process get_8192_addr;
		end generate gen_8192_addr;
-----------------------------------------------------------------------------------------------
-- N=16384
-----------------------------------------------------------------------------------------------
	gen_16384_addr : if(nps=16384) generate
get_16384_sw:process(clk,global_clock_enable,p_count,k_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
						 sw <= "00";
						when "010" =>
						 	sw <= k_count(1 downto 0);
						when "011" => 	
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2);
						when "100" => 	
						 	sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) ;
						when "101" => 	 	
							sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						when "110" => 	 	
							sw <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8);
						when others =>
						 	sw <=(others=>'0');
					end case;
				end if;
			end process get_16384_sw;
			
get_16384_addr:process(clk,global_clock_enable,p_count,k_count)
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case p_count(2 downto 0) is
							when "001" =>
								rd_addr_a <= k_count;
								rd_addr_b <= k_count;
								rd_addr_c <= k_count;
								rd_addr_d <= k_count;
							when "010" =>
							-- offset = mod((0:3)+ 4*floor(k/4),n_by_4)+1;
								rd_addr_a <=  k_count(9 downto 2) & "00";
								rd_addr_b <= (k_count(9 downto 2) & "00") + int2ustd(1,apr);
								rd_addr_c <= (k_count(9 downto 2) & "00") + int2ustd(2,apr);
								rd_addr_d <= (k_count(9 downto 2) & "00") + int2ustd(3,apr);
							when "011" =>
							-- offset = mod((0:3)*4+ floor(mod(k,16)/4)+16*floor(k/16),n_by_4)+1;
								rd_addr_a <=  (k_count(9 downto 4) & "00" & k_count(3 downto 2));
								rd_addr_b <=  (k_count(9 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(4,apr);
								rd_addr_c <=  (k_count(9 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(8,apr);
								rd_addr_d <=  (k_count(9 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(12,apr);
							when "100" =>
							-- offset = mod((0:3)*4+ floor(mod(k,16)/4)+16*floor(k/16),n_by_4)+1;
								rd_addr_a <=  (k_count(9 downto 6) & "00" & k_count(5 downto 2));
								rd_addr_b <=  (k_count(9 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(16,apr);
								rd_addr_c <=  (k_count(9 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(32,apr);
								rd_addr_d <=  (k_count(9 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(48,apr);
							when "101" =>
							-- offset = mod((0:3)*4+ floor(mod(k,16)/4)+16*floor(k/16),n_by_4)+1;
								rd_addr_a <=  (k_count(9 downto 8) & "00" & k_count(7 downto 2));
								rd_addr_b <=  (k_count(9 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(64,apr);
								rd_addr_c <=  (k_count(9 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(128,apr);
								rd_addr_d <=  (k_count(9 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(192,apr);
							when "110" =>	
							  --offset = mod((0:3)*16+ floor(mod(k,16)/4)+mod(4*floor(k/16),16) + 64*floor(k/64),n_by_4)+1;
								rd_addr_a <= ("00" & k_count(9 downto 2));
								rd_addr_b <= ("00" & k_count(9 downto 2))+ int2ustd(256,apr);
								rd_addr_c <= ("00" & k_count(9 downto 2))+ int2ustd(512,apr);
								rd_addr_d <= ("00" & k_count(9 downto 2))+ int2ustd(768,apr);
							when others =>	
								rd_addr_a <= k_count;
								rd_addr_b <= k_count;
								rd_addr_c <= k_count;
								rd_addr_d <= k_count;
						end case;
				end if;
			end process get_16384_addr;
		
		end generate gen_16384_addr;

-----------------------------------------------------------------------------------------------
-- N=32768
-----------------------------------------------------------------------------------------------

gen_32768_addr : if(nps=32768) generate

get_32768_sw:process(clk,global_clock_enable,p_count,k_count)is
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
	    case p_count(2 downto 0) is
            when "001" =>   sw <= "00";
            when "010" =>   sw <= k_count(1 downto 0);
            when "011" => 	sw <= k_count(1 downto 0) + k_count(3 downto 2);
            when "100" => 	sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) ;
            when "101" => 	sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6);
            when "110" => 	sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8);
            when "111" => 	sw <= "00";
            when others =>  sw <=(others=>'0');
        end case;
	end if;
end process get_32768_sw;
			
get_32768_addr:process(clk,global_clock_enable,p_count,k_count)
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
    case p_count(2 downto 0) is
        when "001" =>
            rd_addr_a <= k_count;
            rd_addr_b <= k_count;
            rd_addr_c <= k_count;
            rd_addr_d <= k_count;
        when "010" =>
            rd_addr_a <= k_count(10 downto 2) & "00";
            rd_addr_b <= (k_count(10 downto 2) & "00") + int2ustd(1,apr);
            rd_addr_c <= (k_count(10 downto 2) & "00") + int2ustd(2,apr);
            rd_addr_d <= (k_count(10 downto 2) & "00") + int2ustd(3,apr);
        when "011" =>
            rd_addr_a <= k_count(10 downto 4) & "00" & k_count(3 downto 2);
            rd_addr_b <= (k_count(10 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(4,apr);
            rd_addr_c <= (k_count(10 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(8,apr);
            rd_addr_d <= (k_count(10 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(12,apr);
        when "100" =>
            rd_addr_a <= k_count(10 downto 6) & "00" & k_count(5 downto 2);
            rd_addr_b <= (k_count(10 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(16,apr);
            rd_addr_c <= (k_count(10 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(32,apr);
            rd_addr_d <= (k_count(10 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(48,apr);
        when "101" =>
            rd_addr_a <= k_count(10 downto 8) & "00" & k_count(7 downto 2);
            rd_addr_b <= (k_count(10 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(64,apr);
            rd_addr_c <= (k_count(10 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(128,apr);
            rd_addr_d <= (k_count(10 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(192,apr);
        when "110" =>
            rd_addr_a <= k_count(10) & "00" & k_count(9 downto 2);
            rd_addr_b <= (k_count(10) & "00" & k_count(9 downto 2)) + int2ustd(256,apr);
            rd_addr_c <= (k_count(10) & "00" & k_count(9 downto 2)) + int2ustd(512,apr);
            rd_addr_d <= (k_count(10) & "00" & k_count(9 downto 2)) + int2ustd(768,apr);
        when "111" =>
            rd_addr_a <= k_count;
            rd_addr_b <= k_count;
            rd_addr_c <= k_count;
            rd_addr_d <= k_count;
        when others =>
            rd_addr_a <= k_count;
            rd_addr_b <= k_count;
            rd_addr_c <= k_count;
            rd_addr_d <= k_count;
		end case;
	end if;
end process get_32768_addr;

end generate gen_32768_addr;

-----------------------------------------------------------------------------------------------
-- N=65536
-----------------------------------------------------------------------------------------------

gen_65536_addr : if(nps=65536) generate

get_65536_sw:process(clk,global_clock_enable,p_count,k_count)is
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
	    case p_count(2 downto 0) is
            when "001" =>   sw <= "00";
            when "010" =>   sw <= k_count(1 downto 0);
            when "011" => 	sw <= k_count(1 downto 0) + k_count(3 downto 2);
            when "100" => 	sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) ;
            when "101" => 	sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6);
            when "110" => 	sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8);
            when "111" => 	sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10);
            when others =>  sw <=(others=>'0');
        end case;
	end if;
end process get_65536_sw;
			
get_65536_addr:process(clk,global_clock_enable,p_count,k_count)
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
    case p_count(2 downto 0) is
        when "001" =>
            rd_addr_a <= k_count;
            rd_addr_b <= k_count;
            rd_addr_c <= k_count;
            rd_addr_d <= k_count;
        when "010" =>
            rd_addr_a <=  k_count(11 downto 2) & "00";
            rd_addr_b <= (k_count(11 downto 2) & "00") + int2ustd(1,apr);
            rd_addr_c <= (k_count(11 downto 2) & "00") + int2ustd(2,apr);
            rd_addr_d <= (k_count(11 downto 2) & "00") + int2ustd(3,apr);
        when "011" =>
            rd_addr_a <= k_count(11 downto 4) & "00" & k_count(3 downto 2);
            rd_addr_b <= (k_count(11 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(4,apr);
            rd_addr_c <= (k_count(11 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(8,apr);
            rd_addr_d <= (k_count(11 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(12,apr);
        when "100" =>
            rd_addr_a <= k_count(11 downto 6) & "00" & k_count(5 downto 2);
            rd_addr_b <= (k_count(11 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(16,apr);
            rd_addr_c <= (k_count(11 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(32,apr);
            rd_addr_d <= (k_count(11 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(48,apr);
        when "101" =>
            rd_addr_a <= k_count(11 downto 8) & "00" & k_count(7 downto 2);
            rd_addr_b <= (k_count(11 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(64,apr);
            rd_addr_c <= (k_count(11 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(128,apr);
            rd_addr_d <= (k_count(11 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(192,apr);
        when "110" =>
            rd_addr_a <= k_count(11 downto 10) & "00" & k_count(9 downto 2);
            rd_addr_b <= (k_count(11 downto 10) & "00" & k_count(9 downto 2)) + int2ustd(256,apr);
            rd_addr_c <= (k_count(11 downto 10) & "00" & k_count(9 downto 2)) + int2ustd(512,apr);
            rd_addr_d <= (k_count(11 downto 10) & "00" & k_count(9 downto 2)) + int2ustd(768,apr);
        when "111" =>
            rd_addr_a <= ("00" & k_count(11 downto 2));
            rd_addr_b <= ("00" & k_count(11 downto 2))+ int2ustd(1024,apr);
            rd_addr_c <= ("00" & k_count(11 downto 2))+ int2ustd(2048,apr);
            rd_addr_d <= ("00" & k_count(11 downto 2))+ int2ustd(3072,apr);
        when others =>
            rd_addr_a <= k_count;
            rd_addr_b <= k_count;
            rd_addr_c <= k_count;
            rd_addr_d <= k_count;
		end case;
	end if;
end process get_65536_addr;

end generate gen_65536_addr;

-----------------------------------------------------------------------------------------------
-- N=65536
-----------------------------------------------------------------------------------------------

gen_131072_addr : if(nps=131072) generate

get_131072_sw:process(clk,global_clock_enable,p_count,k_count)is
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
	    case p_count(3 downto 0) is
            when "0001" =>   sw <= "00";
            when "0010" =>   sw <= k_count(1 downto 0);
            when "0011" => 	sw <= k_count(1 downto 0) + k_count(3 downto 2);
            when "0100" => 	sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) ;
            when "0101" => 	sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6);
            when "0110" => 	sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8);
            when "0111" => 	sw <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + k_count(9 downto 8) + k_count(11 downto 10);
            when "1000" => 	sw <= "00";
            when others =>  sw <=(others=>'0');
        end case;
	end if;
end process get_131072_sw;
			
get_131072_addr:process(clk,global_clock_enable,p_count,k_count)
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
    case p_count(3 downto 0) is
        when "0001" =>
            rd_addr_a <= k_count;
            rd_addr_b <= k_count;
            rd_addr_c <= k_count;
            rd_addr_d <= k_count;
        when "0010" =>
            rd_addr_a <= k_count(12 downto 2) & "00";
            rd_addr_b <= (k_count(12 downto 2) & "00") + int2ustd(1,apr);
            rd_addr_c <= (k_count(12 downto 2) & "00") + int2ustd(2,apr);
            rd_addr_d <= (k_count(12 downto 2) & "00") + int2ustd(3,apr);
        when "0011" =>
            rd_addr_a <= k_count(12 downto 4) & "00" & k_count(3 downto 2);
            rd_addr_b <= (k_count(12 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(4,apr);
            rd_addr_c <= (k_count(12 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(8,apr);
            rd_addr_d <= (k_count(12 downto 4) & "00" & k_count(3 downto 2)) + int2ustd(12,apr);
        when "0100" =>
            rd_addr_a <= k_count(12 downto 6) & "00" & k_count(5 downto 2);
            rd_addr_b <= (k_count(12 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(16,apr);
            rd_addr_c <= (k_count(12 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(32,apr);
            rd_addr_d <= (k_count(12 downto 6) & "00" & k_count(5 downto 2)) + int2ustd(48,apr);
        when "0101" =>
            rd_addr_a <= k_count(12 downto 8) & "00" & k_count(7 downto 2);
            rd_addr_b <= (k_count(12 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(64,apr);
            rd_addr_c <= (k_count(12 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(128,apr);
            rd_addr_d <= (k_count(12 downto 8) & "00" & k_count(7 downto 2)) + int2ustd(192,apr);
        when "0110" =>
            rd_addr_a <= k_count(12 downto 10) & "00" & k_count(9 downto 2);
            rd_addr_b <= (k_count(12 downto 10) & "00" & k_count(9 downto 2)) + int2ustd(256,apr);
            rd_addr_c <= (k_count(12 downto 10) & "00" & k_count(9 downto 2)) + int2ustd(512,apr);
            rd_addr_d <= (k_count(12 downto 10) & "00" & k_count(9 downto 2)) + int2ustd(768,apr);
        when "0111" =>
            rd_addr_a <= k_count(12) & "00" & k_count(9 downto 2);
            rd_addr_b <= (k_count(12) & "00" & k_count(9 downto 2)) + int2ustd(1024,apr);
            rd_addr_c <= (k_count(12) & "00" & k_count(9 downto 2)) + int2ustd(2048,apr);
            rd_addr_d <= (k_count(12) & "00" & k_count(9 downto 2)) + int2ustd(3072,apr);
        when "1000" =>
            rd_addr_a <= k_count;
            rd_addr_b <= k_count;
            rd_addr_c <= k_count;
            rd_addr_d <= k_count;
        when others =>
            rd_addr_a <= k_count;
            rd_addr_b <= k_count;
            rd_addr_c <= k_count;
            rd_addr_d <= k_count;
		end case;
	end if;
end process get_131072_addr;

end generate gen_131072_addr;

end generate gen_qe_addr;

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
end generate gen_quad_output;
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- Single Output Engine Generator
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
gen_single_output : if(arch>=3) generate

gen_se_addr : if(nume=1) generate

rd_addr_b <=(others=>'0');
rd_addr_c <=(others=>'0');
rd_addr_d <=(others=>'0');
sw <= (others=>'0');


gen_64_addr : if(nps=64) generate

	
get_64_addr:process(clk,global_clock_enable,p_count,k_count)is
	 variable a : std_logic_vector(apr-1 downto 0);
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							a:=(k_count(1 downto 0) & k_count(5 downto 2));
							rd_addr_a <= a;
						when "010" =>
							a :=k_count(5 downto 4) & k_count(1 downto 0) & k_count(3 downto 2);
							rd_addr_a <= a;				
				 		when "011" =>
						  a:=(others=>'0');
							rd_addr_a <= k_count;
						when others => 
						  a:=(others=>'0');
							rd_addr_a(5 downto 0) <=   k_count(1) & k_count(0)
																			 & k_count(3) & k_count(2)
																			 & k_count(5) & k_count(4);
					end case;
		end if;
		end process get_64_addr;
		
end generate gen_64_addr;

-----------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------

gen_128_addr : if(nps=128) generate

get_128_addr:process(clk,global_clock_enable,p_count,k_count)is
	  variable a : std_logic_vector(apr-1 downto 0) := (others=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							a:=(k_count(1 downto 0) & (apr-3 downto 0 => '0')) + ("00" & k_count(apr-1 downto 2));
							rd_addr_a <= a;
						when "010" =>
							--offset = (0:3)*n_by_16 + floor(mod(k,n_by_4)/4) + n_by_4*floor(k/n_by_4)+1;
							a := ("00" & k_count(1 downto 0) & (apr-5 downto 0 => '0')) 
													+ ("00" & k_count(apr-3 downto 2)) 
													+ (k_count(apr-1 downto apr-2) & (apr-3 downto 0 => '0'));
							rd_addr_a <= a;				
						when "011" =>
						  --offset = mod((0:3)*n_by_64 
						  --             + floor(mod(k,n_by_16)/4) 
						  --             + n_by_16*floor(k/n_by_16),n_by_4) 
						  --             + n_by_4*floor(k/n_by_4)+1;
						  a := ((3 downto 0 => '0') & k_count(1 downto 0) & (apr-7 downto 0 => '0'))
						  	  +((5 downto 0 => '0') & k_count(apr-5 downto 2))
						  	  +(k_count(apr-1 downto apr-4) & (apr-5 downto 0 =>'0'));
							rd_addr_a <= (k_count(apr-1 downto apr-2) & a(apr-3 downto 0));
				 		when "100" =>
				 		  a:=(others=>'0');
							rd_addr_a <= (k_count(apr-1 downto 2)  & k_count(0) & (k_count(1)));
				 		when others =>
							a:=(others=>'0');
							rd_addr_a(6 downto 0) <=   k_count(1) & k_count(0)
																			 & k_count(3) & k_count(2)
																			 & k_count(5) & k_count(4)
																			 & k_count(6);
					end case;
		end if;
	end process get_128_addr;

end generate gen_128_addr;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------



gen_256_addr : if(nps=256) generate

get_256_addr:process(clk,global_clock_enable,p_count,k_count)is
	 variable a : std_logic_vector(apr-1 downto 0) := (others=>'0');
	 variable b : std_logic_vector(apr-1 downto 0) := (others=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							a:=(k_count(1 downto 0) & (apr-3 downto 0 => '0')) + ("00" & k_count(apr-1 downto 2));
							rd_addr_a <= a;
						when "010" =>
							a := ("00" & k_count(1 downto 0) & (apr-5 downto 0 => '0')) 
													+ ("00" & k_count(apr-3 downto 2)) 
													+ (k_count(apr-1 downto apr-2) & (apr-3 downto 0 => '0'));
							rd_addr_a <= a;				
						when "011" =>
						  a := ((3 downto 0 => '0') & k_count(1 downto 0) & (apr-7 downto 0 => '0'))
						  	  +((5 downto 0 => '0') & k_count(apr-5 downto 2))
						  	  +(k_count(apr-1 downto apr-4) & (apr-5 downto 0 =>'0'));
							rd_addr_a <= (k_count(apr-1 downto apr-2) & a(apr-3 downto 0));
				 		when "100" =>
						  a:=(others=>'0');
							rd_addr_a <= k_count;
						when others => 
						  a:=(others=>'0');
							rd_addr_a(7 downto 0) <=   k_count(1) & k_count(0)
																			 & k_count(3) & k_count(2)
																			 & k_count(5) & k_count(4)
																			 & k_count(7) & k_count(6);
					end case;
		end if;
	end process get_256_addr;

end generate gen_256_addr;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

gen_512_addr : if(nps=512) generate
	
get_512_addr:process(clk,global_clock_enable,p_count,k_count)is
	 variable a : std_logic_vector(apr-1 downto 0) := (others=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							a:=(k_count(1 downto 0) & (apr-3 downto 0 => '0')) + ("00" & k_count(apr-1 downto 2));
							rd_addr_a <= a;
						when "010" =>
							--offset = (0:3)*n_by_16 + floor(mod(k,n_by_4)/4) + n_by_4*floor(k/n_by_4)+1;
							a := ("00" & k_count(1 downto 0) & (apr-5 downto 0 => '0')) 
													+ ("00" & k_count(apr-3 downto 2)) 
													+ (k_count(apr-1 downto apr-2) & (apr-3 downto 0 => '0'));
							rd_addr_a <= a;				
						when "011" =>
						  --offset = mod((0:3)*n_by_64 
						  --             + floor(mod(k,n_by_16)/4) 
						  --             + n_by_16*floor(k/n_by_16),n_by_4) 
						  --             + n_by_4*floor(k/n_by_4)+1;
						  a := ((3 downto 0 => '0') & k_count(1 downto 0) & (apr-7 downto 0 => '0'))
						  	  +((5 downto 0 => '0') & k_count(apr-5 downto 2))
						  	  +(k_count(apr-1 downto apr-4) & (apr-5 downto 0 =>'0'));
							rd_addr_a <= (k_count(apr-1 downto apr-2) & a(apr-3 downto 0));
						when "100" =>	
						  --offset = mod((0:3)*n_by_256 
						  --         + floor(mod(k,n_by_64)/4) 
						  --         +n_by_64*floor(k/n_by_64) ,n_by_4) 
						  --         + n_by_4*floor(k/n_by_4)+1;
						  a := ((5 downto 0 => '0') & k_count(1 downto 0) & (apr-9 downto 0 => '0'))
						  	  +((7 downto 0 => '0') & k_count(apr-7 downto 2))
						  	  +(k_count(apr-1 downto apr-6) & (apr-7 downto 0 =>'0'));
							rd_addr_a <= (k_count(apr-1 downto apr-2) & a(apr-3 downto 0));
						when "101"=>
						  a:=(others=>'0');
							rd_addr_a <= (k_count(apr-1 downto 2)  & k_count(0) & (k_count(1)));
						when others =>
							a:=(others=>'0');
							rd_addr_a(8 downto 0) <=   k_count(1) & k_count(0)
																			 & k_count(3) & k_count(2)
																			 & k_count(5) & k_count(4)
																			 & k_count(7) & k_count(6)
																			 & k_count(8);
					end case;
		end if;
	end process get_512_addr;

		
end generate gen_512_addr;


-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

gen_1024_addr : if(nps=1024) generate

get_1024_addr:process(clk,global_clock_enable,p_count,k_count)is
	 	variable a : std_logic_vector(apr-1 downto 0) := (others=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							a:=(k_count(1 downto 0) & (apr-3 downto 0 => '0')) + ("00" & k_count(apr-1 downto 2));
							rd_addr_a <= a;
						when "010" =>
							--offset = (0:3)*n_by_16 + floor(mod(k,n_by_4)/4) + n_by_4*floor(k/n_by_4)+1;
							a := ("00" & k_count(1 downto 0) & (apr-5 downto 0 => '0')) 
													+ ("00" & k_count(apr-3 downto 2)) 
													+ (k_count(apr-1 downto apr-2) & (apr-3 downto 0 => '0'));
							rd_addr_a <= a;				
						when "011" =>
						  --offset = mod((0:3)*n_by_64 
						  --             + floor(mod(k,n_by_16)/4) 
						  --             + n_by_16*floor(k/n_by_16),n_by_4) 
						  --             + n_by_4*floor(k/n_by_4)+1;
						  a := ((3 downto 0 => '0') & k_count(1 downto 0) & (apr-7 downto 0 => '0'))
						  	  +((5 downto 0 => '0') & k_count(apr-5 downto 2))
						  	  +(k_count(apr-1 downto apr-4) & (apr-5 downto 0 =>'0'));
							rd_addr_a <= (k_count(apr-1 downto apr-2) & a(apr-3 downto 0));
						when "100" =>	
					  --offset = mod((0:3)*n_by_256 
						  --         + floor(mod(k,n_by_64)/4) 
						  --         +n_by_64*floor(k/n_by_64) ,n_by_4) 
						  --         + n_by_4*floor(k/n_by_4)+1;
						  a := ((5 downto 0 => '0') & k_count(1 downto 0) & (apr-9 downto 0 => '0'))
						  	  +((7 downto 0 => '0') & k_count(apr-7 downto 2))
						  	  +(k_count(apr-1 downto apr-6) & (apr-7 downto 0 =>'0'));
							rd_addr_a <= (k_count(apr-1 downto apr-2) & a(apr-3 downto 0));
						when "101" =>	
							a:=(others=>'0');
							rd_addr_a <= k_count;
						when others =>
						  a:=(others=>'0');
							rd_addr_a(9 downto 0) <=   k_count(1) & k_count(0)
																			 & k_count(3) & k_count(2)
																			 & k_count(5) & k_count(4)
																			 & k_count(7) & k_count(6)
																			 & k_count(9) & k_count(8);
																			 
					end case;
		end if;
	end process get_1024_addr;

		
end generate gen_1024_addr;
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
	gen_2048_addr : if(nps=2048) generate
			
get_2048_addr:process(clk,global_clock_enable,p_count,k_count)is
			 variable a : std_logic_vector(apr-1 downto 0) := (others=>'0');
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case p_count(2 downto 0) is
							when "001" =>
								a:=(k_count(1 downto 0) & k_count(10 downto 2));
								rd_addr_a <= a;
							when "010" =>
								--a := ("00" & k_count(1 downto 0) & (apr-5 downto 0 => '0')) 
								--		+ ("00" & k_count(8 downto 2)) 
								--		+ (k_count(10 downto 9) & (8 downto 0 => '0'));
								a:=k_count(10 downto 9) & k_count(1 downto 0) & k_count(8 downto 2);		
								rd_addr_a <= a;				
							when "011" =>
							  --a := ((3 downto 0 => '0') & k_count(1 downto 0) & (apr-7 downto 0 => '0'))
							  --	  +((5 downto 0 => '0') & k_count(apr-5 downto 2))
							  --	  +(k_count(apr-1 downto apr-4) & (apr-5 downto 0 =>'0'));
							  a:=k_count(10 downto 7) & k_count(1 downto 0) & k_count(6 downto 2);			  
								rd_addr_a <= a;
							when "100" =>	
							  --a := ((5 downto 0 => '0') & k_count(1 downto 0) & (apr-9 downto 0 => '0'))
							  --	  +((7 downto 0 => '0') & k_count(apr-7 downto 2))
							  --	  +(k_count(apr-1 downto apr-6) & (apr-7 downto 0 =>'0'));
							  a:=k_count(10 downto 5) & k_count(1 downto 0) & k_count(4 downto 2);			  
								rd_addr_a <= a;
							when "101" =>	
								--a := ((7 downto 0 => '0') & k_count(1 downto 0) & (apr-11 downto 0 => '0'))
							  --	  +((9 downto 0 => '0') & k_count(apr-9 downto 2))
							  --	  +(k_count(apr-1 downto apr-8) & (apr-9 downto 0 =>'0'));
							  
							  a:=k_count(10 downto 3) & k_count(1 downto 0) & k_count(2);			  	  
								rd_addr_a <= a;
							when "110"=>
						  	a:=(others=>'0');
								rd_addr_a <= (k_count(apr-1 downto 2)  & k_count(0) & (k_count(1)));
							when others =>
								a:=(others=>'0');
								rd_addr_a(10 downto 0) <=   k_count(1) & k_count(0)
																			 & k_count(3) & k_count(2)
																			 & k_count(5) & k_count(4)
																			 & k_count(7) & k_count(6)
																			 & k_count(9) & k_count(8)
																			 & k_count(10);
						end case;
					end if;
			end process get_2048_addr;
		
		end generate gen_2048_addr;

-----------------------------------------------------------------------------------------
--N=4096
-----------------------------------------------------------------------------------------
	gen_4096_addr : if(nps=4096) generate
			
get_4096_addr:process(clk,global_clock_enable,p_count,k_count)is
			 variable a : std_logic_vector(apr-1 downto 0) := (others=>'0');
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case p_count(2 downto 0) is
							when "001" =>
								a:=(k_count(1 downto 0) & (apr-3 downto 0 => '0')) + ("00" & k_count(apr-1 downto 2));
								rd_addr_a <= a;
							when "010" =>
								--offset = (0:3)*n_by_16 + floor(mod(k,n_by_4)/4) + n_by_4*floor(k/n_by_4)+1;
								a := ("00" & k_count(1 downto 0) & (apr-5 downto 0 => '0')) 
													+ ("00" & k_count(apr-3 downto 2)) 
													+ (k_count(apr-1 downto apr-2) & (apr-3 downto 0 => '0'));
								rd_addr_a <= a;				
							when "011" =>
							  --offset = mod((0:3)*n_by_64 
							  --             + floor(mod(k,n_by_16)/4) 
							  --             + n_by_16*floor(k/n_by_16),n_by_4) 
							  --             + n_by_4*floor(k/n_by_4)+1;
							  a := ((3 downto 0 => '0') & k_count(1 downto 0) & (apr-7 downto 0 => '0'))
							  	  +((5 downto 0 => '0') & k_count(apr-5 downto 2))
							  	  +(k_count(apr-1 downto apr-4) & (apr-5 downto 0 =>'0'));
								rd_addr_a <= (k_count(apr-1 downto apr-2) & a(apr-3 downto 0));
							when "100" =>	
					  		--offset = mod((0:3)*n_by_256 
						  	--         + floor(mod(k,n_by_64)/4) 
						  	--         +n_by_64*floor(k/n_by_64) ,n_by_4) 
						  	--         + n_by_4*floor(k/n_by_4)+1;
						  	a := ((5 downto 0 => '0') & k_count(1 downto 0) & (apr-9 downto 0 => '0'))
						  		  +((7 downto 0 => '0') & k_count(apr-7 downto 2))
						  		  +(k_count(apr-1 downto apr-6) & (apr-7 downto 0 =>'0'));
								rd_addr_a <= (k_count(apr-1 downto apr-2) & a(apr-3 downto 0));
							when "101" =>	
								--offset = mod((0:3)*n_by_1024 
								--         + floor(mod(k,n_by_256)/4) 
								--         + n_by_256*floor(k/n_by_256),n_by_4) 
								--         + n_by_4*floor(k/n_by_4)+1;
							  a := ((7 downto 0 => '0') & k_count(1 downto 0) & (apr-11 downto 0 => '0'))
							  	  +((9 downto 0 => '0') & k_count(apr-9 downto 2))
							  	  +(k_count(apr-1 downto apr-8) & (apr-9 downto 0 =>'0'));
								rd_addr_a <= (k_count(apr-1 downto apr-2) & a(apr-3 downto 0));
							when "110" =>	
								a:=(others=>'0');
								rd_addr_a <= k_count;
							when others =>
						  	a:=(others=>'0');
								rd_addr_a(11 downto 0) <=   k_count(1) & k_count(0)
																			 & k_count(3) & k_count(2)
																			 & k_count(5) & k_count(4)
																			 & k_count(7) & k_count(6)
																			 & k_count(9) & k_count(8)
																			 & k_count(11) & k_count(10);
						end case;
					end if;
			end process get_4096_addr;
		
		end generate gen_4096_addr;
		
-----------------------------------------------------------------------------------------------
-- N=8192
-----------------------------------------------------------------------------------------------
	gen_8192_addr : if(nps=8192) generate
			
get_8192_addr:process(clk,global_clock_enable,p_count,k_count)is
			 --apr=13
			 variable a : std_logic_vector(apr-1 downto 0) := (others=>'0');
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
							case p_count(2 downto 0) is
								when "001" =>
									a:=(k_count(1 downto 0) & k_count(12 downto 2));
									rd_addr_a <= a;
								when "010" =>
									--a := ("00" & k_count(1 downto 0) & (apr-5 downto 0 => '0')) 
									--				+ ("00" & k_count(apr-3 downto 2)) 
									--				+ (k_count(apr-1 downto apr-2) & (apr-3 downto 0 => '0'));
									a:=k_count(12 downto 11) & k_count(1 downto 0) & k_count(10 downto 2);				
									rd_addr_a <= a;				
								when "011" =>
								  --a := ((3 downto 0 => '0') & k_count(1 downto 0) & (apr-7 downto 0 => '0'))
								  --	  +((5 downto 0 => '0') & k_count(apr-5 downto 2))
								  --	  +(k_count(apr-1 downto apr-4) & (apr-5 downto 0 =>'0'));
								  a:=k_count(12 downto 9) & k_count(1 downto 0) & k_count(8 downto 2);					  
									rd_addr_a <= (k_count(apr-1 downto apr-2) & a(apr-3 downto 0));
								when "100" =>	
							  	--a := ((5 downto 0 => '0') & k_count(1 downto 0) & (apr-9 downto 0 => '0'))
								  --	  +((7 downto 0 => '0') & k_count(apr-7 downto 2))
								  --	  +(k_count(apr-1 downto apr-6) & (apr-7 downto 0 =>'0'));
								  a:=k_count(12 downto 7) & k_count(1 downto 0) & k_count(6 downto 2);					  
									rd_addr_a <=a; 
								when "101" =>	
									--a := ((7 downto 0 => '0') & k_count(1 downto 0) & (apr-11 downto 0 => '0'))
								  --	  +((9 downto 0 => '0') & k_count(apr-9 downto 2))
								  --	  +(k_count(apr-1 downto apr-8) & (apr-9 downto 0 =>'0'));
								  a:=k_count(12 downto 5) & k_count(1 downto 0) & k_count(4 downto 2);					  
									rd_addr_a <=a;
								when "110" =>	
									--a := ((9 downto 0 => '0') & k_count(1 downto 0) & (apr-13 downto 0 => '0'))
								  --	  +((11 downto 0 => '0') & k_count(apr-11 downto 2))
								  --	  +(k_count(apr-1 downto apr-10) & (apr-11 downto 0 =>'0'));
								  a:=k_count(12 downto 3) & k_count(1 downto 0) & k_count(2);					  
									rd_addr_a <=a;
	  						when "111" =>	
									a:=(others=>'0');
									rd_addr_a <= (k_count(apr-1 downto 2)  & k_count(0) & (k_count(1)));
								when others =>
						  		a:=(others=>'0');
									rd_addr_a(12 downto 0) <=   k_count(1) & k_count(0)
																			 & k_count(3) & k_count(2)
																			 & k_count(5) & k_count(4)
																			 & k_count(7) & k_count(6)
																			 & k_count(9) & k_count(8)
																			 & k_count(11) & k_count(10)
																			 & k_count(12);
							end case;
				end if;
			end process get_8192_addr;
		
		end generate gen_8192_addr;
-----------------------------------------------------------------------------------------------
-- N=16384
-----------------------------------------------------------------------------------------------
	gen_16384_addr : if(nps=16384) generate
			
get_16384_addr:process(clk,global_clock_enable,p_count,k_count)is
			 variable a : std_logic_vector(apr-1 downto 0) := (others=>'0');
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
							case p_count(2 downto 0) is
								when "001" =>
									a:=(k_count(1 downto 0) & (apr-3 downto 0 => '0')) + ("00" & k_count(apr-1 downto 2));
									rd_addr_a <= a;
								when "010" =>
									a := ("00" & k_count(1 downto 0) & (apr-5 downto 0 => '0')) 
															+ ("00" & k_count(apr-3 downto 2)) 
															+ (k_count(apr-1 downto apr-2) & (apr-3 downto 0 => '0'));
									rd_addr_a <= a;				
								when "011" =>
								  a := ((3 downto 0 => '0') & k_count(1 downto 0) & (apr-7 downto 0 => '0'))
								  	  +((5 downto 0 => '0') & k_count(apr-5 downto 2))
								  	  +(k_count(apr-1 downto apr-4) & (apr-5 downto 0 =>'0'));
									rd_addr_a <= (k_count(apr-1 downto apr-2) & a(apr-3 downto 0));
								when "100" =>	
							  	a := ((5 downto 0 => '0') & k_count(1 downto 0) & (apr-9 downto 0 => '0'))
								  	  +((7 downto 0 => '0') & k_count(apr-7 downto 2))
								  	  +(k_count(apr-1 downto apr-6) & (apr-7 downto 0 =>'0'));
									rd_addr_a <= (k_count(apr-1 downto apr-2) & a(apr-3 downto 0));
								when "101" =>	
									a := ((7 downto 0 => '0') & k_count(1 downto 0) & (apr-11 downto 0 => '0'))
								  	  +((9 downto 0 => '0') & k_count(apr-9 downto 2))
								  	  +(k_count(apr-1 downto apr-8) & (apr-9 downto 0 =>'0'));
									rd_addr_a <= (k_count(apr-1 downto apr-2) & a(apr-3 downto 0));
								when "110" =>	
									a := ((9 downto 0 => '0') & k_count(1 downto 0) & (apr-13 downto 0 => '0'))
								  	  +((11 downto 0 => '0') & k_count(apr-11 downto 2))
								  	  +(k_count(apr-1 downto apr-10) & (apr-11 downto 0 =>'0'));
								  rd_addr_a <= (k_count(apr-1 downto apr-2) & a(apr-3 downto 0));
								when "111" =>	
									a:=(others=>'0');
									rd_addr_a <= k_count;
								when others =>
							  	a:=(others=>'0');
									rd_addr_a(13 downto 0) <=   k_count(1) & k_count(0)
																			 & k_count(3) & k_count(2)
																			 & k_count(5) & k_count(4)
																			 & k_count(7) & k_count(6)
																			 & k_count(9) & k_count(8)
																			 & k_count(11) & k_count(10)
																			 & k_count(13) & k_count(12);
							end case;
				end if;
			end process get_16384_addr;
		
		end generate gen_16384_addr;

-----------------------------------------------------------------------------------------------
-- N=32768
-----------------------------------------------------------------------------------------------
gen_32768_addr : if(nps=32768) generate
get_32768_addr:process(clk,global_clock_enable,p_count,k_count)is
    variable a : std_logic_vector(apr-1 downto 0) := (others=>'0');
    begin
        if((rising_edge(clk) and global_clock_enable='1'))then
		    case p_count(3 downto 0) is
                when "0001" =>
                    a:=(k_count(1 downto 0) & k_count(14 downto 2));
                    rd_addr_a <= a;
                when "0010" =>
                    a:=k_count(14 downto 13) & k_count(1 downto 0) & k_count(12 downto 2);
					rd_addr_a <= a;
                when "0011" =>
                    a:=k_count(14 downto 11) & k_count(1 downto 0) & k_count(10 downto 2);
                    rd_addr_a <= (k_count(apr-1 downto apr-2) & a(apr-3 downto 0));
				when "0100" =>
                    a:=k_count(14 downto 9) & k_count(1 downto 0) & k_count(8 downto 2);
                    rd_addr_a <=a;
                when "0101" =>
                    a:=k_count(14 downto 7) & k_count(1 downto 0) & k_count(6 downto 2);
                    rd_addr_a <=a;
                when "0110" =>
					a:=k_count(14 downto 5) & k_count(1 downto 0) & k_count(4 downto 2);
                    rd_addr_a <=a;
                when "0111" =>
					a:=k_count(14 downto 3) & k_count(1 downto 0) & k_count(2);
                    rd_addr_a <=a;
                when "1000" =>
                    a:=(others=>'0');
                    rd_addr_a <= (k_count(apr-1 downto 2)  & k_count(0) & (k_count(1)));
                when others =>
                    a:=(others=>'0');
                    rd_addr_a(14 downto 0) <=     k_count(1) & k_count(0)
                                                & k_count(3) & k_count(2)
                                                & k_count(5) & k_count(4)
                                                & k_count(7) & k_count(6)
                                                & k_count(9) & k_count(8)
                                                & k_count(11) & k_count(10)
                                                & k_count(13) & k_count(12)
                                                & k_count(14);
            end case;
		end if;
	end process get_32768_addr;
end generate gen_32768_addr;

-----------------------------------------------------------------------------------------------
-- N=65536
-----------------------------------------------------------------------------------------------
gen_65536_addr : if(nps=65536) generate
get_65536_addr:process(clk,global_clock_enable,p_count,k_count)is
    variable a : std_logic_vector(apr-1 downto 0) := (others=>'0');
    begin
        if((rising_edge(clk) and global_clock_enable='1'))then
            case p_count(3 downto 0) is
                when "0001" =>
                    a:=(k_count(1 downto 0) & (apr-3 downto 0 => '0')) + ("00" & k_count(apr-1 downto 2));
                    rd_addr_a <= a;
                when "0010" =>
                    a := ("00" & k_count(1 downto 0) & (apr-5 downto 0 => '0')) 
                         + ("00" & k_count(apr-3 downto 2))
                         + (k_count(apr-1 downto apr-2) & (apr-3 downto 0 => '0'));
                    rd_addr_a <= a;
                when "0011" =>
                    a := ((3 downto 0 => '0') & k_count(1 downto 0) & (apr-7 downto 0 => '0'))
                         +((5 downto 0 => '0') & k_count(apr-5 downto 2))
                         +(k_count(apr-1 downto apr-4) & (apr-5 downto 0 =>'0'));
                    rd_addr_a <= (k_count(apr-1 downto apr-2) & a(apr-3 downto 0));
                when "0100" =>
                    a := ((5 downto 0 => '0') & k_count(1 downto 0) & (apr-9 downto 0 => '0'))
                         +((7 downto 0 => '0') & k_count(apr-7 downto 2))
                         +(k_count(apr-1 downto apr-6) & (apr-7 downto 0 =>'0'));
                    rd_addr_a <= (k_count(apr-1 downto apr-2) & a(apr-3 downto 0));
                when "0101" =>
                    a := ((7 downto 0 => '0') & k_count(1 downto 0) & (apr-11 downto 0 => '0'))
                         +((9 downto 0 => '0') & k_count(apr-9 downto 2))
                         +(k_count(apr-1 downto apr-8) & (apr-9 downto 0 =>'0'));
                    rd_addr_a <= (k_count(apr-1 downto apr-2) & a(apr-3 downto 0));
                when "0110" =>	
                    a := ((9 downto 0 => '0') & k_count(1 downto 0) & (apr-13 downto 0 => '0'))
                         +((11 downto 0 => '0') & k_count(apr-11 downto 2))
                         +(k_count(apr-1 downto apr-10) & (apr-11 downto 0 =>'0'));
                    rd_addr_a <= (k_count(apr-1 downto apr-2) & a(apr-3 downto 0));
                when "0111" =>	
                    a := ((11 downto 0 => '0') & k_count(1 downto 0) & (apr-15 downto 0 => '0'))
                         +((13 downto 0 => '0') & k_count(apr-13 downto 2))
                         +(k_count(apr-1 downto apr-12) & (apr-13 downto 0 =>'0'));
                    rd_addr_a <= (k_count(apr-1 downto apr-2) & a(apr-3 downto 0));
                when "1000" =>
                    a :=(others=>'0');
                    rd_addr_a <= k_count;
                when others =>
                    a:=(others=>'0');
                    rd_addr_a(15 downto 0) <=     k_count(1) & k_count(0)
                                                & k_count(3) & k_count(2)
                                                & k_count(5) & k_count(4)
                                                & k_count(7) & k_count(6)
                                                & k_count(9) & k_count(8)
                                                & k_count(11) & k_count(10)
                                                & k_count(13) & k_count(12)
                                                & k_count(15) & k_count(14);
            end case;
        end if;
	end process get_65536_addr;
end generate gen_65536_addr;

end generate gen_se_addr;

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
gen_de_addr : if(nume=2) generate

rd_addr_c <=(others=>'0');
rd_addr_d <=(others=>'0');
sw <= (others=>'0');


gen_64_addr : if(nps=64) generate

	
get_64_addr:process(clk,global_clock_enable,p_count,k_count)is
	  variable a : std_logic_vector(apr-1 downto 0) := (others=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							do_count <= (others=>'0');
							lp_cnt_en<='0';
							a:=k_count(1 downto 0) & k_count(4 downto 2);
							rd_addr_a <= a(apr-1 downto 0);
							rd_addr_b <= not(a(apr-1)) & a(apr-2 downto 0);
						when "010" =>
							do_count <= (others=>'0');
							lp_cnt_en<='0';
							--a := ("00" & k_count(1 downto 0) & (apr-5 downto 0 => '0')) 
							--						+ ("00" & k_count(apr-3 downto 2)) 
							--						+ (k_count(apr-1 downto apr-2) & (apr-3 downto 0 => '0'));
							a:=k_count(4 downto 3) & k_count(1 downto 0) & k_count(2);
							rd_addr_a <= a(apr-1 downto 0);				
							rd_addr_b <= a(apr-1 downto apr-2) & not(a(apr-3)) & a(apr-4 downto 0);
						when "011" =>
							lp_cnt_en<='0';
					 		do_count <= (others=>'0');
						  a:=(others=>'0');
							rd_addr_a <= k_count(4 downto 2) & k_count(0) & (k_count(1) xor k_count(0));
							rd_addr_b <= k_count(4 downto 2) & not(k_count(0)) & not((k_count(1) xor k_count(0)));
						when others => 
						  a:=(others=>'0');
						  if(k_count=int2ustd(1,apr)) then
						  	lp_cnt_en<='1';
						  else
						  	lp_cnt_en<=lp_cnt_en;
						  end if;
						  if(lp_cnt_en='1') then
						  	do_count <= do_count + int2ustd(1,apr+1);
						  else
						  	do_count <= (others=>'0');
						  end if;
						  rd_addr_a(4 downto 0) <= 	(do_count(1 downto 0) & (2 downto 0=>'0'))
																				+ ((1 downto 0 =>'0') & do_count(3) & do_count(4) & (do_count(5) xor do_count(4)));
																				
																				
							rd_addr_b(4 downto 0) <= 	(do_count(1 downto 0) & (2 downto 0=>'0'))
																				+ ((1 downto 0 =>'0') & do_count(3) & do_count(4) & (do_count(5) xor do_count(4)));
					end case;
		end if;
		end process get_64_addr;
		
end generate gen_64_addr;

-----------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------

gen_128_addr : if(nps=128) generate

get_128_addr:process(clk,global_clock_enable,p_count,k_count)is
	  variable a : std_logic_vector(apr-1 downto 0) := (others=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					--apr=6
					case p_count(2 downto 0) is
						when "001" =>
							lp_cnt_en<='0';
							do_count <= (others=>'0');
							a:=k_count(1 downto 0)  & k_count(5 downto 2);
							rd_addr_a <= a(5 downto 0);
							rd_addr_b <= not(a(5)) & a(4 downto 0);
						when "010" =>
							lp_cnt_en<='0';
							do_count <= (others=>'0');
							a:=k_count(5 downto 4) & k_count(1 downto 0) & k_count(3 downto 2);						
							rd_addr_a <= a(5 downto 0);				
							rd_addr_b <= a(5 downto 4) & not(a(3)) & a(2 downto 0);							
						when "011" =>
						  lp_cnt_en<='0';
							do_count <= (others=>'0');
						  a:=k_count(5 downto 0);
							rd_addr_a <= a(5 downto 0);
							rd_addr_b <= a(5 downto 2) & not(a(1)) & a(0);
				 		when "100" =>
				 			lp_cnt_en<='0';
					 		do_count <= (others=>'0');
						  a:=k_count(5 downto 0);
						  rd_addr_a <= a(5 downto 0);
						  --rd_addr_a <= a(5 downto 2)& (a(1) xor a(0)) & (a(0)) ;
							rd_addr_b <= a(5 downto 2) & not(a(1)) & (a(0)) ;
							--rd_addr_b <= a(5 downto 2) & not(a(1) xor a(0)) & (a(0)) ;
						when others => 
						  a:=(others=>'0');
						  if(k_count=int2ustd(1,apr)) then
						  	lp_cnt_en<='1';
						  else
						  	lp_cnt_en<=lp_cnt_en;
						  end if;
						  if(lp_cnt_en='1') then
						  	do_count <= do_count + int2ustd(1,apr+1);
						  else
						  	do_count <= (others=>'0');
						  end if;
						  rd_addr_a(5 downto 0) <= 	do_count(1 downto 0) & do_count(3 downto 2) & do_count(6) & do_count(4);
							rd_addr_b(5 downto 0) <= 	do_count(1 downto 0) & do_count(3 downto 2) & do_count(6) & do_count(4);
					end case;
		end if;
	end process get_128_addr;

end generate gen_128_addr;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
gen_256_addr : if(nps=256) generate

get_256_addr:process(clk,global_clock_enable,p_count,k_count)is
	 variable a : std_logic_vector(apr-1 downto 0) := (others=>'0');
	 begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							do_count <= (others=>'0');
							lp_cnt_en<='0';
							a:=(k_count(1 downto 0) & (apr-3 downto 0 => '0')) + ("00" & k_count(apr-1 downto apr-5));
							rd_addr_a <= a(apr-1 downto 0);
							rd_addr_b <= not(a(apr-1)) & a(apr-2 downto 0);
						when "010" =>
							lp_cnt_en<='0';
							do_count <= (others=>'0');
							a := ("00" & k_count(1 downto 0) & (apr-5 downto 0 => '0')) 
													+ ("00" & k_count(apr-3 downto 2)) 
													+ (k_count(apr-1 downto apr-2) & (apr-3 downto 0 => '0'));
							rd_addr_a <= a(apr-1 downto 0);				
							rd_addr_b <= a(apr-1 downto apr-2) & not(a(apr-3)) & a(apr-4 downto 0);
						when "011" =>
							lp_cnt_en<='0';
						  do_count <= (others=>'0');
							a := ((3 downto 0 => '0') & k_count(1 downto 0) & (apr-7 downto 0 => '0'))
						  	  +((5 downto 0 => '0') & k_count(apr-5 downto apr-5))
						  	  +(k_count(apr-1 downto apr-4) & (apr-5 downto 0 =>'0'));
							rd_addr_a <= (k_count(apr-1 downto apr-2) & a(apr-3 downto 0));
							rd_addr_b <= a(apr-1 downto apr-4) & not(a(apr-5)) & a(apr-6 downto 0);
				 		when "100" =>
					 		do_count <= (others=>'0');
						  a:=(others=>'0');
							rd_addr_a <= k_count(apr-1 downto apr-5) & k_count(0) & (k_count(1) xor k_count(0));
							rd_addr_b <= k_count(6 downto 2) & not(k_count(0)) & not((k_count(1) xor k_count(0)));
						when others => 
						  a:=(others=>'0');
						  if(k_count=int2ustd(1,apr)) then
						  	lp_cnt_en<='1';
						  else
						  	lp_cnt_en<=lp_cnt_en;
						  end if;
						  if(lp_cnt_en='1') then
						  	do_count <= do_count + int2ustd(1,apr+1);
						  else
						  	do_count <= (others=>'0');
						  end if;
							rd_addr_a(6 downto 0) <= 	(do_count(1 downto 0) & (4 downto 0=>'0'))
																				+ ((1 downto 0 =>'0') & do_count(3) & do_count(2) & "000")
																				+ ((3 downto 0 =>'0') & do_count(5) & do_count(6) & (do_count(7) xor do_count(6)));
																				
																				
							rd_addr_b(6 downto 0) <= 	(do_count(1 downto 0) & (4 downto 0=>'0'))
																				+ ((1 downto 0 =>'0') & do_count(3) & do_count(2) & "000")
																				+ ((3 downto 0 =>'0') & do_count(5) & do_count(6) & (do_count(7) xor do_count(6)));
					end case;
		end if;
	end process get_256_addr;

end generate gen_256_addr;
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

gen_512_addr : if(nps=512) generate
	
get_512_addr:process(clk,global_clock_enable,p_count,k_count)is
	 variable a : std_logic_vector(apr-1 downto 0) := (others=>'0');
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count(2 downto 0) is
						when "001" =>
							lp_cnt_en<='0';
							do_count <= (others=>'0');
							a:=k_count(1 downto 0)  & k_count(7 downto 2);
							rd_addr_a <= a(7 downto 0);
							rd_addr_b <= not(a(7)) & a(6 downto 0);
						when "010" =>
							lp_cnt_en<='0';
							do_count <= (others=>'0');
							a:=k_count(7 downto 6) & k_count(1 downto 0) & k_count(5 downto 4) & k_count(3 downto 2);						
							rd_addr_a <= a(7 downto 0);				
							rd_addr_b <= a(7 downto 6) & not(a(5)) & a(4 downto 0);							
						when "011" =>
						  lp_cnt_en<='0';
							do_count <= (others=>'0');
						  a:=k_count(7 downto 6) & k_count(5 downto 4) & k_count(1 downto 0) & k_count(3 downto 2);						
							rd_addr_a <= a(7 downto 0);
							rd_addr_b <= a(7 downto 4) & not(a(3)) & a(2 downto 0);
				 		when "100" =>
				 			lp_cnt_en<='0';
					 		do_count <= (others=>'0');
						  a:=k_count(7 downto 0);
						  rd_addr_a <= a(7 downto 0);
							rd_addr_b <= a(7 downto 2) & not(a(1)) & (a(0)) ;
						when "101" =>
				 			lp_cnt_en<='0';
					 		do_count <= (others=>'0');
						  a:=k_count(7 downto 0);
						  rd_addr_a <= a(7 downto 0);
							rd_addr_b <= a(7 downto 2) & not(a(1)) & (a(0)) ;
						when others => 
						  a:=(others=>'0');
						  if(k_count=int2ustd(1,apr)) then
						  	lp_cnt_en<='1';
						  else
						  	lp_cnt_en<=lp_cnt_en;
						  end if;
						  if(lp_cnt_en='1') then
						  	do_count <= do_count + int2ustd(1,apr+1);
						  else
						  	do_count <= (others=>'0');
						  end if;
						  rd_addr_a(7 downto 0) <= 	do_count(1 downto 0) & do_count(3 downto 2) & do_count(5 downto 4) & do_count(8) & do_count(6);
							rd_addr_b(7 downto 0) <= 	do_count(1 downto 0) & do_count(3 downto 2) & do_count(5 downto 4) & do_count(8) & do_count(6);
					end case;
		end if;
	end process get_512_addr;

		
end generate gen_512_addr;


-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

gen_1024_addr : if(nps=1024) generate

get_1024_addr:process(clk,global_clock_enable,p_count,k_count)is
	 	variable a : std_logic_vector(apr-1 downto 0) := (others=>'0');
	 	--apr=9
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					case p_count(2 downto 0) is
						when "001" =>
							lp_cnt_en<='0';						
							do_count <= (others=>'0');
							a:=k_count(1 downto 0) & k_count(8 downto 2);
							rd_addr_a <= a(apr-1 downto 0);
							rd_addr_b <= not(a(8)) & a(7 downto 0);
						when "010" =>
							lp_cnt_en<='0';						
							do_count <= (others=>'0');
							a:=	k_count(8 downto 7)	& k_count(1 downto 0) & k_count(6 downto 2);
							rd_addr_a <= a(apr-1 downto 0);				
							rd_addr_b <= a(8 downto 7) & not(a(6)) & a(5 downto 0);						
						when "011" =>
							lp_cnt_en<='0';						
							do_count <= (others=>'0');
						  a:=k_count(8 downto 5) & k_count(1 downto 0) & k_count(4 downto 2);
							rd_addr_a <= a(8 downto 0);
							rd_addr_b <= a(8 downto 5) & not(a(4)) & a(3 downto 0);
						when "100" =>
							lp_cnt_en<='0';						
							do_count <= (others=>'0');
						  a:=k_count(8 downto 3) & k_count(1 downto 0) & k_count(2);
							rd_addr_a <= a(8 downto 0);
							rd_addr_b <= a(8 downto 3) & not(a(2)) & a(1 downto 0);
						when "101" =>	
							lp_cnt_en<='0';						
					 		do_count <= (others=>'0');
						  rd_addr_a <= k_count(8 downto 2) & k_count(0) & (k_count(1) xor k_count(0));
							rd_addr_b <= k_count(8 downto 2) & not(k_count(0)) & not((k_count(1) xor k_count(0)));
						when others=>
						  a:=(others=>'0');
						  if(k_count=int2ustd(1,apr)) then
						  	lp_cnt_en<='1';
						  else
						  	lp_cnt_en<=lp_cnt_en;
						  end if;
						  if(lp_cnt_en='1') then
						  	do_count <= do_count + int2ustd(1,apr+1);
						  else
						  	do_count <= (others=>'0');
						  end if;
							rd_addr_a(8 downto 0) <= 	(do_count(1 downto 0) & (6 downto 0=>'0'))
																				+ ((1 downto 0 =>'0') & do_count(3) & do_count(2) & "00000")
																				+ ((3 downto 0 =>'0') & do_count(5) & do_count(4) & "000")
																				+ ((5 downto 0 =>'0') & do_count(7) & do_count(8) & (do_count(9) xor do_count(8)));
																				
							rd_addr_b(8 downto 0) <= 	(do_count(1 downto 0) & (6 downto 0=>'0'))
																				+ ((1 downto 0 =>'0') & do_count(3) & do_count(2) & "00000")
																				+ ((3 downto 0 =>'0') & do_count(5) & do_count(4) & "000")
																				+ ((5 downto 0 =>'0') & do_count(7) & do_count(8) & (do_count(9) xor do_count(8)));
					end case;
		end if;
	end process get_1024_addr;

		
end generate gen_1024_addr;
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
	gen_2048_addr : if(nps=2048) generate
			
get_2048_addr:process(clk,global_clock_enable,p_count,k_count)is
			 variable a : std_logic_vector(apr-1 downto 0) := (others=>'0');
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count(2 downto 0) is
						when "001" =>
							lp_cnt_en<='0';
							do_count <= (others=>'0');
							a:=k_count(1 downto 0)  & k_count(9 downto 2);
							rd_addr_a <= a(9 downto 0);
							rd_addr_b <= not(a(9)) & a(8 downto 0);
						when "010" =>
							lp_cnt_en<='0';
							do_count <= (others=>'0');
							a:=k_count(9 downto 8) & k_count(1 downto 0) & k_count(7 downto 6) & k_count(5 downto 4) & k_count(3 downto 2);						
							rd_addr_a <= a(9 downto 0);				
							rd_addr_b <= a(9 downto 8) & not(a(7)) & a(6 downto 0);							
						when "011" =>
						  lp_cnt_en<='0';
							do_count <= (others=>'0');
						  a:=k_count(9 downto 8) & k_count(7 downto 6) & k_count(1 downto 0) & k_count(5 downto 4)  & k_count(3 downto 2);						
							rd_addr_a <= a(9 downto 0);
							rd_addr_b <= a(9 downto 6) & not(a(5)) & a(4 downto 0);
						when "100" =>
						  lp_cnt_en<='0';
							do_count <= (others=>'0');
						  a:=k_count(9 downto 8) & k_count(7 downto 6) & k_count(5 downto 4) & k_count(1 downto 0) & k_count(3 downto 2);						
							rd_addr_a <= a(9 downto 0);
							rd_addr_b <= a(9 downto 4) & not(a(3)) & a(2 downto 0);
						when "101" =>
				 			lp_cnt_en<='0';
					 		do_count <= (others=>'0');
						  a:=k_count(9 downto 0);
						  rd_addr_a <= a(9 downto 0);
							rd_addr_b <= a(9 downto 2) & not(a(1)) & (a(0)) ;
						when "110" =>
				 			lp_cnt_en<='0';
					 		do_count <= (others=>'0');
						  a:=k_count(9 downto 0);
						  rd_addr_a <= a(9 downto 0);
							rd_addr_b <= a(9 downto 2) & not(a(1)) & (a(0)) ;
						when others => 
						  a:=(others=>'0');
						  if(k_count=int2ustd(1,apr)) then
						  	lp_cnt_en<='1';
						  else
						  	lp_cnt_en<=lp_cnt_en;
						  end if;
						  if(lp_cnt_en='1') then
						  	do_count <= do_count + int2ustd(1,apr+1);
						  else
						  	do_count <= (others=>'0');
						  end if;
						  rd_addr_a <= 	do_count(1 downto 0) & do_count(3 downto 2) & do_count(5 downto 4) & do_count(7 downto 6) & do_count(10) & do_count(8);
							rd_addr_b <= 	do_count(1 downto 0) & do_count(3 downto 2) & do_count(5 downto 4) & do_count(7 downto 6) & do_count(10) & do_count(8);
						end case;
					end if;
			end process get_2048_addr;
		
		end generate gen_2048_addr;

-----------------------------------------------------------------------------------------
--N=4096
-----------------------------------------------------------------------------------------
	gen_4096_addr : if(nps=4096) generate
			
get_4096_addr:process(clk,global_clock_enable,p_count,k_count)is
			 variable a : std_logic_vector(apr-1 downto 0) := (others=>'0');
			 --apr=11
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case p_count(2 downto 0) is
							when "001" =>
								lp_cnt_en<='0';						
								do_count <= (others=>'0');
								a:=k_count(1 downto 0) & k_count(10 downto 2);
								rd_addr_a <= a(10 downto 0);
								rd_addr_b <= not(a(10)) & a(9 downto 0);
							when "010" =>
								lp_cnt_en<='0';						
								do_count <= (others=>'0');
								a:=	k_count(10 downto 9)	& k_count(1 downto 0) & k_count(8 downto 2);
								rd_addr_a <= a(10 downto 0);				
								rd_addr_b <= a(10 downto 9) & not(a(8)) & a(7 downto 0);						
							when "011" =>
								lp_cnt_en<='0';						
								do_count <= (others=>'0');
							  a:=k_count(10 downto 7) & k_count(1 downto 0) & k_count(6 downto 2);
								rd_addr_a <= a(10 downto 0);
								rd_addr_b <= a(10 downto 7) & not(a(6)) & a(5 downto 0);
							when "100" =>
								lp_cnt_en<='0';						
								do_count <= (others=>'0');
							  a:=k_count(10 downto 5) & k_count(1 downto 0) & k_count(4 downto 2);
								rd_addr_a <= a(10 downto 0);
								rd_addr_b <= a(10 downto 5) & not(a(4)) & a(3 downto 0);
							when "101" =>
								lp_cnt_en<='0';						
								do_count <= (others=>'0');
							  a:=k_count(10 downto 3) & k_count(1 downto 0) & k_count(2);
								rd_addr_a <= a(10 downto 0);
								rd_addr_b <= a(10 downto 3) & not(a(2)) & a(1 downto 0);
							when "110" =>	
								lp_cnt_en<='0';						
						 		do_count <= (others=>'0');
							  rd_addr_a <= k_count(10 downto 2) & k_count(0) & (k_count(1) xor k_count(0));
								rd_addr_b <= k_count(10 downto 2) & not(k_count(0)) & not((k_count(1) xor k_count(0)));
							when others=>
							  a:=(others=>'0');
							  if(k_count=int2ustd(1,apr)) then
							  	lp_cnt_en<='1';
							  else
							  	lp_cnt_en<=lp_cnt_en;
							  end if;
							  if(lp_cnt_en='1') then
							  	do_count <= do_count + int2ustd(1,apr+1);
							  else
							  	do_count <= (others=>'0');
							  end if;
								rd_addr_a <= 	(do_count(1 downto 0) & (8 downto 0=>'0'))
																					+ ((1 downto 0 =>'0') & do_count(3) & do_count(2) & "0000000")
																					+ ((3 downto 0 =>'0') & do_count(5) & do_count(4) & "00000")
																					+ ((5 downto 0 =>'0') & do_count(7) & do_count(6) & "000")
																					+ ((7 downto 0 =>'0') & do_count(9) & do_count(10) & (do_count(11) xor do_count(10)));
																					
								rd_addr_b <= 	(do_count(1 downto 0) & (8 downto 0=>'0'))
																					+ ((1 downto 0 =>'0') & do_count(3) & do_count(2) & "0000000")
																					+ ((3 downto 0 =>'0') & do_count(5) & do_count(4) & "00000")
																					+ ((5 downto 0 =>'0') & do_count(7) & do_count(6) & "000")
																					+ ((7 downto 0 =>'0') & do_count(9) & do_count(10) & (do_count(11) xor do_count(10)));
					end case;
				end if;
			end process get_4096_addr;
		
		end generate gen_4096_addr;
		
-----------------------------------------------------------------------------------------------
-- N=8192
-----------------------------------------------------------------------------------------------
	gen_8192_addr : if(nps=8192) generate
			
get_8192_addr:process(clk,global_clock_enable,p_count,k_count)is
			 --apr=13
			 variable a : std_logic_vector(apr-1 downto 0) := (others=>'0');
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case p_count(2 downto 0) is
							when "001" =>
							lp_cnt_en<='0';
							do_count <= (others=>'0');
							a:=k_count(1 downto 0)  & k_count(11 downto 2);
							rd_addr_a <= a(11 downto 0);
							rd_addr_b <= not(a(11)) & a(10 downto 0);
						when "010" =>
							lp_cnt_en<='0';
							do_count <= (others=>'0');
							a:=k_count(11 downto 10) & k_count(1 downto 0) & k_count(9 downto 2) ;						
							rd_addr_a <= a(11 downto 0);				
							rd_addr_b <= a(11 downto 10) & not(a(9)) & a(8 downto 0);							
						when "011" =>
						  lp_cnt_en<='0';
							do_count <= (others=>'0');
						  a:=k_count(11 downto 8) & k_count(1 downto 0) & k_count(7 downto 2) ;						
							rd_addr_a <= a(11 downto 0);
							rd_addr_b <= a(11 downto 8) & not(a(7)) & a(6 downto 0);
						when "100" =>
						  lp_cnt_en<='0';
							do_count <= (others=>'0');
						  a:=k_count(11 downto 6) & k_count(1 downto 0) & k_count(5 downto 2) ;						
							rd_addr_a <= a(11 downto 0);
							rd_addr_b <= a(11 downto 6) & not(a(5)) & a(4 downto 0);
						when "101" =>
						  lp_cnt_en<='0';
							do_count <= (others=>'0');
						  a:=k_count(11 downto 4) & k_count(1 downto 0) & k_count(3 downto 2) ;						
							rd_addr_a <= a(11 downto 0);
							rd_addr_b <= a(11 downto 4) & not(a(3)) & a(2 downto 0);
						when "110" =>
				 			lp_cnt_en<='0';
					 		do_count <= (others=>'0');
						  a:=k_count(11 downto 0);
						  rd_addr_a <= a(11 downto 0);
							rd_addr_b <= a(11 downto 2) & not(a(1)) & (a(0)) ;
						when "111" =>
				 			lp_cnt_en<='0';
					 		do_count <= (others=>'0');
						  a:=k_count(11 downto 0);
						  rd_addr_a <= a(11 downto 0);
							rd_addr_b <= a(11 downto 2) & not(a(1)) & (a(0)) ;
						when others => 
						  a:=(others=>'0');
						  if(k_count=int2ustd(1,apr)) then
						  	lp_cnt_en<='1';
						  else
						  	lp_cnt_en<=lp_cnt_en;
						  end if;
						  if(lp_cnt_en='1') then
						  	do_count <= do_count + int2ustd(1,apr+1);
						  else
						  	do_count <= (others=>'0');
						  end if;
						  rd_addr_a <= 	do_count(1 downto 0) & do_count(3 downto 2) & do_count(5 downto 4) & do_count(7 downto 6) & do_count(9 downto 8) & do_count(12) & do_count(10);
							rd_addr_b <= 	do_count(1 downto 0) & do_count(3 downto 2) & do_count(5 downto 4) & do_count(7 downto 6) & do_count(9 downto 8) & do_count(12) & do_count(10);
						end case;
				end if;
			end process get_8192_addr;
		
		end generate gen_8192_addr;
-----------------------------------------------------------------------------------------------
-- N=16384
-----------------------------------------------------------------------------------------------
	gen_16384_addr : if(nps=16384) generate
			
get_16384_addr:process(clk,global_clock_enable,p_count,k_count)is
			 variable a : std_logic_vector(apr-1 downto 0) := (others=>'0');
			 --apr=13
				begin
if((rising_edge(clk) and global_clock_enable='1'))then
						case p_count(2 downto 0) is
							when "001" =>
								lp_cnt_en<='0';						
								do_count <= (others=>'0');
								a:=k_count(1 downto 0) & k_count(12 downto 2);
								rd_addr_a <= a(12 downto 0);
								rd_addr_b <= not(a(12)) & a(11 downto 0);
							when "010" =>
								do_count <= (others=>'0');
								a:=	k_count(12 downto 11)	& k_count(1 downto 0) & k_count(10 downto 2);
								rd_addr_a <= a(12 downto 0);				
								rd_addr_b <= a(12 downto 11) & not(a(10)) & a(9 downto 0);						
							when "011" =>
								do_count <= (others=>'0');
							  a:=k_count(12 downto 9) & k_count(1 downto 0) & k_count(8 downto 2);
								rd_addr_a <= a(12 downto 0);
								rd_addr_b <= a(12 downto 9) & not(a(8)) & a(7 downto 0);
							when "100" =>
								do_count <= (others=>'0');
							  a:=k_count(12 downto 7) & k_count(1 downto 0) & k_count(6 downto 2);
								rd_addr_a <= a(12 downto 0);
								rd_addr_b <= a(12 downto 7) & not(a(6)) & a(5 downto 0);
							when "101" =>
								do_count <= (others=>'0');
							  a:=k_count(12 downto 5) & k_count(1 downto 0) & k_count(4 downto 2);
								rd_addr_a <= a(12 downto 0);
								rd_addr_b <= a(12 downto 5) & not(a(4)) & a(3 downto 0);
							when "110" =>
								do_count <= (others=>'0');
							  a:=k_count(12 downto 3) & k_count(1 downto 0) & k_count(2);
								rd_addr_a <= a(12 downto 0);
								rd_addr_b <= a(12 downto 3) & not(a(2)) & a(1 downto 0);
							when "111" =>	
						 		do_count <= (others=>'0');
							  rd_addr_a <= k_count(12 downto 2) & k_count(0) & (k_count(1) xor k_count(0));
								rd_addr_b <= k_count(12 downto 2) & not(k_count(0)) & not((k_count(1) xor k_count(0)));
							when others=>
							  a:=(others=>'0');
								if(k_count=int2ustd(1,apr)) then
							  	lp_cnt_en<='1';
							  else
							  	lp_cnt_en<=lp_cnt_en;
							  end if;
							  if(lp_cnt_en='1') then
							  	do_count <= do_count + int2ustd(1,apr+1);
							  else
							  	do_count <= (others=>'0');
							  end if;								
							  rd_addr_a <= 	(do_count(1 downto 0) & (10 downto 0=>'0'))
																					+ ((1 downto 0 =>'0') & do_count(3) & do_count(2) & "000000000")
																					+ ((3 downto 0 =>'0') & do_count(5) & do_count(4) & "0000000")
																					+ ((5 downto 0 =>'0') & do_count(7) & do_count(6) & "00000")
																					+ ((7 downto 0 =>'0') & do_count(9) & do_count(8) & "000")
																					+ ((9 downto 0 =>'0') & do_count(11) & do_count(12) & (do_count(13) xor do_count(12)));
																					
								rd_addr_b <= 	(do_count(1 downto 0) & (10 downto 0=>'0'))
																					+ ((1 downto 0 =>'0') & do_count(3) & do_count(2) & "000000000")
																					+ ((3 downto 0 =>'0') & do_count(5) & do_count(4) & "0000000")
																					+ ((5 downto 0 =>'0') & do_count(7) & do_count(6) & "00000")
																					+ ((7 downto 0 =>'0') & do_count(9) & do_count(8) & "000")
																					+ ((9 downto 0 =>'0') & do_count(11) & do_count(12) & (do_count(13) xor do_count(12)));
							
					end case;
				end if;
			end process get_16384_addr;
		
		end generate gen_16384_addr;

-----------------------------------------------------------------------------------------------
-- N=32768
-----------------------------------------------------------------------------------------------
gen_32768_addr : if(nps=32768) generate
get_32768_addr:process(clk,global_clock_enable,p_count,k_count)is
    variable a : std_logic_vector(apr-1 downto 0) := (others=>'0');
	begin
        if((rising_edge(clk) and global_clock_enable='1'))then
            case p_count(3 downto 0) is
			    when "0001" =>
                    lp_cnt_en<='0';
                    do_count <= (others=>'0');
                    a:=k_count(1 downto 0)  & k_count(13 downto 2);
                    rd_addr_a <= a(13 downto 0);
                    rd_addr_b <= not(a(13)) & a(12 downto 0);
                when "0010" =>
                    lp_cnt_en<='0';
                    do_count <= (others=>'0');
                    a:=k_count(13 downto 12) & k_count(1 downto 0) & k_count(11 downto 2);
                    rd_addr_a <= a(13 downto 0);
					rd_addr_b <= a(13 downto 12) & not(a(11)) & a(10 downto 0);
                when "0011" =>
                    lp_cnt_en<='0';
                    do_count <= (others=>'0');
                    a:=k_count(13 downto 10) & k_count(1 downto 0) & k_count(9 downto 2);
                    rd_addr_a <= a(13 downto 0);
                    rd_addr_b <= a(13 downto 10) & not(a(9)) & a(8 downto 0);
                when "0100" =>
                    lp_cnt_en<='0';
                    do_count <= (others=>'0');
                    a:=k_count(13 downto 8) & k_count(1 downto 0) & k_count(7 downto 2);
                    rd_addr_a <= a(13 downto 0);
                    rd_addr_b <= a(13 downto 8) & not(a(7)) & a(6 downto 0);
                when "0101" =>
                    lp_cnt_en<='0';
                    do_count <= (others=>'0');
                    a:=k_count(13 downto 6) & k_count(1 downto 0) & k_count(5 downto 2);
                    rd_addr_a <= a(13 downto 0);
                    rd_addr_b <= a(13 downto 6) & not(a(5)) & a(4 downto 0);
                when "0110" =>
                    lp_cnt_en<='0';
                    do_count <= (others=>'0');
                    a:=k_count(13 downto 4) & k_count(1 downto 0) & k_count(3 downto 2);
                    rd_addr_a <= a(13 downto 0);
                    rd_addr_b <= a(13 downto 4) & not(a(3)) & a(2 downto 0);
                when "0111" =>
                    lp_cnt_en<='0';
                    do_count <= (others=>'0');
                    a:=k_count(13 downto 0);
                    rd_addr_a <= a(13 downto 0);
                    rd_addr_b <= a(13 downto 2) & not(a(1)) & (a(0));
                when "1000" =>
                	lp_cnt_en<='0';
                    do_count <= (others=>'0');
                    a:=k_count(13 downto 0);
                    rd_addr_a <= a(13 downto 0);
                    rd_addr_b <= a(13 downto 2) & not(a(1)) & (a(0));
                when others => 
                    a:=(others=>'0');
                    if(k_count=int2ustd(1,apr)) then
                        lp_cnt_en<='1';
                    else
                      	lp_cnt_en<=lp_cnt_en;
                    end if;
                    if(lp_cnt_en='1') then
                        do_count <= do_count + int2ustd(1,apr+1);
                    else
                        do_count <= (others=>'0');
                    end if;
                    rd_addr_a <= 	do_count(1 downto 0) & do_count(3 downto 2) & do_count(5 downto 4) & do_count(7 downto 6) & do_count(9 downto 8) & do_count(11 downto 10) & do_count(14) & do_count(12);
                    rd_addr_b <= 	do_count(1 downto 0) & do_count(3 downto 2) & do_count(5 downto 4) & do_count(7 downto 6) & do_count(9 downto 8) & do_count(11 downto 10) & do_count(14) & do_count(12);
            end case;
        end if;
    end process get_32768_addr;
end generate gen_32768_addr;

-----------------------------------------------------------------------------------------------
-- N=65536
-----------------------------------------------------------------------------------------------
gen_65536_addr : if(nps=65536) generate
get_65536_addr:process(clk,global_clock_enable,p_count,k_count)is
    variable a : std_logic_vector(apr-1 downto 0) := (others=>'0');
    begin
        if((rising_edge(clk) and global_clock_enable='1'))then
            case p_count(3 downto 0) is
                when "0001" =>
                    lp_cnt_en<='0';
                    do_count <= (others=>'0');
                    a:=k_count(1 downto 0) & k_count(14 downto 2);
                    rd_addr_a <= a(14 downto 0);
                    rd_addr_b <= not(a(14)) & a(13 downto 0);
                when "0010" =>
                    do_count <= (others=>'0');
                    a:=	k_count(14 downto 13)	& k_count(1 downto 0) & k_count(12 downto 2);
                    rd_addr_a <= a(14 downto 0);				
                    rd_addr_b <= a(14 downto 13) & not(a(12)) & a(11 downto 0);
                when "0011" =>
                	do_count <= (others=>'0');
                    a:=k_count(14 downto 11) & k_count(1 downto 0) & k_count(10 downto 2);
                    rd_addr_a <= a(14 downto 0);
                    rd_addr_b <= a(14 downto 11) & not(a(10)) & a(9 downto 0);
                when "0100" =>
                	do_count <= (others=>'0');
                    a:=k_count(14 downto 9) & k_count(1 downto 0) & k_count(8 downto 2);
                    rd_addr_a <= a(14 downto 0);
                    rd_addr_b <= a(14 downto 9) & not(a(8)) & a(7 downto 0);
                when "0101" =>
                    do_count <= (others=>'0');
                    a:=k_count(14 downto 7) & k_count(1 downto 0) & k_count(6 downto 2);
                    rd_addr_a <= a(14 downto 0);
                    rd_addr_b <= a(14 downto 7) & not(a(6)) & a(5 downto 0);
                when "0110" =>
                    do_count <= (others=>'0');
                    a:=k_count(14 downto 5) & k_count(1 downto 0) & k_count(4 downto 2);
                    rd_addr_a <= a(14 downto 0);
                    rd_addr_b <= a(14 downto 5) & not(a(4)) & a(3 downto 0);
                when "0111" =>
                    do_count <= (others=>'0');
                    a:=k_count(14 downto 3) & k_count(1 downto 0) & k_count(2);
                    rd_addr_a <= a(14 downto 0);
                    rd_addr_b <= a(14 downto 3) & not(a(2)) & a(1 downto 0);
                when "1000" =>	
                	do_count <= (others=>'0');
                    rd_addr_a <= k_count(14 downto 2) & k_count(0) & (k_count(1) xor k_count(0));
                    rd_addr_b <= k_count(14 downto 2) & not(k_count(0)) & not((k_count(1) xor k_count(0)));
                when others=>
                    a:=(others=>'0');
                    if(k_count=int2ustd(1,apr)) then
                        lp_cnt_en<='1';
                    else
                      	lp_cnt_en<=lp_cnt_en;
                    end if;
                    if(lp_cnt_en='1') then
                    	do_count <= do_count + int2ustd(1,apr+1);
                    else
                    	do_count <= (others=>'0');
                    end if;
                    rd_addr_a <= 	(do_count(1 downto 0) & (12 downto 0=>'0'))
                                    + ((1 downto 0 =>'0') & do_count(3) & do_count(2) & "00000000000")
                                    + ((3 downto 0 =>'0') & do_count(5) & do_count(4) & "000000000")
                                    + ((5 downto 0 =>'0') & do_count(7) & do_count(6) & "0000000")
                                    + ((7 downto 0 =>'0') & do_count(9) & do_count(8) & "00000")
                                    + ((9 downto 0 =>'0') & do_count(11) & do_count(10) & "000")
                                    + ((11 downto 0 =>'0') & do_count(13) & do_count(14) & (do_count(15) xor do_count(14)));
                    rd_addr_b <= 	(do_count(1 downto 0) & (12 downto 0=>'0'))
                                    + ((1 downto 0 =>'0') & do_count(3) & do_count(2) & "00000000000")
                                    + ((3 downto 0 =>'0') & do_count(5) & do_count(4) & "000000000")
                                    + ((5 downto 0 =>'0') & do_count(7) & do_count(6) & "0000000")
                                    + ((7 downto 0 =>'0') & do_count(9) & do_count(8) & "00000")
                                    + ((9 downto 0 =>'0') & do_count(11) & do_count(10) & "000")
                                    + ((11 downto 0 =>'0') & do_count(13) & do_count(14) & (do_count(15) xor do_count(14)));
            end case;
        end if;
    end process get_65536_addr;
end generate gen_65536_addr;
		
end generate gen_de_addr;

end generate gen_single_output;


end;

			
