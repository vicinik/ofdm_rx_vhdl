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
--  version   : $Version: 1.0 $ 
--  revision    : $Revision: #1 $ 
--  designer name   : $Author: psgswbuild $ 
--  company name    : altera corp.
--  company address : 101 innovation drive
--                      san jose, california 95134
--                      u.s.a.
-- 
--  copyright altera corp. 2003
-- 
-- 
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_1tdp_rom.vhd#1 $ 
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
-- Single Dual Port RAM contains odd and even twiddle factors
-- In the case of M512, due to single port access, the ROMS are broken up into odd and even banks
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 



entity asj_fft_1tdp_rom is
  generic(
            device_family : string;
            twr : integer :=20;
            twa : integer :=11;
            m512 : integer :=1;
            rfc1 : string :="rm.hex";
            rfc2 : string :="rm.hex";
            rfc3 : string :="rm.hex";
            rfs1 : string :="rm.hex";
            rfs2 : string :="rm.hex";
            rfs3 : string :="rm.hex"
          );
  port(     clk             : in std_logic;
global_clock_enable : in std_logic;
            twade       : in std_logic_vector(twa-1 downto 0);
            twado       : in std_logic_vector(twa-1 downto 0);
            t1r       : out std_logic_vector(twr-1 downto 0);
            t1i       : out std_logic_vector(twr-1 downto 0)
      );
end asj_fft_1tdp_rom;

architecture syn of asj_fft_1tdp_rom is

begin
  

  gen_m512 : if(m512>0) generate
  
    sin_1ne : twid_rom 
    generic map(
            device_family => device_family,
            twa => twa,
            twr => twr,
            m512 => 1,
            rf  =>rfs1
          )
    port map(
global_clock_enable => global_clock_enable,
            address   => twade,
            clock     => clk,
            q   => t1i
    );
    
    sin_1no : twid_rom 
    generic map(
            device_family => device_family,
            twa => twa,
            twr => twr,
            m512 => 1,
            rf  =>rfs1
          )
    port map(
global_clock_enable => global_clock_enable,
            address   => twado,
            clock     => clk,
            q   => t1r
    );

    
  end generate gen_m512;
  
  gen_auto : if(m512=0) generate
  
    
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
            address_a   => twade,
            address_b   => twado,
            clock     => clk,
            q_a   => t1i,
            q_b   => t1r
    );
    
  end generate gen_auto;
  
  


end;
    
