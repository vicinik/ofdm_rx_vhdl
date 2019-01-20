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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_lpp.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all; 
use work.fft_pack.all;
entity asj_fft_lpp is
    generic (
    				 mpr : integer := 16;  
    				 apr : integer := 16;  
             twr : integer := 16;
             nstages: integer := 6;
             pipe: integer := 1
		);
    port (
global_clock_enable : in std_logic;
         clk   		: in std_logic;
         reset 		: in std_logic;
			   data_1_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_2_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_3_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_4_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_1_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_2_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_3_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_4_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_1_real_o : out std_logic_vector(mpr-1 downto 0);
		     data_2_real_o : out std_logic_vector(mpr-1 downto 0);
		     data_3_real_o : out std_logic_vector(mpr-1 downto 0);
		     data_4_real_o : out std_logic_vector(mpr-1 downto 0);
		     data_1_imag_o : out std_logic_vector(mpr-1 downto 0);
		     data_2_imag_o : out std_logic_vector(mpr-1 downto 0);
		     data_3_imag_o : out std_logic_vector(mpr-1 downto 0);
		     data_4_imag_o : out std_logic_vector(mpr-1 downto 0)
		     );
end asj_fft_lpp;

architecture dft of asj_fft_lpp is

	constant switch : integer :=1;
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


	constant opr : integer :=mpr+twr;
	constant oprp1 : integer :=mpr+twr+1;
	constant oprp2 : integer :=mpr+twr+2;
	
  type four_by_four_m  is array (0 to 3, 0 to 1) of std_logic_vector (mpr downto 0);
  type four_by_four_m1 is array (0 to 3, 0 to 1) of std_logic_vector (mpr+1 downto 0);
  type four_by_four_m2 is array (0 to 3, 0 to 1) of std_logic_vector (mpr-1 downto 0);
  
  type pipe_balancing_act is array (0 to nstages-1,0 to 1) of std_logic_vector (mpr-1 downto 0);
  
  signal butterfly_st1 : four_by_four_m;
  signal butterfly_st2 : four_by_four_m1;
  signal butterfly_out : four_by_four_m2;
  signal reg_no_twiddle : pipe_balancing_act;
  
  
  
begin
  
  
    -- 4 Point DFT
dft_of_4_pts:process(clk,global_clock_enable,reset)is
    begin
