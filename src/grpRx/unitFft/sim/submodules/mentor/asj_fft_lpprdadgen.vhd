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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_lpprdadgen.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
-- Read address generation for Last-Pass Processor is fixed for each N
library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
--use ieee.std_logic_arith.all; 
use work.fft_pack.all;

entity asj_fft_lpprdadgen is
	generic(
						nps : integer :=4096;
						mram : integer :=0;
						nume : integer :=2;
						arch : integer :=0;
						n_passes : integer :=5;
						log2_n_passes : integer:= 3;
						apr : integer :=10
					);
	port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
						reset           : in std_logic;
						data_rdy        : in std_logic;
						lpp_en 					: in std_logic;
						rd_addr_a				: out std_logic_vector(apr-1 downto 0);
						rd_addr_b				: out std_logic_vector(apr-1 downto 0);
						rd_addr_c				: out std_logic_vector(apr-1 downto 0);
						rd_addr_d				: out std_logic_vector(apr-1 downto 0);
						sw_data_read    : out std_logic_vector(1 downto 0);
						sw_addr_read    : out std_logic_vector(1 downto 0);
						en              : out std_logic
						
			);
end asj_fft_lpprdadgen;

architecture gen_all of asj_fft_lpprdadgen is

constant apri : integer := apr + nume - 1 + 2*mram;
-- 4 Engine Counter Resolution
constant apri_qe : integer := apr + 2 + 2*mram;
constant apri_mram 	: integer := apr + 2;
-- MRAM Offset is always n_by_16
constant n_by_16 : integer:=nps/16;


signal sw 		: std_logic_vector(1 downto 0);
signal en_i 		: std_logic;
signal en_d 		: std_logic;
signal count 	: std_logic_vector(apri-1 downto 0);
signal qe_count 	: std_logic_vector(apri_qe-1 downto 0);
signal count_mram 	: std_logic_vector(apri_mram-1 downto 0);
signal sw_mram      : std_logic_vector(1 downto 0);
signal sw_n_by_16   : std_logic;

signal count_rst : std_logic ;


begin




edge_detect:process(clk,global_clock_enable,reset,lpp_en)
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			if(reset='1') then
				en_d <= '0';
			else
				en_d <= lpp_en;
			end if;
		end if;
	end process edge_detect;

-- If the architecture is streaming, want to trigger lpp on either edge 
  gen_str_edge : if(arch=0) generate
		gen_cont : if(nps>1024) generate
reg_edge:process(clk,global_clock_enable,en_d,lpp_en,data_rdy)
			begin                                         
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
						en_i <= '0';
					else
						en_i <= (lpp_en xor en_d) and lpp_en;     
					end if;
				end if;                                     
			end process reg_edge;             
		end generate gen_cont;
		
		gen_noncont : if(nps<=1024) generate
reg_edge:process(clk,global_clock_enable,en_d,lpp_en,data_rdy)
			begin                                         
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
						en_i <= '0';
					else
						en_i <= (lpp_en xor en_d) and (data_rdy and lpp_en);     
					end if;
				end if;                                     
			end process reg_edge;             
		end generate gen_noncont;
		
		
	end generate gen_str_edge;
	
	-- Otherwise, want to trigger lpp on +ve edge 
  gen_nonstr_edge : if(arch>0) generate
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
	end generate gen_nonstr_edge;
	
	
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

-----------------------------------------------------------------------------------------
--
-- M4K Output Buffer
--
-----------------------------------------------------------------------------------------
gen_M4K : if(mram=0) generate
	
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

gen_se_de_count : if(nume=1 or nume=2) generate

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

end generate gen_se_de_count;

gen_qe_count : if(nume=4) generate

counter:process(clk,global_clock_enable,en_i,reset)
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			if(reset='1' or en_i='1') then
				qe_count <= (apri_qe-1 downto 0 => '0');
			else
				qe_count <=qe_count+int2ustd(1,apri_qe);
			end if;
		end if;
	end process counter;

end generate gen_qe_count;


