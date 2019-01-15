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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_bfp_o_1pt.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all; 
use work.fft_pack.all;
entity asj_fft_bfp_o_1pt is
    generic (
    				mpr 	 : integer :=16;
    				bfp    : integer :=1;
    				fpr 	 : integer :=5;
    				rbuspr : integer :=64 -- 4*mpr
		);
    port (
global_clock_enable : in std_logic;
         clk   		: in std_logic;
         reset 		: in std_logic;
         next_pass : in std_logic;
         data_rdy : in std_logic;
         real_bfp_0_in : in std_logic_vector(mpr-1 downto 0); 
         real_bfp_1_in : in std_logic_vector(mpr-1 downto 0); 
         real_bfp_2_in : in std_logic_vector(mpr-1 downto 0); 
         real_bfp_3_in : in std_logic_vector(mpr-1 downto 0); 
         imag_bfp_0_in : in std_logic_vector(mpr-1 downto 0); 
         imag_bfp_1_in : in std_logic_vector(mpr-1 downto 0); 
         imag_bfp_2_in : in std_logic_vector(mpr-1 downto 0); 
         imag_bfp_3_in : in std_logic_vector(mpr-1 downto 0); 
         gain_out : out std_logic_vector(fpr-1 downto 0)
		     );
end asj_fft_bfp_o_1pt;

architecture output_bfp of asj_fft_bfp_o_1pt is

	function sgn_ex(inval : std_logic_vector; w : integer; b : integer) return std_logic_vector is
	-- sign extend input std_logic_vector of width w by b bits
	variable temp :   std_logic_vector(w+b-1 downto 0);
	begin
		temp(w+b-1 downto w-1):=(w+b-1 downto w-1 => inval(w-1));
		temp(w-2 downto 0) := inval(w-2 downto 0);
	return temp;
	end	sgn_ex;
	
	
	
	function int2ustd(value : integer; width : integer) return std_logic_vector is 
	-- convert integer to unsigned std_logicvector
	variable temp :   std_logic_vector(width-1 downto 0);
	begin
	if (width>0) then 
			temp:=conv_std_logic_vector(conv_unsigned(value, width ), width);
	end if ;
	return temp;
	end int2ustd;
	signal real_bfp_in : std_logic_vector(rbuspr-1 downto 0);
	signal imag_bfp_in : std_logic_vector(rbuspr-1 downto 0);
	type rail_arr  is array (0 to 3) of std_logic_vector(fpr downto 0);
	signal rail_p_r : rail_arr; -- real positive rail
	signal rail_p_i : rail_arr; -- imag positive rail
	signal rail_n_r : rail_arr; -- real negative rail
	signal rail_n_i : rail_arr; -- imag negative rail
	
	signal top : std_logic_vector(fpr downto 0);
	signal bottom : std_logic_vector(fpr downto 0);
	
	signal slb_i    : std_logic_vector(fpr-1 downto 0);
	signal gain_lut_8pts    : std_logic_vector(fpr downto 0);
	signal gain_lut_blk    : std_logic_vector(fpr downto 0);
	signal lut_out_tmp     : std_logic_vector(2 downto 0);
	         
	
	
	begin
	-----------------------------------------------------------------------------------------------
	-- Fixed Point - Support for non-Block-Floating Point is not in 2.1.2!
	-- This was a hook to see if it could be easily enabled.
	-----------------------------------------------------------------------------------------------	
	gen_fixed : if(bfp=0) generate	
		gain_out <= (others=>'0');	
	end generate gen_fixed;
	
