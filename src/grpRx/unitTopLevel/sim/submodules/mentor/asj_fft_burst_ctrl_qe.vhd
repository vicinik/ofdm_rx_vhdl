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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_burst_ctrl_qe.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all; 
use work.fft_pack.all;
-----------------------------------------------------------------------------------------------
-- Central Data and Address Switch Control for Quad Engine Quad Output FFT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
-- Quad Quad-Output FFT Engine variation
-----------------------------------------------------------------------------------------------
entity asj_fft_burst_ctrl_qe is
  generic(
            nps : integer :=256;
            mpr : integer :=16;
            apr : integer :=6;
            abuspr : integer :=24; --4*apr
            rbuspr : integer :=64; --4*mpr
            cbuspr : integer :=128 --2*4*mpr
          );
  port(     clk             : in std_logic;
global_clock_enable : in std_logic;
            sel_anb_in      : in std_logic;
            sel_anb_ram     : in std_logic;
            sel_anb_addr    : in std_logic;
            sel_lpp_m1      : in std_logic;
            data_rdy        : in std_logic;
            wraddr_i0_sw    : in std_logic_vector(apr-1 downto 0);
            wraddr_i1_sw    : in std_logic_vector(apr-1 downto 0);
            wraddr_i2_sw    : in std_logic_vector(apr-1 downto 0);
            wraddr_i3_sw    : in std_logic_vector(apr-1 downto 0);
            wraddr0_sw    : in std_logic_vector(apr-1 downto 0);
            wraddr1_sw    : in std_logic_vector(apr-1 downto 0);
            wraddr2_sw    : in std_logic_vector(apr-1 downto 0);
            wraddr3_sw    : in std_logic_vector(apr-1 downto 0);
            rdaddr0_sw    : in std_logic_vector(apr-1 downto 0);
            rdaddr1_sw    : in std_logic_vector(apr-1 downto 0);
            rdaddr2_sw    : in std_logic_vector(apr-1 downto 0);
            rdaddr3_sw    : in std_logic_vector(apr-1 downto 0);
            ram_data_in0_sw_w  : in std_logic_vector(2*mpr-1 downto 0);
            ram_data_in1_sw_w  : in std_logic_vector(2*mpr-1 downto 0);
            ram_data_in2_sw_w  : in std_logic_vector(2*mpr-1 downto 0);
            ram_data_in3_sw_w  : in std_logic_vector(2*mpr-1 downto 0);
            ram_data_in0_sw_x  : in std_logic_vector(2*mpr-1 downto 0);
            ram_data_in1_sw_x  : in std_logic_vector(2*mpr-1 downto 0);
            ram_data_in2_sw_x  : in std_logic_vector(2*mpr-1 downto 0);
            ram_data_in3_sw_x  : in std_logic_vector(2*mpr-1 downto 0);
            ram_data_in0_sw_y  : in std_logic_vector(2*mpr-1 downto 0);
            ram_data_in1_sw_y  : in std_logic_vector(2*mpr-1 downto 0);
            ram_data_in2_sw_y  : in std_logic_vector(2*mpr-1 downto 0);
            ram_data_in3_sw_y  : in std_logic_vector(2*mpr-1 downto 0);
            ram_data_in0_sw_z  : in std_logic_vector(2*mpr-1 downto 0);
            ram_data_in1_sw_z  : in std_logic_vector(2*mpr-1 downto 0);
            ram_data_in2_sw_z  : in std_logic_vector(2*mpr-1 downto 0);
            ram_data_in3_sw_z  : in std_logic_vector(2*mpr-1 downto 0);
            i_ram_data_in0_sw  : in std_logic_vector(2*mpr-1 downto 0);
            i_ram_data_in1_sw  : in std_logic_vector(2*mpr-1 downto 0);
            i_ram_data_in2_sw  : in std_logic_vector(2*mpr-1 downto 0);
            i_ram_data_in3_sw  : in std_logic_vector(2*mpr-1 downto 0);
            a_ram_data_out_bus_w  : in std_logic_vector(cbuspr-1 downto 0);
            a_ram_data_out_bus_x  : in std_logic_vector(cbuspr-1 downto 0);
            a_ram_data_out_bus_y  : in std_logic_vector(cbuspr-1 downto 0);
            a_ram_data_out_bus_z  : in std_logic_vector(cbuspr-1 downto 0);
            b_ram_data_out_bus_w  : in std_logic_vector(cbuspr-1 downto 0);
            b_ram_data_out_bus_x  : in std_logic_vector(cbuspr-1 downto 0);
            b_ram_data_out_bus_y  : in std_logic_vector(cbuspr-1 downto 0);
            b_ram_data_out_bus_z  : in std_logic_vector(cbuspr-1 downto 0);
            a_ram_data_in_bus_w  : out std_logic_vector(cbuspr-1 downto 0);
            a_ram_data_in_bus_x  : out std_logic_vector(cbuspr-1 downto 0);
            a_ram_data_in_bus_y  : out std_logic_vector(cbuspr-1 downto 0);
            a_ram_data_in_bus_z  : out std_logic_vector(cbuspr-1 downto 0);
            b_ram_data_in_bus_w  : out std_logic_vector(cbuspr-1 downto 0);
            b_ram_data_in_bus_x  : out std_logic_vector(cbuspr-1 downto 0);
            b_ram_data_in_bus_y  : out std_logic_vector(cbuspr-1 downto 0);
            b_ram_data_in_bus_z  : out std_logic_vector(cbuspr-1 downto 0);
            wraddress_a_bus   : out std_logic_vector(abuspr-1 downto 0);
            wraddress_b_bus   : out std_logic_vector(abuspr-1 downto 0);
            rdaddress_a_bus   : out std_logic_vector(abuspr-1 downto 0);
            rdaddress_b_bus   : out std_logic_vector(abuspr-1 downto 0);
            ram_data_out0_w    : out std_logic_vector(2*mpr-1 downto 0);
            ram_data_out1_w    : out std_logic_vector(2*mpr-1 downto 0);
            ram_data_out2_w    : out std_logic_vector(2*mpr-1 downto 0);
            ram_data_out3_w    : out std_logic_vector(2*mpr-1 downto 0);
            ram_data_out0_x    : out std_logic_vector(2*mpr-1 downto 0);
            ram_data_out1_x    : out std_logic_vector(2*mpr-1 downto 0);
            ram_data_out2_x    : out std_logic_vector(2*mpr-1 downto 0);
            ram_data_out3_x    : out std_logic_vector(2*mpr-1 downto 0);
            ram_data_out0_y    : out std_logic_vector(2*mpr-1 downto 0);
            ram_data_out1_y    : out std_logic_vector(2*mpr-1 downto 0);
            ram_data_out2_y    : out std_logic_vector(2*mpr-1 downto 0);
            ram_data_out3_y    : out std_logic_vector(2*mpr-1 downto 0);
            ram_data_out0_z    : out std_logic_vector(2*mpr-1 downto 0);
            ram_data_out1_z    : out std_logic_vector(2*mpr-1 downto 0);
            ram_data_out2_z    : out std_logic_vector(2*mpr-1 downto 0);
            ram_data_out3_z    : out std_logic_vector(2*mpr-1 downto 0)
      );
