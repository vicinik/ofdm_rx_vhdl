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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_in_write_sgl.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all; 
use work.fft_pack.all;
entity asj_fft_in_write_sgl is
	generic(
						nps : integer :=2048;
						mram : integer :=0;
						arch : integer :=0;
						nume: integer :=2; -- # Engines
						mpr : integer :=16;
						apr : integer :=8;
						bpr : integer :=16;
						bpb : integer :=4
					);
	port(			clk 						: in std_logic;
global_clock_enable : in std_logic;
						reset 					: in std_logic;
						stp             : in std_logic;
						val             : in std_logic;
						block_done      : in std_logic;
						data_real_in   	: in std_logic_vector(mpr-1 downto 0);
						data_imag_in   	: in std_logic_vector(mpr-1 downto 0);
						wr_address_i    : out std_logic_vector(apr-1 downto 0);
						byte_enable     : out std_logic_vector(bpr-1 downto 0);
						wren_i          : out std_logic_vector(3 downto 0);
						data_rdy        : out std_logic;
						a_not_b         : out std_logic;
						disable_wr      : out std_logic;
						next_block      : out std_logic;
						data_in_r    		: out std_logic_vector(mpr-1 downto 0);
						data_in_i    		: out std_logic_vector(mpr-1 downto 0)
			);
end asj_fft_in_write_sgl;

architecture writer of asj_fft_in_write_sgl is

-- Quad Output : The precision of the counter must be capable of counting to N
-- The precision of the generated addresses is apr 
-- where apr=apri-2 for single engine
--  				 apr=apri-3 for dual engine
--						 apr=apri-4 for quad engine

constant  apri : integer := apr + nume + 1;
constant  apri_qe : integer := apr+4;

-- Single Output : The precision of the counter must be capable of counting to N
-- The precision of the generated addresses is apr 
-- where apr=apri for single engine
-- apr=apri-1 for dual engine
constant  apri_so : integer := apr + nume - 1;


--constant  aprim3 : integer := 2**apri-5;
constant  aprim1 : integer := 2**apri-1;
constant  aprim5 : integer := 2**apri-5;
signal sw : std_logic_vector(1 downto 0);	
signal sw_int : std_logic_vector(1 downto 0);	
signal dual_ram_sel : std_logic_vector(2 downto 0);
signal wr_addr : std_logic_vector(apr-1 downto 0);
signal wr_addr_so : std_logic_vector(apr-3 downto 0);
signal wr_address_i_int : std_logic_vector(apr-1 downto 0);
signal wr_address_i_early : std_logic_vector(apr-1 downto 0);
signal wren          :  std_logic_vector(3 downto 0);

signal data_in_r_int : std_logic_vector(mpr-1 downto 0);
signal data_in_i_int : std_logic_vector(mpr-1 downto 0);
signal data_in_r_int2 : std_logic_vector(mpr-1 downto 0);
signal data_in_i_int2 : std_logic_vector(mpr-1 downto 0);


signal byte_enable_tmp : std_logic_vector(bpr-1 downto 0);
signal count : std_logic_vector(apri-1 downto 0);
signal so_count : std_logic_vector(apri_so-1 downto 0);
signal qe_count : std_logic_vector(apri_qe-1 downto 0);
signal proc_count : std_logic_vector(apri-1 downto 0);
signal anb : std_logic;
signal burst_count_en : std_logic ;
signal str_count_en : std_logic ;
signal count_enable : std_logic ;
signal rdy_for_next_block : std_logic;
signal data_rdy_int       : std_logic;
signal data_loaded       : std_logic;

signal val_d : std_logic;

begin
-- Output address
wr_address_i <= wr_address_i_int; 
-- Output enable
wren_i <= wren;
-- Output switch control
--sw_i <= sw_int;
a_not_b   <= anb;


-----------------------------------------------------------------------------------------------
-- Quad Output Engine Generators and Control
-----------------------------------------------------------------------------------------------
gen_quad : if(arch<3) generate
-----------------------------------------------------------------------------------------
-- Single Engine
-----------------------------------------------------------------------------------------
gen_se_writer : if(nume=1) generate


counter_i:process(clk,global_clock_enable,reset,stp,count_enable,count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			if(reset='1' or stp = '1') then
				count <= (others=>'0');
			elsif(count_enable='1') then
				count <= count + int2ustd(1,apri);
			end if;
		end if;
	end process counter_i;

gen_streaming_rdy : if(arch=0) generate

	count_enable <= str_count_en and val;
	disable_wr <='0';
	data_rdy <= data_rdy_int;


is_data_ready:process(clk,global_clock_enable,reset,count,anb,data_rdy_int)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				if(reset='1') then -- or stp='1') then
						data_rdy_int <='0';	
						anb  <='1';
						next_block <='0';      
						data_loaded <= '0';						
				else
					if(count=(apr+1 downto 0 => '1')) then
					  anb <= not(anb);
						data_rdy_int <='1';
						next_block <= '1';
						data_loaded <= stp;
					else
						data_rdy_int <= data_rdy_int;
						data_loaded <= data_loaded;
						anb <= anb;
					  next_block <= '0';
					end if;
				end if;
			end if;
		end process is_data_ready;
		
			
count_en:process(clk,global_clock_enable,reset,stp,str_count_en)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
						str_count_en<='0';
					elsif(stp='1') then
						str_count_en<='1';
					elsif(count=(apr+1 downto 0 => '1')) then
						str_count_en<='0';
					else
						str_count_en <= str_count_en;
					end if;
				end if;
			end process count_en;

end generate gen_streaming_rdy;

gen_burst_rdy : if(arch=1 or arch=2) generate
		
		count_enable <= burst_count_en and val_d;
		next_block <= rdy_for_next_block;
	  delay_swd : asj_fft_tdl_bit_rst 
			generic map( 
							 		del   => 1
							)
			port map( 	
global_clock_enable => global_clock_enable,
									clk 	=> clk,
									reset => reset,								
									data_in 	=> val,
					 				data_out 	=> val_d
					);

