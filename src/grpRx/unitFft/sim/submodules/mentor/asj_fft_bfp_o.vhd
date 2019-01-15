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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_bfp_o.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all; 
use work.fft_pack.all;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
-- asj_fft_bfp_o performs block dynamic range detection on the FFT Engine outputs
-- It performs the detection on a full block of the per Engine output data 
-- and deduces the amount of scaling permitted on the next pass through the 
-- engine(s)
-- This value is sent to the BFP controller asj_fft_bfp_ctrl which finds the minimum 
-- over each engine and applies this to the next pass data.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
entity asj_fft_bfp_o is
    generic (
            nps    : integer :=1024;
            bfp    : integer :=1;
            nume   : integer :=1;
            arch   : integer :=0;
            mpr    : integer :=16;
            fpr    : integer :=4;
            rbuspr : integer :=64 -- 4*mpr
    );
    port (
global_clock_enable : in std_logic;
         clk      : in std_logic;
         reset    : in std_logic;
         next_pass : in std_logic;
         data_rdy : in std_logic;
         next_blk : in std_logic;
         blk_done : in std_logic;
         gain_in_1pt   : in std_logic_vector(3 downto 0);
         real_bfp_0_in : in std_logic_vector(mpr-1 downto 0); 
         real_bfp_1_in : in std_logic_vector(mpr-1 downto 0); 
         real_bfp_2_in : in std_logic_vector(mpr-1 downto 0); 
         real_bfp_3_in : in std_logic_vector(mpr-1 downto 0); 
         imag_bfp_0_in : in std_logic_vector(mpr-1 downto 0); 
         imag_bfp_1_in : in std_logic_vector(mpr-1 downto 0); 
         imag_bfp_2_in : in std_logic_vector(mpr-1 downto 0); 
         imag_bfp_3_in : in std_logic_vector(mpr-1 downto 0); 
         lut_out : out std_logic_vector(2 downto 0)
         );
end asj_fft_bfp_o;

architecture output_bfp of asj_fft_bfp_o is

  function sgn_ex(inval : std_logic_vector; w : integer; b : integer) return std_logic_vector is
  -- sign extend input std_logic_vector of width w by b bits
  variable temp :   std_logic_vector(w+b-1 downto 0);
  begin
    temp(w+b-1 downto w-1):=(w+b-1 downto w-1 => inval(w-1));
    temp(w-2 downto 0) := inval(w-2 downto 0);
  return temp;
  end sgn_ex;
  
  function int2ustd(value : integer; width : integer) return std_logic_vector is 
  -- convert integer to unsigned std_logicvector
  variable temp :   std_logic_vector(width-1 downto 0);
  begin
  if (width>0) then 
      temp:=conv_std_logic_vector(conv_unsigned(value, width ), width);
  end if ;
  return temp;
  end int2ustd;
  -- last_pass_radix = 0 => radix 4
  -- last_pass_radix = 1 => radix 2
  constant last_pass_radix : integer :=(LOG4_CEIL(nps))-(LOG4_FLOOR(nps));
  constant log2_nps : integer := LOG2_CEIL(nps);
  constant n_passes : integer := LOG4_CEIL(nps);
  constant n_passes_m1 : integer := LOG4_CEIL(nps)-1;
  constant log2_n_passes: integer := LOG2_CEIL(n_passes_m1);
  
  type   det_state is (IDLE,BLOCK_READY,ENABLE,DISABLE,BLOCK_GAP);
  signal sdet :  det_state;
  
  type   det_stated is (IDLE,BLOCK_READY,ENABLE,GBLK,SLBI,DISABLE);
  signal sdetd :  det_stated;
  
  
  signal real_bfp_in : std_logic_vector(rbuspr-1 downto 0);
  signal imag_bfp_in : std_logic_vector(rbuspr-1 downto 0);
  type rail_arr  is array (0 to 3) of std_logic_vector(fpr downto 0);
  signal rail_p_r : rail_arr; -- real positive rail
  signal rail_p_i : rail_arr; -- imag positive rail
  signal rail_n_r : rail_arr; -- real negative rail
  signal rail_n_i : rail_arr; -- imag negative rail
  
  signal top : std_logic_vector(fpr downto 0);
  signal bottom : std_logic_vector(fpr downto 0);
  
  signal slb_i    : std_logic_vector(3 downto 0);
  signal gain_lut_8pts    : std_logic_vector(fpr downto 0);
  signal gain_lut_blk    : std_logic_vector(fpr downto 0);
  signal lut_out_tmp     : std_logic_vector(2 downto 0);
  signal gap_reg   : std_logic;
  signal next_blk_d : std_logic;
  signal next_pass_d : std_logic;
  signal next_pass_d2 : std_logic;
  signal next_pass_d3 : std_logic;
  signal en_gain_lut_8_pts : std_logic;
  signal en_gain_lut_8_pts_d : std_logic;
  signal del_np_cnt : std_logic_vector(4 downto 0);
  signal p_cnt : std_logic_vector(2 downto 0);
  
  -----------------------------------------------------------------------------------------------
  -- Terminal counter values
  signal ben : std_logic_vector(4 downto 0);
  signal den : std_logic_vector(4 downto 0);
  signal nbc : std_logic_vector(2 downto 0);
  
  
begin
-----------------------------------------------------------------------------------------------
-- Fixed Point - Not Supported
----------------------------------------------------------------------------------------------- 
gen_fixed : if(bfp=0) generate  
  lut_out <= (others=>'0'); 