end asj_fft_burst_ctrl_qe;

architecture cnt_sw of asj_fft_burst_ctrl_qe is

constant last_pass_radix : integer :=(LOG4_CEIL(nps))-(LOG4_FLOOR(nps));

signal input_data_vec : std_logic_vector(cbuspr-1 downto 0);      
signal ram_out_select : std_logic_vector(1 downto 0);      

begin
  
input_address:process(clk,global_clock_enable,wraddr_i0_sw,wraddr_i1_sw,wraddr_i2_sw,wraddr_i3_sw)is
    begin
if((rising_edge(clk) and global_clock_enable='1'))then
        wraddress_a_bus <= wraddr_i0_sw & wraddr_i1_sw & wraddr_i2_sw & wraddr_i3_sw;
      end if;
    end process input_address;

work_address:process(clk,global_clock_enable,wraddr0_sw,wraddr1_sw,wraddr2_sw,wraddr3_sw)is
    begin
if((rising_edge(clk) and global_clock_enable='1'))then
        wraddress_b_bus <= wraddr0_sw & wraddr1_sw & wraddr2_sw & wraddr3_sw;
      end if;
    end process work_address;
    
    
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
    
a_ram_data_in_bus_w <= input_data_vec;
a_ram_data_in_bus_x <= input_data_vec;
a_ram_data_in_bus_y <= input_data_vec;
a_ram_data_in_bus_z <= input_data_vec;

    
input_data:process(clk,global_clock_enable,i_ram_data_in0_sw,i_ram_data_in1_sw,i_ram_data_in2_sw,i_ram_data_in3_sw)is
    begin
