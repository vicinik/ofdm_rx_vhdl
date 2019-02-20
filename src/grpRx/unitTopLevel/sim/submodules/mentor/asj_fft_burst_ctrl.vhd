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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_burst_ctrl.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all; 
use work.fft_pack.all;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
-- Central Data and Address Switch and Registering for the Buffered Burst algorithm
-- Single Quad Output FFT Engine variation
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

entity asj_fft_burst_ctrl is
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
            ram_data_in0_sw  : in std_logic_vector(2*mpr-1 downto 0);
            ram_data_in1_sw  : in std_logic_vector(2*mpr-1 downto 0);
            ram_data_in2_sw  : in std_logic_vector(2*mpr-1 downto 0);
            ram_data_in3_sw  : in std_logic_vector(2*mpr-1 downto 0);
            i_ram_data_in0_sw  : in std_logic_vector(2*mpr-1 downto 0);
            i_ram_data_in1_sw  : in std_logic_vector(2*mpr-1 downto 0);
            i_ram_data_in2_sw  : in std_logic_vector(2*mpr-1 downto 0);
            i_ram_data_in3_sw  : in std_logic_vector(2*mpr-1 downto 0);
            a_ram_data_out_bus  : in std_logic_vector(cbuspr-1 downto 0);
            b_ram_data_out_bus  : in std_logic_vector(cbuspr-1 downto 0);
            a_ram_data_in_bus  : out std_logic_vector(cbuspr-1 downto 0);
            b_ram_data_in_bus  : out std_logic_vector(cbuspr-1 downto 0);
            wraddress_a_bus   : out std_logic_vector(abuspr-1 downto 0);
            wraddress_b_bus   : out std_logic_vector(abuspr-1 downto 0);
            rdaddress_a_bus   : out std_logic_vector(abuspr-1 downto 0);
            rdaddress_b_bus   : out std_logic_vector(abuspr-1 downto 0);
            ram_data_out0    : out std_logic_vector(2*mpr-1 downto 0);
            ram_data_out1    : out std_logic_vector(2*mpr-1 downto 0);
            ram_data_out2    : out std_logic_vector(2*mpr-1 downto 0);
            ram_data_out3    : out std_logic_vector(2*mpr-1 downto 0)
            
      );
end asj_fft_burst_ctrl;

architecture burst_sw of asj_fft_burst_ctrl is

constant reg_a_b : integer :=1;

begin
  
gen_reg : if(reg_a_b=1) generate
-- Note the pipelining is there for perf reasons, but not all buses are being muxed
-- If non-registered merging is done (especially in the case where there is no mux)
-- the datapath would have to be retimed, but the design could be that much smaller 
-- and not that much slower.
  
input_address:process(clk,global_clock_enable,wraddr_i0_sw,wraddr_i1_sw,wraddr_i2_sw,wraddr_i3_sw)is
    begin
if((rising_edge(clk) and global_clock_enable='1'))then
            wraddress_a_bus <= wraddr_i0_sw & wraddr_i1_sw & wraddr_i2_sw & wraddr_i3_sw;
      end if;
    end process input_address;
    
    
input_data:process(clk,global_clock_enable,i_ram_data_in0_sw,i_ram_data_in1_sw,i_ram_data_in2_sw,i_ram_data_in3_sw)is
    begin
if((rising_edge(clk) and global_clock_enable='1'))then
            a_ram_data_in_bus <= i_ram_data_in0_sw & i_ram_data_in1_sw & i_ram_data_in2_sw & i_ram_data_in3_sw;
      end if;
    end process input_data;
    
work_address:process(clk,global_clock_enable,wraddr0_sw,wraddr1_sw,wraddr2_sw,wraddr3_sw)is
    begin
if((rising_edge(clk) and global_clock_enable='1'))then
            wraddress_b_bus <= wraddr0_sw & wraddr1_sw & wraddr2_sw & wraddr3_sw;
      end if;
    end process work_address;   
    
    
work_data:process(clk,global_clock_enable,ram_data_in0_sw,ram_data_in1_sw,ram_data_in2_sw,ram_data_in3_sw)is
    begin
if((rising_edge(clk) and global_clock_enable='1'))then
            b_ram_data_in_bus <= ram_data_in0_sw & ram_data_in1_sw & ram_data_in2_sw & ram_data_in3_sw;
      end if;
    end process work_data;    
    
end generate gen_reg;

gen_no_reg : if(reg_a_b=0) generate
  
    wraddress_a_bus <= wraddr_i0_sw & wraddr_i1_sw & wraddr_i2_sw & wraddr_i3_sw;
    a_ram_data_in_bus <= i_ram_data_in0_sw & i_ram_data_in1_sw & i_ram_data_in2_sw & i_ram_data_in3_sw;
    wraddress_b_bus <= wraddr0_sw & wraddr1_sw & wraddr2_sw & wraddr3_sw;
    b_ram_data_in_bus <= ram_data_in0_sw & ram_data_in1_sw & ram_data_in2_sw & ram_data_in3_sw;
    
end generate gen_no_reg;
    
    
    
sel_ram_data:process(clk,global_clock_enable,sel_anb_ram,a_ram_data_out_bus,b_ram_data_out_bus)is
    begin
if((rising_edge(clk) and global_clock_enable='1'))then
        if(sel_anb_ram='1') then
            ram_data_out0 <= b_ram_data_out_bus(8*mpr-1 downto 6*mpr);
            ram_data_out1 <= b_ram_data_out_bus(6*mpr-1 downto 4*mpr);
            ram_data_out2 <= b_ram_data_out_bus(4*mpr-1 downto 2*mpr);
            ram_data_out3 <= b_ram_data_out_bus(2*mpr-1 downto 0);
        else
            ram_data_out0 <= a_ram_data_out_bus(8*mpr-1 downto 6*mpr);
            ram_data_out1 <= a_ram_data_out_bus(6*mpr-1 downto 4*mpr);
            ram_data_out2 <= a_ram_data_out_bus(4*mpr-1 downto 2*mpr);
            ram_data_out3 <= a_ram_data_out_bus(2*mpr-1 downto 0);
        end if;       
      end if;
    end process sel_ram_data;
    
sel_ram_addr:process(clk,global_clock_enable,sel_anb_addr,rdaddr0_sw,rdaddr1_sw,rdaddr2_sw,rdaddr3_sw)is
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

  
end burst_sw;











