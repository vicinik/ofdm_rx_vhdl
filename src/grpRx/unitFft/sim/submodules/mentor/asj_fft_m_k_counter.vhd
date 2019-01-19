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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_m_k_counter.vhd#1 $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all; 
use work.fft_pack.all;

entity asj_fft_m_k_counter is
  generic(
            nps : integer :=1024;
            arch : integer :=0;
            nume : integer :=1;
            n_passes : integer :=3; --log4(nps) - 1
            log2_n_passes : integer := 3; 
            apr : integer :=6; --apr = log2(nps/4);
            cont : integer :=1
          );
  port(     
global_clock_enable : in std_logic;
            clk             : in std_logic;
            reset           : in std_logic;
            stp             : in std_logic; --"start" signal (may not be needed)
            start           : in std_logic; --"start" signal (may not be needed)
            next_block      : in std_logic;
            p_count         : out std_logic_vector(log2_n_passes-1 downto 0);
            k_count         : out std_logic_vector(apr-1 downto 0);
            next_pass       : out std_logic;
            blk_done        : out std_logic
      );
end asj_fft_m_k_counter;

architecture gen_all of asj_fft_m_k_counter is

constant ltc : integer :=2**apr -2;
constant ltc3 : integer :=2**apr -1;

-- last_pass_radix = 0 => radix 4
-- last_pass_radix = 1 => radix 2
constant last_pass_radix : integer :=(LOG4_CEIL(nps))-(LOG4_FLOOR(nps));

type   k_state_type is (IDLE,RUN_CNT,NEXT_PASS_UPD,HOLD);
signal k_state :  k_state_type;
signal k : std_logic_vector(apr+1 downto 0);   
signal p : std_logic_vector(log2_n_passes-1 downto 0);   
signal next_pass_i : std_logic;
-- pass interval counter for single-output engine architectures
signal del_npi_cnt : std_logic_vector(4 downto 0);
signal blk_done_int : std_logic;  
signal next_pass_id : std_logic;  
signal next_pass_en : std_logic;
signal next_pass_ds : std_logic;
signal next_block_en : std_logic;
signal next_block_d : std_logic;
signal next_block_d2 : std_logic;
signal next_block_d3 : std_logic;
signal next_block_d4 : std_logic;
signal next_block_d5 : std_logic;
signal k_count_en : std_logic;
signal del_cnt : std_logic_vector(4 downto 0);


begin
  
next_pass <= next_pass_i; 

-- Quad Engine Variations
gen_quad_m_k : if(arch<3) generate
  gen_streaming : if(arch=0) generate
    gen_cont_counters : if(cont=1) generate
      p_count <= p;
      next_pass_en <= next_pass_i and start;
      
reg_k:process(clk,global_clock_enable,k,next_block,next_block_d,next_block_d2,next_block_d3)is
      begin
if((rising_edge(clk) and global_clock_enable='1'))then
          next_block_d <=next_block;
          next_block_d2 <=next_block_d;
          next_block_d3 <=next_block_d2;
          next_block_d4 <=next_block_d3;
          next_block_d5 <=next_block_d4;
          k_count <= k(apr-1 downto 0);
        end if;
      end process reg_k;
      
    
cnt_k:process(clk,global_clock_enable,reset,k,k_count_en)is
      begin
if((rising_edge(clk) and global_clock_enable='1'))then
          if(reset='1' or next_block_d4='1') then
            k<=(others=>'0');
          elsif(k_count_en='1') then
            k<=k + int2ustd(1,apr);
          else
            k<=k; 
          end if;
        end if;
      end process cnt_k;
      
      
     
cnt_p:process(clk,global_clock_enable,reset,p,next_pass_en)is --next_block
      begin
