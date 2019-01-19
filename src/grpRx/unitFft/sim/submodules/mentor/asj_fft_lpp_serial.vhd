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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_lpp_serial.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all; 

use work.fft_pack.all;
entity asj_fft_lpp_serial is
    generic (
    				 mpr : integer := 16;
    				 arch : integer :=1;
    				 nume : integer :=1;  
    				 apr : integer := 6;  
             del : integer :=4
		);
    port (
global_clock_enable : in std_logic;
         clk   		: in std_logic;
         reset    : in std_logic;
         --clken   : in std_logic;
         lpp_en   : in std_logic;
         data_1_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_2_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_3_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_4_real_i : in std_logic_vector(mpr-1 downto 0);
		     data_1_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_2_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_3_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_4_imag_i : in std_logic_vector(mpr-1 downto 0);
		     data_real_o : out std_logic_vector(mpr-1 downto 0);
		     data_imag_o : out std_logic_vector(mpr-1 downto 0);
		     data_val    : out std_logic
		 );
end asj_fft_lpp_serial;

architecture lp of asj_fft_lpp_serial is

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
	constant switch : integer :=1;
	constant new_scaling : integer :=0;
	constant fullrnd : integer :=1;
	constant add_p : integer :=2-fullrnd;
  constant apri  : integer := apr+nume+1;
  constant apri_qe  : integer := apr+4;
	signal dri_unscaled_0       : std_logic_vector(mpr-1 downto 0);
	signal dri_unscaled_1       : std_logic_vector(mpr-1 downto 0);
	signal dri_unscaled_2       : std_logic_vector(mpr-1 downto 0);
	signal dri_unscaled_3       : std_logic_vector(mpr-1 downto 0);
	signal dri_scaled_0         : std_logic_vector(mpr-1 downto 0);
	signal dri_scaled_1         : std_logic_vector(mpr-1 downto 0);
	signal dri_scaled_2         : std_logic_vector(mpr-1 downto 0);
	signal dri_scaled_3         : std_logic_vector(mpr-1 downto 0);
	
	signal dii_unscaled_0       : std_logic_vector(mpr-1 downto 0);
	signal dii_unscaled_1       : std_logic_vector(mpr-1 downto 0);
	signal dii_unscaled_2       : std_logic_vector(mpr-1 downto 0);
	signal dii_unscaled_3       : std_logic_vector(mpr-1 downto 0);
	signal dii_scaled_0         : std_logic_vector(mpr-1 downto 0);
	signal dii_scaled_1         : std_logic_vector(mpr-1 downto 0);
	signal dii_scaled_2         : std_logic_vector(mpr-1 downto 0);
	signal dii_scaled_3         : std_logic_vector(mpr-1 downto 0);  
	
	--Adder tree level one signals
	signal add_in_r_a           : std_logic_vector(mpr downto 0);
	signal add_in_r_b           : std_logic_vector(mpr downto 0);
	signal add_in_r_c           : std_logic_vector(mpr downto 0);
	signal add_in_r_d           : std_logic_vector(mpr downto 0);
	signal add_in_i_a           : std_logic_vector(mpr downto 0);
	signal add_in_i_b           : std_logic_vector(mpr downto 0);
	signal add_in_i_c           : std_logic_vector(mpr downto 0);
	signal add_in_i_d           : std_logic_vector(mpr downto 0);
	
	signal result_ra            : std_logic_vector(mpr downto 0);
	signal result_rb            : std_logic_vector(mpr downto 0);
	signal result_ia            : std_logic_vector(mpr downto 0);
	signal result_ib            : std_logic_vector(mpr downto 0);
	
	
	--Adder tree level two signals
	signal add_in_r2_a           : std_logic_vector(mpr+1 downto 0);
	signal add_in_r2_b           : std_logic_vector(mpr+1 downto 0);
	signal add_in_i2_a           : std_logic_vector(mpr+1 downto 0);
	signal add_in_i2_b           : std_logic_vector(mpr+1 downto 0);
	
	signal output_r              : std_logic_vector(mpr+1 downto 0);
	signal output_i              : std_logic_vector(mpr+1 downto 0);
	signal output_r_by2           : std_logic_vector(mpr+1 downto 0);
	signal output_i_by2           : std_logic_vector(mpr+1 downto 0);
	
	signal output_r_rnd          : std_logic_vector(mpr-1 downto 0);
	signal output_i_rnd          : std_logic_vector(mpr-1 downto 0);
	
	signal offset_counter       : std_logic_vector(apri-1 downto 0);   
	signal offset_counter_qe       : std_logic_vector(apri_qe-1 downto 0);   
	
	signal sign_sel             : std_logic_vector(1 downto 0);   
	signal sign_sel_d             : std_logic_vector(1 downto 0);      
	signal sign_vec             : std_logic_vector(3 downto 0);   
	signal sgn_0                : std_logic;
	signal sgn_1                : std_logic;
	signal sgn_2r                : std_logic;
	signal sgn_2i                : std_logic;
	signal data_val_i                : std_logic;
	
  