if((rising_edge(clk) and global_clock_enable='1'))then
        input_data_vec <= i_ram_data_in0_sw & i_ram_data_in1_sw & i_ram_data_in2_sw & i_ram_data_in3_sw;
      end if;
    end process input_data;
    
  
work_data:process(clk,global_clock_enable,ram_data_in0_sw_w,ram_data_in1_sw_w,ram_data_in2_sw_w,ram_data_in3_sw_w,
                          ram_data_in0_sw_x,ram_data_in1_sw_x,ram_data_in2_sw_x,ram_data_in3_sw_x,
                          ram_data_in0_sw_y,ram_data_in1_sw_y,ram_data_in2_sw_y,ram_data_in3_sw_y,
                          ram_data_in0_sw_z,ram_data_in1_sw_z,ram_data_in2_sw_z,ram_data_in3_sw_z) is
    begin
if((rising_edge(clk) and global_clock_enable='1'))then
        b_ram_data_in_bus_w <= ram_data_in0_sw_w & ram_data_in1_sw_w & ram_data_in2_sw_w & ram_data_in3_sw_w;
        b_ram_data_in_bus_x <= ram_data_in0_sw_x & ram_data_in1_sw_x & ram_data_in2_sw_x & ram_data_in3_sw_x;
        b_ram_data_in_bus_y <= ram_data_in0_sw_y & ram_data_in1_sw_y & ram_data_in2_sw_y & ram_data_in3_sw_y;
        b_ram_data_in_bus_z <= ram_data_in0_sw_z & ram_data_in1_sw_z & ram_data_in2_sw_z & ram_data_in3_sw_z;
      end if;       
    end process work_data;


gen_r4_wd : if(last_pass_radix=0) generate
    
sel_ram_data:process(clk,global_clock_enable,sel_anb_ram,a_ram_data_out_bus_w,a_ram_data_out_bus_x,a_ram_data_out_bus_y,a_ram_data_out_bus_z,
                                         b_ram_data_out_bus_w,b_ram_data_out_bus_x,b_ram_data_out_bus_y,b_ram_data_out_bus_z) is
    begin
