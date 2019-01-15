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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_lpprdadr2gen.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
-- Read address generation for Last-Pass Processor is fixed for each N
library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
--use ieee.std_logic_arith.all; 
use work.fft_pack.all;

entity asj_fft_lpprdadr2gen is
	generic(
						nps : integer :=4096;
						nume : integer :=2;
						arch : integer :=0;
						mram : integer :=0;
						n_passes : integer :=5;
						log2_n_passes : integer:= 3;
						apr : integer :=10
					);
	port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
						reset           : in std_logic;
						lpp_en 					: in std_logic;
						data_rdy 				: in std_logic;
						rd_addr_a				: out std_logic_vector(apr-1 downto 0);
						rd_addr_b				: out std_logic_vector(apr-1 downto 0);
						sw_data_read    : out std_logic_vector(1 downto 0);
						mid_point      : out std_logic;
						sw_addr_read    : out std_logic_vector(1 downto 0);
						-- Quad Engine select signal 
						qe_select			 : out std_logic_vector(1 downto 0);
						en              : out std_logic
			);
end asj_fft_lpprdadr2gen;

architecture gen_all of asj_fft_lpprdadr2gen is

constant apri 			: integer := apr + nume +1;
constant apri_qe 		: integer := apr + 4;
constant apri_mram 	: integer := apr + 2;
signal sw 					: std_logic_vector(1 downto 0);
signal swd    			: std_logic_vector(1 downto 0); 
signal en_i 				: std_logic;
signal en_d 				: std_logic;
signal count 				: std_logic_vector(apri-1 downto 0);
signal count_qe 		: std_logic_vector(apri_qe-1 downto 0);

signal count_mram 	: std_logic_vector(apri_mram-1 downto 0);
signal sw_mram      : std_logic_vector(1 downto 0);
signal count_rst 		: std_logic ;


begin



edge_detect:process(clk,global_clock_enable,lpp_en)
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			if(reset='1') then
				en_d <= '1';
			else
				en_d <= lpp_en;
			end if;
		end if;
	end process edge_detect;

	
reg_edge:process(clk,global_clock_enable,en_d,lpp_en)
		begin                                         
if((rising_edge(clk) and global_clock_enable='1'))then
				if(reset='1') then
					en_i <= '0';
				else               
					en_i <= (lpp_en xor en_d) and lpp_en;     
				end if;
			end if;                                     
		end process reg_edge;             
	
	
	delay_en : asj_fft_tdl_bit_rst
			generic map( 
								 		del   => 5
								)
				port map( 	
global_clock_enable => global_clock_enable,
										clk 	=> clk,
										reset => reset,
										data_in 	=> en_i,
						 				data_out 	=> en
						);
						

	gen_M4K : if(mram=0) generate
	-----------------------------------------------------------------------------------------------
	-- Single/Dual Engine Counter
	-----------------------------------------------------------------------------------------------
	gen_se_de : if(nume=1 or nume=2) generate
	
counter:process(clk,global_clock_enable,en_i,reset)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1' or en_i='1') then
						count <= (apri-1 downto 0 => '0');
					else
						count <=count+int2ustd(1,apri);
					end if;
				end if;
			end process counter;
	end generate gen_se_de;
	-----------------------------------------------------------------------------------------------
	-- Quad Engine Counter
	-----------------------------------------------------------------------------------------------
	gen_qe : if(nume=4) generate
	
counter:process(clk,global_clock_enable,en_i,reset)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1' or en_i='1') then
						count_qe <= (apri_qe-1 downto 0 => '0');
					else
						count_qe <=count_qe+int2ustd(1,apri_qe);
					end if;
				end if;
			end process counter;
			
	end generate gen_qe;
	
-- Delay required for data switch output
-- due to latency between address generation based on count
-- and data being input to the switch
delay_swd : asj_fft_tdl_rst 
		generic map( 
							 		mpr   => 2,
							 		del   => 5
							)
			port map( 	
global_clock_enable => global_clock_enable,
									clk 	=> clk,
									reset => reset,
									data_in 	=> sw,
					 				data_out 	=> sw_data_read
					);


sw_addr_read <= sw;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-- Single Engine Address Generation
-----------------------------------------------------------------------------------------------
gen_se_addr : if(nume=1) generate

