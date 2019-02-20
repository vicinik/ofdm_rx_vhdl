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


---------------------------------------------------------------------------- 
--  version         : $Version: 1.0 $ 
--  revision        : $Revision: #1 $ 
--  designer name   : $Author: max $ 
--  company name    : altera corp.
-- 
--  copyright altera corp. 2010
-- 
-- 
--  $Header: //acds/main/ip/fft/src/rtl/lib/apn_fft_cmult_cpx.vhd#1 $ 
--  $log$ 
---------------------------------------------------------------------------- 

-- khphuah: to update whole file ww8.2

library ieee;                              
use ieee.std_logic_1164.all;               
use ieee.std_logic_arith.all; 
use ieee.std_logic_unsigned.all;

use work.fft_pack.all;
library altera_mf;
use altera_mf.altera_mf_components.all;

entity apn_fft_cmult_cpx is 
  GENERIC (

    mpr     : integer :=16;
    twr     : integer :=12;
    pipe    : integer :=1
  );
  port(
    clk     : in std_logic;
    global_clock_enable : in std_logic;
    reset   : in std_logic;
    dataa   : in std_logic_vector(mpr-1 downto 0);
    datab   : in std_logic_vector(mpr-1 downto 0);
    datac   : in std_logic_vector(twr-1 downto 0);
    datad   : in std_logic_vector(twr-1 downto 0);
    real_out    : out std_logic_vector(mpr-1 downto 0);
    imag_out    : out std_logic_vector(mpr-1 downto 0)
  );
end apn_fft_cmult_cpx;

architecture model of apn_fft_cmult_cpx is 

    signal result_r : std_logic_vector(twr+mpr downto 0);
    signal result_i : std_logic_vector(twr+mpr downto 0);
    signal result_r_tmp : std_logic_vector(twr+mpr-1 downto 0);
    signal result_i_tmp : std_logic_vector(twr+mpr-1 downto 0);

    signal real_out_reg : std_logic_vector(mpr-1 downto 0);
    signal imag_out_reg : std_logic_vector(mpr-1 downto 0);

    signal vcc : std_logic;

begin

    vcc <= '1';

    gen_infr_cpx : if not (mpr>18 and mpr<=25 and twr<=18) generate
    calc_mult_cpx: apn_fft_mult_cpx
    generic map(
        mpr => mpr,
        twr => twr
    )
    port map(
        global_clock_enable => global_clock_enable,
        clk => clk,
        reset => reset,
        a   => dataa,
        b   => datab,
        c   => datac,
        d   => datad,
        rout    => result_r,
        iout    => result_i
    );
    end generate gen_infr_cpx;

    gen_1825_cpx : if (mpr>18 and mpr<=25 and twr<=18) generate
    calc_mac_cpx: apn_fft_mult_cpx_1825
    generic map(
        mpr => mpr,
        twr => twr
    )
    port map(
        clk => clk,
        reset => reset,
        global_clock_enable => global_clock_enable,
        a_r => dataa,
        a_i => datab,
        b_r => datac,
        b_i => datad,
        p_r => result_r,
        p_i => result_i
    );        
    end generate gen_1825_cpx;
    
    reg_muo:process(clk,global_clock_enable)is
    begin
        if reset = '1' then
            result_r_tmp <= (others => '0');
            result_i_tmp <= (others => '0');
        elsif((rising_edge(clk) and global_clock_enable='1')) then
            result_r_tmp <= result_r(mpr+twr-1 downto 0);
            result_i_tmp <= result_i(mpr+twr-1 downto 0);
        end if;
    end process reg_muo;

    u0 : asj_fft_pround
    generic map (
        widthin   => mpr+twr,
        widthout  => mpr,
        pipe      => 1
    )
    port map (
        global_clock_enable => global_clock_enable,
        clk       => clk,
        clken     => vcc,
        xin       => result_r_tmp,
        yout      => real_out_reg
    );

    u1 : asj_fft_pround
    generic map (
        widthin   => mpr+twr,
        widthout  => mpr,
        pipe      => 1
    )
    port map  (
        global_clock_enable => global_clock_enable,
        clk       => clk,
        clken     => vcc,
        xin       => result_i_tmp,
        yout      => imag_out_reg
    );  
      
    real_delay : asj_fft_tdl
    generic map (
        mpr     => mpr,
        del     => 2,
        srr     => "AUTO_SHIFT_REGISTER_RECOGNITION=OFF"
    )
    port map(   
        global_clock_enable => global_clock_enable,
        clk   => clk,
        data_in   => real_out_reg,
        data_out  => real_out
    );

    imag_delay : asj_fft_tdl
    generic map(
        mpr => mpr,
        del   => 2
    )
    port map(   
        global_clock_enable => global_clock_enable,
        clk   => clk,
        data_in   => imag_out_reg,
        data_out  => imag_out
    ); 

end model;