begin
  
  gen_unsc : if(new_scaling=0) generate
  	dri_unscaled_0 <= data_1_real_i;
		dri_unscaled_1 <= data_2_real_i;
		dri_unscaled_2 <= data_3_real_i;
		dri_unscaled_3 <= data_4_real_i;
		dii_unscaled_0 <= data_1_imag_i;
		dii_unscaled_1 <= data_2_imag_i;
		dii_unscaled_2 <= data_3_imag_i;
		dii_unscaled_3 <= data_4_imag_i;
	end generate gen_unsc;
	
	--gen_sc : if(new_scaling=1) generate
  --	dri_unscaled_0 <= data_1_real_i(mpr-2 downto 0) & '0';
	--	dri_unscaled_1 <= data_2_real_i(mpr-2 downto 0) & '0';
	--	dri_unscaled_2 <= data_3_real_i(mpr-2 downto 0) & '0';
	--	dri_unscaled_3 <= data_4_real_i(mpr-2 downto 0) & '0';
	--	dii_unscaled_0 <= data_1_imag_i(mpr-2 downto 0) & '0';
	--	dii_unscaled_1 <= data_2_imag_i(mpr-2 downto 0) & '0';
	--	dii_unscaled_2 <= data_3_imag_i(mpr-2 downto 0) & '0';
	--	dii_unscaled_3 <= data_4_imag_i(mpr-2 downto 0) & '0';
	--end generate gen_sc;
		
	
	
  
  	
  -----------------------------------------------------------------------------------------------
  -- Streaming
  -----------------------------------------------------------------------------------------------
  
  gen_str_val : if(arch=0) generate
  
offcnt:process(clk,global_clock_enable,reset,lpp_en)is
	  	begin
if((rising_edge(clk) and global_clock_enable='1'))then
	  			if(reset='1') then
	  				offset_counter <= int2ustd(0,apri);
	  			else
	  				if(lpp_en='1') then
	  					offset_counter <= int2ustd((2**apri)-1,apri);
	  				else
	  					offset_counter <= offset_counter + int2ustd(1,apri);
		  			end if;
		  		end if;
	  		end if;
	  	end process offcnt;
	  
	  			
valid_indicator:process(clk,global_clock_enable,reset,lpp_en)
	  	begin
if((rising_edge(clk) and global_clock_enable='1'))then
	  			if(reset='1') then
	  				data_val_i<='0';
	  			else
	  				if(lpp_en='1') then
	  					data_val_i<='1';
	  				end if;
	  			end if;
	  		end if;
	  	end process valid_indicator;
	  	
sign_sel_gen:process(clk,global_clock_enable,offset_counter)is
	  	begin
if((rising_edge(clk) and global_clock_enable='1'))then
	  			sign_sel <= offset_counter(apri-1 downto apri-2);
	  		end if;
	  	end process sign_sel_gen;
	  
	  
	  	delay_val : asj_fft_tdl_bit 
				generic map( 
								 		del   => del
								)
				port map( 	
global_clock_enable => global_clock_enable,
										clk 	=> clk,
										data_in 	=> data_val_i,
						 				data_out 	=> data_val
						);
						
				
  
	end generate gen_str_val;
	
	-----------------------------------------------------------------------------------------------
	-- Buffered Burst
	-----------------------------------------------------------------------------------------------
	
  gen_burst_val : if(arch=1 or arch=2) generate
  
  gen_se_de : if(nume=1 or nume=2) generate
offcnt:process(clk,global_clock_enable,reset,lpp_en)is
	  	begin