qe_select	<="00";


gen_32_addr : if(nps=32) generate

get_32_sw:process(clk,global_clock_enable,count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			sw <= count(1 downto 0)+count(3 downto 2)+('0' & count(4) );
			mid_point <= count(4);
		end if;
	end process get_32_sw;
	
get_32_addr:process(clk,global_clock_enable,count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
  			rd_addr_a <=  (count(4 downto 2) );
				rd_addr_b <=  (count(4 downto 2) ) + int2ustd(4,apr);
			end if;
		end process get_32_addr;
		
end generate gen_32_addr;

gen_128_addr : if(nps=128) generate

get_128_sw:process(clk,global_clock_enable,count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			--sw =  mod(k+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256)+floor(k/1024)+floor(k/4096)+floor(k/16384), 4)+1;
			sw <= count(1 downto 0)+count(3 downto 2)+count(5 downto 4)+('0' & count(6) );
			mid_point <= count(6);
		end if;
	end process get_128_sw;
	
get_128_addr:process(clk,global_clock_enable,count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--offsetr2(1) = mod(floor(k/4),n_by_4)+ 1;
  			--offsetr2(2) = mod(offsetr2(1) - 1 + n_by_8,n_by_4) + 1;
  			rd_addr_a <=  (count(6 downto 2) );
				rd_addr_b <=  (count(6 downto 2) ) + int2ustd(16,apr);
			end if;
		end process get_128_addr;
		
end generate gen_128_addr;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

gen_512_addr : if(nps=512) generate

get_512_sw:process(clk,global_clock_enable,count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
		  ----sw =  mod(k+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256)+floor(k/1024)+floor(k/4096)+floor(k/16384), 4)+1;
			sw <= count(1 downto 0)+count(3 downto 2)+count(5 downto 4)+count(7 downto 6) + ('0' & count(8));
			mid_point <= count(8);
		end if;
	end process get_512_sw;
	
get_512_addr:process(clk,global_clock_enable,count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--offsetr2(1) = mod(floor(k/4),n_by_4)+ 1;
  			--offsetr2(2) = mod(offsetr2(1) - 1 + n_by_8,n_by_4) + 1;
				rd_addr_a <=  (count(8 downto 2) );
				rd_addr_b <=  (count(8 downto 2) ) + int2ustd(64,apr);
			end if;
	end process get_512_addr;

end generate gen_512_addr;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

gen_2048_addr : if(nps=2048) generate

get_2048_sw:process(clk,global_clock_enable,count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			sw <= count(1 downto 0)+count(3 downto 2)+count(5 downto 4)+count(7 downto 6)+count(9 downto 8) + ('0' & count(10));
			mid_point <= count(10);
		end if;
	end process get_2048_sw;
	
get_2048_addr:process(clk,global_clock_enable,count)is
	 begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--offsetr2(1) = mod(floor(k/4),n_by_4)+ 1;
  			--offsetr2(2) = mod(offsetr2(1) - 1 + n_by_8,n_by_4) + 1;
				rd_addr_a <=  (count(10 downto 2) );
				rd_addr_b <=  (count(10 downto 2) ) + int2ustd(256,apr);
		end if;
	end process get_2048_addr;
		
end generate gen_2048_addr;
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
gen_8192_addr : if(nps=8192) generate

get_8192_sw:process(clk,global_clock_enable,count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			sw <= count(1 downto 0)+count(3 downto 2)+count(5 downto 4)+count(7 downto 6)+count(9 downto 8) + count(11 downto 10) + ('0' & count(12));
			mid_point <= count(12);
		end if;
	end process get_8192_sw;
	
get_8192_addr:process(clk,global_clock_enable,count)is
	 begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--offsetr2(1) = mod(floor(k/4),n_by_4)+ 1;
  			--offsetr2(2) = mod(offsetr2(1) - 1 + n_by_8,n_by_4) + 1;
				rd_addr_a <=  (count(12 downto 2) );
				rd_addr_b <=  (count(12 downto 2) ) + int2ustd(1024,apr);
		end if;
	end process get_8192_addr;
		
end generate gen_8192_addr;
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
gen_32768_addr : if(nps=32768) generate

get_32768_sw:process(clk,global_clock_enable,count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			sw <= count(1 downto 0)+count(3 downto 2)+count(5 downto 4)+count(7 downto 6)+count(9 downto 8) + count(11 downto 10) + count(13 downto 12) + ('0' & count(14));
			mid_point <= count(14);
		end if;
	end process get_32768_sw;
	
get_32768_addr:process(clk,global_clock_enable,count)is
	 begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--offsetr2(1) = mod(floor(k/4),n_by_4)+ 1;
  			--offsetr2(2) = mod(offsetr2(1) - 1 + n_by_8,n_by_4) + 1;
				rd_addr_a <=  (count(14 downto 2) );
				rd_addr_b <=  (count(14 downto 2) ) + int2ustd(4096,apr);
		end if;
	end process get_32768_addr;
		
end generate gen_32768_addr;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
gen_131072_addr : if(nps=131072) generate

get_131072_sw:process(clk,global_clock_enable,count)is
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
        sw <= count(1 downto 0) + count(3 downto 2) + count(5 downto 4) + count(7 downto 6) + count(9 downto 8) + count(11 downto 10) + count(13 downto 12) + count(15 downto 14) + ('0' & count(16));
        mid_point <= count(16);
	end if;
end process get_131072_sw;
	
get_131072_addr:process(clk,global_clock_enable,count)is
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
        rd_addr_a <=  (count(16 downto 2) );
        rd_addr_b <=  (count(16 downto 2) ) + int2ustd(16384,apr);
	end if;
end process get_131072_addr;
		
end generate gen_131072_addr;

end generate gen_se_addr;



-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- Dual Engine Address Generation
-----------------------------------------------------------------------------------------------

gen_de_addr : if(nume=2) generate

mid_point <= '0';        
qe_select	<="00";
-----------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------
	gen_128_addr : if(nps=128) generate
	
get_128_sw:process(clk,global_clock_enable,count)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--sw =  mod(k+floor(k/4)+floor(k/16), 4)+1;
				sw <= count(1 downto 0)+count(3 downto 2)+count(5 downto 4);
			end if;
		end process get_128_sw;
		
		
get_128_addr:process(clk,global_clock_enable,count)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
				  --offsetr2(1) = mod(floor(k/4),n_by_8)+ 1;
					rd_addr_a <=  (count(5 downto 2) );
					rd_addr_b <=  (count(5 downto 2) );
				end if;
		end process get_128_addr;
	
	end generate gen_128_addr;
	
-----------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------
	gen_512_addr : if(nps=512) generate
	
get_512_sw:process(clk,global_clock_enable,count)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--sw =  mod(k+floor(k/4)+floor(k/16)+floor(k/64), 4)+1;
				sw <= count(1 downto 0)+count(3 downto 2)+count(5 downto 4)+count(7 downto 6);
			end if;
		end process get_512_sw;
		
		
get_512_addr:process(clk,global_clock_enable,count)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
				  --offsetr2(1) = mod(floor(k/4),n_by_8)+ 1;
					rd_addr_a <=  (count(7 downto 2) );
					rd_addr_b <=  (count(7 downto 2) );
				end if;
		end process get_512_addr;
	
	end generate gen_512_addr;
	
-----------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------
	gen_2048_addr : if(nps=2048) generate
	
get_2048_sw:process(clk,global_clock_enable,count)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw <= count(1 downto 0)+count(3 downto 2)+count(5 downto 4)+count(7 downto 6)+count(9 downto 8);
			end if;
		end process get_2048_sw;
		
		
get_2048_addr:process(clk,global_clock_enable,count)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					rd_addr_a <=  (count(9 downto 2) );
					rd_addr_b <=  (count(9 downto 2) );
				end if;
		end process get_2048_addr;
	
	end generate gen_2048_addr;
-----------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------
	gen_8192_addr : if(nps=8192) generate
	
get_8192_sw:process(clk,global_clock_enable,count)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw <= count(1 downto 0)+count(3 downto 2)+count(5 downto 4)+count(7 downto 6)+count(9 downto 8)+count(11 downto 10);
			end if;
		end process get_8192_sw;
		
		
get_8192_addr:process(clk,global_clock_enable,count)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					rd_addr_a <=  (count(11 downto 2) );
					rd_addr_b <=  (count(11 downto 2) );
				end if;
		end process get_8192_addr;
	
	end generate gen_8192_addr;
	
-----------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------
	gen_32768_addr : if(nps=32768) generate
	
get_32768_sw:process(clk,global_clock_enable,count)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw <= count(1 downto 0)+count(3 downto 2)+count(5 downto 4)+count(7 downto 6)+count(9 downto 8)+count(11 downto 10)+count(13 downto 12);
			end if;
		end process get_32768_sw;
		
		
get_32768_addr:process(clk,global_clock_enable,count)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					rd_addr_a <=  (count(13 downto 2) );
					rd_addr_b <=  (count(13 downto 2) );
				end if;
		end process get_32768_addr;
	
	end generate gen_32768_addr;
-----------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------	
gen_131072_addr : if(nps=131072) generate
	
get_131072_sw:process(clk,global_clock_enable,count)is
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
        sw <= count(1 downto 0) + count(3 downto 2) + count(5 downto 4) + count(7 downto 6) + count(9 downto 8) + count(11 downto 10) + count(13 downto 12) + count(15 downto 14);
	end if;
end process get_131072_sw;
		
get_131072_addr:process(clk,global_clock_enable,count)
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
	    rd_addr_a <=  (count(15 downto 2) );
		rd_addr_b <=  (count(15 downto 2) );
	end if;
end process get_131072_addr;
	
end generate gen_131072_addr;

end generate gen_de_addr;

-----------------------------------------------------------------------------------------------
-- Quad Engine LPP Read Address Generator
-----------------------------------------------------------------------------------------------
gen_qe_addr : if(nume=4) generate

mid_point <= '0';
-----------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------
	gen_128_addr : if(nps=128) generate
	
get_128_sw:process(clk,global_clock_enable,count)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--sw =  mod(k+floor(k/4)+floor(k/16), 4)+1;
				sw <= count_qe(1 downto 0)+count_qe(3 downto 2)+count_qe(5 downto 4);
			end if;
		end process get_128_sw;
		
		
get_128_addr:process(clk,global_clock_enable,count_qe)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
				  --offsetr2(1) = mod(floor(k/4),n_by_8)+ 1;
					rd_addr_a <=  (count_qe(5 downto 2) );
					rd_addr_b <=  (count_qe(5 downto 2) );
				end if;
		end process get_128_addr;
	
	end generate gen_128_addr;
	
-----------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------
	gen_512_addr : if(nps=512) generate
	
get_512_sw:process(clk,global_clock_enable,count_qe)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--sw =  mod(k+floor(k/4)+floor(k/16)+floor(k/64), 4)+1;
				sw <= count_qe(1 downto 0)+count_qe(3 downto 2)+count_qe(5 downto 4);--+count_qe(7 downto 6);
				qe_select	<=count_qe(7 downto 6);
			end if;
		end process get_512_sw;
		
		
get_512_addr:process(clk,global_clock_enable,count_qe)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
				  --offsetr2(1) = mod(floor(k/4),n_by_8)+ 1;
					rd_addr_a <=  (((count_qe(0) xor count_qe(2)) xor count_qe(4)) & count_qe(5 downto 2));-- + ('0' & count_qe(7) & "000"));
					rd_addr_b <=  (((count_qe(0) xor count_qe(2)) xor count_qe(4)) & count_qe(5 downto 2)) + int2ustd(16,apr);
				end if;
		end process get_512_addr;
	
	end generate gen_512_addr;
	
-----------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------
	gen_2048_addr : if(nps=2048) generate
	
	
get_2048_sw:process(clk,global_clock_enable,count_qe)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--sw =  mod(k+floor(k/4)+floor(k/16)+floor(k/64), 4)+1;
				sw <= count_qe(1 downto 0)+count_qe(3 downto 2)+count_qe(5 downto 4)+count_qe(7 downto 6);
				qe_select	<=count_qe(9 downto 8);
			end if;
		end process get_2048_sw;
		
		
get_2048_addr:process(clk,global_clock_enable,count_qe)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
				  --offsetr2(1) = mod(floor(k/4),n_by_8)+ 1;
					rd_addr_a <=  (((count_qe(0) xor count_qe(2)) xor (count_qe(4) xor count_qe(6))) & count_qe(7 downto 2));-- + ('0' & count_qe(7) & "000"));
					rd_addr_b <=  (((count_qe(0) xor count_qe(2)) xor (count_qe(4) xor count_qe(6))) & count_qe(7 downto 2)) + int2ustd(64,apr);
				end if;
		end process get_2048_addr;
	
	
	end generate gen_2048_addr;
-----------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------
	gen_8192_addr : if(nps=8192) generate
	
get_8192_sw:process(clk,global_clock_enable,count_qe)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw <= count_qe(1 downto 0)+count_qe(3 downto 2)+count_qe(5 downto 4)+count_qe(7 downto 6)+count_qe(9 downto 8);
				qe_select <= count_qe(11 downto 10);
			end if;
		end process get_8192_sw;
		
		
get_8192_addr:process(clk,global_clock_enable,count_qe)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
				  --offsetr2(1) = mod(floor(k/4),n_by_8)+ 1;
					rd_addr_a <=  (((count_qe(0) xor count_qe(2)) xor (count_qe(4) xor count_qe(6) xor count_qe(8))) & count_qe(9 downto 2));-- + ('0' & count_qe(7) & "000"));
					rd_addr_b <=  (((count_qe(0) xor count_qe(2)) xor (count_qe(4) xor count_qe(6) xor count_qe(8))) & count_qe(9 downto 2)) + int2ustd(256,apr);
				end if;
		end process get_8192_addr;
	
	end generate gen_8192_addr;
	
-----------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------
	gen_32768_addr : if(nps=32768) generate
	
get_32768_sw:process(clk,global_clock_enable,count_qe)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw <= count_qe(1 downto 0)+count_qe(3 downto 2)+count_qe(5 downto 4)+count_qe(7 downto 6)+count_qe(9 downto 8)+count_qe(11 downto 10);
				qe_select <= count_qe(13 downto 12);
			end if;
		end process get_32768_sw;
		
		
get_32768_addr:process(clk,global_clock_enable,count_qe)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					rd_addr_a <=  (((count_qe(0) xor count_qe(2)) xor (count_qe(4) xor count_qe(6)) xor (count_qe(8) xor count_qe(10))) & count_qe(11 downto 2));
					rd_addr_b <=  (((count_qe(0) xor count_qe(2)) xor (count_qe(4) xor count_qe(6)) xor (count_qe(8) xor count_qe(10))) & count_qe(11 downto 2)) + int2ustd(1024,apr);
				end if;
		end process get_32768_addr;
	
	end generate gen_32768_addr;

-----------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------
gen_131072_addr : if(nps=131072) generate
	
get_131072_sw:process(clk,global_clock_enable,count_qe)is
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
	    sw <= count_qe(1 downto 0)+count_qe(3 downto 2)+count_qe(5 downto 4)+count_qe(7 downto 6)+count_qe(9 downto 8)+count_qe(11 downto 10)+count_qe(13 downto 12);
	end if;
end process get_131072_sw;
		
get_131072_addr:process(clk,global_clock_enable,count_qe)
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
	    rd_addr_a <=  (count_qe(13 downto 2) );
		rd_addr_b <=  (count_qe(13 downto 2) );
	end if;
end process get_131072_addr;
	
end generate gen_131072_addr;

end generate gen_qe_addr;





end generate gen_M4K;

-----------------------------------------------------------------------------------------------
-- MegaRam Last Pass
-----------------------------------------------------------------------------------------------
gen_Mega : if(mram=1) generate

	
		
counter:process(clk,global_clock_enable,en_i,reset)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				if(reset='1' or en_i='1') then
					count_mram <= (others=> '0');
				else
					count_mram <=count_mram+int2ustd(1,apri_mram);
				end if;
			end if;
		end process counter;
	
	-- Delay required for data switch output
	-- due to latency between address generation based on count
	-- and data being input to the switch
	delay_swd : asj_fft_tdl_rst 
			generic map( 
								 		mpr   => 2,
								 		del   => 5
								)
				port map( 	
global_clock_enable => global_clock_enable,
										clk 	=> clk,
										reset => reset,
										data_in 	=> sw,
						 				data_out 	=> sw_data_read
						);
	
	
	sw_addr_read <= sw(1 downto 0);
	-----------------------------------------------------------------------------------------------
	--
	-----------------------------------------------------------------------------------------------
	gen_2048 : if(nps=2048) generate
get_2048_sw:process(clk,global_clock_enable,count_mram)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
				  -- sel_bank = mod(floor(mod(k,n_by_4)/n_by_16)+floor(k/n_by_4),2);
					sw <= count_mram(1 downto 0)+count_mram(3 downto 2)+count_mram(5 downto 4)+count_mram(7 downto 6)+count_mram(9 downto 8);
				end if;
			end process get_2048_sw;
			
get_2048_swd:process(clk,global_clock_enable,count_mram)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
				  -- sel_bank = mod(floor(mod(k,n_by_4)/n_by_16)+floor(k/n_by_4),2);
					mid_point <= count_mram(apri_mram-1);
				end if;
			end process get_2048_swd;
			
		sw_mram <= (count_mram(1) & count_mram(0)) + (count_mram(3) & count_mram(2))+(count_mram(5) & count_mram(4))+(count_mram(7) & count_mram(6));
			
get_2048_addr:process(clk,global_clock_enable,count_mram)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					rd_addr_a(apr-1 downto apr-2) <=sw_mram(1 downto 0) + (sw_mram(0) & '0');
					rd_addr_a(apr-3 downto 0) <=  count_mram(apri_mram-3 downto 2);
					rd_addr_b <=  (others=>'0');
				end if;
			end process get_2048_addr;
	end generate gen_2048;
	
	-----------------------------------------------------------------------------------------------
	--
	-----------------------------------------------------------------------------------------------
	gen_8192 : if(nps=8192) generate
get_8192_sw:process(clk,global_clock_enable,count_mram)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
				  -- sel_bank = mod(floor(mod(k,n_by_4)/n_by_16)+floor(k/n_by_4),2);
					sw <= count_mram(1 downto 0)+count_mram(3 downto 2)+count_mram(5 downto 4)+count_mram(7 downto 6)+count_mram(9 downto 8)+count_mram(11 downto 10);
				end if;
			end process get_8192_sw;
			
get_8192_swd:process(clk,global_clock_enable,count_mram)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
				  -- sel_bank = mod(floor(mod(k,n_by_4)/n_by_16)+floor(k/n_by_4),2);
					mid_point <= count_mram(apri_mram-1);
				end if;
			end process get_8192_swd;
			
		sw_mram <= count_mram(1 downto 0)+count_mram(3 downto 2)+count_mram(5 downto 4)+count_mram(7 downto 6)+count_mram(9 downto 8);
			
get_8192_addr:process(clk,global_clock_enable,count_mram)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					rd_addr_a(apr-1 downto apr-2) <=sw_mram(1 downto 0) + (sw_mram(0) & '0');
					rd_addr_a(apr-3 downto 0) <=  count_mram(apri_mram-3 downto 2);
					rd_addr_b <=  (others=>'0');
				end if;
			end process get_8192_addr;
	end generate gen_8192;
		
-----------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------
gen_32768 : if(nps=32768) generate
get_32768_sw:process(clk,global_clock_enable,count_mram)is
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
		sw <= count_mram(1 downto 0) + count_mram(3 downto 2) + count_mram(5 downto 4) + count_mram(7 downto 6) + count_mram(9 downto 8) + count_mram(11 downto 10) + count_mram(13 downto 12);
	end if;
end process get_32768_sw;
			
get_32768_swd:process(clk,global_clock_enable,count_mram)is
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
	    mid_point <= count_mram(apri_mram-1);
    end if;
end process get_32768_swd;
			
sw_mram <= count_mram(1 downto 0) + count_mram(3 downto 2) + count_mram(5 downto 4) + count_mram(7 downto 6) + count_mram(9 downto 8) + count_mram(11 downto 10);
			
get_32768_addr:process(clk,global_clock_enable,count_mram)
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
        rd_addr_a(apr-1 downto apr-2) <=sw_mram(1 downto 0) + (sw_mram(0) & '0');
		rd_addr_a(apr-3 downto 0) <=  count_mram(apri_mram-3 downto 2);
		rd_addr_b <=  (others=>'0');
	end if;
end process get_32768_addr;
end generate gen_32768;	

end generate gen_Mega;


end;