end generate gen_fixed;
  
-----------------------------------------------------------------------------------------------
-- Bloack Floating Point
----------------------------------------------------------------------------------------------- 
gen_blk_float : if(bfp=1) generate  
  
  lut_out <= lut_out_tmp; 
  
  gen_4_input_bfp_o : if(arch<3) generate
      real_bfp_in(4*mpr-1 downto 3*mpr)   <= real_bfp_0_in;
      real_bfp_in(3*mpr-1 downto 2*mpr)   <= real_bfp_1_in;
      real_bfp_in(2*mpr-1 downto mpr)     <= real_bfp_2_in;
      real_bfp_in(mpr-1 downto 0)         <= real_bfp_3_in;
      imag_bfp_in(4*mpr-1 downto 3*mpr)  <= imag_bfp_0_in;
      imag_bfp_in(3*mpr-1 downto 2*mpr)  <= imag_bfp_1_in;
      imag_bfp_in(2*mpr-1 downto mpr)    <= imag_bfp_2_in;
      imag_bfp_in(mpr-1 downto 0)        <= imag_bfp_3_in;
      
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
  end generate gen_4_input_bfp_o;
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  -- Streaming 1024,512
  -----------------------------------------------------------------------------------------------
  gen_streaming : if(arch=0) generate
  
    gen_cont : if(nps=1024 or nps=512) generate
      
      
        
      delay_next_pass : asj_fft_tdl_bit 
        generic map( 
                    del   => 9
                  )
        port map(   
global_clock_enable => global_clock_enable,
                    clk   => clk,
                    data_in   => next_pass,
                    data_out  => next_pass_d
        );

      delay_next_blk : asj_fft_tdl_bit 
        generic map( 
                    del   => 23
                  )
        port map(   
global_clock_enable => global_clock_enable,
                    clk   => clk,
                    data_in   => next_blk,
                    data_out  => next_blk_d
        );
         
gap : process(clk,global_clock_enable,reset,blk_done,next_blk_d,gap_reg)
begin
	if((rising_edge(clk) and global_clock_enable='1'))then
		if(reset='1') then
			gap_reg <= '0';
		elsif(blk_done='1') then
			gap_reg <= '1';
		elsif(next_blk_d='1') then
			gap_reg <= '0';
                else
			gap_reg <= gap_reg;
		end if;
	end if;
end process gap;

delay_next_pass_counter:process(clk,global_clock_enable,sdet,del_np_cnt)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            -- This should be based on output state bits and not the states themselves
            -- Works fine, but the style leaves a little to be desired.
            if(sdet=DISABLE or sdet=BLOCK_READY) then
              del_np_cnt <= del_np_cnt + int2ustd(1,5);
            else
              del_np_cnt <=(others=>'0');
            end if;
          end if;
        end process delay_next_pass_counter;
      -----------------------------------------------------------------------------------------------
      -- Counter Terminal Values
      -----------------------------------------------------------------------------------------------
      ben <= int2ustd(21,5);
      den <= int2ustd(18,5);
      
      --det_state is (IDLE,BLOCK_READY,ENABLE,DISABLE);
fsm:process(clk,global_clock_enable,reset,sdet,next_pass_d,del_np_cnt,ben,next_blk)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
              sdet <= IDLE;
            else
              case sdet is
                when IDLE=>
                    sdet <= BLOCK_READY;
                when BLOCK_READY=>
                  if(del_np_cnt=ben) then
                    sdet <= ENABLE;                   
                  else
                    sdet <= BLOCK_READY;                    
                  end if;
                when ENABLE =>
                  if(next_pass_d='1') then
                    sdet <= DISABLE;  
                  else
                    sdet <= ENABLE;                   
                  end if;
                when DISABLE =>
                  if(gap_reg='1') then
                    sdet <= BLOCK_GAP; 
                  else
                    sdet <= ENABLE;
                  end if;
                when BLOCK_GAP=>
                  if(gap_reg='1') then
                    sdet <= BLOCK_GAP;                   
                  else
                    sdet <= ENABLE;                    
                  end if;
                when others=>
                  sdet <= IDLE;
              end case;
            end if;
          end if;
        end process fsm;
                
enable_gain:process(clk,global_clock_enable,sdet)is
          begin
if((rising_edge(clk) and global_clock_enable='1'))then
              if(sdet=ENABLE or sdet=DISABLE) then
                en_gain_lut_8_pts <= '1';
              elsif (sdet=BLOCK_GAP) then
                if(gap_reg='1') then
                  en_gain_lut_8_pts <= '0';
                else
                  en_gain_lut_8_pts <= '1';
                end if;
              end if;
            end if;
        end process enable_gain;
      
        en_gain_lut_8_pts_d <= en_gain_lut_8_pts;
      
      
bfp:process(clk,global_clock_enable,reset,top,bottom,en_gain_lut_8_pts_d)
          begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if (reset = '1') then
              gain_lut_8pts(fpr downto 0)<= (others=>'0');
            elsif(en_gain_lut_8_pts_d='1') then
              gain_lut_8pts(fpr downto 0) <=(top(4) or (not(bottom(4)))) & (top(3) or (not(bottom(3)))) & (top(2) or (not(bottom(2)))) & (top(1) or (not(bottom(1)))) & (top(0) or (not(bottom(0))));
            else
              gain_lut_8pts(fpr downto 0)<= (others=>'0');
            end if;
          end if;
        end process;
        
        -- Register LUT output to SLL BFP input