gen_se_addr : if(nume=1) generate


gen_64_addr : if(nps=64) generate

get_64_sw:process(clk,global_clock_enable,count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			sw <= count(1 downto 0)+count(3 downto 2);
		end if;
	end process get_64_sw;
	
get_64_addr:process(clk,global_clock_enable,count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--offset = mod((0:3)*n_by_16+floor(k/4),n_by_4)+1;
				rd_addr_a <=  ("00" & count(3 downto 2) );
				rd_addr_b <=  ("00" & count(3 downto 2) ) + int2ustd(4,apr);
				rd_addr_c <=  ("00" & count(3 downto 2) ) + int2ustd(8,apr);
				rd_addr_d <=  ("00" & count(3 downto 2) ) + int2ustd(12,apr);
			end if;
		end process get_64_addr;
		
end generate gen_64_addr;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

gen_256_addr : if(nps=256) generate
--
get_256_sw:process(clk,global_clock_enable,count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			sw <= count(1 downto 0)+count(3 downto 2)+count(5 downto 4);
		end if;
	end process get_256_sw;
	
get_256_addr:process(clk,global_clock_enable,count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--offset = mod((0:3)*n_by_16+floor(k/4),n_by_4)+1;
				rd_addr_a <=  ("00" & count(5 downto 2) );
				rd_addr_b <=  ("00" & count(5 downto 2) ) + int2ustd(16,apr);
				rd_addr_c <=  ("00" & count(5 downto 2) ) + int2ustd(32,apr);
				rd_addr_d <=  ("00" & count(5 downto 2) ) + int2ustd(48,apr);
			end if;
	end process get_256_addr;

end generate gen_256_addr;
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

gen_1024_addr : if(nps=1024) generate

get_1024_sw:process(clk,global_clock_enable,count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			sw <= count(1 downto 0)+count(3 downto 2)+count(5 downto 4)+count(7 downto 6);
		end if;
	end process get_1024_sw;
	
get_1024_addr:process(clk,global_clock_enable,count)is
	 begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--offset = mod((0:3)*n_by_16+floor(k/4),n_by_4)+1;
				rd_addr_a <=  ("00" & count(7 downto 2) );
				rd_addr_b <=  ("00" & count(7 downto 2) ) + int2ustd(64,apr);
				rd_addr_c <=  ("00" & count(7 downto 2) ) + int2ustd(128,apr);
				rd_addr_d <=  ("00" & count(7 downto 2) ) + int2ustd(192,apr);
		end if;
	end process get_1024_addr;
		
end generate gen_1024_addr;

-----------------------------------------------------------------------------------------
-- N=4096
-----------------------------------------------------------------------------------------

	gen_4096_addr : if(nps=4096) generate
	
get_4096_sw:process(clk,global_clock_enable,count)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw <= count(1 downto 0)+count(3 downto 2)+count(5 downto 4)+count(7 downto 6)+count(9 downto 8);
			end if;
		end process get_4096_sw;
		
		
get_4096_addr:process(clk,global_clock_enable,count)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					--offset = mod((0:3)*n_by_16+floor(k/4),n_by_4)+1;
					rd_addr_a <=  ("00" & count(9 downto 2) );
					rd_addr_b <=  ("00" & count(9 downto 2) ) + int2ustd(256,apr);
					rd_addr_c <=  ("00" & count(9 downto 2) ) + int2ustd(512,apr);
					rd_addr_d <=  ("00" & count(9 downto 2) ) + int2ustd(768,apr);
				end if;
		end process get_4096_addr;
	
	end generate gen_4096_addr;

-----------------------------------------------------------------------------------------------
-- N=16384
-----------------------------------------------------------------------------------------------

	gen_16384_addr : if(nps=16384) generate
	
get_16384_sw:process(clk,global_clock_enable,count)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw <= count(1 downto 0)+count(3 downto 2)+count(5 downto 4)+count(7 downto 6)+count(9 downto 8)+count(11 downto 10);
			end if;
		end process get_16384_sw;
		
		
get_16384_addr:process(clk,global_clock_enable,count)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					--offset = mod((0:3)*n_by_16+floor(k/4),n_by_4)+1;
					rd_addr_a <=  ("00" & count(11 downto 2) );
					rd_addr_b <=  ("00" & count(11 downto 2) ) + int2ustd(1024,apr);
					rd_addr_c <=  ("00" & count(11 downto 2) ) + int2ustd(2048,apr);
					rd_addr_d <=  ("00" & count(11 downto 2) ) + int2ustd(3072,apr);
				end if;
		end process get_16384_addr;
	
	end generate gen_16384_addr;

	gen_65536_addr : if(nps=65536) generate
	
get_65536_sw:process(clk,global_clock_enable,count)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw <= count(1 downto 0)+count(3 downto 2)+count(5 downto 4)+count(7 downto 6)+count(9 downto 8)+count(11 downto 10)+count(13 downto 12);
			end if;
		end process get_65536_sw;
		
		
get_65536_addr:process(clk,global_clock_enable,count)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					--offset = mod((0:3)*n_by_16+floor(k/4),n_by_4)+1;
					rd_addr_a <=  ("00" & count(13 downto 2) );
					rd_addr_b <=  ("00" & count(13 downto 2) ) + int2ustd(4096,apr);
					rd_addr_c <=  ("00" & count(13 downto 2) ) + int2ustd(8192,apr);
					rd_addr_d <=  ("00" & count(13 downto 2) ) + int2ustd(12288,apr);
				end if;
		end process get_65536_addr;
	
	end generate gen_65536_addr;



end generate gen_se_addr;

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- Dual Engine
-----------------------------------------------------------------------------------------------
gen_de_addr : if(nume=2) generate


	gen_64_addr : if(nps=64) generate
	
get_64_sw:process(clk,global_clock_enable,count)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--kkk = mod(k,n_by_4);  
				--ramsel = mod(floor(kkk/4)+floor(kkk/16)+floor(kkk/64)+floor(kkk/64)+mod(kkk,4),4);
				sw <= count(1 downto 0)+count(3 downto 2);
			end if;
		end process get_64_sw;
		
		
get_64_addr:process(clk,global_clock_enable,count)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					--kkk = mod(k,n_by_4);  
				  
					--offset = mod([0 0 1 1].*n_by_16+floor(kkk/4),n_by_4)+1;
					
					rd_addr_a <=  ('0' & count(3 downto 2) );
					rd_addr_b <=  ('0' & count(3 downto 2) );
					rd_addr_c <=  ('0' & count(3 downto 2) ) + int2ustd(4,apr);
					rd_addr_d <=  ('0' & count(3 downto 2) ) + int2ustd(4,apr);
				end if;
		end process get_64_addr;
	
	end generate gen_64_addr;
	
	
	gen_256_addr : if(nps=256) generate
	
get_256_sw:process(clk,global_clock_enable,count)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--kkk = mod(k,n_by_4);  
				--ramsel = mod(floor(kkk/4)+floor(kkk/16)+floor(kkk/64)+floor(kkk/256)+mod(kkk,4),4);
				sw <= count(1 downto 0)+count(3 downto 2)+count(5 downto 4);
			end if;
		end process get_256_sw;
		
		
get_256_addr:process(clk,global_clock_enable,count)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					--kkk = mod(k,n_by_4);  
				  
					--offset = mod([0 0 1 1].*n_by_16+floor(kkk/4),n_by_4)+1;
					
					rd_addr_a <=  ('0' & count(5 downto 2) );
					rd_addr_b <=  ('0' & count(5 downto 2) );
					rd_addr_c <=  ('0' & count(5 downto 2) ) + int2ustd(16,apr);
					rd_addr_d <=  ('0' & count(5 downto 2) ) + int2ustd(16,apr);
				end if;
		end process get_256_addr;
	
	end generate gen_256_addr;



  gen_1024_addr : if(nps=1024) generate
	
get_1024_sw:process(clk,global_clock_enable,count)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--kkk = mod(k,n_by_4);  
				--ramsel = mod(floor(kkk/4)+floor(kkk/16)+floor(kkk/64)+floor(kkk/256)+mod(kkk,4),4);
				sw <= count(1 downto 0)+count(3 downto 2)+count(5 downto 4)+count(7 downto 6);
			end if;
		end process get_1024_sw;
		
		
get_1024_addr:process(clk,global_clock_enable,count)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					--kkk = mod(k,n_by_4);  
				  
					--offset = mod([0 0 1 1].*n_by_16+floor(kkk/4),n_by_4)+1;
					
					rd_addr_a <=  ('0' & count(7 downto 2) );
					rd_addr_b <=  ('0' & count(7 downto 2) );
					rd_addr_c <=  ('0' & count(7 downto 2) ) + int2ustd(64,apr);
					rd_addr_d <=  ('0' & count(7 downto 2) ) + int2ustd(64,apr);
				end if;
		end process get_1024_addr;
	
	end generate gen_1024_addr;


	gen_4096_addr : if(nps=4096) generate
	
get_4096_sw:process(clk,global_clock_enable,count)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--kkk = mod(k,n_by_4);  
				--ramsel = mod(floor(kkk/4)+floor(kkk/16)+floor(kkk/64)+floor(kkk/256)+mod(kkk,4),4);
				sw <= count(1 downto 0)+count(3 downto 2)+count(5 downto 4)+count(7 downto 6)+count(9 downto 8);
			end if;
		end process get_4096_sw;
		
		
get_4096_addr:process(clk,global_clock_enable,count)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					--kkk = mod(k,n_by_4);  
				  
					--offset = mod([0 0 1 1].*n_by_16+floor(kkk/4),n_by_4)+1;
					
					rd_addr_a <=  ('0' & count(9 downto 2) );
					rd_addr_b <=  ('0' & count(9 downto 2) );
					rd_addr_c <=  ('0' & count(9 downto 2) ) + int2ustd(256,apr);
					rd_addr_d <=  ('0' & count(9 downto 2) ) + int2ustd(256,apr);
				end if;
		end process get_4096_addr;
	
	end generate gen_4096_addr;
	
	gen_16384_addr : if(nps=16384) generate
	
get_16384_sw:process(clk,global_clock_enable,count)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--kkk = mod(k,n_by_4);  
				--ramsel = mod(floor(kkk/4)+floor(kkk/16)+floor(kkk/64)+floor(kkk/256)+mod(kkk,4),4);
				sw <= count(1 downto 0)+count(3 downto 2)+count(5 downto 4)+count(7 downto 6)+count(9 downto 8)+count(11 downto 10);
			end if;
		end process get_16384_sw;
		
		
get_16384_addr:process(clk,global_clock_enable,count)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					--kkk = mod(k,n_by_4);  
				  
					--offset = mod([0 0 1 1].*n_by_16+floor(kkk/4),n_by_4)+1;
					
					rd_addr_a <=  ('0' & count(11 downto 2) );
					rd_addr_b <=  ('0' & count(11 downto 2) );
					rd_addr_c <=  ('0' & count(11 downto 2) ) + int2ustd(1024,apr);
					rd_addr_d <=  ('0' & count(11 downto 2) ) + int2ustd(1024,apr);
				end if;
		end process get_16384_addr;
	
	end generate gen_16384_addr;

gen_65536_addr : if(nps=65536) generate
	
get_65536_sw:process(clk,global_clock_enable,count)is
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
		sw <= count(1 downto 0) + count(3 downto 2) + count(5 downto 4) + count(7 downto 6) + count(9 downto 8) + count(11 downto 10) + count(13 downto 12);
	end if;
end process get_65536_sw;
		
get_65536_addr:process(clk,global_clock_enable,count)
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
        rd_addr_a <=  ('0' & count(13 downto 2) );
        rd_addr_b <=  ('0' & count(13 downto 2) );
        rd_addr_c <=  ('0' & count(13 downto 2) ) + int2ustd(4096,apr);
        rd_addr_d <=  ('0' & count(13 downto 2) ) + int2ustd(4096,apr);
	end if;
end process get_65536_addr;
	
end generate gen_65536_addr;
	

end generate gen_de_addr;


-----------------------------------------------------------------------------------------------
-- Quad Engine
-----------------------------------------------------------------------------------------------
gen_qe_addr : if(nume=4) generate


	gen_64_addr : if(nps=64) generate
	
get_64_sw:process(clk,global_clock_enable,qe_count)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--kkk = mod(k,n_by_4);  
				--ramsel = mod(floor(kkk/4)+floor(kkk/16)+floor(kkk/64)+floor(kkk/64)+mod(kkk,4),4);
				sw <= qe_count(1 downto 0)+qe_count(3 downto 2);
			end if;
		end process get_64_sw;
		
		
get_64_addr:process(clk,global_clock_enable,qe_count)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					--kkk = mod(k,n_by_4);  
				  
					--offset = mod([0 0 1 1].*n_by_16+floor(kkk/4),n_by_4)+1;
					
					rd_addr_a <=  ('0' & qe_count(3 downto 2) );
					rd_addr_b <=  ('0' & qe_count(3 downto 2) );
					rd_addr_c <=  ('0' & qe_count(3 downto 2) ) + int2ustd(4,apr);
					rd_addr_d <=  ('0' & qe_count(3 downto 2) ) + int2ustd(4,apr);
				end if;
		end process get_64_addr;
	
	end generate gen_64_addr;
	
	
	gen_256_addr : if(nps=256) generate
	
get_256_sw:process(clk,global_clock_enable,qe_count)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--kkk = mod(k,n_by_4);  
				--ramsel = mod(floor(kkk/4)+floor(kkk/16)+floor(kkk/64)+floor(kkk/256)+mod(kkk,4),4);
				sw <= qe_count(1 downto 0)+qe_count(3 downto 2)+qe_count(5 downto 4);
			end if;
		end process get_256_sw;
		
		
get_256_addr:process(clk,global_clock_enable,qe_count)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					rd_addr_a <=  (qe_count(5 downto 2) );
					rd_addr_b <=  (qe_count(5 downto 2) );
					rd_addr_c <=  (qe_count(5 downto 2) );-- + int2ustd(16,apr);
					rd_addr_d <=  (qe_count(5 downto 2) );-- + int2ustd(16,apr);
				end if;
		end process get_256_addr;
	
	end generate gen_256_addr;



  gen_1024_addr : if(nps=1024) generate
	
get_1024_sw:process(clk,global_clock_enable,qe_count)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--kkk = mod(k,n_by_4);  
				--ramsel = mod(floor(kkk/4)+floor(kkk/16)+floor(kkk/64)+floor(kkk/256)+mod(kkk,4),4);
				sw <= qe_count(1 downto 0)+qe_count(3 downto 2)+qe_count(5 downto 4)+qe_count(7 downto 6);
			end if;
		end process get_1024_sw;
		
		
get_1024_addr:process(clk,global_clock_enable,qe_count)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					--kkk = mod(k,n_by_4);  
				  
					--offset = mod([0 0 1 1].*n_by_16+floor(kkk/4),n_by_4)+1;
					
					rd_addr_a <=  (qe_count(7 downto 2) );
					rd_addr_b <=  (qe_count(7 downto 2) );
					rd_addr_c <=  (qe_count(7 downto 2) );-- + int2ustd(64,apr);
					rd_addr_d <=  (qe_count(7 downto 2) );-- + int2ustd(64,apr);
				end if;
		end process get_1024_addr;
	
	end generate gen_1024_addr;


	gen_4096_addr : if(nps=4096) generate
	
get_4096_sw:process(clk,global_clock_enable,qe_count)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--kkk = mod(k,n_by_4);  
				--ramsel = mod(floor(kkk/4)+floor(kkk/16)+floor(kkk/64)+floor(kkk/256)+mod(kkk,4),4);
				sw <= qe_count(1 downto 0)+qe_count(3 downto 2)+qe_count(5 downto 4)+qe_count(7 downto 6)+qe_count(9 downto 8);
			end if;
		end process get_4096_sw;
		
		
get_4096_addr:process(clk,global_clock_enable,qe_count)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					--kkk = mod(k,n_by_4);  
				  
					--offset = mod([0 0 1 1].*n_by_16+floor(kkk/4),n_by_4)+1;
					
					rd_addr_a <=  (qe_count(9 downto 2) );
					rd_addr_b <=  (qe_count(9 downto 2) );
					rd_addr_c <=  (qe_count(9 downto 2) );
					rd_addr_d <=  (qe_count(9 downto 2) );
				end if;
		end process get_4096_addr;
	
	end generate gen_4096_addr;
	
	gen_16384_addr : if(nps=16384) generate
	
get_16384_sw:process(clk,global_clock_enable,qe_count)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--kkk = mod(k,n_by_4);  
				--ramsel = mod(floor(kkk/4)+floor(kkk/16)+floor(kkk/64)+floor(kkk/256)+mod(kkk,4),4);
				sw <= qe_count(1 downto 0)+qe_count(3 downto 2)+qe_count(5 downto 4)+qe_count(7 downto 6)+qe_count(9 downto 8)+qe_count(11 downto 10);
			end if;
		end process get_16384_sw;
		
		
get_16384_addr:process(clk,global_clock_enable,qe_count)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					--kkk = mod(k,n_by_4);  
				  
					--offset = mod([0 0 1 1].*n_by_16+floor(kkk/4),n_by_4)+1;
					
					rd_addr_a <=  (qe_count(11 downto 2) );
					rd_addr_b <=  (qe_count(11 downto 2) );
					rd_addr_c <=  (qe_count(11 downto 2) );
					rd_addr_d <=  (qe_count(11 downto 2) );
				end if;
		end process get_16384_addr;
	
	end generate gen_16384_addr;
	
gen_65536_addr : if(nps=65536) generate
	
get_65536_sw:process(clk,global_clock_enable,qe_count)is
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
		sw <= qe_count(1 downto 0) + qe_count(3 downto 2) + qe_count(5 downto 4) + qe_count(7 downto 6) + qe_count(9 downto 8) + qe_count(11 downto 10) + qe_count(13 downto 12);
	end if;
end process get_65536_sw;
		
get_65536_addr:process(clk,global_clock_enable,qe_count)
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
        rd_addr_a <=  (qe_count(13 downto 2) );
        rd_addr_b <=  (qe_count(13 downto 2) );
        rd_addr_c <=  (qe_count(13 downto 2) );
        rd_addr_d <=  (qe_count(13 downto 2) );
    end if;
end process get_65536_addr;
	
end generate gen_65536_addr;	

end generate gen_qe_addr;



end generate gen_M4K;

-----------------------------------------------------------------------------------------
--
-- MegaRAM Output Buffer
--
-----------------------------------------------------------------------------------------
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
	gen_4096 : if(nps=4096) generate	
		
get_4096_sw:process(clk,global_clock_enable,count_mram)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
				  -- sel_bank = mod(floor(mod(k,n_by_4)/n_by_16)+floor(k/n_by_4),2);
					sw <= count_mram(1 downto 0)+count_mram(3 downto 2)+count_mram(5 downto 4)+count_mram(7 downto 6)+count_mram(9 downto 8);
				end if;
			end process get_4096_sw;
				
		sw_mram <= (count_mram(1) & count_mram(0)) + (count_mram(3) & count_mram(2))+(count_mram(5) & count_mram(4))+(count_mram(7) & count_mram(6))+('0' & count_mram(8));
			
get_4096_addr:process(clk,global_clock_enable,count_mram)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					rd_addr_a(apr-1 downto apr-2) <= sw_mram(0) & (sw_mram(0) xor sw_mram(1));
					rd_addr_a(apr-3 downto 0) <=  count_mram(apri_mram-3 downto 2);
					if(count_mram(8)='1') then
						rd_addr_b(apr-1 downto apr-2) <= not(sw_mram(0)) & (sw_mram(1));
					else
						rd_addr_b(apr-1 downto apr-2) <= not(sw_mram(0)) & not(sw_mram(1));
					end if;
					rd_addr_b(apr-3 downto 0) <=  not(count_mram(apri_mram-3)) & count_mram(apri_mram-4 downto 2);
				end if;
			end process get_4096_addr;
	
	end generate gen_4096;				
	-----------------------------------------------------------------------------------------------
	--
	-----------------------------------------------------------------------------------------------
	gen_16384 : if(nps=16384) generate	
		
get_16384_sw:process(clk,global_clock_enable,count_mram)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
				  -- sel_bank = mod(floor(mod(k,n_by_4)/n_by_16)+floor(k/n_by_4),2);
					sw <= count_mram(1 downto 0)+count_mram(3 downto 2)+count_mram(5 downto 4)+count_mram(7 downto 6)+count_mram(9 downto 8)+count_mram(11 downto 10);
				end if;
			end process get_16384_sw;
				
		sw_mram <= (count_mram(1) & count_mram(0)) + (count_mram(3) & count_mram(2))+(count_mram(5) & count_mram(4))+(count_mram(7) & count_mram(6))+(count_mram(9) & count_mram(8))+('0' & count_mram(10));
			
get_16384_addr:process(clk,global_clock_enable,count_mram)
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					rd_addr_a(apr-1 downto apr-2) <= sw_mram(0) & (sw_mram(0) xor sw_mram(1));
					rd_addr_a(apr-3 downto 0) <=  count_mram(apri_mram-3 downto 2);
					if(count_mram(10)='1') then
						rd_addr_b(apr-1 downto apr-2) <= not(sw_mram(0)) & (sw_mram(1));
					else
						rd_addr_b(apr-1 downto apr-2) <= not(sw_mram(0)) & not(sw_mram(1));
					end if;
					rd_addr_b(apr-3 downto 0) <=  not(count_mram(apri_mram-3)) & count_mram(apri_mram-4 downto 2);
				end if;
			end process get_16384_addr;
	
	end generate gen_16384;				
	
-----------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------
gen_65536 : if(nps=65536) generate	
		
get_65536_sw:process(clk,global_clock_enable,count_mram)is
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
		sw <= count_mram(1 downto 0) + count_mram(3 downto 2) + count_mram(5 downto 4) + count_mram(7 downto 6) + count_mram(9 downto 8) + count_mram(11 downto 10) + count_mram(13 downto 12);
    end if;
end process get_65536_sw;
				
	sw_mram <= (count_mram(1) & count_mram(0)) + (count_mram(3) & count_mram(2)) + (count_mram(5) & count_mram(4)) + (count_mram(7) & count_mram(6)) + (count_mram(9) & count_mram(8)) + (count_mram(11) & count_mram(10)) + ('0' & count_mram(12));
			
get_65536_addr:process(clk,global_clock_enable,count_mram)
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
		rd_addr_a(apr-1 downto apr-2) <= sw_mram(0) & (sw_mram(0) xor sw_mram(1));
		rd_addr_a(apr-3 downto 0) <=  count_mram(apri_mram-3 downto 2);
		if(count_mram(10)='1') then
			rd_addr_b(apr-1 downto apr-2) <= not(sw_mram(0)) & (sw_mram(1));
		else
			rd_addr_b(apr-1 downto apr-2) <= not(sw_mram(0)) & not(sw_mram(1));
		end if;
		rd_addr_b(apr-3 downto 0) <=  not(count_mram(apri_mram-3)) & count_mram(apri_mram-4 downto 2);
	end if;
end process get_65536_addr;
	
end generate gen_65536;	
		
end generate gen_Mega;


end;

			