if((rising_edge(clk) and global_clock_enable='1'))then
          if(reset='1') then
            p<=(others=>'0');
          else
            if(next_block_d5='1') then
              p<=int2ustd(1,log2_n_passes);
            elsif(next_pass_en='1') then
              if(p=int2ustd(n_passes,log2_n_passes)) then
                p<=int2ustd(1,log2_n_passes);
              else
                p<=p+int2ustd(1,log2_n_passes);
              end if;
            else
              p<=p;
            end if;
          end if;
        end if;
      end process cnt_p;  
      
      kce : process(k_state) is
        begin
          case k_state is
            when IDLE =>
              k_count_en <='0';
            when RUN_CNT =>
              k_count_en <='1';
            when NEXT_PASS_UPD =>
              k_count_en <='1';
            when HOLD =>
              k_count_en <='1';
            when others=>
              k_count_en <='0';
          end case;
        end process kce;  
        
fsm:process(clk,global_clock_enable,reset,k_state,next_pass_id)is --stp
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
              k_state <= IDLE;
            else
              case k_state is
                when IDLE =>
                  if(next_block_d4='1' or next_block_d5='1') then
                    k_state <= RUN_CNT;
                  else
                    k_state <=IDLE;
                  end if;
                when RUN_CNT =>
                  if(k(apr-1 downto 0)=int2ustd(ltc3-1,apr)) then
                    k_state <= NEXT_PASS_UPD;
                  else
                    k_state <=RUN_CNT;
                  end if;
                when NEXT_PASS_UPD =>
                  k_state <= HOLD;
                when HOLD =>
                  if(p=int2ustd(n_passes,log2_n_passes)) then
                    if(next_block_d4='1' or next_block_d5='1') then
                      k_state <= RUN_CNT;
                    else
                      k_state <=IDLE;
                    end if;
                  elsif(next_pass_i='1') then
                    k_state <= RUN_CNT;
                  else
                    k_state <=IDLE;
                  end if;
                when others=>
                  k_state <= IDLE;
              end case;
            end if;
          end if;
        end process fsm;
        
                  
      blk_done <= blk_done_int;
          
np:process(clk,global_clock_enable,reset,k,p)is --stp
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then -- or next_block='1') then
              next_pass_i <= '0';
              blk_done_int  <= '0';
            else
              case k_state is
                when IDLE=>
                  next_pass_i <= '0';
                  blk_done_int  <= '0';
                when NEXT_PASS_UPD=>    
                  next_pass_i <= '1';
                  if(p=int2ustd(n_passes,log2_n_passes)) then
                    blk_done_int<='1';
                  else
                    blk_done_int <= '0';
                  end if;
                when others=>
                  next_pass_i <= '0';
                  blk_done_int  <= '0';
              end case;
            end if;
          end if;
      end process np;           
    
    end generate gen_cont_counters;
    
    
    -----------------------------------------------------------------------------------------------
    -- Non-continuous streaming
    -----------------------------------------------------------------------------------------------
    gen_disc_counters : if(cont=0) generate
      p_count <= p;
      next_pass_en <= next_pass_i and start;
      
reg_k:process(clk,global_clock_enable,k,next_block,next_block_d,next_block_d2,next_block_d3)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            next_block_d <=next_block;
            next_block_d2 <=next_block_d;
            next_block_d3 <=next_block_d2;
            next_block_d4 <=next_block_d3;
            k_count <= k(apr-1 downto 0);
          end if;
        end process reg_k;
    
cnt_k:process(clk,global_clock_enable,reset,k,k_count_en)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1' or next_block = '1') then
              k<=(others=>'0');
            elsif(k_count_en='1') then
              k<=k + int2ustd(1,apr);
            else
              k<=k; 
            end if;
          end if;
        end process cnt_k;
      
cnt_p:process(clk,global_clock_enable,reset,p,next_pass_en)is --next_block
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
              p<=(others=>'0');
            else
              if(next_block_d4='1') then
                p<=int2ustd(1,log2_n_passes);
              elsif(next_pass_en='1') then
                if(p=int2ustd(n_passes,log2_n_passes)) then
                  p<=(others=>'0');
                else
                  p<=p+int2ustd(1,log2_n_passes);
                end if;
              else
                p<=p;
              end if;
            end if;
          end if;
        end process cnt_p;  
      