if((rising_edge(clk) and global_clock_enable='1'))then
	  		if(reset='1') then
	  			for i in 0 to 3 loop
	  				for j in 0 to 1 loop
	  					butterfly_st1(i,j)(mpr downto 0) <= (others=>'0');
	  					butterfly_st2(i,j)(mpr+1 downto 0) <= (others=>'0');
	  					--butterfly_out(i,j)(mpr-1 downto 0) <= (others=>'0');
	  				end loop;
	  			end loop;
	  		else
	  		
	  			butterfly_st1(0,0)(mpr downto 0) <= sgn_ex(data_1_real_i,mpr,1) + sgn_ex(data_3_real_i,mpr,1); --xr(1) + xr(3)
    			butterfly_st1(1,0)(mpr downto 0) <= sgn_ex(data_2_real_i,mpr,1) + sgn_ex(data_4_real_i,mpr,1); --xr(2) + xr(4)
    			butterfly_st1(2,0)(mpr downto 0) <= sgn_ex(data_1_real_i,mpr,1) - sgn_ex(data_3_real_i,mpr,1); --xr(1) - xr(3)
    			butterfly_st1(3,0)(mpr downto 0) <= sgn_ex(data_2_real_i,mpr,1) - sgn_ex(data_4_real_i,mpr,1); --xr(2) - xr(4)
	  			butterfly_st1(0,1)(mpr downto 0) <= sgn_ex(data_1_imag_i,mpr,1) + sgn_ex(data_3_imag_i,mpr,1); --xi(1) + xi(3)
    			butterfly_st1(1,1)(mpr downto 0) <= sgn_ex(data_2_imag_i,mpr,1) + sgn_ex(data_4_imag_i,mpr,1); --xi(2) + xi(4)
    	    butterfly_st1(2,1)(mpr downto 0) <= sgn_ex(data_1_imag_i,mpr,1) - sgn_ex(data_3_imag_i,mpr,1); --xi(1) - xi(3)
    		  butterfly_st1(3,1)(mpr downto 0) <= sgn_ex(data_2_imag_i,mpr,1) - sgn_ex(data_4_imag_i,mpr,1); --xi(2) - xi(4)
					--Gr(1) = xr(1) + xr(2) + xr(3) + xr(4)
	  			butterfly_st2(0,0)(mpr+1 downto 0) <= sgn_ex(butterfly_st1(0,0),mpr+1,1) + sgn_ex(butterfly_st1(1,0),mpr+1,1); 
	  			--Gr(2) = xr(1) + xi(2) - xr(3) - xi(4) 
    			butterfly_st2(1,0)(mpr+1 downto 0) <= sgn_ex(butterfly_st1(2,0),mpr+1,1) + sgn_ex(butterfly_st1(3,1),mpr+1,1); 
    			--Gr(3) = xr(1) - xr(2) + xr(3) - xr(4) 
    			butterfly_st2(2,0)(mpr+1 downto 0) <= sgn_ex(butterfly_st1(0,0),mpr+1,1) - sgn_ex(butterfly_st1(1,0),mpr+1,1); 
    			--Gr(4) = xr(1) - xi(2) - xr(3) + xi(4) 
    			butterfly_st2(3,0)(mpr+1 downto 0) <= sgn_ex(butterfly_st1(2,0),mpr+1,1) - sgn_ex(butterfly_st1(3,1),mpr+1,1); 
    			--Gi(1)= xi(1) + xi(2) + xi(3) + xi(4)
	  			butterfly_st2(0,1)(mpr+1 downto 0) <= sgn_ex(butterfly_st1(0,1),mpr+1,1) + sgn_ex(butterfly_st1(1,1),mpr+1,1); 
	  			--Gi(2)= xi(1) - xr(2) - xi(3) + xr(4)
    			butterfly_st2(1,1)(mpr+1 downto 0) <= sgn_ex(butterfly_st1(2,1),mpr+1,1) - sgn_ex(butterfly_st1(3,0),mpr+1,1); 
    			--Gi(3) = xi(1) - xi(2) + xi(3) - xi(4)
    	    butterfly_st2(2,1)(mpr+1 downto 0) <= sgn_ex(butterfly_st1(0,1),mpr+1,1) - sgn_ex(butterfly_st1(1,1),mpr+1,1); 
    	    --Gi(4) = xi(1) + xr(2) - xi(3) - xr(4)
    		  butterfly_st2(3,1)(mpr+1 downto 0) <= sgn_ex(butterfly_st1(2,1),mpr+1,1) + sgn_ex(butterfly_st1(3,0),mpr+1,1); 
    		  -----------------------------------------------------------------------------------------------------------------------------
    		  -- Shift by 2 and round
					butterfly_out(0,0)(mpr-1 downto 0) <= butterfly_st2(0,0)(mpr+1 downto 2) + ((mpr-1 downto 1 => '0') & butterfly_st2(0,0)(1));  
					butterfly_out(1,0)(mpr-1 downto 0) <= butterfly_st2(1,0)(mpr+1 downto 2) + ((mpr-1 downto 1 => '0') & butterfly_st2(1,0)(1));
    	  	butterfly_out(2,0)(mpr-1 downto 0) <= butterfly_st2(2,0)(mpr+1 downto 2) + ((mpr-1 downto 1 => '0') & butterfly_st2(2,0)(1));
    	    butterfly_out(3,0)(mpr-1 downto 0) <= butterfly_st2(3,0)(mpr+1 downto 2) + ((mpr-1 downto 1 => '0') & butterfly_st2(3,0)(1));
    	    butterfly_out(0,1)(mpr-1 downto 0) <= butterfly_st2(0,1)(mpr+1 downto 2) + ((mpr-1 downto 1 => '0') & butterfly_st2(0,1)(1));  
  				butterfly_out(1,1)(mpr-1 downto 0) <= butterfly_st2(1,1)(mpr+1 downto 2) + ((mpr-1 downto 1 => '0') & butterfly_st2(1,1)(1));
  				butterfly_out(2,1)(mpr-1 downto 0) <= butterfly_st2(2,1)(mpr+1 downto 2) + ((mpr-1 downto 1 => '0') & butterfly_st2(2,1)(1));
  				butterfly_out(3,1)(mpr-1 downto 0) <= butterfly_st2(3,1)(mpr+1 downto 2) + ((mpr-1 downto 1 => '0') & butterfly_st2(3,1)(1));
  				
    		end if;
    	end if;
  end process dft_of_4_pts;
  
    	    

pipe_delay:process(clk,global_clock_enable,reset)is
  begin
if((rising_edge(clk) and global_clock_enable='1'))then
  		if(reset='1') then
  			for i in nstages-1 downto 0 loop
  				for j in 1 downto 0 loop
  					reg_no_twiddle(i,j) <= (others=> '0');
  				end loop;	
  			end loop;
  		else
  			for i in nstages-1 downto 1 loop
  					reg_no_twiddle(i,0)(mpr-1 downto 0) <= reg_no_twiddle(i-1,0)(mpr-1 downto 0);
  					reg_no_twiddle(i,1)(mpr-1 downto 0) <= reg_no_twiddle(i-1,1)(mpr-1 downto 0);
  			end loop;
  			reg_no_twiddle(0,0)(mpr-1 downto 0)  <= butterfly_out(0,0)(mpr-1 downto 0);
  			reg_no_twiddle(0,1)(mpr-1 downto 0)  <= butterfly_out(0,1)(mpr-1 downto 0);
  		end if;
  	end if;
  end process pipe_delay;
  			
  
  
  data_1_real_o <= reg_no_twiddle(nstages-1,0);
  data_1_imag_o <= reg_no_twiddle(nstages-1,1);
  
  
  
  
  
 
end dft;