if((rising_edge(clk) and global_clock_enable='1'))then
	  			if(reset='1') then
	  				offset_counter <= int2ustd(0,apri);
	  			else
	  				if(lpp_en='1') then
	  					offset_counter <= int2ustd((2**apri)-1,apri);
	  				else
	  					offset_counter <= offset_counter + int2ustd(1,apri);
		  			end if;
		  		end if;
	  		end if;
	  	end process offcnt;
  
valid_indicator:process(clk,global_clock_enable,reset,lpp_en)
	  	begin
if((rising_edge(clk) and global_clock_enable='1'))then
	  			if(reset='1') then
	  				data_val_i<='0';
	  			else
	  				if(lpp_en='1') then
	  					data_val_i<='1';
	  				elsif(offset_counter=int2ustd((2**apri)-3,apri)) then
	  					data_val_i<='0';
	  				else
	  					data_val_i<=data_val_i;
	  				end if;
	  			end if;
	  		end if;
	  	end process valid_indicator;
	  	
sign_sel_gen:process(clk,global_clock_enable,offset_counter)is
  		begin
if((rising_edge(clk) and global_clock_enable='1'))then
	  			sign_sel <= offset_counter(apri-1 downto apri-2);
	  		end if;
  		end process sign_sel_gen;
		  
	  	
	  	
	end generate gen_se_de;
	  
	gen_qe : if(nume=4) generate
offcnt:process(clk,global_clock_enable,reset,lpp_en)is
	  	begin
if((rising_edge(clk) and global_clock_enable='1'))then
	  			if(reset='1') then
	  				offset_counter_qe <= int2ustd(0,apri_qe);
	  			else
	  				if(lpp_en='1') then
	  					offset_counter_qe <= int2ustd((2**apri_qe)-1,apri_qe);
	  				else
	  					offset_counter_qe <= offset_counter_qe + int2ustd(1,apri_qe);
		  			end if;
		  		end if;
	  		end if;
	  	end process offcnt;
  
valid_indicator:process(clk,global_clock_enable,reset,lpp_en)
	  	begin
if((rising_edge(clk) and global_clock_enable='1'))then
	  			if(reset='1') then
	  				data_val_i<='0';
	  			else
	  				if(lpp_en='1') then
	  					data_val_i<='1';
	  				elsif(offset_counter_qe=int2ustd((2**apri_qe)-3,apri_qe)) then
	  					data_val_i<='0';
	  				else
	  					data_val_i<=data_val_i;
	  				end if;
	  			end if;
	  		end if;
	  	end process valid_indicator;
	  	
sign_sel_gen:process(clk,global_clock_enable,offset_counter_qe)is
  	begin
if((rising_edge(clk) and global_clock_enable='1'))then
  			sign_sel <= offset_counter_qe(apri_qe-1 downto apri_qe-2);
  		end if;
  	end process sign_sel_gen;
	  	
	  	
	  	
	end generate gen_qe;
	  	
	  
	  	delay_val : asj_fft_tdl_bit 
				generic map( 
								 		del   => del
								)
				port map( 	
global_clock_enable => global_clock_enable,
										clk 	=> clk,
										data_in 	=> data_val_i,
						 				data_out 	=> data_val
						);
						
				
  	
	end generate gen_burst_val;
	
  
		
  
  
sign_gen:process(clk,global_clock_enable,sign_sel)is
  	begin
if((rising_edge(clk) and global_clock_enable='1'))then
  			sgn_2r <= sign_vec(1);
  			sgn_2i <= sign_vec(0);
  			case sign_sel(1 downto 0) is
  				when "00" =>
  					sign_vec<="1111";
  				when "01" => 
  					sign_vec<="0010";
  				when "10" => 
  					sign_vec<="1100";
  				when "11" => 
  					sign_vec<="0001";
  				when others =>
  					sign_vec<="XXXX";
  			end case;
  		end if;
  	end process sign_gen;
  	
  	
  	sgn_0 <= sign_vec(3);
  	sgn_1 <= sign_vec(2);
  	
sw_gen:process(clk,global_clock_enable,sign_sel)is
  	begin