delay_next_pass:process(clk,global_clock_enable,k_state,del_npi_cnt)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(k_state=HOLD) then
              del_npi_cnt <= del_npi_cnt + int2ustd(1,5);
              if(del_npi_cnt=int2ustd(11,5) and p/=(log2_n_passes-1 downto 0 => '0')) then
                next_pass_id<='1';
              else
                next_pass_id<='0';
              end if;
            else
              del_npi_cnt <=(others=>'0');
              next_pass_id<='0';
            end if;
          end if;
        end process delay_next_pass;

      kce : process(k_state) is
        begin
            case k_state is
                when IDLE =>
                  k_count_en <='0';
                when RUN_CNT =>
                  k_count_en <='1';
                when NEXT_PASS_UPD =>
                  k_count_en <='1';
                when HOLD =>
                  k_count_en <='0';
                when others=>
                  k_count_en <='0';
            end case;
        end process kce;  
        
fsm:process(clk,global_clock_enable,reset,k_state,next_pass_id)is --stp
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
              k_state <= IDLE;
            else
              case k_state is
                when IDLE =>
                  if(next_block_d4='1') then
                    k_state <= RUN_CNT;
                  else
                    k_state <=IDLE;
                  end if;
                when RUN_CNT =>
                  if(k(apr-1 downto 0)=int2ustd(ltc3-1,apr)) then
                    k_state <= NEXT_PASS_UPD;
                  else
                    k_state <=RUN_CNT;
                  end if;
                when NEXT_PASS_UPD =>
                  k_state <= HOLD;
                when HOLD =>
                  if(next_pass_id='1' or next_block_d4='1') then
                    k_state <= RUN_CNT;
                  else
                    k_state <=HOLD;
                  end if;
                when others=>
                  k_state <= IDLE;
              end case;
            end if;
          end if;
        end process fsm;

      blk_done <= blk_done_int;
          
np:process(clk,global_clock_enable,reset,k,p)is --stp
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then -- or next_block='1') then
              next_pass_i <= '0';
              blk_done_int  <= '0';
            else
              case k_state is
                when IDLE=>
                  next_pass_i <= '0';
                  blk_done_int  <= '0';
                when NEXT_PASS_UPD=>    
                  next_pass_i <= '1';
                  if(p=int2ustd(n_passes,log2_n_passes)) then
                    blk_done_int<='1';
                  else
                    blk_done_int <= '0';
                  end if;
                when others=>
                  next_pass_i <= '0';
                  blk_done_int  <= '0';
              end case;
            end if;
          end if;
      end process np;     
    end generate gen_disc_counters;
  end generate gen_streaming;   
  
  -----------------------------------------------------------------------------------------------
  -- Buffered Burst and Burst Architecture Counters
  -----------------------------------------------------------------------------------------------
  
  gen_b : if(arch=1 or arch=2) generate
  
      
      --gen_del_cnt_gt128 : if(nps>128) generate
      gen_dc_se : if(nume=1) generate
        del_cnt <= int2ustd(11,5);
      end generate gen_dc_se;
      
      gen_dc_de : if(nume=2) generate
      
      gen_gt128 : if(nps>128) generate
        del_cnt <= int2ustd(11,5);
      end generate gen_gt128;
      
      gen_128 : if(nps<=128) generate
        del_cnt <= int2ustd(12,5);
      end generate gen_128;
        
      end generate gen_dc_de;
      
      gen_dc_qe : if(nume=4) generate
        del_cnt <= int2ustd(12,5);
      end generate gen_dc_qe;
      
      --end generate gen_del_cnt_gt128;
      
      p_count <= p;
      next_pass_en <= next_pass_i and start;
      next_block_en <= next_block or next_block_d or next_block_d2 or next_block_d3 or next_block_d4;
reg_k:process(clk,global_clock_enable,k,next_block,next_block_d,next_block_d2,next_block_d3)is
      begin
if((rising_edge(clk) and global_clock_enable='1'))then
          next_block_d <=next_block;
          next_block_d2 <=next_block_d;
          next_block_d3 <=next_block_d2;
          next_block_d4 <=next_block_d3;
          k_count <= k(apr-1 downto 0);
        end if;
      end process reg_k;
      
    
