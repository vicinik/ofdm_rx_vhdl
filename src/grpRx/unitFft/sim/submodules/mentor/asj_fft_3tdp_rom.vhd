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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_3tdp_rom.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all; 
use work.fft_pack.all;
library lpm;
use lpm.lpm_components.all;
library altera_mf;
use altera_mf.altera_mf_components.all;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
-- 3-bank Dual Port ROM used in all Dual-Engine variations to use the doubled bandwidth for M4K
-- For cases where the ROM is distributed across M512, and ROM is single port, the access is split across 
-- two individual banks (odd and even) with single port access to each
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
-- NB: Mapping is a little confusing, for legacy reasons in the GUI code, 
-- that can and should be corrected.
-- m512 = {0,1,2,3} : m512 = 0 => 100% M4K 0% M512
--                    m512 = 1 => 0% M4K  100% M512
-- And just when you thought that made sense:
--                    m512 = 2 => 33% M4K  66% M512
--                    m512 = 3 => 66% M4K  33% M512
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

entity asj_fft_3tdp_rom is
	generic(
						device_family : string;
						twr : integer :=16;
						twa : integer :=11;
						m512 : integer :=3;
						rfc1 : string :="rm.hex";
						rfc2 : string :="rm.hex";
						rfc3 : string :="rm.hex";
						rfs1 : string :="rm.hex";
						rfs2 : string :="rm.hex";
						rfs3 : string :="rm.hex"
					);
	port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
						twade   	  : in std_logic_vector(twa-1 downto 0);
						twado   	  : in std_logic_vector(twa-1 downto 0);
						t1re				: out std_logic_vector(twr-1 downto 0);
						t2re				: out std_logic_vector(twr-1 downto 0);
						t3re				: out std_logic_vector(twr-1 downto 0);
						t1ie				: out std_logic_vector(twr-1 downto 0);
						t2ie				: out std_logic_vector(twr-1 downto 0);
						t3ie				: out std_logic_vector(twr-1 downto 0);
						t1ro				: out std_logic_vector(twr-1 downto 0);
						t2ro				: out std_logic_vector(twr-1 downto 0);
						t3ro				: out std_logic_vector(twr-1 downto 0);
						t1io				: out std_logic_vector(twr-1 downto 0);
						t2io				: out std_logic_vector(twr-1 downto 0);
						t3io				: out std_logic_vector(twr-1 downto 0)
			);
end asj_fft_3tdp_rom;

architecture syn of asj_fft_3tdp_rom is
constant merge : integer :=0;
type twiddle_data_bus	is array (0 to 2) of std_logic_vector(2*twr-1 downto 0);
signal odd_value : twiddle_data_bus;
signal even_value : twiddle_data_bus;
	


