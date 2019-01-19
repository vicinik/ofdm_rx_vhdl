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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_wrengen.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
-- generate write enables for writing butterfly outputs to RAM blocks A,B,C,D
-- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all; 
use work.fft_pack.all;

entity asj_fft_wrengen is
	generic(
						nps : integer :=4096;
						arch : integer :=0;
						n_passes : integer :=5;
						log2_n_passes : integer:= 3;
						apr : integer :=10;
						del : integer :=17
					);
	port(			clk 					: in std_logic;
global_clock_enable : in std_logic;
						reset         : in std_logic;
						p_count       : in std_logic_vector(log2_n_passes-1 downto 0);
						anb           : in std_logic;
						lpp_c_en      : out std_logic;
						lpp_d_en      : out std_logic;
						wc            : out std_logic;
						wd            : out std_logic
			);
end asj_fft_wrengen;

architecture gen_all of asj_fft_wrengen is

constant  ptc : integer := LOG4_CEIL(nps)-1;
constant  apri : integer := LOG2_CEIL(nps)-1;
--type sw_array is array (0 to del-1) of std_logic_vector(1 downto 0);
--signal swd_tdl : sw_array;
signal lpp_c_i : std_logic;
signal lpp_d_i : std_logic;
signal wc_i : std_logic;
signal wc_i_d : std_logic;
signal lpp_trig : std_logic;
signal lpp_count : std_logic_vector(apri-1 downto 0);
type   wc_state_type is (IDLE,WAIT_LAT,ENABLE);
signal wc_state :  wc_state_type;
signal wait_count : std_logic_vector(3 downto 0);
	
signal wd_i : std_logic;

begin
	
gen_streaming_en : if(arch=0) generate
	lpp_c_en <= lpp_c_i;
	lpp_d_en <= lpp_d_i;
	wc <= wc_i;
	wd <= wd_i;
end generate gen_streaming_en;


gen_burst_en : if(arch=1 or arch=2) generate
	lpp_c_en <= lpp_c_i;
	lpp_d_en <= '0';
	wc <= wc_i;
	wd <= '0';
end generate gen_burst_en;
			
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
gen_streaming_enables : if(arch=0) generate

				gen_64_addr : if(nps<=256) generate
get_64_sw:process(clk,global_clock_enable,anb,p_count)is
						begin
if((rising_edge(clk) and global_clock_enable='1'))then
								if(reset='1') then
									lpp_d_i<='0';
									lpp_c_i<='0';
									wd_i<='0';                 
									wc_i<='0';                 
								else
									lpp_d_i <= not(anb);
									lpp_c_i <= anb;
									if(p_count=int2ustd(ptc,2)) then        
										wd_i<=anb;  
										wc_i<=not(anb);  
									else                         
										wd_i<='0';                 
										wc_i<='0';                 
									end if;  
								end if;
							end if;       
						end process get_64_sw;
				end generate gen_64_addr;
			gen_1024_addr : if(nps=512 or nps=1024) generate
get_1024_sw:process(clk,global_clock_enable,p_count,anb)is
					begin
if((rising_edge(clk) and global_clock_enable='1'))then
							if(reset='1') then     
								lpp_d_i<='0';
								lpp_c_i<='1';
								wd_i<='0';                 
								wc_i<='0';                 
							else
								lpp_d_i <= not(anb);
								lpp_c_i <= anb;
								if(p_count=int2ustd(ptc,3)) then        
									wd_i<=anb;  
									wc_i<=not(anb);  
								else                         
									wd_i<='0';                 
									wc_i<='0';                 
								end if;  
							end if;  
						end if;                      
					end process get_1024_sw;
						
				end generate gen_1024_addr;
				
				-----------------------------------------------------------------------------------------
				--
				--
				-----------------------------------------------------------------------------------------
				
				gen_4096_addr : if(nps=4096 or nps=2048) generate
				
				
--get_4096_sw:process(clk,global_clock_enable,p_count,anb)is
				--	begin
--if((rising_edge(clk) and global_clock_enable='1'))then
				--			if(anb='1') then               
				--				if(p_count="101") then        
				--					wd_i<='1';  
				--				else
				--					wd_i<='0';                 
				--				end if;  
				--			else
				--				if(p_count="101") then        
				--					wc_i<='1';  
				--				else           
				--					wc_i<='0';    
				--				end if;       
				--			end if;    
				--		end if;                            
				--	end process get_4096_sw;
					
					
get_4096_sw:process(clk,global_clock_enable,p_count,anb)is
					begin
if((rising_edge(clk) and global_clock_enable='1'))then
							if(reset='1') then
								wc_i <='0';
                wd_i <='0';								
              else
								if(p_count="101") then        
									wd_i<=anb;  
									wc_i<=not(anb);
								else
									wc_i<='0';                 
									wd_i<='0';                 
								end if;  
							end if;
						end if;                            
					end process get_4096_sw;
        
					
				
d_lpp:process(clk,global_clock_enable,reset,anb,p_count)is
						begin