cnt_k:process(clk,global_clock_enable,reset,k,next_block_en,k_count_en)is
      begin
if((rising_edge(clk) and global_clock_enable='1'))then
          if(reset='1' or next_block_en = '1') then
            k<=(others=>'0');
          elsif(k_count_en='1') then
            k<=k + int2ustd(1,apr);
          else
            k<=k; 
          end if;
        end if;
      end process cnt_k;
     
cnt_p:process(clk,global_clock_enable,reset,p,next_block,next_pass_en)is
      begin
if((rising_edge(clk) and global_clock_enable='1'))then
          if(reset='1') then
            p<=(others=>'0');
          else
            if(next_block='1') then
              p<=int2ustd(1,log2_n_passes);
            elsif(next_pass_en='1') then
              if(p=int2ustd(n_passes,log2_n_passes)) then
                p<=(others=>'0');
              else
                p<=p+int2ustd(1,log2_n_passes);
              end if;
            else
              p<=p;
            end if;
          end if;
        end if;
      end process cnt_p;  
      
          
delay_next_pass:process(clk,global_clock_enable,k_state,del_npi_cnt)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(k_state=HOLD) then
              del_npi_cnt <= del_npi_cnt + int2ustd(1,5);
              if(del_npi_cnt=del_cnt and p/=(log2_n_passes-1 downto 0 => '0')) then
                next_pass_id<='1';
              else
                next_pass_id<='0';
              end if;
            else
              del_npi_cnt <=(others=>'0');
              next_pass_id<='0';
            end if;
          end if;
        end process delay_next_pass;
        
              

      kce : process(k_state) is
        begin
            case k_state is
                when IDLE =>
                  k_count_en <='0';
                when RUN_CNT =>
                  k_count_en <='1';
                when NEXT_PASS_UPD =>
                  k_count_en <='1';
                when HOLD =>
                  k_count_en <='0';
                when others=>
                  k_count_en <='0';
            end case;
        end process kce;  
        
fsm:process(clk,global_clock_enable,reset,k_state,start,next_pass_id)is --stp
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then-- or stp='1') then
              k_state <= IDLE;
            else
              case k_state is
                when IDLE =>
                  if(start='1') then
                    k_state <= RUN_CNT;
                  else
                    k_state <=IDLE;
                  end if;
                when RUN_CNT =>
                  if(k(apr-1 downto 0)=int2ustd(ltc3-1,apr)) then
                    k_state <= NEXT_PASS_UPD;
                  else
                    k_state <=RUN_CNT;
                  end if;
                when NEXT_PASS_UPD =>
                  k_state <= HOLD;
                when HOLD =>
                  if(next_pass_id='1') then
                    k_state <= RUN_CNT;
                  elsif(start='0') then
                    k_state <= IDLE;
                  else
                    k_state <=HOLD;
                  end if;
                when others=>
                  k_state <= IDLE;
              end case;
            end if;
          end if;
        end process fsm;
        
                  
      blk_done <= blk_done_int;
          
np:process(clk,global_clock_enable,reset,k,p)is --stp
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            --if(reset='1' or stp='1') then
            if(reset='1') then
              next_pass_i <= '0';
              blk_done_int  <= '0';
            else
              case k_state is
                when IDLE=>
                  next_pass_i <= '0';
                  blk_done_int  <= '0';
                when NEXT_PASS_UPD=>    
                  next_pass_i <= '1';
                  if(p=int2ustd(n_passes,log2_n_passes)) then
                    blk_done_int<='1';
                  else
                    blk_done_int <= '0';
                  end if;
                when others=>
                  next_pass_i <= '0';
                  blk_done_int  <= '0';
              end case;
            end if;
          end if;
      end process np;     
  end generate gen_b;   
      

end generate gen_quad_m_k;

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------
-- Single-Output Engine Variations
-----------------------------------------------------------------------------------------------
gen_so_m_k : if(arch=3) generate

      p_count <= p;
      next_pass_en <= next_pass_i and start;
      next_pass_ds <= next_pass_i and not start;
      next_block_en <= next_block;-- or next_block_d or next_block_d2 or next_block_d3 or next_block_d4;
      gen_de : if(nume<=2) generate
      