reg_slb:process(clk,global_clock_enable,sdet,slb_i,gain_lut_8pts,gain_lut_blk,gain_in_1pt)
          begin
if((rising_edge(clk) and global_clock_enable='1'))then
              case sdet is
                when IDLE =>
                  slb_i <= (others=>'1');
                  gain_lut_blk <= (others=>'0');
                when BLOCK_READY=>
                  slb_i <= (others=>'1');
                  gain_lut_blk <= (others=>'0');
                when DISABLE=>
                  gain_lut_blk <= (others=>'0');
                  slb_i <= gain_lut_blk(3 downto 0) or gain_in_1pt or gain_lut_8pts(3 downto 0);
                when ENABLE=>
                  gain_lut_blk <= gain_lut_blk or gain_lut_8pts;    
                  slb_i <= slb_i;
                when BLOCK_GAP=>
                  gain_lut_blk <= (others=>'0');
                  slb_i <= slb_i;
                when others=>
                  gain_lut_blk <= gain_lut_blk or gain_lut_8pts;    
                  slb_i <= slb_i;
              end case;
            end if;
        end process reg_slb;
        
        
        apply_gain_lut : process(slb_i,reset) is
        begin
--if((rising_edge(clk) and global_clock_enable='1'))then
          if(reset='1') then
              lut_out_tmp <="000";
          else
            case slb_i(3 downto 0) is
              when "1111" =>
                lut_out_tmp <="000";
              when "1110" =>
                lut_out_tmp <="000";
              when "1101" =>
                lut_out_tmp <="000";
              when "1100" =>
                lut_out_tmp <="000";
              when "1011" =>
                lut_out_tmp <="000";
              when "1010" =>
                lut_out_tmp <="000";
              when "1001" =>
                lut_out_tmp <="000";
              when "1000" =>
                lut_out_tmp <="000";
              when "0111" =>
                lut_out_tmp <="001";
              when "0110" =>
                lut_out_tmp <="001";
              when "0101" =>
                lut_out_tmp <="001";
              when "0100" =>
                lut_out_tmp <="001";
              when "0011" =>
                lut_out_tmp <="010";
              when "0010" =>
                lut_out_tmp <="010";
              when "0001" =>
                lut_out_tmp <="011";
              when "0000" =>
                lut_out_tmp <="100";
              when others =>
                lut_out_tmp <="XXX";
            end case;
          end if;
        end process apply_gain_lut;   
      end generate gen_cont;
  -----------------------------------------------------------------------------------------------
  -- Streaming N=128,256,2048,4096,8192,16384
  -----------------------------------------------------------------------------------------------
  gen_disc : if(nps/=512 and nps/=1024) generate
      delay_next_blk : asj_fft_tdl_bit_rst               
      generic map(                               
                  del   => 1                     
              )                                  
      port map(                                  
global_clock_enable => global_clock_enable,
                  clk   => clk,           
                  reset => reset,      
                  data_in   => next_blk,      
                  data_out  => next_blk_d
          );                                     
  
          

      delay_next_pass3 : asj_fft_tdl_bit 
            generic map( 
                        del   => 2
                    )
            port map(   
global_clock_enable => global_clock_enable,
                        clk   => clk,
                        data_in   => next_pass_d,
                        data_out  => next_pass_d3
                );
                      
                                         
delay_next_pass_counter:process(clk,global_clock_enable,sdetd,del_np_cnt)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
              del_np_cnt <=(others=>'0');
            else
              if(sdetd=DISABLE or sdetd=BLOCK_READY) then
                del_np_cnt <= del_np_cnt + int2ustd(1,5);
              else
                del_np_cnt <=(others=>'0');
              end if;
            end if;
          end if;
        end process delay_next_pass_counter;
      -----------------------------------------------------------------------------------------------
      -- Different counter terminal value constants
      -----------------------------------------------------------------------------------------------
      gen_consts_64 : if(nps=64 or nps=32) generate
        nbc <= int2ustd(2,3);
        ben <= int2ustd(21,5);
        den <= int2ustd(11,5);
        delay_next_pass : asj_fft_tdl_bit_rst 
          generic map( 
                        del   => 7
                  )
          port map(   
global_clock_enable => global_clock_enable,
                        clk   => clk,
                        reset => reset,
                        data_in   => next_pass,
                        data_out  => next_pass_d
                );
      end generate gen_consts_64;
      
      gen_consts_256 : if(nps=256 or nps=128) generate
        nbc <= int2ustd(3,3);
        ben <= int2ustd(21,5);
        den <= int2ustd(11,5);
        delay_next_pass : asj_fft_tdl_bit_rst 
          generic map( 
                        del   => 7
                  )
          port map(   
global_clock_enable => global_clock_enable,
                        clk   => clk,
                        reset => reset,
                        data_in   => next_pass,
                        data_out  => next_pass_d
                );
      end generate gen_consts_256;
      gen_consts_2048 : if(nps=2048 or nps=4096) generate
        nbc <= int2ustd(5,3);
        ben <= int2ustd(21,5);
        den <= int2ustd(11,5);
        delay_next_pass : asj_fft_tdl_bit_rst
          generic map( 
                        del   => 7
                  )
          port map(   
global_clock_enable => global_clock_enable,
                        clk   => clk,
                        reset => reset,
                        data_in   => next_pass,
                        data_out  => next_pass_d
                );

      end generate gen_consts_2048;
      gen_consts_8192 : if(nps=8192 or nps=16384) generate
        nbc <= int2ustd(6,3);
        ben <= int2ustd(21,5);
        den <= int2ustd(11,5);
        delay_next_pass : asj_fft_tdl_bit_rst 
          generic map( 
                        del   => 7
                  )
          port map(   
global_clock_enable => global_clock_enable,
                        clk   => clk,
                        reset => reset,
                        data_in   => next_pass,
                        data_out  => next_pass_d
                );

      end generate gen_consts_8192;

      gen_consts_others : if(nps=32768 or nps=65536 or nps=131072) generate
        ben <= int2ustd(21,5);
        den <= int2ustd(11,5);
        delay_next_pass : asj_fft_tdl_bit_rst 
          generic map( 
                        del   => 7
                  )
          port map(   
global_clock_enable => global_clock_enable,
                        clk   => clk,
                        reset => reset,
                        data_in   => next_pass,
                        data_out  => next_pass_d
                );

      end generate gen_consts_others;
        
      