-----------------------------------------------------------------------------------------------
-- Block Floating Point Detector
-----------------------------------------------------------------------------------------------	
gen_blk_float : if(bfp=1) generate	
			
		real_bfp_in(4*mpr-1 downto 3*mpr)   <= real_bfp_0_in;
		real_bfp_in(3*mpr-1 downto 2*mpr) 	<= real_bfp_1_in;
		real_bfp_in(2*mpr-1 downto mpr) 		<= real_bfp_2_in;
		real_bfp_in(mpr-1 downto 0) 				<= real_bfp_3_in;
		imag_bfp_in(4*mpr-1 downto 3*mpr)  <= imag_bfp_0_in;
		imag_bfp_in(3*mpr-1 downto 2*mpr)  <= imag_bfp_1_in;
		imag_bfp_in(2*mpr-1 downto mpr) 	 <= imag_bfp_2_in;
		imag_bfp_in(mpr-1 downto 0) 			 <= imag_bfp_3_in;
	  
    form_rails : for i in 0 to 3 generate
    	bit_by_bit : for k in fpr downto 0 generate
	    	rail_p_r(i)(k) <=not(real_bfp_in((4-i)*mpr -1)) and real_bfp_in((4-i)*mpr-(fpr+1-k));
	      rail_p_i(i)(k) <=not(imag_bfp_in((4-i)*mpr -1)) and imag_bfp_in((4-i)*mpr-(fpr+1-k));
	      rail_n_r(i)(k) <=not(real_bfp_in((4-i)*mpr -1)) or real_bfp_in((4-i)*mpr-(fpr+1-k));
	      rail_n_i(i)(k) <=not(imag_bfp_in((4-i)*mpr -1)) or imag_bfp_in((4-i)*mpr-(fpr+1-k));
      end generate bit_by_bit;
    end generate form_rails;
	  bit_by_bit_2 : for k in fpr downto 0 generate
    	top(k) <= rail_p_r(0)(k) or rail_p_r(1)(k) or rail_p_r(2)(k) or rail_p_r(3)(k) or rail_p_i(0)(k) or rail_p_i(1)(k) or rail_p_i(2)(k) or rail_p_i(3)(k);
    	bottom(k) <= rail_n_r(0)(k) and rail_n_r(1)(k) and rail_n_r(2)(k) and rail_n_r(3)(k) and rail_n_i(0)(k) and rail_n_i(1)(k) and rail_n_i(2)(k) and rail_n_i(3)(k);
    end generate bit_by_bit_2;
  

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- 4 Bit BFP
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

gen_4bit_bfp : if(fpr=4) generate

bfp:process(clk,global_clock_enable,reset,top,bottom)
    begin
if((rising_edge(clk) and global_clock_enable='1'))then
      if (reset = '1') then
  		  gain_lut_8pts(fpr downto 0)<= (others=>'0');
      elsif(data_rdy='1') then
      	gain_lut_8pts(fpr downto 0) <= (top(4) or (not(bottom(4)))) & (top(3) or (not(bottom(3)))) & (top(2) or (not(bottom(2)))) & (top(1) or (not(bottom(1)))) & (top(0) or (not(bottom(0))));
      else
      	gain_lut_8pts(fpr downto 0) <=(others=>'0');
      end if;
  	end if;
  end process;
  
  gain_out <= gain_lut_8pts(fpr-1 downto 0);

end generate gen_4bit_bfp;


-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- 5 Bit BFP
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
    
gen_5bit_bfp : if(fpr=5) generate

bfp:process(clk,global_clock_enable,reset,top,bottom,data_rdy)
    begin
if((rising_edge(clk) and global_clock_enable='1'))then
      if (reset = '1') then
  		  gain_lut_8pts(fpr downto 0)<= (others=>'0');
      elsif(data_rdy='1') then
      	gain_lut_8pts(fpr downto 0) <= (top(5) or (not(bottom(5)))) & (top(4) or (not(bottom(4)))) & (top(3) or (not(bottom(3)))) & (top(2) or (not(bottom(2)))) & (top(1) or (not(bottom(1)))) & (top(0) or (not(bottom(0))));
      else
        gain_lut_8pts(fpr downto 0)<= (others=>'0');
      end if;
  	end if;
  end process bfp;
  
  gain_out <= gain_lut_8pts(fpr-1 downto 0);

end generate gen_5bit_bfp;


end generate gen_blk_float;



end;