reg_k:process(clk,global_clock_enable,k,next_block,next_block_d,next_block_d2,next_block_d3)is
          begin
if((rising_edge(clk) and global_clock_enable='1'))then
              k_count <= k(apr-1 downto 0);
          end if;
        end process reg_k;
        
      end generate gen_de;
      
    
cnt_k:process(clk,global_clock_enable,reset,k,next_block_en,k_count_en)is
      begin
if((rising_edge(clk) and global_clock_enable='1'))then
          if(reset='1' or next_block_en = '1') then
            k<=(others=>'0');
          elsif(k_count_en='1') then
            k<=k + int2ustd(1,apr);
          else
            k<=k; 
          end if;
        end if;
      end process cnt_k;
     
cnt_p:process(clk,global_clock_enable,reset,p,next_block,next_pass_en)is
      begin
if((rising_edge(clk) and global_clock_enable='1'))then
          if(reset='1') then
            p<=(others=>'0');
          else
            if(next_block='1') then
              p<=int2ustd(1,log2_n_passes);
            elsif(next_pass_en='1') then
              if(p=int2ustd(n_passes,log2_n_passes)) then
                p<=(others=>'0');
              else
                p<=p+int2ustd(1,log2_n_passes);
              end if;
            else
              p<=p;
            end if;
          end if;
        end if;
      end process cnt_p;  
      
      
          
delay_next_pass:process(clk,global_clock_enable,k_state,del_npi_cnt)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(k_state=HOLD) then
              del_npi_cnt <= del_npi_cnt + int2ustd(1,5);
              if(del_npi_cnt=int2ustd(17,5)) then
                next_pass_id<='1';
              else
                next_pass_id<='0';
              end if;
            else
              del_npi_cnt <=(others=>'0');
              next_pass_id<='0';
            end if;
          end if;
        end process delay_next_pass;
        
              

      kce : process(k_state) is
        begin
            case k_state is
                when IDLE =>
                  k_count_en <='0';
                when RUN_CNT =>
                  k_count_en <='1';
                when HOLD =>
                  k_count_en <='0';
                when others=>
                  k_count_en <='0';
            end case;
        end process kce;  
        
fsm:process(clk,global_clock_enable,reset,k_state,stp,start,next_pass_id)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1' or stp='1') then
              k_state <= IDLE;
            else
              case k_state is
                when IDLE =>
                  if(start='1') then
                    k_state <= RUN_CNT;
                  else
                    k_state <=IDLE;
                  end if;
                when RUN_CNT =>
                  if(k(apr-1 downto 0)=int2ustd(ltc3,apr)) then
                    k_state <= NEXT_PASS_UPD;
                  else
                    k_state <=RUN_CNT;
                  end if;
                when NEXT_PASS_UPD =>
                  k_state <= HOLD;
                when HOLD =>
                  if(next_pass_id='1') then
                    k_state <= RUN_CNT;
                  elsif(next_pass_ds='1') then
                    k_state <=IDLE;
                  else
                    k_state <=HOLD;
                  end if;
                when others=>
                  k_state <= IDLE;
              end case;
            end if;
          end if;
        end process fsm;
        
                  
          
          
np:process(clk,global_clock_enable,reset,k,p,stp)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1' or stp='1') then
              next_pass_i <= '0';
              blk_done  <= '0';
            else
              case k_state is
                when IDLE=>
                  next_pass_i <= '0';
                  blk_done  <= '0';
                when NEXT_PASS_UPD=>    
                  next_pass_i <= '1';
                  if(p=int2ustd(n_passes,log2_n_passes)) then
                    blk_done<='1';
                  else
                    blk_done <= '0';
                  end if;
                when others=>
                  next_pass_i <= '0';
                  blk_done  <= '0';
              end case;
            end if;
          end if;
      end process np;     


end generate gen_so_m_k;






end;

      


    
