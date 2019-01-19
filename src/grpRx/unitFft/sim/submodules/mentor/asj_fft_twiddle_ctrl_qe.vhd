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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_twiddle_ctrl_qe.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all; 
use work.fft_pack.all;
-----------------------------------------------------------------------------------------------
-- Central Data and Address Switch Control for Quad Engine Quad Output FFT
-----------------------------------------------------------------------------------------------
entity asj_fft_twiddle_ctrl_qe is
	generic(
						nps : integer :=256;
						log2_n_passes : integer :=3;
						X1            : integer:=23170;
						X2            : integer:=32767;
						apr : integer :=6;
						twr : integer :=16;
						twa : integer :=6
						
					);
	port(			clk 					: in std_logic;
global_clock_enable : in std_logic;
						reset    			: in std_logic;
						k_count_d1    : in std_logic_vector(apr-1 downto 0);
						k_count_d2    : in std_logic_vector(apr-1 downto 0);
						p_count_d1       : in std_logic_vector(2 downto 0);
						p_count_d2       : in std_logic_vector(2 downto 0);
						t1w_i  				: in std_logic_vector(2*twr-1 downto 0);
						t2w_i  				: in std_logic_vector(2*twr-1 downto 0);
						t3w_i  				: in std_logic_vector(2*twr-1 downto 0);
						t1x_i  				: in std_logic_vector(2*twr-1 downto 0);
						t2x_i  				: in std_logic_vector(2*twr-1 downto 0);
						t3x_i  				: in std_logic_vector(2*twr-1 downto 0);
						t1y_i  				: in std_logic_vector(2*twr-1 downto 0);
						t2y_i  				: in std_logic_vector(2*twr-1 downto 0);
						t3y_i  				: in std_logic_vector(2*twr-1 downto 0);
						t1z_i  				: in std_logic_vector(2*twr-1 downto 0);
						t2z_i  				: in std_logic_vector(2*twr-1 downto 0);
						t3z_i  				: in std_logic_vector(2*twr-1 downto 0);
						twade_0_i     : in std_logic_vector(twa-1 downto 0);
						twade_1_i     : in std_logic_vector(twa-1 downto 0);
						t1w_o  				: out std_logic_vector(2*twr-1 downto 0);
						t2w_o  				: out std_logic_vector(2*twr-1 downto 0);
						t3w_o  				: out std_logic_vector(2*twr-1 downto 0);
						t1x_o  				: out std_logic_vector(2*twr-1 downto 0);
						t2x_o  				: out std_logic_vector(2*twr-1 downto 0);
						t3x_o  				: out std_logic_vector(2*twr-1 downto 0);
						t1y_o  				: out std_logic_vector(2*twr-1 downto 0);
						t2y_o  				: out std_logic_vector(2*twr-1 downto 0);
						t3y_o  				: out std_logic_vector(2*twr-1 downto 0);
						t1z_o  				: out std_logic_vector(2*twr-1 downto 0);
						t2z_o  				: out std_logic_vector(2*twr-1 downto 0);
						t3z_o  				: out std_logic_vector(2*twr-1 downto 0);
						twade_0_o     : out std_logic_vector(twa-1 downto 0);
						twade_1_o     : out std_logic_vector(twa-1 downto 0)
			);
end asj_fft_twiddle_ctrl_qe;

architecture cnt_sw of asj_fft_twiddle_ctrl_qe is

constant last_pass_radix : integer :=(LOG4_CEIL(nps))-(LOG4_FLOOR(nps));
type twiddle_bus is array (0 to 2) of std_logic_vector(2*twr-1 downto 0);
	
signal twiddle_rom_out_w : twiddle_bus;
signal twiddle_rom_out_x : twiddle_bus;
signal twiddle_rom_out_y : twiddle_bus;
signal twiddle_rom_out_z : twiddle_bus;
signal twiddle_data_w 		: twiddle_bus;
signal twiddle_data_w_tmp : twiddle_bus;
signal twiddle_data_x 		: twiddle_bus;
signal twiddle_data_x_tmp : twiddle_bus;
signal twiddle_data_y 		: twiddle_bus;
signal twiddle_data_y_tmp : twiddle_bus;
signal twiddle_data_z 		: twiddle_bus;
signal twiddle_data_z_tmp : twiddle_bus;

signal sel_twid,sel_twid_ad : std_logic;

begin
	
twiddle_rom_out_w(0)<=t1w_i;
twiddle_rom_out_w(1)<=t2w_i;
twiddle_rom_out_w(2)<=t3w_i;
twiddle_rom_out_x(0)<=t1x_i;
twiddle_rom_out_x(1)<=t2x_i;
twiddle_rom_out_x(2)<=t3x_i;
twiddle_rom_out_y(0)<=t1y_i;
twiddle_rom_out_y(1)<=t2y_i;
twiddle_rom_out_y(2)<=t3y_i;
twiddle_rom_out_z(0)<=t1z_i;
twiddle_rom_out_z(1)<=t2z_i;
twiddle_rom_out_z(2)<=t3z_i;

t1w_o <= twiddle_data_w(0);
t2w_o <= twiddle_data_w(1);
t3w_o <= twiddle_data_w(2);
t1x_o <= twiddle_data_x(0);
t2x_o <= twiddle_data_x(1);
t3x_o <= twiddle_data_x(2);
t1y_o <= twiddle_data_y(0);
t2y_o <= twiddle_data_y(1);
t3y_o <= twiddle_data_y(2);
t1z_o <= twiddle_data_z(0);
t2z_o <= twiddle_data_z(1);
t3z_o <= twiddle_data_z(2);


-----------------------------------------------------------------------------------------------
-- N=256
-----------------------------------------------------------------------------------------------
gen_256 : if(nps=256) generate
		