fsm:process(clk,global_clock_enable,reset,sdetd,next_blk_d,next_pass_d,del_np_cnt,ben,den)is
          begin
if((rising_edge(clk) and global_clock_enable='1'))then
              if(reset='1') then
                sdetd <= IDLE;
              else
                case sdetd is
                  when IDLE=>
                      sdetd <= ENABLE;
                  when ENABLE =>
                    if(next_pass_d='1') then
                      sdetd <= GBLK;  
                    elsif(next_blk_d='1') then
                      sdetd <= BLOCK_READY; 
                    else
                      sdetd <= ENABLE;                    
                    end if;
                  when BLOCK_READY=>
                    if(del_np_cnt=ben) then
                      sdetd <= ENABLE;                    
                    else
                      sdetd <= BLOCK_READY;
                    end if;
                  when GBLK =>
                      sdetd <= SLBI;                    
                  when SLBI =>
                      sdetd <= DISABLE;                   
                  when DISABLE =>
                    if(del_np_cnt=den) then
                      sdetd <= ENABLE;                    
                    else
                      sdetd <= DISABLE;                   
                    end if; 
                  when others=>
                    sdetd <= IDLE;
                end case;
              end if;
            end if;
          end process fsm;
      
bfp:process(clk,global_clock_enable,sdetd,top,bottom)
          begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(sdetd=ENABLE or sdetd=GBLK) then-- or sdetd=SLBI) then
              gain_lut_8pts(fpr downto 0) <=(top(4) or (not(bottom(4)))) & (top(3) or (not(bottom(3)))) & (top(2) or (not(bottom(2)))) & (top(1) or (not(bottom(1)))) & (top(0) or (not(bottom(0))));
            else
              gain_lut_8pts(fpr downto 0)<= (others=>'0');
            end if;
          end if;
        end process;
        
p_counter:process(clk,global_clock_enable,reset,next_pass,next_blk,p_cnt)is
          begin
if((rising_edge(clk) and global_clock_enable='1'))then
              if(reset='1' or next_blk='1') then
                p_cnt<=(others=>'0');
              elsif(next_pass='1') then
                p_cnt<= p_cnt+int2ustd(1,3);
              else
                p_cnt<= p_cnt;
              end if;
            end if;
          end process p_counter;
        
reg_glbi:process(clk,global_clock_enable,sdetd,gain_lut_8pts,gain_lut_blk,slb_i)
          begin
if((rising_edge(clk) and global_clock_enable='1'))then
              case sdetd is
                when IDLE =>
                  gain_lut_blk <= (others=>'0');
                when BLOCK_READY=>
                  gain_lut_blk <= (others=>'0');
                when ENABLE=>
                  gain_lut_blk <= gain_lut_blk or gain_lut_8pts;    
                when GBLK=>
                  gain_lut_blk <= gain_lut_blk or gain_lut_8pts;    
                when SLBI=>
                  gain_lut_blk <= (others=>'0');
                when DISABLE=>
                  gain_lut_blk <= (others=>'0');
                when others=>
                  gain_lut_blk <= gain_lut_blk or gain_lut_8pts;    
                end case;
            end if;
        end process reg_glbi;
        

        --reg_slbi: process (sdetd,gain_lut_8pts,gain_lut_blk, slb_i)
        --  begin
----if((rising_edge(clk) and global_clock_enable='1'))then
        --      case sdetd is
        --        when IDLE =>
        --          slb_i <=(others=>'1');
        --        when BLOCK_READY=>
        --          slb_i <=(others=>'1');
        --        --when ENABLE=>
        --        --  slb_i <= slb_i;
        --        --when GBLK=>
        --        --  slb_i <= slb_i;
        --        when SLBI=>
        --          slb_i <= gain_lut_blk(3 downto 0) or gain_lut_8pts(3 downto 0);
        --        --when DISABLE=>
        --        --  slb_i <= slb_i;
        --        when others=>
        --          slb_i <= slb_i;
        --        end case;
        --    --end if;
        --end process reg_slbi;
         
        slb_i <= gain_lut_blk(3 downto 0) or gain_lut_8pts(3 downto 0); 
        