is_anb_ready:process(clk,global_clock_enable,reset,count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
							anb  <='1';
					else
						if(count=(apr+1 downto 0 => '1')) then
						  anb <= '0';
						end if;
					end if;
				end if;
			end process is_anb_ready;
		
		data_rdy <= data_rdy_int;
		
is_data_ready:process(clk,global_clock_enable,reset,rdy_for_next_block,data_rdy_int,block_done)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
							data_rdy_int <='0';	
					else
						if(rdy_for_next_block='1') then
							data_rdy_int <='1';
						elsif(block_done='1') then
							data_rdy_int <='0';
						else
							data_rdy_int <=data_rdy_int;
						end if;
					end if;
				end if;
			end process is_data_ready;
			
			
count_en:process(clk,global_clock_enable,reset,stp,val,rdy_for_next_block)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
						burst_count_en<='0';
					elsif(stp='1') then
						burst_count_en<='1';
					elsif(rdy_for_next_block='1') then
						burst_count_en<='0';
					end if;
				end if;
			end process count_en;
			
		
is_next_blk:process(clk,global_clock_enable,reset,count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
							rdy_for_next_block <='0';
					else
						if(count=int2ustd(aprim1,apri)) then
							rdy_for_next_block <= '1';
						else
							rdy_for_next_block <= '0';
						end if;
					end if;
				end if;
			end process is_next_blk;
			
disable_writer:process(clk,global_clock_enable,reset,count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
							disable_wr <='0';
					else
						if(count=int2ustd(aprim5,apri)) then
							disable_wr <='1';
						else
							disable_wr <='0';
						end if;
					end if;
				end if;
			end process disable_writer;
			
		
end generate gen_burst_rdy;
	

	gen_se_wr_M4K : if(mram=0) generate

output_data:process(clk,global_clock_enable,sw,reset,data_real_in,data_imag_in,wr_addr)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
			if(reset='1') then
				wren <= "0000";
				data_in_r 		<= (others=>'0');
				data_in_i		 	<= (others=>'0');
				wr_address_i_int <= (others=>'0');
			else
				wr_address_i_int <= wr_addr;
				-- shift input by 2 to allow for increased internal precision?
				--data_in_r <= (data_real_in(mpr-1) & data_real_in(mpr-1 downto 1)) + ((mpr-1 downto 1 => '0') & (not(data_real_in(mpr-1)) and data_real_in(0)));
				--data_in_i <= (data_imag_in(mpr-1) & data_imag_in(mpr-1 downto 1)) + ((mpr-1 downto 1 => '0') & (not(data_imag_in(mpr-1)) and data_imag_in(0)));
				data_in_r <= (data_real_in);
				data_in_i <= (data_imag_in);
				
				byte_enable <=(others=>'1');
				case sw(1 downto 0) is
					when "00" =>
						wren <= "0001";
					when "01" =>
						wren <= "0010";
					when "10" =>
						wren <= "0100";
					when "11" =>
						wren <= "1000";
					when others =>
						wren <= "XXXX";
				end case;
			end if;
		end if;
		end process output_data;
	
	end generate gen_se_wr_M4K;
	
gen_se_wr_Mega : if(mram=1) generate

output_data:process(clk,global_clock_enable,sw,reset,data_real_in,data_imag_in,wr_addr,byte_enable_tmp)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
			if(reset='1') then
				wren <= "0000";
				byte_enable <=(others=>'0');
				byte_enable_tmp <=(others=>'0');
				data_in_r 		<= (others=>'0');
				data_in_i		 	<= (others=>'0');
				wr_address_i_int <= (others=>'0');
			else
				wr_address_i_int <= wr_addr;
				
				-- shift input by 2 to allow for increased internal precision?
				--data_in_r <= (data_real_in(mpr-1) & data_real_in(mpr-1 downto 1)) + ((mpr-1 downto 1 => '0') & (not(data_real_in(mpr-1)) and data_real_in(0)));
				--data_in_i <= (data_imag_in(mpr-1) & data_imag_in(mpr-1 downto 1)) + ((mpr-1 downto 1 => '0') & (not(data_imag_in(mpr-1)) and data_imag_in(0)));
				data_in_r <= (data_real_in);
				data_in_i <= (data_imag_in);
				wren <="1111";
				byte_enable <= byte_enable_tmp;
				case sw(1 downto 0) is
					when "00" =>
						byte_enable_tmp(bpr-1 downto bpr-bpb) <= (bpr-1 downto bpr-bpb =>'1');
						byte_enable_tmp(bpr-bpb-1 downto 0) <= (bpr-bpb-1 downto 0 =>'0');
					when "01" =>
						byte_enable_tmp(bpr-1 downto bpr-bpb) <= (bpr-1 downto bpr-bpb =>'0');
						byte_enable_tmp(bpr-bpb-1 downto bpr-2*bpb) <= (bpr-bpb-1 downto bpr-2*bpb =>'1');
						byte_enable_tmp(bpr-2*bpb-1 downto 0) <= (bpr-2*bpb-1 downto 0 =>'0');
					when "10" =>
						byte_enable_tmp(bpr-1 downto bpr-2*bpb) <= (bpr-1 downto bpr-2*bpb =>'0');
						byte_enable_tmp(bpr-2*bpb-1 downto bpr-3*bpb) <= (bpr-2*bpb-1 downto bpr-3*bpb =>'1');
						byte_enable_tmp(bpr-3*bpb-1 downto 0) <= (bpr-3*bpb-1 downto 0 =>'0');
					when "11" =>
						byte_enable_tmp(bpr-1 downto bpb) <= (bpr-1 downto bpb =>'0');
						byte_enable_tmp(bpr-3*bpb-1 downto 0) <= (bpr-3*bpb-1 downto 0 =>'1');
					when others =>
						byte_enable_tmp(bpr-1 downto 0) <= (bpr-1 downto 0 =>'0');
				end case;
			end if;
		end if;
		end process output_data;
	
	end generate gen_se_wr_Mega;
	

end generate gen_se_writer;
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- Dual Engine
-----------------------------------------------------------------------------------------
gen_de_writer : if(nume=2) generate

-- apr is apr/2 form that required for single engine case

counter_i:process(clk,global_clock_enable,reset,stp,count_enable,count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			if(reset='1' or stp = '1') then
				count <= (others=>'0');
			elsif(count_enable='1') then
				count <= count + int2ustd(1,apri);
			end if;
		end if;
	end process counter_i;
	
	
gen_streaming_rdy : if(arch=0) generate

	count_enable <= str_count_en and val;
	disable_wr <='0';
	data_rdy <= data_rdy_int;


is_data_ready:process(clk,global_clock_enable,reset,count,anb,data_rdy_int)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				if(reset='1') then -- or stp='1') then
						data_rdy_int <='0';	
						anb  <='1';
						next_block <='0';      
						data_loaded <= '0';						
				else
					if(count(apri-1 downto 0)=(apri-1 downto 0 => '1')) then
					  anb <= not(anb);
						data_rdy_int <='1';
						next_block <= '1';
						data_loaded <= stp;
					else
						data_rdy_int <= data_rdy_int;
						data_loaded <= data_loaded;
						anb <= anb;
					  next_block <= '0';
					end if;
				end if;
			end if;
		end process is_data_ready;
		
			
count_en:process(clk,global_clock_enable,reset,stp,str_count_en)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
						str_count_en<='0';
					elsif(stp='1') then
						str_count_en<='1';
					elsif(count(apri-1 downto 0)=(apri-1 downto 0 => '1')) then
						str_count_en<='0';
					else
						str_count_en <= str_count_en;
					end if;
				end if;
			end process count_en;
	
end generate gen_streaming_rdy;

gen_burst_rdy : if(arch=1 or arch=2) generate
		
		count_enable <= burst_count_en and val_d;
		--count_enable <= val_d;
	  next_block <= rdy_for_next_block;
	  
	  delay_swd : asj_fft_tdl_bit_rst 
			generic map( 
							 		del   => 1
							)
			port map( 	
global_clock_enable => global_clock_enable,
									clk 	=> clk,
									reset => reset,								
									data_in 	=> val,
					 				data_out 	=> val_d
					);
	  
is_anb_ready:process(clk,global_clock_enable,reset,count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
							anb  <='1';
					else
						if(count=(apr+1 downto 0 => '1')) then
						  anb <= '0';
						end if;
					end if;
				end if;
			end process is_anb_ready;
		
		data_rdy <= data_rdy_int;
		
is_data_ready:process(clk,global_clock_enable,reset,rdy_for_next_block,data_rdy_int,block_done)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
							data_rdy_int <='0';	
					else
						if(rdy_for_next_block='1') then
							data_rdy_int <='1';
						elsif(block_done='1') then
							data_rdy_int <='0';
						else
							data_rdy_int <=data_rdy_int;
						end if;
					end if;
				end if;
			end process is_data_ready;
			
			
count_en:process(clk,global_clock_enable,reset,stp,rdy_for_next_block)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
						burst_count_en<='0';
					elsif(stp='1') then
						burst_count_en<='1';
					elsif(rdy_for_next_block='1') then
						burst_count_en<='0';
					end if;
				end if;
			end process count_en;
			
		
is_next_blk:process(clk,global_clock_enable,reset,count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
							rdy_for_next_block <='0';
					else
						if(count=int2ustd(aprim1,apri)) then
							rdy_for_next_block <= '1';
						else
							rdy_for_next_block <= '0';
						end if;
					end if;
				end if;
			end process is_next_blk;
			
disable_writer:process(clk,global_clock_enable,reset,count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
							disable_wr <='0';
					else
						if(count=int2ustd(aprim5,apri)) then
							disable_wr <='1';
						else
							disable_wr <='0';
						end if;
					end if;
				end if;
			end process disable_writer;
			
		
end generate gen_burst_rdy;
	
	gen_de_wr_M4K : if(mram=0) generate

output_data:process(clk,global_clock_enable,sw,reset,wr_addr,data_real_in,data_imag_in)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
			if(reset='1') then
				wren <= "0000";
				data_in_r 		<= (others=>'0');
				data_in_i		 	<= (others=>'0');
				wr_address_i_int <= (others=>'0');
			else
				wr_address_i_int <= wr_addr;
				-- shift input by 2 to allow for increased internal precision?
				--data_in_r <= (data_real_in(mpr-1) & data_real_in(mpr-1 downto 1))+ ((mpr-1 downto 1 => '0') & (not(data_real_in(mpr-1)) and data_real_in(0)));
				--data_in_i <= (data_imag_in(mpr-1) & data_imag_in(mpr-1 downto 1))+ ((mpr-1 downto 1 => '0') & (not(data_imag_in(mpr-1)) and data_imag_in(0)));
				data_in_r <= data_real_in;   
				data_in_i <= data_imag_in;   

				byte_enable <=(others=>'1');
				case sw(1 downto 0) is
					when "00" =>
						wren <= "0001";
					when "01" =>
						wren <= "0010";
					when "10" =>
						wren <= "0100";
					when "11" =>
						wren <= "1000";
					when others =>
						wren <= "XXXX";
				end case;
			end if;
		end if;
		end process output_data;
	
	end generate gen_de_wr_M4K;
	
	gen_de_wr_Mega : if(mram=1) generate
	
		--wr_address_i_int <= wr_addr;

output_data:process(clk,global_clock_enable,sw,reset,wr_addr,data_real_in,data_imag_in,byte_enable_tmp)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
			if(reset='1') then
				wren <= "0000";
				byte_enable <=(others=>'0');
				byte_enable_tmp <=(others=>'0');
				data_in_r 		<= (others=>'0');
				data_in_i		 	<= (others=>'0');
				wr_address_i_int <= (others=>'0');
			else
				wr_address_i_int <= wr_addr;
				-- shift input by 2 to allow for increased internal precision?
				--data_in_r <= (data_real_in(mpr-1) & data_real_in(mpr-1 downto 1))+ ((mpr-1 downto 1 => '0') & (not(data_real_in(mpr-1)) and data_real_in(0)));
				--data_in_i <= (data_imag_in(mpr-1) & data_imag_in(mpr-1 downto 1))+ ((mpr-1 downto 1 => '0') & (not(data_imag_in(mpr-1)) and data_imag_in(0)));
				data_in_r <= data_real_in;   
				data_in_i <= data_imag_in;   
				wren <="1111";
				byte_enable <= byte_enable_tmp;
				case sw(1 downto 0) is
					when "00" =>
						byte_enable_tmp(bpr-1 downto bpr-bpb) <= (bpr-1 downto bpr-bpb =>'1');
						byte_enable_tmp(bpr-bpb-1 downto 0) <= (bpr-bpb-1 downto 0 =>'0');
					when "01" =>
						byte_enable_tmp(bpr-1 downto bpr-bpb) <= (bpr-1 downto bpr-bpb =>'0');
						byte_enable_tmp(bpr-bpb-1 downto bpr-2*bpb) <= (bpr-bpb-1 downto bpr-2*bpb =>'1');
						byte_enable_tmp(bpr-2*bpb-1 downto 0) <= (bpr-2*bpb-1 downto 0 =>'0');
					when "10" =>
						byte_enable_tmp(bpr-1 downto bpr-2*bpb) <= (bpr-1 downto bpr-2*bpb =>'0');
						byte_enable_tmp(bpr-2*bpb-1 downto bpr-3*bpb) <= (bpr-2*bpb-1 downto bpr-3*bpb =>'1');
						byte_enable_tmp(bpr-3*bpb-1 downto 0) <= (bpr-3*bpb-1 downto 0 =>'0');
					when "11" =>
						byte_enable_tmp(bpr-1 downto bpb) <= (bpr-1 downto bpb =>'0');
						byte_enable_tmp(bpr-3*bpb-1 downto 0) <= (bpr-3*bpb-1 downto 0 =>'1');
					when others =>
						byte_enable_tmp(bpr-1 downto 0) <= (bpr-1 downto 0 =>'0');
				end case;
			end if;
		end if;
		end process output_data;
	
	end generate gen_de_wr_Mega;
	
	
	
	

end generate gen_de_writer;

-----------------------------------------------------------------------------------------------
-- Quad Engine Writer
-----------------------------------------------------------------------------------------------
gen_qe_writer : if(nume=4) generate

-- apr is apr/4 form that required for single engine case

counter_i:process(clk,global_clock_enable,reset,stp,count_enable,count)is
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
			if(reset='1' or stp = '1') then
				qe_count <= (others=>'0');
			elsif(count_enable='1') then
				qe_count <= qe_count + int2ustd(1,apri_qe);
			end if;
		end if;
	end process counter_i;
	
	

gen_burst_rdy : if(arch=1 or arch=2) generate
		
		count_enable <= burst_count_en and val_d;
		--count_enable <= val_d;
	  next_block <= rdy_for_next_block;
	  
	   delay_swd : asj_fft_tdl_bit_rst 
			generic map( 
							 		del   => 1
							)
			port map( 	
global_clock_enable => global_clock_enable,
									clk 	=> clk,
									reset => reset,								
									data_in 	=> val,
					 				data_out 	=> val_d
					);
	  
is_anb_ready:process(clk,global_clock_enable,reset,count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
							anb  <='1';
					else
						if(qe_count=(apr+1 downto 0 => '1')) then
						  anb <= '0';
						end if;
					end if;
				end if;
			end process is_anb_ready;
		
		data_rdy <= data_rdy_int;
		
is_data_ready:process(clk,global_clock_enable,reset,rdy_for_next_block,data_rdy_int,block_done)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
							data_rdy_int <='0';	
					else
						if(rdy_for_next_block='1') then
							data_rdy_int <='1';
						elsif(block_done='1') then
							data_rdy_int <='0';
						else
							data_rdy_int <=data_rdy_int;
						end if;
					end if;
				end if;
			end process is_data_ready;
			
			
count_en:process(clk,global_clock_enable,reset,stp,rdy_for_next_block)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
						burst_count_en<='0';
					elsif(stp='1') then
						burst_count_en<='1';
					elsif(rdy_for_next_block='1') then
						burst_count_en<='0';
					end if;
				end if;
			end process count_en;
			
		
is_next_blk:process(clk,global_clock_enable,reset,count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
							rdy_for_next_block <='0';
					else
						if(qe_count=int2ustd(aprim1,apri)) then
							rdy_for_next_block <= '1';
						else
							rdy_for_next_block <= '0';
						end if;
					end if;
				end if;
			end process is_next_blk;
			
disable_writer:process(clk,global_clock_enable,reset,count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
							disable_wr <='0';
					else
						if(qe_count=int2ustd(aprim5,apri)) then
							disable_wr <='1';
						else
							disable_wr <='0';
						end if;
					end if;
				end if;
			end process disable_writer;
			
		
end generate gen_burst_rdy;
	
	gen_qe_wr_M4K : if(mram=0) generate

output_data:process(clk,global_clock_enable,sw,reset,wr_addr,data_real_in,data_imag_in)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
			if(reset='1') then
				wren <= "0000";
				data_in_r 		<= (others=>'0');
				data_in_i		 	<= (others=>'0');
				wr_address_i_int <= (others=>'0');
			else
				wr_address_i_int <= wr_addr;
				-- shift input by 2 to allow for increased internal precision?
				--data_in_r <= (data_real_in(mpr-1) & data_real_in(mpr-1 downto 1))+ ((mpr-1 downto 1 => '0') & (not(data_real_in(mpr-1)) and data_real_in(0)));
				--data_in_i <= (data_imag_in(mpr-1) & data_imag_in(mpr-1 downto 1))+ ((mpr-1 downto 1 => '0') & (not(data_imag_in(mpr-1)) and data_imag_in(0)));
				data_in_r <= data_real_in;   
				data_in_i <= data_imag_in;   

				byte_enable <=(others=>'1');
				case sw(1 downto 0) is
					when "00" =>
						wren <= "0001";
					when "01" =>
						wren <= "0010";
					when "10" =>
						wren <= "0100";
					when "11" =>
						wren <= "1000";
					when others =>
						wren <= "XXXX";
				end case;
			end if;
		end if;
		end process output_data;
	
	end generate gen_qe_wr_M4K;
	
	gen_qe_wr_Mega : if(mram=1) generate
	
		--wr_address_i_int <= wr_addr;

output_data:process(clk,global_clock_enable,sw,reset,wr_addr,data_real_in,data_imag_in,byte_enable_tmp)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
			if(reset='1') then
				wren <= "0000";
				byte_enable <=(others=>'0');
				byte_enable_tmp <=(others=>'0');
				data_in_r 		<= (others=>'0');
				data_in_i		 	<= (others=>'0');
				wr_address_i_int <= (others=>'0');
			else
				wr_address_i_int <= wr_addr;
				-- shift input by 2 to allow for increased internal precision?
				--data_in_r <= (data_real_in(mpr-1) & data_real_in(mpr-1 downto 1))+ ((mpr-1 downto 1 => '0') & (not(data_real_in(mpr-1)) and data_real_in(0)));
				--data_in_i <= (data_imag_in(mpr-1) & data_imag_in(mpr-1 downto 1))+ ((mpr-1 downto 1 => '0') & (not(data_imag_in(mpr-1)) and data_imag_in(0)));
				data_in_r <= data_real_in;   
				data_in_i <= data_imag_in;   
				wren <="1111";
				byte_enable <= byte_enable_tmp;
				case sw(1 downto 0) is
					when "00" =>
						byte_enable_tmp(bpr-1 downto bpr-bpb) <= (bpr-1 downto bpr-bpb =>'1');
						byte_enable_tmp(bpr-bpb-1 downto 0) <= (bpr-bpb-1 downto 0 =>'0');
					when "01" =>
						byte_enable_tmp(bpr-1 downto bpr-bpb) <= (bpr-1 downto bpr-bpb =>'0');
						byte_enable_tmp(bpr-bpb-1 downto bpr-2*bpb) <= (bpr-bpb-1 downto bpr-2*bpb =>'1');
						byte_enable_tmp(bpr-2*bpb-1 downto 0) <= (bpr-2*bpb-1 downto 0 =>'0');
					when "10" =>
						byte_enable_tmp(bpr-1 downto bpr-2*bpb) <= (bpr-1 downto bpr-2*bpb =>'0');
						byte_enable_tmp(bpr-2*bpb-1 downto bpr-3*bpb) <= (bpr-2*bpb-1 downto bpr-3*bpb =>'1');
						byte_enable_tmp(bpr-3*bpb-1 downto 0) <= (bpr-3*bpb-1 downto 0 =>'0');
					when "11" =>
						byte_enable_tmp(bpr-1 downto bpb) <= (bpr-1 downto bpb =>'0');
						byte_enable_tmp(bpr-3*bpb-1 downto 0) <= (bpr-3*bpb-1 downto 0 =>'1');
					when others =>
						byte_enable_tmp(bpr-1 downto 0) <= (bpr-1 downto 0 =>'0');
				end case;
			end if;
		end if;
		end process output_data;
	end generate gen_qe_wr_Mega;
end generate gen_qe_writer;

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

gen_se_addr : if(nume=1) generate

-- Calculate the 4 addresses. This is dependend on N and the number of engines.
gen_32_addr : if(nps=32) generate
				--sw = mod(2*mod(k,2) + floor(k/2) + floor(k/32),4) + 1;
        --offset_r =   mod(16*mod(k,2)+4*floor(mod(k,8)/2) +  floor(mod(k,32)/8),n_by_4) + 1;
get_32_addr:process(clk,global_clock_enable,count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= (count(0) & '0') + count(2 downto 1) + count(apri-1 downto apri-2);
				wr_addr   <= (count(0)  & count(2 downto 1));
			end if;
		end process get_32_addr;
		
end generate gen_32_addr;


gen_64_addr : if(nps=64) generate

get_64_addr:process(clk,global_clock_enable,count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= count(apri-1 downto apri-2)+count(1 downto 0);
				wr_addr   <= (count(1 downto 0) & "00") + ("00" & count(3 downto 2));
			end if;
		end process get_64_addr;
		
end generate gen_64_addr;

gen_128_addr : if(nps=128) generate
				--sw = mod(2*mod(k,2) + floor(k/2) + floor(k/32),4) + 1;
        --offset_r =   mod(16*mod(k,2)+4*floor(mod(k,8)/2) +  floor(mod(k,32)/8),n_by_4) + 1;
get_128_addr:process(clk,global_clock_enable,count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= (count(0) & '0') + count(2 downto 1) + count(apri-1 downto apri-2);
				wr_addr   <= (count(0) & "0000") + ('0' & count(2 downto 1) & "00")+ ("000" & count(4 downto 3));
			end if;
		end process get_128_addr;
		
end generate gen_128_addr;


gen_256_addr : if(nps=256) generate

get_256_addr:process(clk,global_clock_enable,count)
		--sw = mod(mod(k,4) + floor(k/64),4) + 1;
    --offset_r =  mod(16*mod(k,4)+4*floor(mod(k,16)/4) + floor(mod(k,64)/16),n_by_4) + 1;
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= count(apri-1 downto apri-2)+count(1 downto 0);
				wr_addr   <= (count(1 downto 0) & "0000") + ("00" & count(3 downto 2) & "00") + ("0000" & count(5 downto 4));
			end if;
		end process get_256_addr;
		
end generate gen_256_addr;

gen_512_addr : if(nps=512) generate

get_512_addr:process(clk,global_clock_enable,count)
		begin
			--sw = mod(2*mod(k,2) + floor(k/2) + floor(k/128),4) + 1;
			--offset_r =   mod(64*mod(k,2)+16*floor(mod(k,8)/2) +  4*floor(mod(k,32)/8)+ floor(mod(k,128)/32),n_by_4) + 1;
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= (count(0) & '0') + count(2 downto 1) + count(apri-1 downto apri-2);
				wr_addr   <= (count(0) & "000000") + ('0' & count(2 downto 1) & "0000")+ ("000" & count(4 downto 3) & "00") + ("00000" & count(6 downto 5));
			end if;

		end process get_512_addr;

end generate gen_512_addr;

gen_1024_addr : if(nps=1024) generate

get_1024_addr:process(clk,global_clock_enable,count)
	--sw = mod(mod(k,4) + floor(k/256),4) + 1;
  --offset_r =   mod(64*mod(k,4)+16*floor(mod(k,16)/4) + 4*floor(mod(k,64)/16) + floor(mod(k,256)/64),n_by_4) + 1;
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= count(apri-1 downto apri-2)+count(1 downto 0);
				wr_addr   <= (count(1 downto 0) & "000000") + ("00" & count(3 downto 2) & "0000") + ("0000" & count(5 downto 4) & "00") + ("000000" & count(7 downto 6));
			end if;

		end process get_1024_addr;
		
end generate gen_1024_addr;

gen_2048_addr : if(nps=2048) generate

get_2048_addr:process(clk,global_clock_enable,count)
	  --     sw = mod(2*mod(k,2) + floor(k/2) + floor(k/512),4) + 1;
    --    offset_r =   mod(256*mod(k,2)+64*floor(mod(k,8)/2) +  16*floor(mod(k,32)/8)+ 4*floor(mod(k,128)/32) + floor(mod(k,512)/128),n_by_4) + 1;
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= (count(0) & '0') + count(2 downto 1) + count(apri-1 downto apri-2);
				wr_addr   <= (count(0) & "00000000") + ('0' & count(2 downto 1) & "000000")+ ("000" & count(4 downto 3) & "0000") + ("00000" & count(6 downto 5) & "00")+("0000000" & count(8 downto 7));
			end if;

		end process get_2048_addr;
	
		
end generate gen_2048_addr;

gen_4096_addr : if(nps=4096) generate
  --      sw = mod(mod(k,4) + floor(k/1024),4) + 1;
--offset_r=mod(256*mod(k,4)+64*floor(mod(k,16)/4)+16*floor(mod(k,64)/16)+4*floor(mod(k,256)/64)+floor(mod(k,1024)/256),n_by_4)+1;get_4096_addr:process(clk,global_clock_enable,count)
get_4096_addr:process(clk,global_clock_enable,count)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= count(apri-1 downto apri-2)+count(1 downto 0);
				wr_addr   <= (count(1 downto 0) & "00000000") + ("00" & count(3 downto 2) & "000000") + ("0000" & count(5 downto 4) & "0000") + ("000000" & count(7 downto 6) & "00")+ ("00000000" & count(9 downto 8)) ;
			end if;

		end process get_4096_addr;
		
end generate gen_4096_addr;

gen_8192_addr : if(nps=8192) generate

	--sw = sw = mod(2*mod(k,2) + floor(k/2) + floor(k/2048),4) + 1;
  --offset_r =   mod(1024*mod(k,2)+256*floor(mod(k,8)/2) +  64*floor(mod(k,32)/8)+ 16*floor(mod(k,128)/32) + 4*floor(mod(k,512)/128) + floor(mod(k,2048)/512),n_by_4) + 1;

get_8192_addr:process(clk,global_clock_enable,count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= (count(0) & '0') + count(2 downto 1) + count(apri-1 downto apri-2);
				wr_addr   <= (count(0) & "0000000000") + ('0' & count(2 downto 1) & "00000000")+ ("000" & count(4 downto 3) & "000000") + ("00000" & count(6 downto 5) & "0000")+("0000000" & count(8 downto 7) & "00") + ("000000000" & count(10 downto 9));
			end if;
		end process get_8192_addr;
		
end generate gen_8192_addr;

gen_16384_addr : if(nps=16384) generate

get_16384_addr:process(clk,global_clock_enable,count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= count(apri-1 downto apri-2)+count(1 downto 0);
				wr_addr   <= (count(1 downto 0) & "0000000000") + ("00" & count(3 downto 2) & "00000000") + ("0000" & count(5 downto 4) & "000000") + ("000000" & count(7 downto 6) & "0000") + ("00000000" & count(9 downto 8) & "00") + ("0000000000" & count(11 downto 10) );
			end if;

		end process get_16384_addr;
		
end generate gen_16384_addr;

gen_32768_addr : if(nps=32768) generate

get_32768_addr:process(clk,global_clock_enable,count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
					sw 		  <= (count(0) & '0') + count(2 downto 1) + count(apri-1 downto apri-2);
					wr_addr   <= count(0) & count(2 downto 1) & count(4 downto 3) & count(6 downto 5) & count(8 downto 7) & count(10 downto 9) & count(12 downto 11);
			end if;

		end process get_32768_addr;
		
end generate gen_32768_addr;

gen_65536_addr : if(nps=65536) generate

get_65536_addr:process(clk,global_clock_enable,count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 		  <= count(apri-1 downto apri-2)+count(1 downto 0);
				wr_addr   <= count(1 downto 0) & count(3 downto 2) & count(5 downto 4) & count(7 downto 6) & count(9 downto 8) & count(11 downto 10) & count(13 downto 12);
			end if;

		end process get_65536_addr;
		
end generate gen_65536_addr;





end generate gen_se_addr;
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
gen_de_addr : if(nume=2) generate

gen_64_addr : if(nps=64) generate

get_64_addr:process(clk,global_clock_enable,count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--sw = mod(mod(kkk,2) + floor(kkk/8),4) + 1;
        --offset_r =   mod(4*mod(kkk,4)+floor(mod(k,16)/4),n_by_8) + 1;
				sw 				<= count(apri-1 downto apri-2)+('0' & count(1));
				wr_addr   <= (count(1) & "00") + ('0' & count(3 downto 2));
			end if;
		end process get_64_addr;
		
end generate gen_64_addr;

gen_128_addr : if(nps=128) generate

get_128_addr:process(clk,global_clock_enable,count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--sw = mod(mod(kkk,2) + floor(kkk/8),4) + 1;
        --offset_r =   mod(16*mod(kkk,2)+4*floor(mod(k,8)/2) +  floor(mod(k,32)/8),n_by_8) + 1;
				sw 				<= count(apri-1 downto apri-2)+('0' & count(1));
				wr_addr   <= (count(2 downto 1) & "00") + ("00" & count(4 downto 3));
			end if;
		end process get_128_addr;
		
end generate gen_128_addr;



gen_256_addr : if(nps=256) generate

get_256_addr:process(clk,global_clock_enable,count)
		--sw = mod(mod(kkk,2) + floor(kkk/32),4) + 1;
    --offset_r =   mod(16*mod(kkk,4)+4*floor(mod(k,16)/4) + floor(mod(k,64)/16),n_by_8) + 1;
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= count(apri-1 downto apri-2)+('0' & count(1));
				wr_addr   <= (count(1) & "0000") + ('0' & count(3 downto 2) & "00") + ("000" & count(5 downto 4));
			end if;
		end process get_256_addr;
		
end generate gen_256_addr;

gen_512_addr : if(nps=512) generate

get_512_addr:process(clk,global_clock_enable,count)
	  -- Edit this
	  --    sw = mod(2*mod(k,2) + floor(k/2) + floor(k/512),4) + 1;
    --    offset_r =   mod(256*mod(k,2)+64*floor(mod(k,8)/2) +  16*floor(mod(k,32)/8)+ 4*floor(mod(k,128)/32) + floor(mod(k,512)/128),n_by_4) + 1;
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= count(apri-1 downto apri-2)+('0' & count(1));
				wr_addr   <= (count(2 downto 1) & "0000") + ("00" & count(4 downto 3) & "00") + ("0000" & count(6 downto 5));
			end if;

		end process get_512_addr;
		
end generate gen_512_addr;


gen_1024_addr : if(nps=1024) generate

get_1024_addr:process(clk,global_clock_enable,count)
	
	--sw = mod(mod(kkk,2) + floor(kkk/128),4) + 1;
  --offset_r =   mod(64*mod(kkk,4)+16*floor(mod(k,16)/4) + 4*floor(mod(k,64)/16) + floor(mod(k,256)/64),n_by_8) + 1;
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= count(apri-1 downto apri-2)+('0' & count(1));
				wr_addr   <= (count(1) & "000000") + ('0' & count(3 downto 2) & "0000") + ("000" & count(5 downto 4) & "00") + ("00000" & count(7 downto 6));
			end if;

		end process get_1024_addr;
		
end generate gen_1024_addr;

gen_2048_addr : if(nps=2048) generate

get_2048_addr:process(clk,global_clock_enable,count)
	  -- Edit this
	  --    sw = mod(2*mod(k,2) + floor(k/2) + floor(k/512),4) + 1;
    --    offset_r =   mod(256*mod(k,2)+64*floor(mod(k,8)/2) +  16*floor(mod(k,32)/8)+ 4*floor(mod(k,128)/32) + floor(mod(k,512)/128),n_by_4) + 1;
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= count(apri-1 downto apri-2)+('0' & count(1));
				wr_addr   <= (count(2 downto 1) & "000000") + ("00" & count(4 downto 3) & "0000") + ("0000" & count(6 downto 5) & "00") + ("000000" & count(8 downto 7));
			end if;

		end process get_2048_addr;
		
end generate gen_2048_addr;


gen_4096_addr : if(nps=4096) generate

get_4096_addr:process(clk,global_clock_enable,count)
	--sw = mod(mod(kkk,2) + floor(kkk/512),4) + 1;
  --offset_r =   mod(256*mod(kkk,4)+64*floor(mod(k,16)/4)+16*floor(mod(k,64)/16) + 4*floor(mod(k,256)/64)+floor(mod(k,1024)/256),n_by_8) + 1;
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= count(apri-1 downto apri-2)+('0' & count(1));
				wr_addr   <= (count(1) & "00000000") + ('0' & count(3 downto 2) & "000000") + ("000" & count(5 downto 4) & "0000") + ("00000" & count(7 downto 6) & "00") + ("0000000" & count(9 downto 8));
			end if;

		end process get_4096_addr;
		
end generate gen_4096_addr;

gen_8192_addr : if(nps=8192) generate

get_8192_addr:process(clk,global_clock_enable,count)
	  -- wradd is 10 bits
	  --sw = mod(kkk + floor(kkk/1024),4) + 1;
    --offset_r =   mod(1024*mod(kkk,2)+256*floor(mod(k,8)/2) + 64*floor(mod(k,32)/8)+ 16*floor(mod(k,128)/32) + 4*floor(mod(k,512)/128)+floor(mod(k,2048)/512),n_by_8) + 1;         
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= count(apri-1 downto apri-2)+('0' & count(1));
				wr_addr   <= (count(2 downto 1) & "00000000") + ("00" & count(4 downto 3) & "000000") + ("0000" & count(6 downto 5) & "0000") + ("000000" & count(8 downto 7) & "00") + ("00000000" & count(10 downto 9));
			end if;

		end process get_8192_addr;
		
end generate gen_8192_addr;

gen_16384_addr : if(nps=16384) generate

get_16384_addr:process(clk,global_clock_enable,count)
	--        sw = mod(mod(kkk,2) + floor(kkk/2048),4) + 1;
  --      offset_r =   mod(1024*mod(kkk,4)+256*floor(mod(k,16)/4)+64*floor(mod(k,64)/16) + 16*floor(mod(k,256)/64)+4*floor(mod(k,1024)/256)+floor(mod(k,4096)/1024),n_by_8) + 1;
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= count(apri-1 downto apri-2)+('0' & count(1));
				wr_addr   <= (count(1) & "0000000000") + ('0' & count(3 downto 2) & "00000000") + ("000" & count(5 downto 4) & "000000") + ("00000" & count(7 downto 6) & "0000") + ("0000000" & count(9 downto 8) &"00") + ("000000000" & count(11 downto 10));
			end if;

		end process get_16384_addr;
		
end generate gen_16384_addr;

gen_32768_addr : if(nps=32768) generate

get_32768_addr:process(clk,global_clock_enable,count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 		  <= count(apri-1 downto apri-2)+('0' & count(1));
				wr_addr   <= count(2 downto 1) & count(4 downto 3) & count(6 downto 5) & count(8 downto 7) & count(10 downto 9) & count(12 downto 11);
			end if;

		end process get_32768_addr;
		
end generate gen_32768_addr;

gen_65536_addr : if(nps=65536) generate

get_65536_addr:process(clk,global_clock_enable,count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 		  <= count(apri-1 downto apri-2)+('0' & count(1));
				wr_addr   <= count(1) & count(3 downto 2) & count(5 downto 4) & count(7 downto 6) & count(9 downto 8) & count(11 downto 10) & count(13 downto 12);
			end if;

		end process get_65536_addr;
		
end generate gen_65536_addr;
		
end generate gen_de_addr;

-----------------------------------------------------------------------------------------------
-- Quad Engine
-----------------------------------------------------------------------------------------------

gen_qe_addr : if(nume=4) generate

gen_64_addr : if(nps=64) generate

get_64_addr:process(clk,global_clock_enable,count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= count(apri-1 downto apri-2)+('0' & count(1));
				wr_addr   <= (count(2 downto 1) & "00") + ("00" & count(3 downto 2));
			end if;
		end process get_64_addr;
		
end generate gen_64_addr;

gen_128_addr : if(nps=128) generate

get_128_addr:process(clk,global_clock_enable,count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				--sw = mod(mod(kkk,2) + floor(kkk/8),4) + 1;
        --offset_r =   mod(16*mod(kkk,2)+4*floor(mod(k,8)/2) +  floor(mod(k,32)/8),n_by_8) + 1;
				sw 				<= count(apri-1 downto apri-2)+('0' & count(1));
				wr_addr   <= (count(2 downto 1) & "00") + ("00" & count(4 downto 3));
			end if;
		end process get_128_addr;
		
end generate gen_128_addr;



gen_256_addr : if(nps=256) generate

get_256_addr:process(clk,global_clock_enable,count)
		--sw = mod(mod(kkk,2) + floor(kkk/32),4) + 1;
    --offset_r =   mod(16*mod(kkk,4)+4*floor(mod(k,16)/4) + floor(mod(k,64)/16),n_by_8) + 1;
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= qe_count(apri_qe-1 downto apri_qe-2);
				wr_addr   <= qe_count(3 downto 2) & qe_count(5 downto 4);
			end if;
		end process get_256_addr;
		
end generate gen_256_addr;

gen_512_addr : if(nps=512) generate

get_512_addr:process(clk,global_clock_enable,count)
	  -- Edit this
	  --    sw = mod(2*mod(k,2) + floor(k/2) + floor(k/512),4) + 1;
    --    offset_r =   mod(256*mod(k,2)+64*floor(mod(k,8)/2) +  16*floor(mod(k,32)/8)+ 4*floor(mod(k,128)/32) + floor(mod(k,512)/128),n_by_4) + 1;
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= qe_count(apri_qe-1 downto apri_qe-2);
				wr_addr   <= qe_count(0) & qe_count(4) & qe_count(3) & qe_count(6) & qe_count(5);
			end if;

		end process get_512_addr;
		
end generate gen_512_addr;


gen_1024_addr : if(nps=1024) generate

get_1024_addr:process(clk,global_clock_enable,count)
	
	--sw = mod(mod(kkk,2) + floor(kkk/128),4) + 1;
  --offset_r =   mod(64*mod(kkk,4)+16*floor(mod(k,16)/4) + 4*floor(mod(k,64)/16) + floor(mod(k,256)/64),n_by_8) + 1;
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= qe_count(apri_qe-1 downto apri_qe-2);
				wr_addr   <= qe_count(3 downto 2) & qe_count(5 downto 4) & qe_count(7 downto 6);
			end if;
		end process get_1024_addr;
		
end generate gen_1024_addr;

gen_2048_addr : if(nps=2048) generate
get_2048_addr:process(clk,global_clock_enable,count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= qe_count(apri_qe-1 downto apri_qe-2);
				wr_addr   <= qe_count(0) & qe_count(4) & qe_count(3) & qe_count(6) & qe_count(5) & qe_count(8) & qe_count(7);
			end if;
		end process get_2048_addr;
end generate gen_2048_addr;


gen_4096_addr : if(nps=4096) generate
get_4096_addr:process(clk,global_clock_enable,count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= qe_count(apri_qe-1 downto apri_qe-2);
				wr_addr   <= qe_count(3 downto 2) & qe_count(5 downto 4) & qe_count(7 downto 6) & qe_count(9 downto 8);
			end if;
		end process get_4096_addr;
end generate gen_4096_addr;

gen_8192_addr : if(nps=8192) generate

get_8192_addr:process(clk,global_clock_enable,count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= qe_count(apri_qe-1 downto apri_qe-2);
				wr_addr   <= qe_count(0) & qe_count(4) & qe_count(3) & qe_count(6 downto 5) & qe_count(8 downto 7) & qe_count(10 downto 9);
			end if;
		end process get_8192_addr;
		
end generate gen_8192_addr;

gen_16384_addr : if(nps=16384) generate

get_16384_addr:process(clk,global_clock_enable,count)
	--        sw = mod(mod(kkk,2) + floor(kkk/2048),4) + 1;
  --      offset_r =   mod(1024*mod(kkk,4)+256*floor(mod(k,16)/4)+64*floor(mod(k,64)/16) + 16*floor(mod(k,256)/64)+4*floor(mod(k,1024)/256)+floor(mod(k,4096)/1024),n_by_8) + 1;
	begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 				<= qe_count(apri_qe-1 downto apri_qe-2);
				wr_addr   <= qe_count(3 downto 2) & qe_count(5 downto 4) & qe_count(7 downto 6) & qe_count(9 downto 8) & qe_count(11 downto 10);
			end if;
		
		end process get_16384_addr;
		
end generate gen_16384_addr;

gen_32768_addr : if(nps=32768) generate

get_32768_addr:process(clk,global_clock_enable,count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 		  <= qe_count(apri_qe-1 downto apri_qe-2);
				wr_addr   <= qe_count(0) & qe_count(4 downto 3) & qe_count(6 downto 5) & qe_count(8 downto 7) & qe_count(10 downto 9) & qe_count(12 downto 11);
			end if;

		end process get_32768_addr;
		
end generate gen_32768_addr;

gen_65536_addr : if(nps=65536) generate

get_65536_addr:process(clk,global_clock_enable,count)
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				sw 		  <= qe_count(apri_qe-1 downto apri_qe-2);
				wr_addr   <= qe_count(3 downto 2) & qe_count(5 downto 4) & qe_count(7 downto 6) & qe_count(9 downto 8) & qe_count(11 downto 10) & qe_count(13 downto 12);
			end if;

		end process get_65536_addr;
		
end generate gen_65536_addr;
		
end generate gen_qe_addr;

-----------------------------------------------------------------------------------------------
end generate gen_quad;
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- Single Output Engine Input Buffer Address Generator and Control
-----------------------------------------------------------------------------------------------
gen_soe : if(arch=3) generate

counter_i:process(clk,global_clock_enable,reset,stp,count_enable,so_count)is
		begin
if((rising_edge(clk) and global_clock_enable='1'))then
				if(reset='1' or stp = '1') then
					so_count <= (others=>'0');
				elsif(count_enable='1') then
					so_count <= so_count + int2ustd(1,apr);
				end if;
			end if;
		end process counter_i;
		
		count_enable <= burst_count_en and val_d;
		--count_enable <= val_d;
	  next_block <= rdy_for_next_block;
	  
	   delay_swd : asj_fft_tdl_bit_rst 
			generic map( 
							 		del   => 1
							)
			port map( 	
global_clock_enable => global_clock_enable,
									clk 	=> clk,
									reset => reset,								
									data_in 	=> val,
					 				data_out 	=> val_d
					);
	  
is_anb_ready:process(clk,global_clock_enable,reset,count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
							anb  <='1';
					else
						if(so_count=(apri_so-1 downto 0 => '1')) then
						  anb <= '0';
						end if;
					end if;
				end if;
			end process is_anb_ready;
		
		data_rdy <= data_rdy_int;
		
is_data_ready:process(clk,global_clock_enable,reset,rdy_for_next_block,data_rdy_int,block_done)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
							data_rdy_int <='0';	
					else
						if(rdy_for_next_block='1') then
							data_rdy_int <='1';
						elsif(block_done='1') then
							data_rdy_int <='0';
						else
							data_rdy_int <=data_rdy_int;
						end if;
					end if;
				end if;
			end process is_data_ready;
			
			
count_en:process(clk,global_clock_enable,reset,stp,rdy_for_next_block)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
						burst_count_en<='0';
					elsif(stp='1') then
						burst_count_en<='1';
					elsif(rdy_for_next_block='1') then
						burst_count_en<='0';
					end if;
				end if;
			end process count_en;
			
		
is_next_blk:process(clk,global_clock_enable,reset,so_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
							rdy_for_next_block <='0';
					else
						if(so_count=int2ustd(aprim1,apri_so)) then
							rdy_for_next_block <= '1';
						else
							rdy_for_next_block <= '0';
						end if;
					end if;
				end if;
			end process is_next_blk;
			
disable_writer:process(clk,global_clock_enable,reset,so_count)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
							disable_wr <='0';
					else
						if(so_count=int2ustd(aprim5,apri_so)) then
							disable_wr <='1';
						else
							disable_wr <='0';
						end if;
					end if;
				end if;
			end process disable_writer;
			
		-----------------------------------------------------------------------------------------------
		-- Single Output Loader
		-----------------------------------------------------------------------------------------------
		gen_se : if(nume=1) generate
output_data:process(clk,global_clock_enable,sw,reset,data_real_in,data_imag_in,wr_addr,wr_address_i_early)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
						wren <= "0000";
						data_in_r 		<= (others=>'0');
						data_in_i		 	<= (others=>'0');
						wr_address_i_int <= (others=>'0');
						wr_address_i_early<= (others=>'0');
					else
						wr_address_i_int <= wr_address_i_early;
						wr_address_i_early <= so_count;
						-- shift input by 2 to allow for increased internal precision?
						--data_in_r <= (data_real_in(mpr-1) & data_real_in(mpr-1 downto 1)) + ((mpr-1 downto 1 => '0') & (not(data_real_in(mpr-1)) and data_real_in(0)));
						--data_in_i <= (data_imag_in(mpr-1) & data_imag_in(mpr-1 downto 1)) + ((mpr-1 downto 1 => '0') & (not(data_imag_in(mpr-1)) and data_imag_in(0)));
						data_in_r <= data_real_in;
						data_in_i <= data_imag_in;
						wren <= "1111";
					end if;
				end if;
				end process output_data;	
		end generate gen_se;
		-----------------------------------------------------------------------------------------------
		-- Dual Output Loader
		-----------------------------------------------------------------------------------------------
		gen_de : if(nume=2) generate
output_data:process(clk,global_clock_enable,sw,reset,data_real_in,data_imag_in,wr_addr,wr_address_i_early)is
			begin
if((rising_edge(clk) and global_clock_enable='1'))then
					if(reset='1') then
						wren <= "0000";
						data_in_r 		<= (others=>'0');
						data_in_i		 	<= (others=>'0');
						wr_address_i_int <= (others=>'0');
						wr_address_i_early<= (others=>'0');
					else
						wr_address_i_int <= wr_address_i_early;
						wr_address_i_early <= so_count(apri_so-1 downto 1);
						-- shift input by 2 to allow for increased internal precision?
						--data_in_r <= (data_real_in(mpr-1) & data_real_in(mpr-1 downto 1)) + ((mpr-1 downto 1 => '0') & (not(data_real_in(mpr-1)) and data_real_in(0)));
						--data_in_i <= (data_imag_in(mpr-1) & data_imag_in(mpr-1 downto 1)) + ((mpr-1 downto 1 => '0') & (not(data_imag_in(mpr-1)) and data_imag_in(0)));
						data_in_r <= data_real_in;
						data_in_i <= data_imag_in;
						wren <= "1111";
					end if;
				end if;
				end process output_data;	
		end generate gen_de;
		
		-----------------------------------------------------------------------------------------------
		-- Megaram Byte Enable based on LSB's of generated Address 
		-----------------------------------------------------------------------------------------------
		--gen_be_Mega : if(mram=1) generate
	  --
--byte_en:process(clk,global_clock_enable,sw,reset,wr_addr,data_real_in,data_imag_in,byte_enable_tmp)is
		--	begin
--if((rising_edge(clk) and global_clock_enable='1'))then
		--		if(reset='1') then
		--			sw <=(others=>'0');
		--			byte_enable <=(others=>'0');
		--			byte_enable_tmp <=(others=>'0');
		--		else
		--			sw <= wr_address_i_early(1 downto 0);
		--			byte_enable <= byte_enable_tmp;
		--			case sw(1 downto 0) is
		--				when "00" =>
		--					byte_enable_tmp(bpr-1 downto bpr-bpb) <= (bpr-1 downto bpr-bpb =>'1');
		--					byte_enable_tmp(bpr-bpb-1 downto 0) <= (bpr-bpb-1 downto 0 =>'0');
		--				when "01" =>
		--					byte_enable_tmp(bpr-1 downto bpr-bpb) <= (bpr-1 downto bpr-bpb =>'0');
		--					byte_enable_tmp(bpr-bpb-1 downto bpr-2*bpb) <= (bpr-bpb-1 downto bpr-2*bpb =>'1');
		--					byte_enable_tmp(bpr-2*bpb-1 downto 0) <= (bpr-2*bpb-1 downto 0 =>'0');
		--				when "10" =>
		--					byte_enable_tmp(bpr-1 downto bpr-2*bpb) <= (bpr-1 downto bpr-2*bpb =>'0');
		--					byte_enable_tmp(bpr-2*bpb-1 downto bpr-3*bpb) <= (bpr-2*bpb-1 downto bpr-3*bpb =>'1');
		--					byte_enable_tmp(bpr-3*bpb-1 downto 0) <= (bpr-3*bpb-1 downto 0 =>'0');
		--				when "11" =>
		--					byte_enable_tmp(bpr-1 downto bpb) <= (bpr-1 downto bpb =>'0');
		--					byte_enable_tmp(bpr-3*bpb-1 downto 0) <= (bpr-3*bpb-1 downto 0 =>'1');
		--				when others =>
		--					byte_enable_tmp(bpr-1 downto 0) <= (bpr-1 downto 0 =>'0');
		--			end case;
		--		end if;
		--	end if;
		--end process byte_en;
		--end generate gen_be_Mega;
	-----------------------------------------------------------------------------------------------
	-- M4K tie BE to VCC
	-----------------------------------------------------------------------------------------------	
	--gen_be_M4K : if(mram=0) generate
		sw <=(others=>'0');
		byte_enable <=(others=>'1');
	--end generate gen_be_Mega;
end generate gen_soe;
	
		  		
  
end writer;