if((rising_edge(clk) and global_clock_enable='1'))then
								if(reset='1') then
									lpp_d_i <= '0';
									lpp_c_i <= '0';
								else
									if(p_count = "110") then
											lpp_d_i <= anb;
											lpp_c_i <= not(anb);
									else
											lpp_d_i <= lpp_d_i;
											lpp_c_i <= lpp_c_i;
									end if;
								end if;
							end if;
						end process d_lpp;
						
				
				
				end generate gen_4096_addr;
				
				gen_8192_addr : if(nps =16384 or nps=8192) generate
		
				
get_4096_sw:process(clk,global_clock_enable,p_count,anb)is
					begin
if((rising_edge(clk) and global_clock_enable='1'))then
							if(reset='1') then
								wc_i <='0';
                wd_i <='0';								
              else
								if(p_count="110") then        
									wd_i<=anb;  
									wc_i<=not(anb);
								else
									wc_i<='0';                 
									wd_i<='0';                 
								end if;  
							end if;
						end if;                            
					end process get_4096_sw;
				
d_lpp:process(clk,global_clock_enable,reset,anb,p_count)is
						begin
if((rising_edge(clk) and global_clock_enable='1'))then
								if(reset='1') then
									lpp_d_i <= '0';
									lpp_c_i <= '0';
								else
									if(p_count = "111") then
										lpp_d_i <= anb;
										lpp_c_i <= not(anb);
									end if;
								end if;
							end if;
						end process d_lpp;
						
				
				
				end generate gen_8192_addr;

gen_65536_addr : if(nps=65536 or nps=32768) generate
				
get_65536_sw:process(clk,global_clock_enable,p_count,anb)is
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
	    if(reset='1') then
            wc_i <='0';
            wd_i <='0';								
        else
            if(p_count="0111") then
                wd_i<=anb;
                wc_i<=not(anb);
            else
                wc_i<='0';
                wd_i<='0';
            end if;
        end if;
    end if;
end process get_65536_sw;
				
d_lpp:process(clk,global_clock_enable,reset,anb,p_count)is
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
        if(reset='1') then
            lpp_d_i <= '0';
            lpp_c_i <= '0';
        else
            if(p_count = "1000") then
                lpp_d_i <= anb;
                lpp_c_i <= not(anb);
            end if;
        end if;
    end if;
end process d_lpp;
						
end generate gen_65536_addr;

gen_131072_addr : if(nps=131072) generate
				
get_131072_sw:process(clk,global_clock_enable,p_count,anb)is
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
	    if(reset='1') then
            wc_i <='0';
            wd_i <='0';								
        else
            if(p_count="1000") then
                wd_i<=anb;
                wc_i<=not(anb);
            else
                wc_i<='0';
                wd_i<='0';
            end if;
        end if;
    end if;
end process get_131072_sw;
				
d_lpp:process(clk,global_clock_enable,reset,anb,p_count)is
begin
    if((rising_edge(clk) and global_clock_enable='1'))then
        if(reset='1') then
            lpp_d_i <= '0';
            lpp_c_i <= '0';
        else
            if(p_count = "1001") then
                lpp_d_i <= anb;
                lpp_c_i <= not(anb);
            end if;
        end if;
    end if;
end process d_lpp;
						
end generate gen_131072_addr;

end generate gen_streaming_enables;
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
gen_bb_enables : if(arch=1 or arch=2) generate

				
fsm:process(clk,global_clock_enable,wc_state,reset)is
					begin
if((rising_edge(clk) and global_clock_enable='1'))then
							if(reset='1') then
								wc_state<=IDLE;
							else
								case wc_state is
									when IDLE=>
										if(p_count=int2ustd(ptc,log2_n_passes)) then        
											wc_state<=WAIT_LAT;
										else
											wc_state<=IDLE;
										end if;
										wait_count<=(others=>'0');
									when WAIT_LAT=>
										wait_count<=wait_count+int2ustd(1,4);
										if(wait_count=int2ustd(12,4)) then
											wc_state<=ENABLE;
										else
											wc_state<=WAIT_LAT;
										end if;
									when ENABLE=>
										wait_count<=(others=>'0');
										if(p_count=int2ustd(ptc,log2_n_passes)) then        
											wc_state<=ENABLE;
										else
											wc_state<=IDLE;
										end if;
								end case;
							end if;
						end if;
					end process fsm;
									
					
get_256_sw:process(clk,global_clock_enable,wc_state)is
						begin
if((rising_edge(clk) and global_clock_enable='1'))then
								if(wc_state=ENABLE) then
									wc_i<='1';  
								else                         
									wc_i<='0';    
								end if;       
							end if;       
						end process get_256_sw;	
						
					lpp_trig <= wc_i xor wc_i_d; 	
get_256_lpp:process(clk,global_clock_enable,wc_i,lpp_trig)is
						begin
if((rising_edge(clk) and global_clock_enable='1'))then
								if(reset='1') then
								   wc_i_d<='0';
								   lpp_c_i <='0';
								else
									wc_i_d<=wc_i;
									if(lpp_trig='1') then
										lpp_c_i<=not(wc_i);
									end if;
								end if;
							end if;                        
						end process get_256_lpp;
				
end generate gen_bb_enables;


end;

	