apply_gain_lut:process(clk,global_clock_enable,slb_i,reset)is
          begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
                  lut_out_tmp <="000";
            elsif(sdetd=SLBI) then
              --lut_out_tmp(2) <= not(slb_i(3) or slb_i(2) or slb_i(1) or slb_i(0));
              --lut_out_tmp(1) <= not(slb_i(3) or slb_i(2)) and (slb_i(1) or slb_i(0));
              --lut_out_tmp(0) <= (not(slb_i(3)) or slb_i(2)) or (not(slb_i(3)) and not(slb_i(2)) and not(slb_i(1)) and slb_i(0));
              case slb_i(3 downto 0) is
                when "1111" =>
                  lut_out_tmp <="000";
                when "1110" =>
                  lut_out_tmp <="000";
                when "1101" =>
                  lut_out_tmp <="000";
                when "1100" =>
                  lut_out_tmp <="000";
                when "1011" =>
                  lut_out_tmp <="000";
                when "1010" =>
                  lut_out_tmp <="000";
                when "1001" =>
                  lut_out_tmp <="000";
                when "1000" =>
                  lut_out_tmp <="000";
                when "0111" =>
                  lut_out_tmp <="001";
                when "0110" =>
                  lut_out_tmp <="001";
                when "0101" =>
                  lut_out_tmp <="001";
                when "0100" =>
                  lut_out_tmp <="001";
                when "0011" =>
                  lut_out_tmp <="010";
                when "0010" =>
                  lut_out_tmp <="010";
                when "0001" =>
                  lut_out_tmp <="011";
                when "0000" =>
                  lut_out_tmp <="100";
                when others =>
                  lut_out_tmp <="XXX";
              end case;
            elsif(sdetd=BLOCK_READY) then
              lut_out_tmp <= "000";
            end if;
          end if;
          end process apply_gain_lut;   
    end generate gen_disc;
  end generate gen_streaming;
  -----------------------------------------------------------------------------------------------
  -- BFP Output Detector Control is different only for Streaming 1024,512
  -- Arch=1,2 also indicates non-continuous streaming for N/=1024,512
  -----------------------------------------------------------------------------------------------   
  gen_b : if(arch=1 or arch=2) generate
  
  
      delay_next_pass : asj_fft_tdl_bit_rst 
          generic map( 
                        del   => 7
                  )
          port map(   
global_clock_enable => global_clock_enable,
                        clk   => clk,
                        reset => reset,
                        data_in   => next_pass,
                        data_out  => next_pass_d
                );
      
      delay_next_blk : asj_fft_tdl_bit_rst               
      generic map(                               
                  del   => 1                     
              )                                  
      port map(                                  
global_clock_enable => global_clock_enable,
                  clk   => clk,        
                  reset => reset,          
                  data_in   => next_blk,      
                  data_out  => next_blk_d
          );                                     
  
                                         
delay_next_pass4:process(clk,global_clock_enable,sdetd,del_np_cnt)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(sdetd=DISABLE or sdetd=BLOCK_READY) then
              del_np_cnt <= del_np_cnt + int2ustd(1,5);
            else
              del_np_cnt <=(others=>'0');
            end if;
          end if;
        end process delay_next_pass4;
                  
                
     
      
      -----------------------------------------------------------------------------------------------
      -- Different counter terminal value constants
      -----------------------------------------------------------------------------------------------
      gen_se_de_consts : if(nume=1 or nume=2) generate
        gen_consts_64 : if(nps=64) generate
          nbc <= int2ustd(2,3);
          ben <= int2ustd(22,5);
          den <= int2ustd(11,5);
        end generate gen_consts_64; 
        gen_consts_256 : if(nps=256 or nps=128) generate
          nbc <= int2ustd(3,3);
          ben <= int2ustd(22,5);
          den <= int2ustd(11,5);
        end generate gen_consts_256; 
        gen_consts_1024 : if(nps=1024 or nps=512) generate
          nbc <= int2ustd(4,3);
          ben <= int2ustd(21,5);
          den <= int2ustd(11,5);
        end generate gen_consts_1024; 
        gen_consts_2048 : if(nps=2048 or nps=4096) generate
          nbc <= int2ustd(5,3);
          ben <= int2ustd(21,5);
          den <= int2ustd(11,5);
        end generate gen_consts_2048;
        gen_consts_8192 : if(nps=8192 or nps=16384) generate
          nbc <= int2ustd(6,3);
          ben <= int2ustd(21,5);
          den <= int2ustd(11,5);
        end generate gen_consts_8192;
        gen_consts_others : if(nps=32768 or nps=65536 or nps=131072) generate
          ben <= int2ustd(21,5);
          den <= int2ustd(11,5);
        end generate gen_consts_others;
      end generate gen_se_de_consts;
      
      gen_qe_consts : if(nume=4) generate
        gen_consts_64 : if(nps=64) generate
          nbc <= int2ustd(2,3);
          ben <= int2ustd(21,5);
          den <= int2ustd(12,5);
        end generate gen_consts_64; 
        gen_consts_256 : if(nps=256 or nps=128) generate
          nbc <= int2ustd(3,3);
          ben <= int2ustd(21,5);
          den <= int2ustd(12,5);
        end generate gen_consts_256; 
        gen_consts_1024 : if(nps=1024 or nps=512) generate
          nbc <= int2ustd(4,3);
          ben <= int2ustd(21,5);
          den <= int2ustd(12,5);
        end generate gen_consts_1024; 
        gen_consts_2048 : if(nps=2048 or nps=4096) generate
          nbc <= int2ustd(5,3);
          ben <= int2ustd(21,5);
          den <= int2ustd(12,5);
        end generate gen_consts_2048;
        gen_consts_8192 : if(nps=8192 or nps=16384) generate
          nbc <= int2ustd(6,3);
          ben <= int2ustd(21,5);
          den <= int2ustd(12,5);
        end generate gen_consts_8192;
        gen_consts_others : if(nps=32768 or nps=65536 or nps=131072) generate
          ben <= int2ustd(21,5);
          den <= int2ustd(12,5);
        end generate gen_consts_others;
      end generate gen_qe_consts;
        
      