if((rising_edge(clk) and global_clock_enable='1'))then
  		  if(sign_sel(0)='0') then	
  				add_in_r_c <= sgn_ex(dri_unscaled_1,mpr,1);
  				add_in_r_d <= sgn_ex(dri_unscaled_3,mpr,1);
  				add_in_i_c <= sgn_ex(dii_unscaled_1,mpr,1);
  				add_in_i_d <= sgn_ex(dii_unscaled_3,mpr,1);		
  			else
  				add_in_r_c <= sgn_ex(dii_unscaled_1,mpr,1);
  				add_in_r_d <= sgn_ex(dii_unscaled_3,mpr,1);
  				add_in_i_c <= sgn_ex(dri_unscaled_1,mpr,1);
  				add_in_i_d <= sgn_ex(dri_unscaled_3,mpr,1);		
				end if;  				
  			add_in_r_a <= sgn_ex(dri_unscaled_0,mpr,1);
  			add_in_r_b <= sgn_ex(dri_unscaled_2,mpr,1);
  			add_in_i_a <= sgn_ex(dii_unscaled_0,mpr,1);
  			add_in_i_b <= sgn_ex(dii_unscaled_2,mpr,1);
  			end if;
  	end process sw_gen;
  	
  	
  	
                                           
 -- Level one adders                                          
--  add_0_real : lpm_add_sub           
--  	generic map (
--			lpm_width => mpr+1,
--			lpm_direction => "UNUSED",
--			lpm_representation => "SIGNED",
--			--lpm_type => "LPM_ADD_SUB",
--			lpm_hint => "ONE_INPUT_IS_CONSTANT=NO",
--			lpm_pipeline => add_p
--		)
--		port map (
--			dataa => add_in_r_a,
--			add_sub => sgn_0,
--			datab => add_in_r_b,
--			clock => clk,
--			result => result_ra
--		);
--         
--  add_1_real : lpm_add_sub           
--  	generic map (
--			lpm_width => mpr+1,
--			lpm_direction => "UNUSED",
--			lpm_representation => "SIGNED",
--			--lpm_type => "LPM_ADD_SUB",
--			lpm_hint => "ONE_INPUT_IS_CONSTANT=NO",
--			lpm_pipeline => add_p
--		)
--		port map (
--			dataa => add_in_r_c,
--			add_sub => sgn_1,
--			datab => add_in_r_d,
--			clock => clk,
--			result => result_rb
--		);
--		
--		
--  add_0_imag : lpm_add_sub           
--  	generic map (
--			lpm_width => mpr+1,
--			lpm_direction => "UNUSED",
--			lpm_representation => "SIGNED",
--			--lpm_type => "LPM_ADD_SUB",
--			lpm_hint => "ONE_INPUT_IS_CONSTANT=NO",
--			lpm_pipeline => add_p
--		)
--		port map (
--			dataa => add_in_i_a,
--			add_sub => sgn_0,
--			datab => add_in_i_b,
--			clock => clk,
--			result => result_ia
--		);
--         
--  add_1_imag : lpm_add_sub           
--  	generic map (
--			lpm_width => mpr+1,
--			lpm_direction => "UNUSED",
--			lpm_representation => "SIGNED",
--			--lpm_type => "LPM_ADD_SUB",
--			lpm_hint => "ONE_INPUT_IS_CONSTANT=NO",
--			lpm_pipeline => add_p
--		)
--		port map (
--			dataa => add_in_i_c,
--			add_sub => sgn_1,
--			datab => add_in_i_d,
--			clock => clk,
--			result => result_ib
--		);
--		
--		add_in_r2_a <= sgn_ex(result_ra,mpr+1,1);
--		add_in_r2_b <= sgn_ex(result_rb,mpr+1,1);
--		add_in_i2_a <= sgn_ex(result_ia,mpr+1,1);
--		add_in_i2_b <= sgn_ex(result_ib,mpr+1,1);
--		
--		
--  -- Level two adders
--  add_2_real : lpm_add_sub           
--  	generic map (
--			lpm_width => mpr+2,
--			lpm_direction => "UNUSED",
--			lpm_representation => "SIGNED",
--			--lpm_type => "LPM_ADD_SUB",
--			lpm_hint => "ONE_INPUT_IS_CONSTANT=NO",
--			lpm_pipeline => add_p
--		)
--		port map (
--			dataa => add_in_r2_a,
--			add_sub => sgn_2r,
--			datab => add_in_r2_b,
--			clock => clk,
--			result => output_r
--		);
--         
--  add_2_imag : lpm_add_sub           
--  	generic map (
--			lpm_width => mpr+2,
--			lpm_direction => "UNUSED",
--			lpm_representation => "SIGNED",
--			--lpm_type => "LPM_ADD_SUB",
--			lpm_hint => "ONE_INPUT_IS_CONSTANT=NO",
--			lpm_pipeline => add_p
--		)
--		port map (
--			dataa => add_in_i2_a,
--			add_sub => sgn_2i,
--			datab => add_in_i2_b,
--			clock => clk,
--			result => output_i
--		);
		