begin
	
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
-- gen_auto : 100%M4K (All Dual Port ROMs
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
	gen_auto : if(m512=0) generate
		
		sin_1n : asj_fft_twid_rom_tdp 
		generic map(
						device_family => device_family,
						twa => twa,
						twr => twr,
						m512 => m512,
						rf  =>rfs1
					)
		port map(
global_clock_enable => global_clock_enable,
						address_a		=> twade,
						address_b		=> twado,
						clock		  => clk,
						q_a		=> t1ie,
						q_b		=> t1io
		);
		
    sin_2n : asj_fft_twid_rom_tdp 
		generic map(
						device_family => device_family,
						twa => twa,
						twr => twr,
						m512 => m512,
						rf  =>rfs2
					)
		port map(
global_clock_enable => global_clock_enable,
						address_a		=> twade,
						address_b		=> twado,
						clock		  => clk,
						q_a		=> t2ie,
						q_b		=> t2io
		);
		
    sin_3n : asj_fft_twid_rom_tdp 
		generic map(
						device_family => device_family,
						twa => twa,
						twr => twr,
						m512 => m512,
						rf  =>rfs3
					)
		port map(
global_clock_enable => global_clock_enable,
						address_a		=> twade,
						address_b		=> twado,
						clock		  => clk,
						q_a		=> t3ie,
						q_b		=> t3io
		);
		
		cos_1n : asj_fft_twid_rom_tdp 
		generic map(
						device_family => device_family,
						twa => twa,
						twr => twr,
						m512 => m512,
						rf  =>rfc1
					)
		port map(
global_clock_enable => global_clock_enable,
						address_a		=> twade,
						address_b		=> twado,
						clock		  => clk,
						q_a		=> t1re,
						q_b		=> t1ro
		);
		
    cos_2n : asj_fft_twid_rom_tdp 
		generic map(
						device_family => device_family,
						twa => twa,
						twr => twr,
						m512 => m512,
						rf  =>rfc2
					)
		port map(
global_clock_enable => global_clock_enable,
						address_a		=> twade,
						address_b		=> twado,
						clock		  => clk,
						q_a		=> t2re,
						q_b		=> t2ro
		);
		
    cos_3n : asj_fft_twid_rom_tdp 
		generic map(
						device_family => device_family,
						twa => twa,
						twr => twr,
						m512 => m512,
						rf  =>rfc3
					)
		port map(
global_clock_enable => global_clock_enable,
						address_a		=> twade,
						address_b		=> twado,
						clock		  => clk,
						q_a		=> t3re,
						q_b		=> t3ro
		);
	end generate gen_auto;
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
-- gen_m512 : 100%M512 (All Single Port ROMs)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
	
	gen_m512 : if(m512=1) generate
	
		sin_1ne : twid_rom 
			generic map(
							device_family => device_family,
							twa => twa,
							twr => twr,
							m512 => m512,
							rf  =>rfs1
						)
			port map(
global_clock_enable => global_clock_enable,
							address		=> twade,
							clock		  => clk,
							q		=> t1ie
			);
	
		sin_1no : twid_rom 
			generic map(
							device_family => device_family,
							twa => twa,
							twr => twr,
							m512 => m512,
							rf  =>rfs1
						)
			port map(
global_clock_enable => global_clock_enable,
							address		=> twado,
							clock		  => clk,
							q		=> t1io
			);
			
		sin_2ne : twid_rom 
			generic map(
							device_family => device_family,
							twa => twa,
							twr => twr,
							m512 => m512,
							rf  =>rfs2
						)
			port map(
global_clock_enable => global_clock_enable,
							address		=> twade,
							clock		  => clk,
							q		=> t2ie
			);
	
		sin_2no : twid_rom 
			generic map(
							device_family => device_family,
							twa => twa,
							twr => twr,
							m512 => m512,
							rf  =>rfs2
						)
			port map(
global_clock_enable => global_clock_enable,
							address		=> twado,
							clock		  => clk,
							q		=> t2io
			);
		
		sin_3ne : twid_rom 
			generic map(
							device_family => device_family,
							twa => twa,
							twr => twr,
							m512 => m512,
							rf  =>rfs3
						)
			port map(
global_clock_enable => global_clock_enable,
							address		=> twade,
							clock		  => clk,
							q		=> t3ie
			);
	
		sin_3no : twid_rom 
			generic map(
							device_family => device_family,
							twa => twa,
							twr => twr,
							m512 => m512,
							rf  =>rfs3
						)
			port map(
global_clock_enable => global_clock_enable,
							address		=> twado,
							clock		  => clk,
							q		=> t3io
			);	
			
		cos_1ne : twid_rom 
			generic map(
							device_family => device_family,
							twa => twa,
							twr => twr,
							m512 => m512,
							rf  =>rfc1
						)
			port map(
global_clock_enable => global_clock_enable,
							address		=> twade,
							clock		  => clk,
							q		=> t1re
			);
	
		cos_1no : twid_rom 
			generic map(
							device_family => device_family,
							twa => twa,
							twr => twr,
							m512 => m512,
							rf  =>rfc1
						)
			port map(
global_clock_enable => global_clock_enable,
							address		=> twado,
							clock		  => clk,
							q		=> t1ro
			);
			
		cos_2ne : twid_rom 
			generic map(
							device_family => device_family,
							twa => twa,
							twr => twr,
							m512 => m512,
							rf  =>rfc2
						)
			port map(
global_clock_enable => global_clock_enable,
							address		=> twade,
							clock		  => clk,
							q		=> t2re
			);
	
		cos_2no : twid_rom 
			generic map(
							device_family => device_family,
							twa => twa,
							twr => twr,
							m512 => m512,
							rf  =>rfc2
						)
			port map(
global_clock_enable => global_clock_enable,
							address		=> twado,
							clock		  => clk,
							q		=> t2ro
			);
		
		cos_3ne : twid_rom 
			generic map(
							device_family => device_family,
							twa => twa,
							twr => twr,
							m512 => m512,
							rf  =>rfc3
						)
			port map(
global_clock_enable => global_clock_enable,
							address		=> twade,
							clock		  => clk,
							q		=> t3re
			);
	
		cos_3no : twid_rom 
			generic map(
							device_family => device_family,
							twa => twa,
							twr => twr,
							m512 => m512,
							rf  =>rfc3
						)
			port map(
global_clock_enable => global_clock_enable,
							address		=> twado,
							clock		  => clk,
							q		=> t3ro
			);		
		end generate gen_m512;
	-----------------------------------------------------------------------------------------------
	-- gen_M4K_sgl
	-- 1 ROM Bank in M4K/AUTO
	-- 2 ROM Banks in M512
	-----------------------------------------------------------------------------------------------	
	gen_M4K_sgl : if(m512=2) generate
	
		sin_1n : asj_fft_twid_rom_tdp 
		generic map(
						device_family => device_family,
						twa => twa,
						twr => twr,
						m512 => 0,
						rf  =>rfs1
					)
		port map(
global_clock_enable => global_clock_enable,
						address_a		=> twade,
						address_b		=> twado,
						clock		  => clk,
						q_a		=> t1ie,
						q_b		=> t1io
		);

			
		sin_2ne : twid_rom 
			generic map(
							device_family => device_family,
							twa => twa,
							twr => twr,
							m512 => 1,
							rf  =>rfs2
						)
			port map(
global_clock_enable => global_clock_enable,
							address		=> twade,
							clock		  => clk,
							q		=> t2ie
			);
	
		sin_2no : twid_rom 
			generic map(
							device_family => device_family,
							twa => twa,
							twr => twr,
							m512 => 1,
							rf  =>rfs2
						)
			port map(
global_clock_enable => global_clock_enable,
							address		=> twado,
							clock		  => clk,
							q		=> t2io
			);
		
		sin_3ne : twid_rom 
			generic map(
							device_family => device_family,
							twa => twa,
							twr => twr,
							m512 => 1,
							rf  =>rfs3
						)
			port map(
global_clock_enable => global_clock_enable,
							address		=> twade,
							clock		  => clk,
							q		=> t3ie
			);
	
		sin_3no : twid_rom 
			generic map(
							device_family => device_family,
							twa => twa,
							twr => twr,
							m512 => 1,
							rf  =>rfs3
						)
			port map(
global_clock_enable => global_clock_enable,
							address		=> twado,
							clock		  => clk,
							q		=> t3io
			);	
			
		cos_1n : asj_fft_twid_rom_tdp 
		generic map(
						device_family => device_family,
						twa => twa,
						twr => twr,
						m512 => 0,
						rf  =>rfc1
					)
		port map(
global_clock_enable => global_clock_enable,
						address_a		=> twade,
						address_b		=> twado,
						clock		  => clk,
						q_a		=> t1re,
						q_b		=> t1ro
		);
			
		cos_2ne : twid_rom 
			generic map(
							device_family => device_family,
							twa => twa,
							twr => twr,
							m512 => 1,
							rf  =>rfc2
						)
			port map(
global_clock_enable => global_clock_enable,
							address		=> twade,
							clock		  => clk,
							q		=> t2re
			);
	
		cos_2no : twid_rom 
			generic map(
							device_family => device_family,
							twa => twa,
							twr => twr,
							m512 => 1,
							rf  =>rfc2
						)
			port map(
global_clock_enable => global_clock_enable,
							address		=> twado,
							clock		  => clk,
							q		=> t2ro
			);
		
		cos_3ne : twid_rom 
			generic map(
							device_family => device_family,
							twa => twa,
							twr => twr,
							m512 => 1,
							rf  =>rfc3
						)
			port map(
global_clock_enable => global_clock_enable,
							address		=> twade,
							clock		  => clk,
							q		=> t3re
			);
	
		cos_3no : twid_rom 
			generic map(
							device_family => device_family,
							twa => twa,
							twr => twr,
							m512 => 1,
							rf  =>rfc3
						)
			port map(
global_clock_enable => global_clock_enable,
							address		=> twado,
							clock		  => clk,
							q		=> t3ro
			);		
		end generate gen_M4K_sgl;
	
	-----------------------------------------------------------------------------------------------
	-- gen_M4K_dbl
	-- 2 ROM Banks in M4K/AUTO
	-- 1 ROM Banks in M512
	-----------------------------------------------------------------------------------------------
	
	gen_M4K_dbl : if(m512=3) generate
	
		sin_1n : asj_fft_twid_rom_tdp 
		generic map(
						device_family => device_family,
						twa => twa,
						twr => twr,
						m512 => 0,
						rf  =>rfs1
					)
		port map(
global_clock_enable => global_clock_enable,
						address_a		=> twade,
						address_b		=> twado,
						clock		  => clk,
						q_a		=> t1ie,
						q_b		=> t1io
		);

			
		sin_2n : asj_fft_twid_rom_tdp 
		generic map(
						device_family => device_family,
						twa => twa,
						twr => twr,
						m512 => 0,
						rf  =>rfs2
					)
		port map(
global_clock_enable => global_clock_enable,
						address_a		=> twade,
						address_b		=> twado,
						clock		  => clk,
						q_a		=> t2ie,
						q_b		=> t2io
		);
		
		sin_3ne : twid_rom 
			generic map(
							device_family => device_family,
							twa => twa,
							twr => twr,
							m512 => 1,
							rf  =>rfs3
						)
			port map(
global_clock_enable => global_clock_enable,
							address		=> twade,
							clock		  => clk,
							q		=> t3ie
			);
	
		sin_3no : twid_rom 
			generic map(
							device_family => device_family,
							twa => twa,
							twr => twr,
							m512 => 1,
							rf  =>rfs3
						)
			port map(
global_clock_enable => global_clock_enable,
							address		=> twado,
							clock		  => clk,
							q		=> t3io
			);	
			
		cos_1n : asj_fft_twid_rom_tdp 
		generic map(
						device_family => device_family,
						twa => twa,
						twr => twr,
						m512 => 0,
						rf  =>rfc1
					)
		port map(
global_clock_enable => global_clock_enable,
						address_a		=> twade,
						address_b		=> twado,
						clock		  => clk,
						q_a		=> t1re,
						q_b		=> t1ro
		);
			
		cos_2n : asj_fft_twid_rom_tdp 
		generic map(
						device_family => device_family,
						twa => twa,
						twr => twr,
						m512 => 0,
						rf  =>rfc2
					)
		port map(
global_clock_enable => global_clock_enable,
						address_a		=> twade,
						address_b		=> twado,
						clock		  => clk,
						q_a		=> t2re,
						q_b		=> t2ro
		);
		
		cos_3ne : twid_rom 
			generic map(
							device_family => device_family,
							twa => twa,
							twr => twr,
							m512 => 1,
							rf  =>rfc3
						)
			port map(
global_clock_enable => global_clock_enable,
							address		=> twade,
							clock		  => clk,
							q		=> t3re
			);
	
		cos_3no : twid_rom 
			generic map(
							device_family => device_family,
							twa => twa,
							twr => twr,
							m512 => 1,
							rf  =>rfc3
						)
			port map(
global_clock_enable => global_clock_enable,
							address		=> twado,
							clock		  => clk,
							q		=> t3ro
			);		
		end generate gen_M4K_dbl;

end;
    