fsm:process(clk,global_clock_enable,reset,sdetd,next_blk_d,next_pass_d,del_np_cnt,ben,den)is
          begin
if((rising_edge(clk) and global_clock_enable='1'))then
              if(reset='1') then
                sdetd <= IDLE;
              else  
                case sdetd is
                  when IDLE=>
                      sdetd <= ENABLE;
                  when ENABLE =>
                    if(next_pass_d='1') then
                      sdetd <= GBLK;  
                    elsif(next_blk_d='1') then
                      sdetd <= BLOCK_READY; 
                    else
                      sdetd <= ENABLE;                    
                    end if;
                  when BLOCK_READY=>
                    if(del_np_cnt=ben) then
                      sdetd <= ENABLE;                    
                    else
                      sdetd <= BLOCK_READY;
                    end if;
                  when GBLK =>
                      sdetd <= SLBI;                    
                  when SLBI =>
                      sdetd <= DISABLE;                   
                  when DISABLE =>
                    if(del_np_cnt=den) then
                      sdetd <= ENABLE;                    
                    else
                      sdetd <= DISABLE;                   
                    end if; 
                  when others=>
                    sdetd <= IDLE;
                end case;
              end if;
            end if;
          end process fsm;
      
bfp:process(clk,global_clock_enable,sdetd,top,bottom)is
          begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(sdetd=ENABLE or sdetd=GBLK) then
              gain_lut_8pts(fpr downto 0) <=(top(4) or (not(bottom(4)))) & (top(3) or (not(bottom(3)))) & (top(2) or (not(bottom(2)))) & (top(1) or (not(bottom(1)))) & (top(0) or (not(bottom(0))));
            else
              gain_lut_8pts(fpr downto 0)<= (others=>'0');
            end if;
          end if;
        end process bfp;
        
p_counter:process(clk,global_clock_enable,reset,next_pass,next_blk,p_cnt)is
          begin
if((rising_edge(clk) and global_clock_enable='1'))then
              if(reset='1' or next_blk='1') then
                p_cnt<=(others=>'0');
              elsif(next_pass='1') then
                p_cnt<= p_cnt+int2ustd(1,3);
              else
                p_cnt<= p_cnt;
              end if;
            end if;
          end process p_counter;
        -----------------------------------------------------------------------------------------------
        -- 9/15/03 djm : Reverting to original lut based aproach for registered scaling
        -----------------------------------------------------------------------------------------------
reg_glbi:process(clk,global_clock_enable,sdetd,gain_lut_8pts,gain_lut_blk,slb_i)
          begin
if((rising_edge(clk) and global_clock_enable='1'))then
              case sdetd is
                when IDLE =>
                  gain_lut_blk <= (others=>'0');
                  slb_i <=(others=>'1');
                when BLOCK_READY=>
                  gain_lut_blk <= (others=>'0');
                  slb_i <=(others=>'1');
                when ENABLE=>
                    gain_lut_blk <= gain_lut_blk or gain_lut_8pts;    
                    slb_i <= slb_i;
                when GBLK=>
                    gain_lut_blk <= gain_lut_blk or gain_lut_8pts;    
                    slb_i <= slb_i;
                when SLBI=>
                    gain_lut_blk <= (others=>'0');
                    slb_i <= gain_lut_blk(3 downto 0) or gain_lut_8pts(3 downto 0);
                when DISABLE=>
                    gain_lut_blk <= (others=>'0');
                    slb_i <= slb_i;
                when others=>
                    gain_lut_blk <= gain_lut_blk or gain_lut_8pts;    
                    slb_i <= slb_i;
                end case;
            end if;
        end process reg_glbi;
        
        apply_gain_lut : process(slb_i,reset) is
          begin
            if(reset='1') then
              lut_out_tmp <="000";
            else
              case slb_i(3 downto 0) is
                when "1111" =>
                  lut_out_tmp <="000";
                when "1110" =>
                  lut_out_tmp <="000";
                when "1101" =>
                  lut_out_tmp <="000";
                when "1100" =>
                  lut_out_tmp <="000";
                when "1011" =>
                  lut_out_tmp <="000";
                when "1010" =>
                  lut_out_tmp <="000";
                when "1001" =>
                  lut_out_tmp <="000";
                when "1000" =>
                  lut_out_tmp <="000";
                when "0111" =>
                  lut_out_tmp <="001";
                when "0110" =>
                  lut_out_tmp <="001";
                when "0101" =>
                  lut_out_tmp <="001";
                when "0100" =>
                  lut_out_tmp <="001";
                when "0011" =>
                  lut_out_tmp <="010";
                when "0010" =>
                  lut_out_tmp <="010";
                when "0001" =>
                  lut_out_tmp <="011";
                when "0000" =>
                  lut_out_tmp <="100";
                when others =>
                  lut_out_tmp <="XXX";
              end case;
            end if;
          end process apply_gain_lut;   

        
      
  end generate gen_b;   
  
  
  
  
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------    
  -----------------------------------------------------------------------------------------------
  -- Single output Engine (arch>=3)
  -----------------------------------------------------------------------------------------------  
  -----------------------------------------------------------------------------------------------
  gen_1_input_bfp_o : if(arch>=3) generate
      
    real_bfp_in(4*mpr-1 downto 3*mpr)   <= (others=>'0');
    real_bfp_in(3*mpr-1 downto 2*mpr)   <= (others=>'0');
    real_bfp_in(2*mpr-1 downto mpr)     <= (others=>'0');
    real_bfp_in(mpr-1 downto 0)         <= real_bfp_0_in;
    imag_bfp_in(4*mpr-1 downto 3*mpr)  <= (others=>'0');
    imag_bfp_in(3*mpr-1 downto 2*mpr)  <= (others=>'0');
    imag_bfp_in(2*mpr-1 downto mpr)    <= (others=>'0');
    imag_bfp_in(mpr-1 downto 0)        <= imag_bfp_0_in;
    
    bit_by_bit : for k in fpr downto 0 generate
      rail_p_r(0)(k) <=not(real_bfp_in(mpr-1)) and real_bfp_in(mpr-(fpr+1-k));
      rail_p_i(0)(k) <=not(imag_bfp_in(mpr-1)) and imag_bfp_in(mpr-(fpr+1-k));
      rail_n_r(0)(k) <=not(real_bfp_in(mpr-1)) or real_bfp_in(mpr-(fpr+1-k));
      rail_n_i(0)(k) <=not(imag_bfp_in(mpr-1)) or imag_bfp_in(mpr-(fpr+1-k));
    end generate bit_by_bit;
    bit_by_bit_2 : for k in fpr downto 0 generate
      top(k)    <= rail_p_r(0)(k) or rail_p_i(0)(k);
      bottom(k) <= rail_n_r(0)(k) and rail_n_i(0)(k);
    end generate bit_by_bit_2;
    
      delay_next_pass : asj_fft_tdl_bit 
            generic map( 
                        del   => 9+last_pass_radix
                      )
            port map(   
global_clock_enable => global_clock_enable,
                        clk   => clk,
                        data_in   => next_pass,
                        data_out  => next_pass_d
                );
                
      
          
      delay_next_pass3 : asj_fft_tdl_bit 
            generic map( 
                        del   => 3
                    )
            port map(   
global_clock_enable => global_clock_enable,
                        clk   => clk,
                        data_in   => next_pass_d,
                        data_out  => next_pass_d3
                );
                