l_one:process(clk,global_clock_enable)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(sgn_0='1') then
						result_ra <= add_in_r_a + add_in_r_b;
						result_ia <= add_in_i_a + add_in_i_b;
						result_rb <= add_in_r_c + add_in_r_d;
						result_ib <= add_in_i_c + add_in_i_d;
					else
						result_ra <= add_in_r_a - add_in_r_b;
						result_ia <= add_in_i_a - add_in_i_b;
						result_rb <= add_in_r_c - add_in_r_d;
						result_ib <= add_in_i_c - add_in_i_d;
					end if;
				end if;
			end process l_one;
    
		add_in_r2_a <= sgn_ex(result_ra,mpr+1,1);
		add_in_r2_b <= sgn_ex(result_rb,mpr+1,1);
		add_in_i2_a <= sgn_ex(result_ia,mpr+1,1);
		add_in_i2_b <= sgn_ex(result_ib,mpr+1,1);
    
								
l_two_r:process(clk,global_clock_enable)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(sgn_2r='1') then
						output_r <= add_in_r2_a + add_in_r2_b;
					else
						output_r <= add_in_r2_a - add_in_r2_b;
					end if;
				end if;
			end process l_two_r;
			
l_two_i:process(clk,global_clock_enable)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(sgn_2i='1') then
						output_i <= add_in_i2_a + add_in_i2_b;
					else
						output_i <= add_in_i2_a - add_in_i2_b;
					end if;
				end if;
			end process l_two_i;
			
					
		
		gen_full_rnd : if(fullrnd=1) generate
		
		--output_r_by2 <= output_r(mpr downto 0) & '0';
		--output_i_by2 <= output_i(mpr downto 0) & '0';
		
reg_output:process(clk,global_clock_enable,reset,output_r,output_i)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				if(reset='1') then
					data_real_o(mpr-1 downto 0) <= (others=>'0');
					data_real_o(mpr-1 downto 0) <= (others=>'0');
				else
					data_real_o(mpr-1 downto 0) <= output_r_rnd(mpr-1 downto 0);-- + ((mpr-1 downto 1 => '0') & (output_r(1) and not(output_r(mpr+1))));  
					data_imag_o(mpr-1 downto 0) <= output_i_rnd(mpr-1 downto 0);-- + ((mpr-1 downto 1 => '0') & (output_i(1) and not(output_i(mpr+1))));  			
				end if;
			end if;
		end process reg_output;
		
		u0 : asj_fft_pround
		generic map (     
									widthin		=> mpr+2,
									widthout	=> mpr,
									pipe      => 1
			)
		port map	( 
global_clock_enable => global_clock_enable,
									clk       => clk,
									clken     => '1',
									--xin				=> output_r_by2,
									xin				=> output_r,
									yout			=> output_r_rnd
			);	
		
  	u1 : asj_fft_pround
		generic map (     
									widthin		=> mpr+2,
									widthout	=> mpr,
									pipe      => 1
			)
		port map	( 
global_clock_enable => global_clock_enable,
									clk       => clk,
									clken     => '1',
									--xin				=> output_i_by2,
									xin				=> output_i,
									yout			=> output_i_rnd
			);	
		
	end generate gen_full_rnd;
	
	gen_fast_rnd : if(fullrnd=0) generate
		
reg_output:process(clk,global_clock_enable,reset,output_r,output_i)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				if(reset='1') then
					data_real_o(mpr-1 downto 0) <= (others=>'0');
					data_real_o(mpr-1 downto 0) <= (others=>'0');
				else
					--if(lpp_en='1') then
						data_real_o(mpr-1 downto 0) <= output_r(mpr+1 downto 2) + ((mpr-1 downto 1 => '0') & output_r(1));  
						data_imag_o(mpr-1 downto 0) <= output_i(mpr+1 downto 2) + ((mpr-1 downto 1 => '0') & output_i(1));  			
					--end if;
				end if;
			end if;
	end process reg_output;
		
	end generate gen_fast_rnd;
	
	
end lp;