twiddle_addr_sw:process(clk,global_clock_enable,reset,k_count_d1,p_count_d1)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d1 is
					when "000" =>
							sel_twid_ad <='1';
					when "001" =>
							sel_twid_ad <='1';
					when "010" =>		
						if(k_count_d1(1 downto 0)="00") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "011" =>
						if(k_count_d1(3 downto 0)="0000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when others=>
							sel_twid_ad<='1';
				end case;
			end if;
		end process twiddle_addr_sw;
-----------------------------------------------------------------------------------------------		
twiddle_addr_control:process(clk,global_clock_enable,twade_0_i,twade_1_i,p_count_d1)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d1 is
					when "001" =>
						twade_0_o <= twade_0_i;
						twade_1_o <= twade_1_i;
					when "010"=>
						--if(k_count_d1(1 downto 0)="00") then
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(2,twa);
							twade_1_o <= twade_1_i + int2ustd(2,twa);
						end if;
					when "011"=>
						--if(k_count_d1(3 downto 0)="0000") then
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(8,twa);
							twade_1_o <= twade_1_i + int2ustd(8,twa);
						end if;
					when others=>
						twade_0_o <= twade_0_i;
						twade_1_o <= twade_1_i;
				end case;
			end if;
		end process twiddle_addr_control;
-----------------------------------------------------------------------------------------------	
twiddle_sw:process(clk,global_clock_enable,reset,k_count_d2,p_count_d2)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d2 is
					when "000" =>
							sel_twid <='1';
					when "001" =>
							sel_twid <='1';
					when "010" =>		
						if(k_count_d2(1 downto 0)="00") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when "011" =>
						if(k_count_d2(3 downto 0)="0000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when others=>
							sel_twid<='1';
				end case;
			end if;
		end process twiddle_sw;
		
end generate gen_256;
-----------------------------------------------------------------------------------------------
-- N=512
-----------------------------------------------------------------------------------------------
gen_512 : if(nps=512) generate
		
twiddle_addr_sw:process(clk,global_clock_enable,reset,k_count_d1,p_count_d1)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d1 is
					when "000" =>
							sel_twid_ad <='1';
					when "001" =>
							sel_twid_ad <='1';
					when "010" =>		
						if(k_count_d1(1 downto 0)="00") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "011" =>
						if(k_count_d1(3 downto 0)="0000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "100" =>
						if(k_count_d1(4 downto 0)="10000") then
							sel_twid_ad<='0';
						--else
						--	sel_twid_ad<='0';
						end if;
					when others=>
							sel_twid_ad<='1';
				end case;
			end if;
		end process twiddle_addr_sw;
-----------------------------------------------------------------------------------------------		
twiddle_addr_control:process(clk,global_clock_enable,twade_0_i,twade_1_i,p_count_d1)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d1 is
					when "001" =>
						twade_0_o <= twade_0_i;
						twade_1_o <= twade_1_i;
					when "010"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(4,twa);
							twade_1_o <= twade_1_i + int2ustd(4,twa);
						end if;
					when "011"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(16,twa);
							twade_1_o <= twade_1_i + int2ustd(16,twa);
						end if;
					when "100"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(32,twa);
							twade_1_o <= twade_1_i + int2ustd(32,twa);
						end if;
					when others=>
						twade_0_o <= twade_0_i;
						twade_1_o <= twade_1_i;
				end case;
			end if;
		end process twiddle_addr_control;
-----------------------------------------------------------------------------------------------	
twiddle_sw:process(clk,global_clock_enable,reset,k_count_d2,p_count_d2)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d2 is
					when "000" =>
							sel_twid <='1';
					when "001" =>
							sel_twid <='1';
					when "010" =>		
						if(k_count_d2(1 downto 0)="00") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when "011" =>
						if(k_count_d2(3 downto 0)="0000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when "100" =>
						if(k_count_d2(4 downto 0)="10000") then
							sel_twid<='0';
--						else
--							sel_twid<='0';
						end if;
					when others=>
							sel_twid<='1';
				end case;
			end if;
		end process twiddle_sw;
		
-----------------------------------------------------------------------------------------------
twiddle_data_control:process(clk,global_clock_enable,reset,p_count_d2)is
		begin                                                                             
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d2 is
				-----------------------------------------------------------------------------------------------
				when "000" =>
				----------------------------------------------------------------------------
						for i in 0 to 2 loop                                                    
    					twiddle_data_w(i) <= twiddle_data_w_tmp(i);                       
    					twiddle_data_w_tmp(i) <= twiddle_rom_out_w(i);                    
				    	twiddle_data_x(i) <= twiddle_data_x_tmp(i);                       
				    	twiddle_data_x_tmp(i) <= twiddle_rom_out_x(i);                    
    					twiddle_data_y(i) <= twiddle_data_y_tmp(i);                       
    					twiddle_data_y_tmp(i) <= twiddle_rom_out_y(i);                    
				    	twiddle_data_z(i) <= twiddle_data_z_tmp(i);                       
    					twiddle_data_z_tmp(i) <= twiddle_rom_out_z(i);                    
				    end loop;                                                               
			  ----------------------------------------------------------------------------
			  when "001" =>
				----------------------------------------------------------------------------
						for i in 0 to 2 loop                                                    
    					twiddle_data_w(i) <= twiddle_data_w_tmp(i);                       
    					twiddle_data_w_tmp(i) <= twiddle_rom_out_w(i);                    
				    	twiddle_data_x(i) <= twiddle_data_x_tmp(i);                       
				    	twiddle_data_x_tmp(i) <= twiddle_rom_out_x(i);                    
    					twiddle_data_y(i) <= twiddle_data_y_tmp(i);                       
    					twiddle_data_y_tmp(i) <= twiddle_rom_out_y(i);                    
				    	twiddle_data_z(i) <= twiddle_data_z_tmp(i);                       
    					twiddle_data_z_tmp(i) <= twiddle_rom_out_z(i);                    
				    end loop;
				-----------------------------------------------------------------------------------------------                                                                   
			  when "100" =>
			  -----------------------------------------------------------------------------------------------
			  	if(sel_twid='1') then                                                     
						for i in 0 to 2 loop                                                    
    					twiddle_data_w(i) <=  twiddle_data_w_tmp(i);                                             
    					twiddle_data_w_tmp(i) <= int2ustd(X2,twr) & int2ustd(0,twr);                       
				    	twiddle_data_x(i) <= twiddle_data_x_tmp(i);                       
				    	twiddle_data_x_tmp(i) <= int2ustd(X2,twr) & int2ustd(0,twr);                       
    					twiddle_data_y(i) <= twiddle_data_y_tmp(i);                       
    					twiddle_data_y_tmp(i) <= int2ustd(X2,twr) & int2ustd(0,twr);                       
				    	twiddle_data_z(i) <= twiddle_data_z_tmp(i);                       
    					twiddle_data_z_tmp(i) <= int2ustd(X2,twr) & int2ustd(0,twr);                       
			  	  end loop;               
			  	else
			  		for i in 0 to 2 loop                                                    
    					twiddle_data_w(i) <=  twiddle_data_w_tmp(i);                                             
    			  	twiddle_data_x(i) <= twiddle_data_x_tmp(i);                       
				  		twiddle_data_y(i) <= twiddle_data_y_tmp(i);                       
    			  	twiddle_data_z(i) <= twiddle_data_z_tmp(i);                       
    			  end loop;               
			  	  twiddle_data_w_tmp(0) <= int2ustd(X1,twr) & int2ustd(X1,twr);                       
    				twiddle_data_w_tmp(1) <= int2ustd(0,twr) & int2ustd(X2,twr);                       
				    twiddle_data_w_tmp(2) <= int2ustd(-X1,twr) & int2ustd(X1,twr);                       
			  	  twiddle_data_x_tmp(0) <= int2ustd(X1,twr) & int2ustd(X1,twr);                       
    				twiddle_data_x_tmp(1) <= int2ustd(0,twr) & int2ustd(X2,twr);                       
				    twiddle_data_x_tmp(2) <= int2ustd(-X1,twr) & int2ustd(X1,twr);                       
			  	  twiddle_data_y_tmp(0) <= int2ustd(X1,twr) & int2ustd(X1,twr);                       
    				twiddle_data_y_tmp(1) <= int2ustd(0,twr) & int2ustd(X2,twr);                       
				    twiddle_data_y_tmp(2) <= int2ustd(-X1,twr) & int2ustd(X1,twr);                       
			  	  twiddle_data_z_tmp(0) <= int2ustd(X1,twr) & int2ustd(X1,twr);                       
    				twiddle_data_z_tmp(1) <= int2ustd(0,twr) & int2ustd(X2,twr);                       
				    twiddle_data_z_tmp(2) <= int2ustd(-X1,twr) & int2ustd(X1,twr);                       
			  	end if;                                                                   
			  -----------------------------------------------------------------------------------------------
			  when others=>
					if(sel_twid='1') then                                                     
						for i in 0 to 2 loop                                                    
    					twiddle_data_w_tmp(i) <= twiddle_rom_out_w(i);                    
	    				twiddle_data_y_tmp(i) <= twiddle_rom_out_y(i);                    
			  	  end loop;                                                               
			  	end if;                                                                   
			  	for i in 0 to 2 loop                                                      
    				twiddle_data_w(i) <= twiddle_data_w_tmp(i);                         
					  twiddle_data_y(i) <= twiddle_data_y_tmp(i);                         
			  	end loop;                                                                 
					if(sel_twid='0') then                                                     
						for i in 0 to 2 loop                                                    
    					twiddle_data_x(i) <= twiddle_rom_out_w(i);                        
				    	twiddle_data_z(i) <= twiddle_rom_out_y(i);                        
			    	end loop;                                                               
			    end if;                                                                   
			  ----------------------------------------------------------------------------
			 end case;
			 -----------------------------------------------------------------------------
		end if;                                                                         
	end process twiddle_data_control;                                                 
end generate gen_512;
-----------------------------------------------------------------------------------------------
-- N=1024
-----------------------------------------------------------------------------------------------
gen_1024 : if(nps=1024) generate
twiddle_addr_sw:process(clk,global_clock_enable,reset,k_count_d1,p_count_d1)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d1 is
					when "000" =>
							sel_twid_ad <='1';
					when "001" =>
							sel_twid_ad <='1';
					when "010" =>		
						if(k_count_d1(1 downto 0)="00") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "011" =>
						if(k_count_d1(3 downto 0)="0000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "100" =>
						if(k_count_d1(5 downto 0)="000000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when others=>
							sel_twid_ad<='1';
				end case;
			end if;
		end process twiddle_addr_sw;
-----------------------------------------------------------------------------------------------		
twiddle_addr_control:process(clk,global_clock_enable,twade_0_i,twade_1_i,p_count_d1)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d1 is
					when "001" =>
						twade_0_o <= twade_0_i;
						twade_1_o <= twade_1_i;
					when "010"=>
						--if(k_count_d1(1 downto 0)="00") then
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(2,twa);
							twade_1_o <= twade_1_i + int2ustd(2,twa);
						end if;
					when "011"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(8,twa);
							twade_1_o <= twade_1_i + int2ustd(8,twa);
						end if;
					when "100"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(32,twa);
							twade_1_o <= twade_1_i + int2ustd(32,twa);
						end if;
						
					when others=>
						twade_0_o <= twade_0_i;
						twade_1_o <= twade_1_i;
				end case;
			end if;
		end process twiddle_addr_control;
-----------------------------------------------------------------------------------------------	
twiddle_sw:process(clk,global_clock_enable,reset,k_count_d2,p_count_d2)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d2 is
					when "000" =>
							sel_twid <='1';
					when "001" =>
							sel_twid <='1';
					when "010" =>		
						if(k_count_d2(1 downto 0)="00") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when "011" =>
						if(k_count_d2(3 downto 0)="0000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when "100" =>
						if(k_count_d2(5 downto 0)="000000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;	
					when others=>
							sel_twid<='1';
				end case;
			end if;
		end process twiddle_sw;
		
end generate gen_1024;

-----------------------------------------------------------------------------------------------
-- N=2048
-----------------------------------------------------------------------------------------------
gen_2048 : if(nps=2048) generate
		
twiddle_addr_sw:process(clk,global_clock_enable,reset,k_count_d1,p_count_d1)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d1 is
					when "000" =>
							sel_twid_ad <='1';
					when "001" =>
							sel_twid_ad <='1';
					when "010" =>		
						if(k_count_d1(1 downto 0)="00") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "011" =>
						if(k_count_d1(3 downto 0)="0000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "100" =>
						if(k_count_d1(5 downto 0)="000000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "101" =>
						if(k_count_d1(6 downto 0)="1000000") then
							sel_twid_ad<='0';
						end if;
					when others=>
							sel_twid_ad<='1';
				end case;
			end if;
		end process twiddle_addr_sw;
-----------------------------------------------------------------------------------------------		
twiddle_addr_control:process(clk,global_clock_enable,twade_0_i,twade_1_i,p_count_d1)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d1 is
					when "001" =>
						twade_0_o <= twade_0_i;
						twade_1_o <= twade_1_i;
					when "010"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(4,twa);
							twade_1_o <= twade_1_i + int2ustd(4,twa);
						end if;
					when "011"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(16,twa);
							twade_1_o <= twade_1_i + int2ustd(16,twa);
						end if;
					when "100"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(64,twa);
							twade_1_o <= twade_1_i + int2ustd(64,twa);
						end if;
					when "101"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(128,twa);
							twade_1_o <= twade_1_i + int2ustd(128,twa);
						end if;
					when others=>
						twade_0_o <= twade_0_i;
						twade_1_o <= twade_1_i;
				end case;
			end if;
		end process twiddle_addr_control;
-----------------------------------------------------------------------------------------------	
twiddle_sw:process(clk,global_clock_enable,reset,k_count_d2,p_count_d2)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d2 is
					when "000" =>
							sel_twid <='1';
					when "001" =>
							sel_twid <='1';
					when "010" =>		
						if(k_count_d2(1 downto 0)="00") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when "011" =>
						if(k_count_d2(3 downto 0)="0000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when "100" =>
						if(k_count_d2(5 downto 0)="000000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when "101" =>
						if(k_count_d2(6 downto 0)="1000000") then
							sel_twid<='0';
						end if;
					when others=>
							sel_twid<='1';
				end case;
			end if;
		end process twiddle_sw;
		
-----------------------------------------------------------------------------------------------
twiddle_data_control:process(clk,global_clock_enable,reset,p_count_d2)is
		begin                                                                             
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d2 is
				-----------------------------------------------------------------------------------------------
				when "000" =>
				----------------------------------------------------------------------------
						for i in 0 to 2 loop                                                    
    					twiddle_data_w(i) <= twiddle_data_w_tmp(i);                       
    					twiddle_data_w_tmp(i) <= twiddle_rom_out_w(i);                    
				    	twiddle_data_x(i) <= twiddle_data_x_tmp(i);                       
				    	twiddle_data_x_tmp(i) <= twiddle_rom_out_x(i);                    
    					twiddle_data_y(i) <= twiddle_data_y_tmp(i);                       
    					twiddle_data_y_tmp(i) <= twiddle_rom_out_y(i);                    
				    	twiddle_data_z(i) <= twiddle_data_z_tmp(i);                       
    					twiddle_data_z_tmp(i) <= twiddle_rom_out_z(i);                    
				    end loop;                                                               
			  ----------------------------------------------------------------------------
			  when "001" =>
				----------------------------------------------------------------------------
						for i in 0 to 2 loop                                                    
    					twiddle_data_w(i) <= twiddle_data_w_tmp(i);                       
    					twiddle_data_w_tmp(i) <= twiddle_rom_out_w(i);                    
				    	twiddle_data_x(i) <= twiddle_data_x_tmp(i);                       
				    	twiddle_data_x_tmp(i) <= twiddle_rom_out_x(i);                    
    					twiddle_data_y(i) <= twiddle_data_y_tmp(i);                       
    					twiddle_data_y_tmp(i) <= twiddle_rom_out_y(i);                    
				    	twiddle_data_z(i) <= twiddle_data_z_tmp(i);                       
    					twiddle_data_z_tmp(i) <= twiddle_rom_out_z(i);                    
				    end loop;
				-----------------------------------------------------------------------------------------------                                                                   
			  when "101" =>
			  -----------------------------------------------------------------------------------------------
			  	if(sel_twid='1') then                                                     
						for i in 0 to 2 loop                                                    
    					twiddle_data_w(i) <=  twiddle_data_w_tmp(i);                                             
    					twiddle_data_w_tmp(i) <= int2ustd(X2,twr) & int2ustd(0,twr);                       
				    	twiddle_data_x(i) <= twiddle_data_x_tmp(i);                       
				    	twiddle_data_x_tmp(i) <= int2ustd(X2,twr) & int2ustd(0,twr);                       
    					twiddle_data_y(i) <= twiddle_data_y_tmp(i);                       
    					twiddle_data_y_tmp(i) <= int2ustd(X2,twr) & int2ustd(0,twr);                       
				    	twiddle_data_z(i) <= twiddle_data_z_tmp(i);                       
    					twiddle_data_z_tmp(i) <= int2ustd(X2,twr) & int2ustd(0,twr);                       
			  	  end loop;               
			  	else
			  		for i in 0 to 2 loop                                                    
    					twiddle_data_w(i) <=  twiddle_data_w_tmp(i);                                             
    			  	twiddle_data_x(i) <= twiddle_data_x_tmp(i);                       
				  		twiddle_data_y(i) <= twiddle_data_y_tmp(i);                       
    			  	twiddle_data_z(i) <= twiddle_data_z_tmp(i);                       
    			  end loop;               
			  	  twiddle_data_w_tmp(0) <= int2ustd(X1,twr) & int2ustd(X1,twr);                       
    				twiddle_data_w_tmp(1) <= int2ustd(0,twr) & int2ustd(X2,twr);                       
				    twiddle_data_w_tmp(2) <= int2ustd(-X1,twr) & int2ustd(X1,twr);                       
			  	  twiddle_data_x_tmp(0) <= int2ustd(X1,twr) & int2ustd(X1,twr);                       
    				twiddle_data_x_tmp(1) <= int2ustd(0,twr) & int2ustd(X2,twr);                       
				    twiddle_data_x_tmp(2) <= int2ustd(-X1,twr) & int2ustd(X1,twr);                       
			  	  twiddle_data_y_tmp(0) <= int2ustd(X1,twr) & int2ustd(X1,twr);                       
    				twiddle_data_y_tmp(1) <= int2ustd(0,twr) & int2ustd(X2,twr);                       
				    twiddle_data_y_tmp(2) <= int2ustd(-X1,twr) & int2ustd(X1,twr);                       
			  	  twiddle_data_z_tmp(0) <= int2ustd(X1,twr) & int2ustd(X1,twr);                       
    				twiddle_data_z_tmp(1) <= int2ustd(0,twr) & int2ustd(X2,twr);                       
				    twiddle_data_z_tmp(2) <= int2ustd(-X1,twr) & int2ustd(X1,twr);                       
			  	end if;                                                                   
			  -----------------------------------------------------------------------------------------------
			  when others=>
					if(sel_twid='1') then                                                     
						for i in 0 to 2 loop                                                    
    					twiddle_data_w_tmp(i) <= twiddle_rom_out_w(i);                    
	    				twiddle_data_y_tmp(i) <= twiddle_rom_out_y(i);                    
			  	  end loop;                                                               
			  	end if;                                                                   
			  	for i in 0 to 2 loop                                                      
    				twiddle_data_w(i) <= twiddle_data_w_tmp(i);                         
					  twiddle_data_y(i) <= twiddle_data_y_tmp(i);                         
			  	end loop;                                                                 
					if(sel_twid='0') then                                                     
						for i in 0 to 2 loop                                                    
    					twiddle_data_x(i) <= twiddle_rom_out_w(i);                        
				    	twiddle_data_z(i) <= twiddle_rom_out_y(i);                        
			    	end loop;                                                               
			    end if;                                                                   
			  ----------------------------------------------------------------------------
			 end case;
			 -----------------------------------------------------------------------------
		end if;                                                                         
	end process twiddle_data_control;                                                 
end generate gen_2048;

-----------------------------------------------------------------------------------------------
-- N=4096
-----------------------------------------------------------------------------------------------
gen_4096 : if(nps=4096) generate
twiddle_addr_sw:process(clk,global_clock_enable,reset,k_count_d1,p_count_d1)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d1 is
					when "000" =>
							sel_twid_ad <='1';
					when "001" =>
							sel_twid_ad <='1';
					when "010" =>		
						if(k_count_d1(1 downto 0)="00") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "011" =>
						if(k_count_d1(3 downto 0)="0000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "100" =>
						if(k_count_d1(5 downto 0)="000000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "101" =>
						if(k_count_d1(7 downto 0)="00000000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when others=>
							sel_twid_ad<='1';
				end case;
			end if;
		end process twiddle_addr_sw;
-----------------------------------------------------------------------------------------------		
twiddle_addr_control:process(clk,global_clock_enable,twade_0_i,twade_1_i,p_count_d1)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d1 is
					when "001" =>
						twade_0_o <= twade_0_i;
						twade_1_o <= twade_1_i;
					when "010"=>
						--if(k_count_d1(1 downto 0)="00") then
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(2,twa);
							twade_1_o <= twade_1_i + int2ustd(2,twa);
						end if;
					when "011"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(8,twa);
							twade_1_o <= twade_1_i + int2ustd(8,twa);
						end if;
					when "100"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(32,twa);
							twade_1_o <= twade_1_i + int2ustd(32,twa);
						end if;
					when "101"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(128,twa);
							twade_1_o <= twade_1_i + int2ustd(128,twa);
						end if;
					when others=>
						twade_0_o <= twade_0_i;
						twade_1_o <= twade_1_i;
				end case;
			end if;
		end process twiddle_addr_control;
-----------------------------------------------------------------------------------------------	
twiddle_sw:process(clk,global_clock_enable,reset,k_count_d2,p_count_d2)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d2 is
					when "000" =>
							sel_twid <='1';
					when "001" =>
							sel_twid <='1';
					when "010" =>		
						if(k_count_d2(1 downto 0)="00") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when "011" =>
						if(k_count_d2(3 downto 0)="0000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when "100" =>
						if(k_count_d2(5 downto 0)="000000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;	
					when "101" =>
						if(k_count_d2(7 downto 0)="00000000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;	
					when others=>
							sel_twid<='1';
				end case;
			end if;
		end process twiddle_sw;
		
end generate gen_4096;

-----------------------------------------------------------------------------------------------
-- N=8192
-----------------------------------------------------------------------------------------------
gen_8192 : if(nps=8192) generate
		
twiddle_addr_sw:process(clk,global_clock_enable,reset,k_count_d1,p_count_d1)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d1 is
					when "000" =>
							sel_twid_ad <='1';
					when "001" =>
							sel_twid_ad <='1';
					when "010" =>		
						if(k_count_d1(1 downto 0)="00") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "011" =>
						if(k_count_d1(3 downto 0)="0000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "100" =>
						if(k_count_d1(5 downto 0)="000000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "101" =>
						if(k_count_d1(7 downto 0)="00000000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "110" =>
						if(k_count_d1(8 downto 0)="100000000") then
							sel_twid_ad<='0';
						end if;
					when others=>
							sel_twid_ad<='1';
				end case;
			end if;
		end process twiddle_addr_sw;
-----------------------------------------------------------------------------------------------		
twiddle_addr_control:process(clk,global_clock_enable,twade_0_i,twade_1_i,p_count_d1)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d1 is
					when "001" =>
						twade_0_o <= twade_0_i;
						twade_1_o <= twade_1_i;
					when "010"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(4,twa);
							twade_1_o <= twade_1_i + int2ustd(4,twa);
						end if;
					when "011"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(16,twa);
							twade_1_o <= twade_1_i + int2ustd(16,twa);
						end if;
					when "100"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(64,twa);
							twade_1_o <= twade_1_i + int2ustd(64,twa);
						end if;
					when "101"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(256,twa);
							twade_1_o <= twade_1_i + int2ustd(256,twa);
						end if;
					when "110"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(512,twa);
							twade_1_o <= twade_1_i + int2ustd(512,twa);
						end if;
					when others=>
						twade_0_o <= twade_0_i;
						twade_1_o <= twade_1_i;
				end case;
			end if;
		end process twiddle_addr_control;
-----------------------------------------------------------------------------------------------	
twiddle_sw:process(clk,global_clock_enable,reset,k_count_d2,p_count_d2)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d2 is
					when "000" =>
							sel_twid <='1';
					when "001" =>
							sel_twid <='1';
					when "010" =>		
						if(k_count_d2(1 downto 0)="00") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when "011" =>
						if(k_count_d2(3 downto 0)="0000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when "100" =>
						if(k_count_d2(5 downto 0)="000000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when "101" =>
						if(k_count_d2(7 downto 0)="00000000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when "110" =>
						if(k_count_d2(8 downto 0)="100000000") then
							sel_twid<='0';
						end if;
					when others=>
							sel_twid<='1';
				end case;
			end if;
		end process twiddle_sw;
		
-----------------------------------------------------------------------------------------------
twiddle_data_control:process(clk,global_clock_enable,reset,p_count_d2)is
		begin                                                                             
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d2 is
				-----------------------------------------------------------------------------------------------
				when "000" =>
				----------------------------------------------------------------------------
						for i in 0 to 2 loop                                                    
    					twiddle_data_w(i) <= twiddle_data_w_tmp(i);                       
    					twiddle_data_w_tmp(i) <= twiddle_rom_out_w(i);                    
				    	twiddle_data_x(i) <= twiddle_data_x_tmp(i);                       
				    	twiddle_data_x_tmp(i) <= twiddle_rom_out_x(i);                    
    					twiddle_data_y(i) <= twiddle_data_y_tmp(i);                       
    					twiddle_data_y_tmp(i) <= twiddle_rom_out_y(i);                    
				    	twiddle_data_z(i) <= twiddle_data_z_tmp(i);                       
    					twiddle_data_z_tmp(i) <= twiddle_rom_out_z(i);                    
				    end loop;                                                               
			  ----------------------------------------------------------------------------
			  when "001" =>
				----------------------------------------------------------------------------
						for i in 0 to 2 loop                                                    
    					twiddle_data_w(i) <= twiddle_data_w_tmp(i);                       
    					twiddle_data_w_tmp(i) <= twiddle_rom_out_w(i);                    
				    	twiddle_data_x(i) <= twiddle_data_x_tmp(i);                       
				    	twiddle_data_x_tmp(i) <= twiddle_rom_out_x(i);                    
    					twiddle_data_y(i) <= twiddle_data_y_tmp(i);                       
    					twiddle_data_y_tmp(i) <= twiddle_rom_out_y(i);                    
				    	twiddle_data_z(i) <= twiddle_data_z_tmp(i);                       
    					twiddle_data_z_tmp(i) <= twiddle_rom_out_z(i);                    
				    end loop;
				-----------------------------------------------------------------------------------------------                                                                   
			  when "110" =>
			  -----------------------------------------------------------------------------------------------
			  	if(sel_twid='1') then                                                     
						for i in 0 to 2 loop                                                    
    					twiddle_data_w(i) <=  twiddle_data_w_tmp(i);                                             
    					twiddle_data_w_tmp(i) <= int2ustd(X2,twr) & int2ustd(0,twr);                       
				    	twiddle_data_x(i) <= twiddle_data_x_tmp(i);                       
				    	twiddle_data_x_tmp(i) <= int2ustd(X2,twr) & int2ustd(0,twr);                       
    					twiddle_data_y(i) <= twiddle_data_y_tmp(i);                       
    					twiddle_data_y_tmp(i) <= int2ustd(X2,twr) & int2ustd(0,twr);                       
				    	twiddle_data_z(i) <= twiddle_data_z_tmp(i);                       
    					twiddle_data_z_tmp(i) <= int2ustd(X2,twr) & int2ustd(0,twr);                       
			  	  end loop;               
			  	else
			  		for i in 0 to 2 loop                                                    
    					twiddle_data_w(i) <=  twiddle_data_w_tmp(i);                                             
    			  	twiddle_data_x(i) <= twiddle_data_x_tmp(i);                       
				  		twiddle_data_y(i) <= twiddle_data_y_tmp(i);                       
    			  	twiddle_data_z(i) <= twiddle_data_z_tmp(i);                       
    			  end loop;               
			  	  twiddle_data_w_tmp(0) <= int2ustd(X1,twr) & int2ustd(X1,twr);                       
    				twiddle_data_w_tmp(1) <= int2ustd(0,twr) & int2ustd(X2,twr);                       
				    twiddle_data_w_tmp(2) <= int2ustd(-X1,twr) & int2ustd(X1,twr);                       
			  	  twiddle_data_x_tmp(0) <= int2ustd(X1,twr) & int2ustd(X1,twr);                       
    				twiddle_data_x_tmp(1) <= int2ustd(0,twr) & int2ustd(X2,twr);                       
				    twiddle_data_x_tmp(2) <= int2ustd(-X1,twr) & int2ustd(X1,twr);                       
			  	  twiddle_data_y_tmp(0) <= int2ustd(X1,twr) & int2ustd(X1,twr);                       
    				twiddle_data_y_tmp(1) <= int2ustd(0,twr) & int2ustd(X2,twr);                       
				    twiddle_data_y_tmp(2) <= int2ustd(-X1,twr) & int2ustd(X1,twr);                       
			  	  twiddle_data_z_tmp(0) <= int2ustd(X1,twr) & int2ustd(X1,twr);                       
    				twiddle_data_z_tmp(1) <= int2ustd(0,twr) & int2ustd(X2,twr);                       
				    twiddle_data_z_tmp(2) <= int2ustd(-X1,twr) & int2ustd(X1,twr);                       
			  	end if;                                                                   
			  -----------------------------------------------------------------------------------------------
			  when others=>
					if(sel_twid='1') then                                                     
						for i in 0 to 2 loop                                                    
    					twiddle_data_w_tmp(i) <= twiddle_rom_out_w(i);                    
	    				twiddle_data_y_tmp(i) <= twiddle_rom_out_y(i);                    
			  	  end loop;                                                               
			  	end if;                                                                   
			  	for i in 0 to 2 loop                                                      
    				twiddle_data_w(i) <= twiddle_data_w_tmp(i);                         
					  twiddle_data_y(i) <= twiddle_data_y_tmp(i);                         
			  	end loop;                                                                 
					if(sel_twid='0') then                                                     
						for i in 0 to 2 loop                                                    
    					twiddle_data_x(i) <= twiddle_rom_out_w(i);                        
				    	twiddle_data_z(i) <= twiddle_rom_out_y(i);                        
			    	end loop;                                                               
			    end if;                                                                   
			  ----------------------------------------------------------------------------
			 end case;
			 -----------------------------------------------------------------------------
		end if;                                                                         
	end process twiddle_data_control;                                                 
end generate gen_8192;
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- N=16384
-----------------------------------------------------------------------------------------------
gen_16384 : if(nps=16384) generate
twiddle_addr_sw:process(clk,global_clock_enable,reset,k_count_d1,p_count_d1)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d1 is
					when "000" =>
							sel_twid_ad <='1';
					when "001" =>
							sel_twid_ad <='1';
					when "010" =>		
						if(k_count_d1(1 downto 0)="00") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "011" =>
						if(k_count_d1(3 downto 0)="0000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "100" =>
						if(k_count_d1(5 downto 0)="000000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "101" =>
						if(k_count_d1(7 downto 0)="00000000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "110" =>
						if(k_count_d1(9 downto 0)="0000000000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when others=>
							sel_twid_ad<='1';
				end case;
			end if;
		end process twiddle_addr_sw;
-----------------------------------------------------------------------------------------------		
twiddle_addr_control:process(clk,global_clock_enable,twade_0_i,twade_1_i,p_count_d1)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d1 is
					when "001" =>
						twade_0_o <= twade_0_i;
						twade_1_o <= twade_1_i;
					when "010"=>
						--if(k_count_d1(1 downto 0)="00") then
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(2,twa);
							twade_1_o <= twade_1_i + int2ustd(2,twa);
						end if;
					when "011"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(8,twa);
							twade_1_o <= twade_1_i + int2ustd(8,twa);
						end if;
					when "100"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(32,twa);
							twade_1_o <= twade_1_i + int2ustd(32,twa);
						end if;
					when "101"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(128,twa);
							twade_1_o <= twade_1_i + int2ustd(128,twa);
						end if;
					when "110"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(512,twa);
							twade_1_o <= twade_1_i + int2ustd(512,twa);
						end if;
					when others=>
						twade_0_o <= twade_0_i;
						twade_1_o <= twade_1_i;
				end case;
			end if;
		end process twiddle_addr_control;
-----------------------------------------------------------------------------------------------	
twiddle_sw:process(clk,global_clock_enable,reset,k_count_d2,p_count_d2)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d2 is
					when "000" =>
							sel_twid <='1';
					when "001" =>
							sel_twid <='1';
					when "010" =>		
						if(k_count_d2(1 downto 0)="00") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when "011" =>
						if(k_count_d2(3 downto 0)="0000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when "100" =>
						if(k_count_d2(5 downto 0)="000000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;	
					when "101" =>
						if(k_count_d2(7 downto 0)="00000000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;	
					when "110" =>
						if(k_count_d2(9 downto 0)="0000000000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;	
					when others=>
							sel_twid<='1';
				end case;
			end if;
		end process twiddle_sw;
		
end generate gen_16384;

-----------------------------------------------------------------------------------------------
-- N=32768
-----------------------------------------------------------------------------------------------
gen_32768 : if(nps=32768) generate
		
twiddle_addr_sw:process(clk,global_clock_enable,reset,k_count_d1,p_count_d1)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d1 is
					when "000" =>
							sel_twid_ad <='1';
					when "001" =>
							sel_twid_ad <='1';
					when "010" =>		
						if(k_count_d1(1 downto 0)="00") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "011" =>
						if(k_count_d1(3 downto 0)="0000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "100" =>
						if(k_count_d1(5 downto 0)="000000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "101" =>
						if(k_count_d1(7 downto 0)="00000000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "110" =>
						if(k_count_d1(9 downto 0)="0000000000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "111" =>
						if(k_count_d1(10 downto 0)="10000000000") then
							sel_twid_ad<='0';
						end if;
					when others=>
							sel_twid_ad<='1';
				end case;
			end if;
		end process twiddle_addr_sw;
-----------------------------------------------------------------------------------------------		
twiddle_addr_control:process(clk,global_clock_enable,twade_0_i,twade_1_i,p_count_d1)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d1 is
					when "001" =>
						twade_0_o <= twade_0_i;
						twade_1_o <= twade_1_i;
					when "010"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(4,twa);
							twade_1_o <= twade_1_i + int2ustd(4,twa);
						end if;
					when "011"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(16,twa);
							twade_1_o <= twade_1_i + int2ustd(16,twa);
						end if;
					when "100"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(64,twa);
							twade_1_o <= twade_1_i + int2ustd(64,twa);
						end if;
					when "101"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(256,twa);
							twade_1_o <= twade_1_i + int2ustd(256,twa);
						end if;
					when "110"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(1024,twa);
							twade_1_o <= twade_1_i + int2ustd(1024,twa);
						end if;
					when "111"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(2048,twa);
							twade_1_o <= twade_1_i + int2ustd(2048,twa);
						end if;
					when others=>
						twade_0_o <= twade_0_i;
						twade_1_o <= twade_1_i;
				end case;
			end if;
		end process twiddle_addr_control;
-----------------------------------------------------------------------------------------------	
twiddle_sw:process(clk,global_clock_enable,reset,k_count_d2,p_count_d2)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d2 is
					when "000" =>
							sel_twid <='1';
					when "001" =>
							sel_twid <='1';
					when "010" =>		
						if(k_count_d2(1 downto 0)="00") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when "011" =>
						if(k_count_d2(3 downto 0)="0000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when "100" =>
						if(k_count_d2(5 downto 0)="000000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when "101" =>
						if(k_count_d2(7 downto 0)="00000000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when "110" =>
						if(k_count_d2(9 downto 0)="0000000000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when "111" =>
						if(k_count_d2(10 downto 0)="10000000000") then
							sel_twid<='0';
						end if;
					when others=>
							sel_twid<='1';
				end case;
			end if;
		end process twiddle_sw;
		
-----------------------------------------------------------------------------------------------
twiddle_data_control:process(clk,global_clock_enable,reset,p_count_d2)is
		begin                                                                             
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d2 is
				-----------------------------------------------------------------------------------------------
				when "000" =>
				----------------------------------------------------------------------------
						for i in 0 to 2 loop                                                    
    					twiddle_data_w(i) <= twiddle_data_w_tmp(i);                       
    					twiddle_data_w_tmp(i) <= twiddle_rom_out_w(i);                    
				    	twiddle_data_x(i) <= twiddle_data_x_tmp(i);                       
				    	twiddle_data_x_tmp(i) <= twiddle_rom_out_x(i);                    
    					twiddle_data_y(i) <= twiddle_data_y_tmp(i);                       
    					twiddle_data_y_tmp(i) <= twiddle_rom_out_y(i);                    
				    	twiddle_data_z(i) <= twiddle_data_z_tmp(i);                       
    					twiddle_data_z_tmp(i) <= twiddle_rom_out_z(i);                    
				    end loop;                                                               
			  ----------------------------------------------------------------------------
			  when "001" =>
				----------------------------------------------------------------------------
						for i in 0 to 2 loop                                                    
    					twiddle_data_w(i) <= twiddle_data_w_tmp(i);                       
    					twiddle_data_w_tmp(i) <= twiddle_rom_out_w(i);                    
				    	twiddle_data_x(i) <= twiddle_data_x_tmp(i);                       
				    	twiddle_data_x_tmp(i) <= twiddle_rom_out_x(i);                    
    					twiddle_data_y(i) <= twiddle_data_y_tmp(i);                       
    					twiddle_data_y_tmp(i) <= twiddle_rom_out_y(i);                    
				    	twiddle_data_z(i) <= twiddle_data_z_tmp(i);                       
    					twiddle_data_z_tmp(i) <= twiddle_rom_out_z(i);                    
				    end loop;
				-----------------------------------------------------------------------------------------------                                                                   
			  when "111" =>
			  -----------------------------------------------------------------------------------------------
			  	if(sel_twid='1') then                                                     
						for i in 0 to 2 loop                                                    
    					twiddle_data_w(i) <=  twiddle_data_w_tmp(i);                                             
    					twiddle_data_w_tmp(i) <= int2ustd(X2,twr) & int2ustd(0,twr);                       
				    	twiddle_data_x(i) <= twiddle_data_x_tmp(i);                       
				    	twiddle_data_x_tmp(i) <= int2ustd(X2,twr) & int2ustd(0,twr);                       
    					twiddle_data_y(i) <= twiddle_data_y_tmp(i);                       
    					twiddle_data_y_tmp(i) <= int2ustd(X2,twr) & int2ustd(0,twr);                       
				    	twiddle_data_z(i) <= twiddle_data_z_tmp(i);                       
    					twiddle_data_z_tmp(i) <= int2ustd(X2,twr) & int2ustd(0,twr);                       
			  	  end loop;               
			  	else
			  		for i in 0 to 2 loop                                                    
    					twiddle_data_w(i) <=  twiddle_data_w_tmp(i);                                             
    			  	twiddle_data_x(i) <= twiddle_data_x_tmp(i);                       
				  		twiddle_data_y(i) <= twiddle_data_y_tmp(i);                       
    			  	twiddle_data_z(i) <= twiddle_data_z_tmp(i);                       
    			  end loop;               
			  	  twiddle_data_w_tmp(0) <= int2ustd(X1,twr) & int2ustd(X1,twr);                       
    				twiddle_data_w_tmp(1) <= int2ustd(0,twr) & int2ustd(X2,twr);                       
				    twiddle_data_w_tmp(2) <= int2ustd(-X1,twr) & int2ustd(X1,twr);                       
			  	  twiddle_data_x_tmp(0) <= int2ustd(X1,twr) & int2ustd(X1,twr);                       
    				twiddle_data_x_tmp(1) <= int2ustd(0,twr) & int2ustd(X2,twr);                       
				    twiddle_data_x_tmp(2) <= int2ustd(-X1,twr) & int2ustd(X1,twr);                       
			  	  twiddle_data_y_tmp(0) <= int2ustd(X1,twr) & int2ustd(X1,twr);                       
    				twiddle_data_y_tmp(1) <= int2ustd(0,twr) & int2ustd(X2,twr);                       
				    twiddle_data_y_tmp(2) <= int2ustd(-X1,twr) & int2ustd(X1,twr);                       
			  	  twiddle_data_z_tmp(0) <= int2ustd(X1,twr) & int2ustd(X1,twr);                       
    				twiddle_data_z_tmp(1) <= int2ustd(0,twr) & int2ustd(X2,twr);                       
				    twiddle_data_z_tmp(2) <= int2ustd(-X1,twr) & int2ustd(X1,twr);                       
			  	end if;                                                                   
			  -----------------------------------------------------------------------------------------------
			  when others=>
					if(sel_twid='1') then                                                     
						for i in 0 to 2 loop                                                    
    					twiddle_data_w_tmp(i) <= twiddle_rom_out_w(i);                    
	    				twiddle_data_y_tmp(i) <= twiddle_rom_out_y(i);                    
			  	  end loop;                                                               
			  	end if;                                                                   
			  	for i in 0 to 2 loop                                                      
    				twiddle_data_w(i) <= twiddle_data_w_tmp(i);                         
					  twiddle_data_y(i) <= twiddle_data_y_tmp(i);                         
			  	end loop;                                                                 
					if(sel_twid='0') then                                                     
						for i in 0 to 2 loop                                                    
    					twiddle_data_x(i) <= twiddle_rom_out_w(i);                        
				    	twiddle_data_z(i) <= twiddle_rom_out_y(i);                        
			    	end loop;                                                               
			    end if;                                                                   
			  ----------------------------------------------------------------------------
			 end case;
			 -----------------------------------------------------------------------------
		end if;                                                                         
	end process twiddle_data_control;                                                 
end generate gen_32768;
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- N=65536
-----------------------------------------------------------------------------------------------
gen_65536 : if(nps=65536) generate
twiddle_addr_sw:process(clk,global_clock_enable,reset,k_count_d1,p_count_d1)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d1 is
					when "000" =>
							sel_twid_ad <='1';
					when "001" =>
							sel_twid_ad <='1';
					when "010" =>		
						if(k_count_d1(1 downto 0)="00") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "011" =>
						if(k_count_d1(3 downto 0)="0000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "100" =>
						if(k_count_d1(5 downto 0)="000000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "101" =>
						if(k_count_d1(7 downto 0)="00000000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "110" =>
						if(k_count_d1(9 downto 0)="0000000000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when "111" =>
						if(k_count_d1(11 downto 0)="000000000000") then
							sel_twid_ad<='1';
						else
							sel_twid_ad<='0';
						end if;
					when others=>
							sel_twid_ad<='1';
				end case;
			end if;
		end process twiddle_addr_sw;
-----------------------------------------------------------------------------------------------		
twiddle_addr_control:process(clk,global_clock_enable,twade_0_i,twade_1_i,p_count_d1)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d1 is
					when "001" =>
						twade_0_o <= twade_0_i;
						twade_1_o <= twade_1_i;
					when "010"=>
						--if(k_count_d1(1 downto 0)="00") then
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(2,twa);
							twade_1_o <= twade_1_i + int2ustd(2,twa);
						end if;
					when "011"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(8,twa);
							twade_1_o <= twade_1_i + int2ustd(8,twa);
						end if;
					when "100"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(32,twa);
							twade_1_o <= twade_1_i + int2ustd(32,twa);
						end if;
					when "101"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(128,twa);
							twade_1_o <= twade_1_i + int2ustd(128,twa);
						end if;
					when "110"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(512,twa);
							twade_1_o <= twade_1_i + int2ustd(512,twa);
						end if;
					when "111"=>
						if(sel_twid_ad='1') then
							twade_0_o <= twade_0_i;
							twade_1_o <= twade_1_i;
						else
							twade_0_o <= twade_0_i + int2ustd(2048,twa);
							twade_1_o <= twade_1_i + int2ustd(2048,twa);
						end if;	
					when others=>
						twade_0_o <= twade_0_i;
						twade_1_o <= twade_1_i;
				end case;
			end if;
		end process twiddle_addr_control;
-----------------------------------------------------------------------------------------------	
twiddle_sw:process(clk,global_clock_enable,reset,k_count_d2,p_count_d2)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				case p_count_d2 is
					when "000" =>
							sel_twid <='1';
					when "001" =>
							sel_twid <='1';
					when "010" =>		
						if(k_count_d2(1 downto 0)="00") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when "011" =>
						if(k_count_d2(3 downto 0)="0000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when "100" =>
						if(k_count_d2(5 downto 0)="000000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;	
					when "101" =>
						if(k_count_d2(7 downto 0)="00000000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;	
					when "110" =>
						if(k_count_d2(9 downto 0)="0000000000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;
					when "111" =>
						if(k_count_d2(11 downto 0)="000000000000") then
							sel_twid<='1';
						else
							sel_twid<='0';
						end if;	
					when others=>
							sel_twid<='1';
				end case;
			end if;
		end process twiddle_sw;
		
end generate gen_65536;


-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- Twiddle Data Switch
-- Should be identical across all N for radix-4 last pass
-----------------------------------------------------------------------------------------------		
gen_r4 : if(last_pass_radix=0) generate
			
twiddle_data_control:process(clk,global_clock_enable,reset,p_count_d2)is
		begin                                                                             
if((rising_edge(clk) and global_clock_enable='1'))then
				if(p_count_d2<="001") then
				----------------------------------------------------------------------------
						for i in 0 to 2 loop                                                    
    					twiddle_data_w(i) <= twiddle_data_w_tmp(i);                       
    					twiddle_data_w_tmp(i) <= twiddle_rom_out_w(i);                    
				    	twiddle_data_x(i) <= twiddle_data_x_tmp(i);                       
				    	twiddle_data_x_tmp(i) <= twiddle_rom_out_x(i);                    
    					twiddle_data_y(i) <= twiddle_data_y_tmp(i);                       
    					twiddle_data_y_tmp(i) <= twiddle_rom_out_y(i);                    
				    	twiddle_data_z(i) <= twiddle_data_z_tmp(i);                       
    					twiddle_data_z_tmp(i) <= twiddle_rom_out_z(i);                    
				    end loop;                                                               
			  ----------------------------------------------------------------------------
				else
					if(sel_twid='1') then                                                     
						for i in 0 to 2 loop                                                    
    					twiddle_data_w_tmp(i) <= twiddle_rom_out_w(i);                    
	    				twiddle_data_y_tmp(i) <= twiddle_rom_out_y(i);                    
			  	  end loop;                                                               
			  	end if;                                                                   
			  	for i in 0 to 2 loop                                                      
    				twiddle_data_w(i) <= twiddle_data_w_tmp(i);                         
					  twiddle_data_y(i) <= twiddle_data_y_tmp(i);                         
			  	end loop;                                                                 
					if(sel_twid='0') then                                                     
						for i in 0 to 2 loop                                                    
    					twiddle_data_x(i) <= twiddle_rom_out_w(i);                        
				    	twiddle_data_z(i) <= twiddle_rom_out_y(i);                        
			    	end loop;                                                               
			    end if;                                                                   
			  ----------------------------------------------------------------------------
			 end if;
			 -----------------------------------------------------------------------------
		end if;                                                                         
	end process twiddle_data_control;                                                 

end generate gen_r4;



  
end cnt_sw;