delay_next_pass_counter:process(clk,global_clock_enable,sdet,del_np_cnt)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(sdet=DISABLE or sdet=BLOCK_READY) then
              del_np_cnt <= del_np_cnt + int2ustd(1,5);
            else
              del_np_cnt <=(others=>'0');
            end if;
          end if;
        end process delay_next_pass_counter;
                  
                
      
      -----------------------------------------------------------------------------------------------
      -- Set counter terminal value constants
      -----------------------------------------------------------------------------------------------
      
      gen_r4_consts : if(last_pass_radix=0) generate  
        ben <= int2ustd(24,5);
        den <= int2ustd(19,5);
      end generate gen_r4_consts;
      
      gen_r2_consts : if(last_pass_radix=1) generate  
        ben <= int2ustd(25,5);
        den <= int2ustd(19,5);
      end generate gen_r2_consts;
      
      
      --det_state is (IDLE,BLOCK_READY,ENABLE,DISABLE);
fsm:process(clk,global_clock_enable,reset,sdet,next_blk,next_pass_d,del_np_cnt,ben,den)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
              sdet <= IDLE;
            else
              case sdet is
                when IDLE=>
                    sdet <= BLOCK_READY;
                when BLOCK_READY=>
                  if(del_np_cnt=ben) then
                    sdet <= ENABLE;                   
                  else
                    sdet <= BLOCK_READY;                    
                  end if;
                when ENABLE =>
                  if(next_pass_d='1') then
                    sdet <= DISABLE;  
                  elsif(next_blk='1') then
                    sdet <= IDLE; 
                  else
                    sdet <= ENABLE;                   
                  end if;
                when DISABLE =>
                  if(del_np_cnt=den) then
                    sdet <= ENABLE;                   
                  else
                    sdet <= DISABLE;                    
                  end if;
                when others=>
                  sdet <= IDLE;
              end case;
            end if;
          end if;
        end process fsm;
      
                
enable_gain:process(clk,global_clock_enable,sdet)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(sdet=ENABLE) then
              en_gain_lut_8_pts <= '1';
            else
              en_gain_lut_8_pts <= '0';
            end if;
          end if;
      end process enable_gain;
      
      en_gain_lut_8_pts_d <= en_gain_lut_8_pts;
      
      gen_4bit_bfp : if(fpr=4) generate
bfp:process(clk,global_clock_enable,reset,top,bottom,en_gain_lut_8_pts_d)
          begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if (reset = '1') then
              gain_lut_8pts(fpr downto 0)<= (others=>'0');
            elsif(en_gain_lut_8_pts_d='1') then
              gain_lut_8pts(fpr downto 0) <=(top(4) or (not(bottom(4)))) & (top(3) or (not(bottom(3)))) & (top(2) or (not(bottom(2)))) & (top(1) or (not(bottom(1)))) & (top(0) or (not(bottom(0))));
            else
              gain_lut_8pts(fpr downto 0)<= (others=>'0');
            end if;
          end if;
        end process;
        
        -- Register LUT output to SLL BFP input
