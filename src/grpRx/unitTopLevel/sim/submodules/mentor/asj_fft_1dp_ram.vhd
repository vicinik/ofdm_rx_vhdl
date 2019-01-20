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
--  version             : $Version:     1.0 $ 
--  revision            : $Revision: #1 $ 
--  designer name       : $Author: psgswbuild $ 
--  company name        : altera corp.
--  company address     : 101 innovation drive
--                        san jose, california 95134
--                        u.s.a.
-- 
--  copyright altera corp. 2003
-- 
-- 
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_1dp_ram.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
-----------------------------------------------------------------------------------
-- Single Bank of Data RAM for simgle output engine variations
-- storing a real/imaginary complex data element pair
-- No special handling required for MRAM
-----------------------------------------------------------------------------------
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

entity asj_fft_1dp_ram is
        generic(
                device_family : string;
                apr : integer :=14;
                mpr : integer :=16;
                rfd  : string :="M-RAM"
        );
        port(
global_clock_enable : in std_logic;
                clk             : in std_logic;
                rdaddress       : in std_logic_vector(apr-1 downto 0);
                wraddress       : in std_logic_vector(apr-1 downto 0);
                data_in         : in std_logic_vector(2*mpr-1 downto 0);
                wren            : in std_logic;
                rden            : in std_logic;
                data_out        : out std_logic_vector(2*mpr-1 downto 0)
        );
end asj_fft_1dp_ram;

architecture syn of asj_fft_1dp_ram is

constant dpr : integer := 2*mpr;

signal wren_a : std_logic;
signal rden_a : std_logic;

begin
        
wren_a <= wren;
rden_a <= rden;
                        
dat_A : asj_fft_data_ram
generic map(
        device_family => device_family,
        apr => apr,
        dpr => dpr,
        rfd => rfd
)
port map(
global_clock_enable => global_clock_enable,
        rdaddress => rdaddress,
        data      => data_in,
        wraddress => wraddress,
        wren      => wren_a,
        rden      => rden_a,
        clock     => clk,
        q         => data_out
);

end;
    