if((rising_edge(clk) and global_clock_enable='1'))then
          if(sel_anb_ram='1') then
              ram_data_out0_w <= b_ram_data_out_bus_w(8*mpr-1 downto 6*mpr);
              ram_data_out1_w <= b_ram_data_out_bus_w(6*mpr-1 downto 4*mpr);
              ram_data_out2_w <= b_ram_data_out_bus_w(4*mpr-1 downto 2*mpr);
              ram_data_out3_w <= b_ram_data_out_bus_w(2*mpr-1 downto 0);
              
              ram_data_out0_x <= b_ram_data_out_bus_x(8*mpr-1 downto 6*mpr);
              ram_data_out1_x <= b_ram_data_out_bus_x(6*mpr-1 downto 4*mpr);
              ram_data_out2_x <= b_ram_data_out_bus_x(4*mpr-1 downto 2*mpr);
              ram_data_out3_x <= b_ram_data_out_bus_x(2*mpr-1 downto 0);
              
              ram_data_out0_y <= b_ram_data_out_bus_y(8*mpr-1 downto 6*mpr);
              ram_data_out1_y <= b_ram_data_out_bus_y(6*mpr-1 downto 4*mpr);
              ram_data_out2_y <= b_ram_data_out_bus_y(4*mpr-1 downto 2*mpr);
              ram_data_out3_y <= b_ram_data_out_bus_y(2*mpr-1 downto 0);
              
              ram_data_out0_z <= b_ram_data_out_bus_z(8*mpr-1 downto 6*mpr);
              ram_data_out1_z <= b_ram_data_out_bus_z(6*mpr-1 downto 4*mpr);
              ram_data_out2_z <= b_ram_data_out_bus_z(4*mpr-1 downto 2*mpr);
              ram_data_out3_z <= b_ram_data_out_bus_z(2*mpr-1 downto 0);
          else
              ram_data_out0_w <= a_ram_data_out_bus_w(8*mpr-1 downto 6*mpr);
              ram_data_out1_w <= a_ram_data_out_bus_w(6*mpr-1 downto 4*mpr);
              ram_data_out2_w <= a_ram_data_out_bus_w(4*mpr-1 downto 2*mpr);
              ram_data_out3_w <= a_ram_data_out_bus_w(2*mpr-1 downto 0);
              
              ram_data_out0_x <= a_ram_data_out_bus_x(8*mpr-1 downto 6*mpr);
              ram_data_out1_x <= a_ram_data_out_bus_x(6*mpr-1 downto 4*mpr);
              ram_data_out2_x <= a_ram_data_out_bus_x(4*mpr-1 downto 2*mpr);
              ram_data_out3_x <= a_ram_data_out_bus_x(2*mpr-1 downto 0);
  
              ram_data_out0_y <= a_ram_data_out_bus_y(8*mpr-1 downto 6*mpr);
              ram_data_out1_y <= a_ram_data_out_bus_y(6*mpr-1 downto 4*mpr);
              ram_data_out2_y <= a_ram_data_out_bus_y(4*mpr-1 downto 2*mpr);
              ram_data_out3_y <= a_ram_data_out_bus_y(2*mpr-1 downto 0);
              
              ram_data_out0_z <= a_ram_data_out_bus_z(8*mpr-1 downto 6*mpr);
              ram_data_out1_z <= a_ram_data_out_bus_z(6*mpr-1 downto 4*mpr);
              ram_data_out2_z <= a_ram_data_out_bus_z(4*mpr-1 downto 2*mpr);
              ram_data_out3_z <= a_ram_data_out_bus_z(2*mpr-1 downto 0);
          end if;
        end if;
    end process sel_ram_data;
  end generate gen_r4_wd;
    
gen_r2_wd : if(last_pass_radix=1) generate
    
sel_ram_data:process(clk,global_clock_enable)is
    begin