reg_slb:process(clk,global_clock_enable,sdet,next_pass_d3,next_blk,gain_lut_8pts,gain_lut_blk,slb_i)
          begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if (sdet=IDLE or sdet=BLOCK_READY) then
               slb_i <= (others=>'1');
               gain_lut_blk <= (others=>'0');
            else
              if (next_pass_d3='1' or next_blk = '1') then
                  gain_lut_blk <= (others=>'0');
                  slb_i <= gain_lut_blk(3 downto 0);
              else
                  gain_lut_blk <= gain_lut_blk or gain_lut_8pts;    
                  slb_i <= slb_i;
              end if;
            end if;
          end if;
        end process reg_slb;
      end generate gen_4bit_bfp;
            
      apply_gain_lut : process(slb_i,reset) is
        begin
--if((rising_edge(clk) and global_clock_enable='1'))then
          if(reset='1') then
              lut_out_tmp <="000";
          else
            case slb_i(3 downto 0) is
              when "1111" =>
                lut_out_tmp <="000";
              when "1110" =>
                lut_out_tmp <="000";
              when "1101" =>
                lut_out_tmp <="000";
              when "1100" =>
                lut_out_tmp <="000";
              when "1011" =>
                lut_out_tmp <="000";
              when "1010" =>
                lut_out_tmp <="000";
              when "1001" =>
                lut_out_tmp <="000";
              when "1000" =>
                lut_out_tmp <="000";
              when "0111" =>
                lut_out_tmp <="001";
              when "0110" =>
                lut_out_tmp <="001";
              when "0101" =>
                lut_out_tmp <="001";
              when "0100" =>
                lut_out_tmp <="001";
              when "0011" =>
                lut_out_tmp <="010";
              when "0010" =>
                lut_out_tmp <="010";
              when "0001" =>
                lut_out_tmp <="011";
              when "0000" =>
                lut_out_tmp <="100";
              when others =>
                lut_out_tmp <="XXX";
            end case;
          end if;
        end process apply_gain_lut;   

      
  
end generate gen_1_input_bfp_o; 

end generate gen_blk_float;

end;    

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- 5 Bit BFP
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------    
--gen_5bit_bfp : if(fpr=5) generate
--
--bfp:process(clk,global_clock_enable,reset,top,bottom,en_gain_lut_8_pts_d)
--  begin
--if((rising_edge(clk) and global_clock_enable='1'))then
--    if (reset = '1') then
--      gain_lut_8pts(fpr downto 0)<= (others=>'0');
--    elsif(en_gain_lut_8_pts_d = '1') then
--      gain_lut_8pts(fpr downto 0) <= (top(5) or (not(bottom(5)))) & (top(4) or (not(bottom(4)))) & (top(3) or (not(bottom(3)))) & (top(2) or (not(bottom(2)))) & (top(1) or (not(bottom(1)))) & (top(0) or (not(bottom(0))));
--    else
--      gain_lut_8pts(fpr downto 0)<= (others=>'0');
--    end if;
--  end if;
--end process bfp;
--
--
--
--
---- Register LUT output to SLL BFP input
--reg_slb: process (reset,next_pass,gain_lut_blk,gain_lut_8pts)
--  begin
----if((rising_edge(clk) and global_clock_enable='1'))then
--    if (reset = '1') then
--       slb_i <= (others=>'1');
--       gain_lut_blk <= (others=>'0');
--    else
--      if (next_pass = '1') then
--          gain_lut_blk <= (others=>'0');
--          slb_i <= gain_lut_blk(3 downto 0);
--      else
--          gain_lut_blk <= gain_lut_blk or gain_lut_8pts;    
--      end if;
--    end if;
----  end if;
--end process reg_slb;
----
--apply_gain_lut:process(clk,global_clock_enable,slb_i)is
--  begin
----if((rising_edge(clk) and global_clock_enable='1'))then
--      case slb_i(4 downto 0) is
--        when "11111" =>
--          lut_out_tmp <="000";
--        when "01111" =>
--          lut_out_tmp <="001";
--        when "00111" =>
--          lut_out_tmp <="010";
--        when "00011" =>
--          lut_out_tmp <="011";
--        when "00001" =>
--          lut_out_tmp <="100";
--        when "00000" =>
--          lut_out_tmp <="101";
--        when others =>
--          lut_out_tmp <="XXX";
--      end case;
--    --end if;
--  end process apply_gain_lut;   
--
--  
--end generate gen_5bit_bfp;

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- 4 Bit BFP
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------





--apply_gain_lut : process(slb_i) is
--  begin
----if((rising_edge(clk) and global_clock_enable='1'))then
--      case slb_i(3 downto 0) is
--        when "1111" =>
--          lut_out_tmp <="000";
--        when "1110" =>
--          lut_out_tmp <="000";
--        when "1101" =>
--          lut_out_tmp <="000";
--        when "1100" =>
--          lut_out_tmp <="000";
--        when "1011" =>
--          lut_out_tmp <="000";
--        when "1010" =>
--          lut_out_tmp <="000";
--        when "1001" =>
--          lut_out_tmp <="000";
--        when "1000" =>
--          lut_out_tmp <="000";
--        when "0111" =>
--          lut_out_tmp <="001";
--        when "0110" =>
--          lut_out_tmp <="001";
--        when "0101" =>
--          lut_out_tmp <="001";
--        when "0100" =>
--          lut_out_tmp <="001";
--        when "0011" =>
--          lut_out_tmp <="010";
--        when "0010" =>
--          lut_out_tmp <="010";
--        when "0001" =>
--          lut_out_tmp <="011";
--        when "0000" =>
--          lut_out_tmp <="100";
--        when others =>
--          lut_out_tmp <="XXX";
--      end case;
--    --end if;
--  end process apply_gain_lut;   