if((rising_edge(clk) and global_clock_enable='1'))then
        ram_out_select<= sel_anb_ram & sel_lpp_m1;
          case ram_out_select(1 downto 0) is
            when "00" =>
              ram_data_out0_w <= a_ram_data_out_bus_w(8*mpr-1 downto 6*mpr);
              ram_data_out1_w <= a_ram_data_out_bus_w(6*mpr-1 downto 4*mpr);
              ram_data_out2_w <= a_ram_data_out_bus_w(4*mpr-1 downto 2*mpr);
              ram_data_out3_w <= a_ram_data_out_bus_w(2*mpr-1 downto 0);
              
              ram_data_out0_x <= a_ram_data_out_bus_x(8*mpr-1 downto 6*mpr);
              ram_data_out1_x <= a_ram_data_out_bus_x(6*mpr-1 downto 4*mpr);
              ram_data_out2_x <= a_ram_data_out_bus_x(4*mpr-1 downto 2*mpr);
              ram_data_out3_x <= a_ram_data_out_bus_x(2*mpr-1 downto 0);
  
              ram_data_out0_y <= a_ram_data_out_bus_y(8*mpr-1 downto 6*mpr);
              ram_data_out1_y <= a_ram_data_out_bus_y(6*mpr-1 downto 4*mpr);
              ram_data_out2_y <= a_ram_data_out_bus_y(4*mpr-1 downto 2*mpr);
              ram_data_out3_y <= a_ram_data_out_bus_y(2*mpr-1 downto 0);
              
              ram_data_out0_z <= a_ram_data_out_bus_z(8*mpr-1 downto 6*mpr);
              ram_data_out1_z <= a_ram_data_out_bus_z(6*mpr-1 downto 4*mpr);
              ram_data_out2_z <= a_ram_data_out_bus_z(4*mpr-1 downto 2*mpr);
              ram_data_out3_z <= a_ram_data_out_bus_z(2*mpr-1 downto 0);
        
            when "01" =>
              ram_data_out0_w <= a_ram_data_out_bus_w(8*mpr-1 downto 6*mpr);
              ram_data_out1_w <= a_ram_data_out_bus_w(6*mpr-1 downto 4*mpr);
              ram_data_out2_w <= a_ram_data_out_bus_w(4*mpr-1 downto 2*mpr);
              ram_data_out3_w <= a_ram_data_out_bus_w(2*mpr-1 downto 0);
              
              ram_data_out0_x <= a_ram_data_out_bus_x(8*mpr-1 downto 6*mpr);
              ram_data_out1_x <= a_ram_data_out_bus_x(6*mpr-1 downto 4*mpr);
              ram_data_out2_x <= a_ram_data_out_bus_x(4*mpr-1 downto 2*mpr);
              ram_data_out3_x <= a_ram_data_out_bus_x(2*mpr-1 downto 0);
  
              ram_data_out0_y <= a_ram_data_out_bus_y(8*mpr-1 downto 6*mpr);
              ram_data_out1_y <= a_ram_data_out_bus_y(6*mpr-1 downto 4*mpr);
              ram_data_out2_y <= a_ram_data_out_bus_y(4*mpr-1 downto 2*mpr);
              ram_data_out3_y <= a_ram_data_out_bus_y(2*mpr-1 downto 0);
              
              ram_data_out0_z <= a_ram_data_out_bus_z(8*mpr-1 downto 6*mpr);
              ram_data_out1_z <= a_ram_data_out_bus_z(6*mpr-1 downto 4*mpr);
              ram_data_out2_z <= a_ram_data_out_bus_z(4*mpr-1 downto 2*mpr);
              ram_data_out3_z <= a_ram_data_out_bus_z(2*mpr-1 downto 0);
          
            when "10" =>
              ram_data_out0_w <= b_ram_data_out_bus_w(8*mpr-1 downto 6*mpr);
              ram_data_out1_w <= b_ram_data_out_bus_w(6*mpr-1 downto 4*mpr);
              ram_data_out2_w <= b_ram_data_out_bus_w(4*mpr-1 downto 2*mpr);
              ram_data_out3_w <= b_ram_data_out_bus_w(2*mpr-1 downto 0);
              
              ram_data_out0_x <= b_ram_data_out_bus_x(8*mpr-1 downto 6*mpr);
              ram_data_out1_x <= b_ram_data_out_bus_x(6*mpr-1 downto 4*mpr);
              ram_data_out2_x <= b_ram_data_out_bus_x(4*mpr-1 downto 2*mpr);
              ram_data_out3_x <= b_ram_data_out_bus_x(2*mpr-1 downto 0);
              
              ram_data_out0_y <= b_ram_data_out_bus_y(8*mpr-1 downto 6*mpr);
              ram_data_out1_y <= b_ram_data_out_bus_y(6*mpr-1 downto 4*mpr);
              ram_data_out2_y <= b_ram_data_out_bus_y(4*mpr-1 downto 2*mpr);
              ram_data_out3_y <= b_ram_data_out_bus_y(2*mpr-1 downto 0);
              
              ram_data_out0_z <= b_ram_data_out_bus_z(8*mpr-1 downto 6*mpr);
              ram_data_out1_z <= b_ram_data_out_bus_z(6*mpr-1 downto 4*mpr);
              ram_data_out2_z <= b_ram_data_out_bus_z(4*mpr-1 downto 2*mpr);
              ram_data_out3_z <= b_ram_data_out_bus_z(2*mpr-1 downto 0);
            when "11" =>
              ram_data_out0_w <= b_ram_data_out_bus_w(8*mpr-1 downto 6*mpr);
              ram_data_out1_w <= b_ram_data_out_bus_x(8*mpr-1 downto 6*mpr);
              ram_data_out2_w <= b_ram_data_out_bus_y(8*mpr-1 downto 6*mpr);
              ram_data_out3_w <= b_ram_data_out_bus_z(8*mpr-1 downto 6*mpr);
              
              ram_data_out0_x <= b_ram_data_out_bus_w(6*mpr-1 downto 4*mpr);
              ram_data_out1_x <= b_ram_data_out_bus_x(6*mpr-1 downto 4*mpr);
              ram_data_out2_x <= b_ram_data_out_bus_y(6*mpr-1 downto 4*mpr);
              ram_data_out3_x <= b_ram_data_out_bus_z(6*mpr-1 downto 4*mpr);
              
              ram_data_out0_y <= b_ram_data_out_bus_w(4*mpr-1 downto 2*mpr);
              ram_data_out1_y <= b_ram_data_out_bus_x(4*mpr-1 downto 2*mpr);
              ram_data_out2_y <= b_ram_data_out_bus_y(4*mpr-1 downto 2*mpr);
              ram_data_out3_y <= b_ram_data_out_bus_z(4*mpr-1 downto 2*mpr);
              
              ram_data_out0_z <= b_ram_data_out_bus_w(2*mpr-1 downto 0);
              ram_data_out1_z <= b_ram_data_out_bus_x(2*mpr-1 downto 0);
              ram_data_out2_z <= b_ram_data_out_bus_y(2*mpr-1 downto 0);
              ram_data_out3_z <= b_ram_data_out_bus_z(2*mpr-1 downto 0);
            
            when others =>
              ram_data_out0_w <= b_ram_data_out_bus_w(8*mpr-1 downto 6*mpr);
              ram_data_out1_w <= b_ram_data_out_bus_x(8*mpr-1 downto 6*mpr);
              ram_data_out2_w <= b_ram_data_out_bus_y(8*mpr-1 downto 6*mpr);
              ram_data_out3_w <= b_ram_data_out_bus_z(8*mpr-1 downto 6*mpr);
              
              ram_data_out0_x <= b_ram_data_out_bus_w(6*mpr-1 downto 4*mpr);
              ram_data_out1_x <= b_ram_data_out_bus_x(6*mpr-1 downto 4*mpr);
              ram_data_out2_x <= b_ram_data_out_bus_y(6*mpr-1 downto 4*mpr);
              ram_data_out3_x <= b_ram_data_out_bus_z(6*mpr-1 downto 4*mpr);
              
              ram_data_out0_y <= b_ram_data_out_bus_w(4*mpr-1 downto 2*mpr);
              ram_data_out1_y <= b_ram_data_out_bus_x(4*mpr-1 downto 2*mpr);
              ram_data_out2_y <= b_ram_data_out_bus_y(4*mpr-1 downto 2*mpr);
              ram_data_out3_y <= b_ram_data_out_bus_z(4*mpr-1 downto 2*mpr);
              
              ram_data_out0_z <= b_ram_data_out_bus_w(2*mpr-1 downto 0);
              ram_data_out1_z <= b_ram_data_out_bus_x(2*mpr-1 downto 0);
              ram_data_out2_z <= b_ram_data_out_bus_y(2*mpr-1 downto 0);
              ram_data_out3_z <= b_ram_data_out_bus_z(2*mpr-1 downto 0);
          end case;                     
      end if;
    end process sel_ram_data;
    
  end generate gen_r2_wd; 
    
sel_ram_addr:process(clk,global_clock_enable)is
    begin
if((rising_edge(clk) and global_clock_enable='1'))then
        if(sel_anb_addr='1') then
            rdaddress_b_bus <= rdaddr0_sw & rdaddr1_sw & rdaddr2_sw & rdaddr3_sw;
            rdaddress_a_bus <= (others=>'0');
        else
            rdaddress_a_bus <= rdaddr0_sw & rdaddr1_sw & rdaddr2_sw & rdaddr3_sw;
            rdaddress_b_bus <= (others=>'0');
        end if;       
      end if;
    end process sel_ram_addr;

  
end cnt_sw;











