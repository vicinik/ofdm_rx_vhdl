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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_cmult_std.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

library ieee;                              
use ieee.std_logic_1164.all;               
use ieee.std_logic_arith.all; 
use ieee.std_logic_unsigned.all;

use work.fft_pack.all;
library lpm;
use lpm.lpm_components.all;
library altera_mf;
use altera_mf.altera_mf_components.all;
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
-- Complex Multiplier Standard Implementation (4 Mults, 2 Adds)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
entity asj_fft_cmult_std is 
generic( device_family    : string;
         mpr    : integer :=18;
         twr    : integer :=16;
         mult_imp : integer :=0;
         pipe   : integer :=1
        );
port(   clk     : in std_logic;
global_clock_enable : in std_logic;
        reset   : in std_logic;
        dataa   : in std_logic_vector(mpr-1 downto 0);
        datab   : in std_logic_vector(mpr-1 downto 0);
        datac   : in std_logic_vector(twr-1 downto 0);
        datad   : in std_logic_vector(twr-1 downto 0);
        real_out : out std_logic_vector(mpr-1 downto 0);
        imag_out : out std_logic_vector(mpr-1 downto 0)
    );

end asj_fft_cmult_std;
architecture model of asj_fft_cmult_std is 

  function sgn_ex(inval : std_logic_vector; w : integer; b : integer) return std_logic_vector is
  -- sign extend input std_logic_vector of width w by b bits
  variable temp :   std_logic_vector(w+b-1 downto 0);
  begin
    temp(w+b-1 downto w-1):=(w+b-1 downto w-1 => inval(w-1));
    temp(w-2 downto 0) := inval(w-2 downto 0);
  return temp;
  end sgn_ex;
  
  constant m_p : integer := 3;
  constant add_p : integer := 1;
  constant new_scaling  : integer :=0;
   
signal vcc : std_logic;
signal gnd : std_logic;


signal result_a_c : std_logic_vector(mpr+twr-1 downto 0);
signal result_b_d : std_logic_vector(mpr+twr-1 downto 0);
signal result_a_d : std_logic_vector(mpr+twr-1 downto 0);
signal result_b_c : std_logic_vector(mpr+twr-1 downto 0);
signal result_a_c_se : std_logic_vector(mpr+twr downto 0);
signal result_b_d_se : std_logic_vector(mpr+twr downto 0);
signal result_a_d_se : std_logic_vector(mpr+twr downto 0);
signal result_b_c_se : std_logic_vector(mpr+twr downto 0);




signal result_r : std_logic_vector(twr+mpr downto 0);
signal result_i : std_logic_vector(twr+mpr downto 0);
signal result_r_early : std_logic_vector(twr+mpr downto 0);
signal result_i_early : std_logic_vector(twr+mpr downto 0);

signal result_r_tmp : std_logic_vector(twr+mpr-1 downto 0);
signal result_i_tmp : std_logic_vector(twr+mpr-1 downto 0);



signal real_out_reg : std_logic_vector(mpr-1 downto 0);
signal imag_out_reg : std_logic_vector(mpr-1 downto 0);



begin
  gnd <= '0';
  vcc <= '1';
  
  gen_ma : if(mult_imp=0) generate
  
  gen_ma_full : if(mpr<=18 and twr <=18) generate

      ms : asj_fft_mult_add 
        generic map(
                    device_family   => device_family, 
                    mpr   => mpr, 
                    twr   => twr,
                    dirn  => "SUB"
        )
        port map(
global_clock_enable => global_clock_enable,
                    clock0  => clk,
                    dataa_0 => dataa,
                    dataa_1 => datab,
                    datab_0 => datac,
                    datab_1 => datad,
                    result  => result_r
      );
      
      ma : asj_fft_mult_add 
        generic map(
                    device_family   => device_family, 
                    mpr   => mpr, 
                    twr   => twr,
                    dirn  => "ADD"
        )
        port map(
global_clock_enable => global_clock_enable,
                    clock0  => clk,
                    dataa_0 => datab,
                    dataa_1 => dataa,
                    datab_0 => datac,
                    datab_1 => datad,
                    result  => result_i
      );
      
      
reg_muo:process(clk,global_clock_enable)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            result_r_tmp <= result_r(mpr+twr-1 downto 0);
            result_i_tmp <= result_i(mpr+twr-1 downto 0);
          end if;
        end process reg_muo;
      
      
      u0 : asj_fft_pround
        generic map (     
                      widthin   => mpr+twr,
                      widthout  => mpr,
                      pipe      => 1
          )
        port map  ( 
global_clock_enable => global_clock_enable,
                      clk       => clk,
                      clken     => vcc,
                      xin       => result_r_tmp,
                      yout      => real_out_reg
          );  
        
      u1 : asj_fft_pround
        generic map (     
                      widthin   => mpr+twr,
                      widthout  => mpr,
                      pipe      => 1
          )
        port map  ( 
global_clock_enable => global_clock_enable,
                      clk       => clk,
                      clken     => vcc,
                      xin       => result_i_tmp,
                      yout      => imag_out_reg
          );  
      
      real_delay : asj_fft_tdl
      generic map( 
                    mpr => mpr,
                    del   => 2,
                    srr   => "AUTO_SHIFT_REGISTER_RECOGNITION=OFF"
                )
        port map(   
global_clock_enable => global_clock_enable,
                    clk   => clk,
                    data_in   => real_out_reg,
                    data_out  => real_out
            );
    
      imag_delay : asj_fft_tdl
      generic map( 
                    mpr => mpr,
                    del   => 2
                )
        port map(   
global_clock_enable => global_clock_enable,
                    clk   => clk,
                    data_in   => imag_out_reg,
                    data_out  => imag_out
            );
            
    end generate gen_ma_full;
    
    gen_ma_mix_4m : if(mpr>18 and twr>18) generate
    
      m_ac :  asj_fft_lcm_mult
        generic map(mpr=>mpr,
                    twr=>twr,
                    use_dedicated_for_all => 0,
                    pipe => 1
              )
          port map  ( clk =>clk,
global_clock_enable => global_clock_enable,
              dataa =>dataa,
              datab =>datac,
              result =>result_a_c
          );        
          
        m_bd :  asj_fft_lcm_mult
        generic map(mpr=>mpr,
                    twr=>twr,
                    use_dedicated_for_all => 0,
                    pipe => 1
              )
          port map  ( clk =>clk,
global_clock_enable => global_clock_enable,
              dataa =>datab,
              datab =>datad,
              result =>result_b_d
          );        
          
        m_ad :  asj_fft_lcm_mult
        generic map(mpr=>mpr,
                    twr=>twr,
                    use_dedicated_for_all => 0,
                    pipe => 1 
              )
          port map  ( clk =>clk,
global_clock_enable => global_clock_enable,
              dataa =>dataa,
              datab =>datad,
              result =>result_a_d
          );        
          
        m_bc :  asj_fft_lcm_mult
        generic map(mpr=>mpr,
                    twr=>twr,
                    use_dedicated_for_all => 0,
                    pipe => 1
              )
          port map  ( clk =>clk,
global_clock_enable => global_clock_enable,
              dataa =>datab,
              datab =>datac,
              result =>result_b_c
          );        
          
reg_mult:process(clk,global_clock_enable,result_a_c,result_b_d,result_a_d,result_b_c)is
            begin
if((rising_edge(clk) and global_clock_enable='1'))then
                result_a_c_se <= sgn_ex(result_a_c,mpr+twr,1);
                result_b_d_se <= sgn_ex(result_b_d,mpr+twr,1);
                result_a_d_se <= sgn_ex(result_a_d,mpr+twr,1);
                result_b_c_se <= sgn_ex(result_b_c,mpr+twr,1);
              end if;
            end process;
          
          
--           s_ac_bd :   lpm_add_sub
--           generic map(lpm_width=> mpr+twr+1,
--                 lpm_pipeline => add_p,
--                 lpm_representation=>"SIGNED"
--                 )
--           port map(   clock=>clk,
--                 dataa=>result_a_c_se,
--                 datab=>result_b_d_se,
--                 add_sub=> gnd,
--                 result=>result_r
--               );
sub_s_ac_bd:process(clk,global_clock_enable)is
          begin  -- process sub_s_ac_bd
if(rising_edge(clk) and global_clock_enable='1')then--risingclockedge
                  result_r <= result_a_c_se - result_b_d_se;
              end if;
          end process sub_s_ac_bd;
          
--           a_ac_bd :   lpm_add_sub
--           generic map(lpm_width=> mpr+twr+1,
--                 lpm_pipeline => add_p,
--                 lpm_representation=>"SIGNED"
--                 )
--           port map(   clock=>clk,
--                 dataa=>result_a_d_se,
--                 datab=>result_b_c_se,
--                 add_sub=> vcc,
--                 result=>result_i
--               );
add_a_ac_bd:process(clk,global_clock_enable)is
      begin  -- process add_a_ac_bd
if(rising_edge(clk) and global_clock_enable='1')then--risingclockedge
              result_i <= result_a_d_se + result_b_c_se;
          end if;
      end process add_a_ac_bd;
          
        
        result_r_tmp <= result_r(mpr+twr-1 downto 0);
        result_i_tmp <= result_i(mpr+twr-1 downto 0);
        
        
        u0 : asj_fft_pround
          generic map (     
                        widthin   => mpr+twr,
                        widthout  => mpr,
                        pipe      => 1
            )
          port map  ( 
global_clock_enable => global_clock_enable,
                        clk       => clk,
                        clken     => vcc,
                        xin       => result_r_tmp,
                        yout      => real_out_reg
            );  
          
        u1 : asj_fft_pround
          generic map (     
                        widthin   => mpr+twr,
                        widthout  => mpr,
                        pipe      => 1
            )
          port map  ( 
global_clock_enable => global_clock_enable,
                        clk       => clk,
                        clken     => vcc,
                        xin       => result_i_tmp,
                        yout      => imag_out_reg
            );  
      
      real_out <= real_out_reg;
      imag_out <= imag_out_reg;
  
    end generate gen_ma_mix_4m;
    
    gen_ma_mix_2m : if(mpr>18 and twr<=18) generate
    
      m_ac :  asj_fft_lcm_mult_2m
        generic map(mpr=>mpr,
                    twr=>twr,
                    use_dedicated_for_all => 0,
                    pipe => 1
                    
              )
          port map  ( clk =>clk,
global_clock_enable => global_clock_enable,
              dataa =>dataa,
              datab =>datac,
              result =>result_a_c
          );        
          
        m_bd :  asj_fft_lcm_mult_2m
        generic map(mpr=>mpr,
                    twr=>twr,
                    use_dedicated_for_all => 0,
                    pipe => 1
              )
          port map  ( clk =>clk,
global_clock_enable => global_clock_enable,
              dataa =>datab,
              datab =>datad,
              result =>result_b_d
          );        
          
        m_ad :  asj_fft_lcm_mult_2m
        generic map(mpr=>mpr,
                    twr=>twr,
                    use_dedicated_for_all => 0,
                    pipe => 1 
              )
          port map  ( clk =>clk,
global_clock_enable => global_clock_enable,
              dataa =>dataa,
              datab =>datad,
              result =>result_a_d
          );        
          
        m_bc :  asj_fft_lcm_mult_2m
        generic map(mpr=>mpr,
                    twr=>twr,
                    use_dedicated_for_all => 0,
                    pipe => 1
              )
          port map  ( clk =>clk,
global_clock_enable => global_clock_enable,
              dataa =>datab,
              datab =>datac,
              result =>result_b_c
          );        
          
reg_mult:process(clk,global_clock_enable,result_a_c,result_b_d,result_a_d,result_b_c)is
            begin
if((rising_edge(clk) and global_clock_enable='1'))then
                result_a_c_se <= sgn_ex(result_a_c,mpr+twr,1);
                result_b_d_se <= sgn_ex(result_b_d,mpr+twr,1);
                result_a_d_se <= sgn_ex(result_a_d,mpr+twr,1);
                result_b_c_se <= sgn_ex(result_b_c,mpr+twr,1);
              end if;
            end process;
          
          
--           s_ac_bd :   lpm_add_sub
--           generic map(lpm_width=> mpr+twr+1,
--                 lpm_pipeline => add_p,
--                 lpm_representation=>"SIGNED"
--                 )
--           port map(   clock=>clk,
--                 dataa=>result_a_c_se,
--                 datab=>result_b_d_se,
--                 add_sub=> gnd,
--                 result=>result_r
--               );
sub_s_ac_bd:process(clk,global_clock_enable)is
          begin  -- process sub_s_ac_bd
if(rising_edge(clk) and global_clock_enable='1')then--risingclockedge
                  result_r <= result_a_c_se - result_b_d_se;
              end if;
          end process sub_s_ac_bd;
          
--           a_ac_bd :   lpm_add_sub
--           generic map(lpm_width=> mpr+twr+1,
--                 lpm_pipeline => add_p,
--                 lpm_representation=>"SIGNED"
--                 )
--           port map(   clock=>clk,
--                 dataa=>result_a_d_se,
--                 datab=>result_b_c_se,
--                 add_sub=> vcc,
--                 result=>result_i
--               );
add_a_ac_bd:process(clk,global_clock_enable)is
      begin  -- process add_a_ac_bd
if(rising_edge(clk) and global_clock_enable='1')then--risingclockedge
              result_i <= result_a_d_se + result_b_c_se;
          end if;
      end process add_a_ac_bd;
          
        
        result_r_tmp <= result_r(mpr+twr-1 downto 0);
        result_i_tmp <= result_i(mpr+twr-1 downto 0);
        
        
        u0 : asj_fft_pround
          generic map (     
                        widthin   => mpr+twr,
                        widthout  => mpr,
                        pipe      => 1
            )
          port map  ( 
global_clock_enable => global_clock_enable,
                        clk       => clk,
                        clken     => vcc,
                        xin       => result_r_tmp,
                        yout      => real_out_reg
            );  
          
        u1 : asj_fft_pround
          generic map (     
                        widthin   => mpr+twr,
                        widthout  => mpr,
                        pipe      => 1
            )
          port map  ( 
global_clock_enable => global_clock_enable,
                        clk       => clk,
                        clken     => vcc,
                        xin       => result_i_tmp,
                        yout      => imag_out_reg
            );  
      
      
      real_out <= real_out_reg;
      imag_out <= imag_out_reg;
  
    end generate gen_ma_mix_2m;
    
    

  end generate gen_ma;
  
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  
  gen_le_4m : if(mult_imp=1) generate
  
        m_ac :  lpm_mult
        generic map(LPM_WIDTHA=>mpr,
                    LPM_WIDTHB=>twr,
                    LPM_WIDTHP=>mpr+twr,
                    LPM_WIDTHS=>1,
                    LPM_REPRESENTATION => "SIGNED",
                    LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=NO,MAXIMIZE_SPEED=9",
                    LPM_PIPELINE=>m_p
              )
          port map  ( clock =>clk,
clken => global_clock_enable,
              dataa =>dataa,
              datab =>datac,
              result =>result_a_c
          );        
          
        m_bd :  lpm_mult
        generic map(LPM_WIDTHA=>mpr,
                    LPM_WIDTHB=>twr,
                    LPM_WIDTHP=>mpr+twr,
                    LPM_WIDTHS=>1,
                    LPM_REPRESENTATION => "SIGNED",
                    LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=NO,MAXIMIZE_SPEED=9",
                    LPM_PIPELINE=>m_p
              )
          port map  ( clock =>clk,
clken => global_clock_enable,
              dataa =>datab,
              datab =>datad,
              result =>result_b_d
          );        
          
        m_ad :  lpm_mult
        generic map(LPM_WIDTHA=>mpr,
                    LPM_WIDTHB=>twr,
                    LPM_WIDTHP=>mpr+twr,
                    LPM_WIDTHS=>1,
                    LPM_REPRESENTATION => "SIGNED",
                    LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=NO,MAXIMIZE_SPEED=9",
                    LPM_PIPELINE=>m_p
              )
          port map  ( clock =>clk,
clken => global_clock_enable,
              dataa =>dataa,
              datab =>datad,
              result =>result_a_d
          );        
          
        m_bc :  lpm_mult
        generic map(LPM_WIDTHA=>mpr,
                    LPM_WIDTHB=>twr,
                    LPM_WIDTHP=>mpr+twr,
                    LPM_WIDTHS=>1,
                    LPM_REPRESENTATION => "SIGNED",
                    LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=NO,MAXIMIZE_SPEED=9",
                    LPM_PIPELINE=>m_p
              )
          port map  ( clock =>clk,
clken => global_clock_enable,
              dataa =>datab,
              datab =>datac,
              result =>result_b_c
          );        
          
reg_mult:process(clk,global_clock_enable,result_a_c,result_b_d,result_a_d,result_b_c)is
            begin
if((rising_edge(clk) and global_clock_enable='1'))then
                result_a_c_se <= sgn_ex(result_a_c,mpr+twr,1);
                result_b_d_se <= sgn_ex(result_b_d,mpr+twr,1);
                result_a_d_se <= sgn_ex(result_a_d,mpr+twr,1);
                result_b_c_se <= sgn_ex(result_b_c,mpr+twr,1);
              end if;
            end process;
          
          
--           s_ac_bd :   lpm_add_sub
--           generic map(lpm_width=> mpr+twr+1,
--                 lpm_pipeline => add_p+1,
--                 lpm_representation=>"SIGNED"
--                 )
--           port map(   clock=>clk,
--                 dataa=>result_a_c_se,
--                 datab=>result_b_d_se,
--                 add_sub=> gnd,
--                 result=>result_r
--               );
sub_s_ac_bd:process(clk,global_clock_enable)is
          begin  -- process sub_s_ac_bd
if(rising_edge(clk) and global_clock_enable='1')then--risingclockedge
                  result_r_early <= result_a_c_se - result_b_d_se;                  
                  result_r <= result_r_early;
              end if;
          end process sub_s_ac_bd;
          
--           a_ac_bd :   lpm_add_sub
--           generic map(lpm_width=> mpr+twr+1,
--                 lpm_pipeline => add_p+1,
--                 lpm_representation=>"SIGNED"
--                 )
--           port map(   clock=>clk,
--                 dataa=>result_a_d_se,
--                 datab=>result_b_c_se,
--                 add_sub=> vcc,
--                 result=>result_i
--               );
add_a_ac_bd:process(clk,global_clock_enable)is
      begin  -- process add_a_ac_bd
if(rising_edge(clk) and global_clock_enable='1')then--risingclockedge
              result_i_early <= result_a_d_se + result_b_c_se;
              result_i <= result_i_early;
          end if;
      end process add_a_ac_bd;
          
        
        result_r_tmp <= result_r(mpr+twr-1 downto 0);
        result_i_tmp <= result_i(mpr+twr-1 downto 0);
        
        
        u0 : asj_fft_pround
          generic map (     
                        widthin   => mpr+twr,
                        widthout  => mpr,
                        pipe      => 1
            )
          port map  ( 
global_clock_enable => global_clock_enable,
                        clk       => clk,
                        clken     => vcc,
                        xin       => result_r_tmp,
                        yout      => real_out_reg
            );  
          
        u1 : asj_fft_pround
          generic map (     
                        widthin   => mpr+twr,
                        widthout  => mpr,
                        pipe      => 1
            )
          port map  ( 
global_clock_enable => global_clock_enable,
                        clk       => clk,
                        clken     => vcc,
                        xin       => result_i_tmp,
                        yout      => imag_out_reg
            );  
      
        real_out <= real_out_reg;
        imag_out <= imag_out_reg;
    

end generate gen_le_4m;
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

gen_dsp_only : if(mult_imp=2) generate

  gen_ma_full : if(mpr<=18 and twr <=18) generate

      ms : asj_fft_mult_add 
        generic map(
                    device_family   => device_family, 
                    mpr   => mpr, 
                    twr   => twr,
                    dirn  => "SUB"
        )
        port map(
global_clock_enable => global_clock_enable,
                    clock0  => clk,
                    dataa_0 => dataa,
                    dataa_1 => datab,
                    datab_0 => datac,
                    datab_1 => datad,
                    result  => result_r
      );
      
      ma : asj_fft_mult_add 
        generic map(
                    device_family   => device_family, 
                    mpr   => mpr, 
                    twr   => twr,
                    dirn  => "ADD"
        )
        port map(
global_clock_enable => global_clock_enable,
                    clock0  => clk,
                    dataa_0 => datab,
                    dataa_1 => dataa,
                    datab_0 => datac,
                    datab_1 => datad,
                    result  => result_i
      );
      
      
reg_muo:process(clk,global_clock_enable)is
        begin
if((rising_edge(clk) and global_clock_enable='1'))then
            result_r_tmp <= result_r(mpr+twr-1 downto 0);
            result_i_tmp <= result_i(mpr+twr-1 downto 0);
          end if;
        end process reg_muo;
        
        u0 : asj_fft_pround
          generic map (     
                        widthin   => mpr+twr,
                        widthout  => mpr,
                        pipe      => 1
            )
          port map  ( 
global_clock_enable => global_clock_enable,
                        clk       => clk,
                        clken     => vcc,
                        xin       => result_r_tmp,
                        yout      => real_out_reg
            );  
          
        u1 : asj_fft_pround
          generic map (     
                        widthin   => mpr+twr,
                        widthout  => mpr,
                        pipe      => 1
            )
          port map  ( 
global_clock_enable => global_clock_enable,
                        clk       => clk,
                        clken     => vcc,
                        xin       => result_i_tmp,
                        yout      => imag_out_reg
            );  
      
        real_delay : asj_fft_tdl
        generic map( 
                      mpr => mpr,
                      del   => 2,
                      srr   => "AUTO_SHIFT_REGISTER_RECOGNITION=OFF"
                  )
          port map(   
global_clock_enable => global_clock_enable,
                      clk   => clk,
                      data_in   => real_out_reg,
                      data_out  => real_out
              );
    
        imag_delay : asj_fft_tdl
        generic map( 
                      mpr => mpr,
                      del   => 2
                  )
          port map(   
global_clock_enable => global_clock_enable,
                      clk   => clk,
                      data_in   => imag_out_reg,
                      data_out  => imag_out
              );
            
    end generate gen_ma_full;
    
    gen_ma_mix_4m : if(mpr>18 and twr>18) generate
    
      m_ac :  lpm_mult
      generic map(lpm_widtha=>mpr,
                  lpm_widthb=>twr,
                  lpm_widthp=>mpr+twr,
                  lpm_widths=>1,
                  LPM_REPRESENTATION => "SIGNED",
                  LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",
                  LPM_PIPELINE=>4
            )
      port map (  clock =>clk,
clken => global_clock_enable,
                  dataa =>dataa,
                  datab =>datac,
                  result =>result_a_c
          );        
      
      m_bd :  lpm_mult
      generic map(lpm_widtha=>mpr,
                  lpm_widthb=>twr,
                  lpm_widthp=>mpr+twr,
                  lpm_widths=>1,
                  LPM_REPRESENTATION => "SIGNED",
                  LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",
                  LPM_PIPELINE=>4
            )
      port map (  clock =>clk,
clken => global_clock_enable,
                  dataa =>datab,
                  datab =>datad,
                  result =>result_b_d
          );        
      
      m_ad :  lpm_mult
      generic map(lpm_widtha=>mpr,
                  lpm_widthb=>twr,
                  lpm_widthp=>mpr+twr,
                  lpm_widths=>1,
                  LPM_REPRESENTATION => "SIGNED",
                  LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",
                  LPM_PIPELINE=>4
            )
      port map (  clock =>clk,
clken => global_clock_enable,
                  dataa =>dataa,
                  datab =>datad,
                  result =>result_a_d
          );        
      
      m_bc :  lpm_mult
      generic map(lpm_widtha=>mpr,
                  lpm_widthb=>twr,
                  lpm_widthp=>mpr+twr,
                  lpm_widths=>1,
                  LPM_REPRESENTATION => "SIGNED",
                  LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",
                  LPM_PIPELINE=>4
            )
      port map (  clock =>clk,
clken => global_clock_enable,
                  dataa =>datab,
                  datab =>datac,
                  result =>result_b_c
          );        
        
reg_mult:process(clk,global_clock_enable,result_a_c,result_b_d,result_a_d,result_b_c)is
          begin
if((rising_edge(clk) and global_clock_enable='1'))then
              result_a_c_se <= sgn_ex(result_a_c,mpr+twr,1);
              result_b_d_se <= sgn_ex(result_b_d,mpr+twr,1);
              result_a_d_se <= sgn_ex(result_a_d,mpr+twr,1);
              result_b_c_se <= sgn_ex(result_b_c,mpr+twr,1);
            end if;
          end process;
        
        
--         s_ac_bd :   lpm_add_sub
--         generic map(lpm_width=> mpr+twr+1,
--               lpm_pipeline => add_p,
--               lpm_representation=>"SIGNED"
--               )
--         port map(   clock=>clk,
--               dataa=>result_a_c_se,
--               datab=>result_b_d_se,
--               add_sub=> gnd,
--               result=>result_r
--             );
sub_s_ac_bd:process(clk,global_clock_enable)is
          begin  -- process sub_s_ac_bd
if(rising_edge(clk) and global_clock_enable='1')then--risingclockedge
                  result_r <= result_a_c_se - result_b_d_se;
              end if;
          end process sub_s_ac_bd;
       
--         a_ac_bd :   lpm_add_sub
--         generic map(lpm_width=> mpr+twr+1,
--               lpm_pipeline => add_p,
--               lpm_representation=>"SIGNED"
--               )
--         port map(   clock=>clk,
--               dataa=>result_a_d_se,
--               datab=>result_b_c_se,
--               add_sub=> vcc,
--               result=>result_i
--             );
add_a_ac_bd:process(clk,global_clock_enable)is
      begin  -- process add_a_ac_bd
if(rising_edge(clk) and global_clock_enable='1')then--risingclockedge
              result_i <= result_a_d_se + result_b_c_se;
          end if;
      end process add_a_ac_bd;

        result_r_tmp <= result_r(mpr+twr-1 downto 0);
        result_i_tmp <= result_i(mpr+twr-1 downto 0);
      
        
        u0 : asj_fft_pround
          generic map (     
                        widthin   => mpr+twr,
                        widthout  => mpr,
                        pipe      => 1
            )
          port map  ( 
global_clock_enable => global_clock_enable,
                        clk       => clk,
                        clken     => vcc,
                        xin       => result_r_tmp,
                        yout      => real_out_reg
            );  
          
        u1 : asj_fft_pround
          generic map (     
                        widthin   => mpr+twr,
                        widthout  => mpr,
                        pipe      => 1
            )
          port map  ( 
global_clock_enable => global_clock_enable,
                        clk       => clk,
                        clken     => vcc,
                        xin       => result_i_tmp,
                        yout      => imag_out_reg
            );  
      
      real_out <= real_out_reg;
      imag_out <= imag_out_reg;
    end generate gen_ma_mix_4m;
    
    gen_ma_mix_2m : if(mpr>18 and twr<=18) generate
    
      m_ac :  asj_fft_lcm_mult_2m
        generic map(mpr=>mpr,
                    twr=>twr,  
                    use_dedicated_for_all => 1,
                    pipe => 1
              )
          port map  ( clk =>clk,
global_clock_enable => global_clock_enable,
              dataa =>dataa,
              datab =>datac,
              result =>result_a_c
          );        
          
        m_bd :  asj_fft_lcm_mult_2m
        generic map(mpr=>mpr,
                    twr=>twr,
                    use_dedicated_for_all => 1,
                    pipe => 1
              )
          port map  ( clk =>clk,
global_clock_enable => global_clock_enable,
              dataa =>datab,
              datab =>datad,
              result =>result_b_d
          );        
          
        m_ad :  asj_fft_lcm_mult_2m
        generic map(mpr=>mpr,
                    twr=>twr,
                    use_dedicated_for_all => 1,
                    pipe => 1 
              )
          port map  ( clk =>clk,
global_clock_enable => global_clock_enable,
              dataa =>dataa,
              datab =>datad,
              result =>result_a_d
          );        
          
        m_bc :  asj_fft_lcm_mult_2m
        generic map(mpr=>mpr,
                    twr=>twr,
                    use_dedicated_for_all => 1,
                    pipe => 1
              )
          port map  ( clk =>clk,
global_clock_enable => global_clock_enable,
              dataa =>datab,
              datab =>datac,
              result =>result_b_c
          );        
          
reg_mult:process(clk,global_clock_enable,result_a_c,result_b_d,result_a_d,result_b_c)is
            begin
if((rising_edge(clk) and global_clock_enable='1'))then
                result_a_c_se <= sgn_ex(result_a_c,mpr+twr,1);
                result_b_d_se <= sgn_ex(result_b_d,mpr+twr,1);
                result_a_d_se <= sgn_ex(result_a_d,mpr+twr,1);
                result_b_c_se <= sgn_ex(result_b_c,mpr+twr,1);
              end if;
            end process;
          
          
--           s_ac_bd :   lpm_add_sub
--           generic map(lpm_width=> mpr+twr+1,
--                 lpm_pipeline => add_p,
--                 lpm_representation=>"SIGNED"
--                 )
--           port map(   clock=>clk,
--                 dataa=>result_a_c_se,
--                 datab=>result_b_d_se,
--                 add_sub=> gnd,
--                 result=>result_r
--               );
sub_s_ac_bd:process(clk,global_clock_enable)is
          begin  -- process sub_s_ac_bd
if(rising_edge(clk) and global_clock_enable='1')then--risingclockedge
                  result_r <= result_a_c_se - result_b_d_se;
              end if;
          end process sub_s_ac_bd;
          
--           a_ac_bd :   lpm_add_sub
--           generic map(lpm_width=> mpr+twr+1,
--                 lpm_pipeline => add_p,
--                 lpm_representation=>"SIGNED"
--                 )
--           port map(   clock=>clk,
--                 dataa=>result_a_d_se,
--                 datab=>result_b_c_se,
--                 add_sub=> vcc,
--                 result=>result_i
--               );
add_a_ac_bd:process(clk,global_clock_enable)is
      begin  -- process add_a_ac_bd
if(rising_edge(clk) and global_clock_enable='1')then--risingclockedge
              result_i <= result_a_d_se + result_b_c_se;
          end if;
      end process add_a_ac_bd;
          
        
        result_r_tmp <= result_r(mpr+twr-1 downto 0);
        result_i_tmp <= result_i(mpr+twr-1 downto 0);
        
        
        u0 : asj_fft_pround
          generic map (     
                        widthin   => mpr+twr,
                        widthout  => mpr,
                        pipe      => 1
            )
          port map  ( 
global_clock_enable => global_clock_enable,
                        clk       => clk,
                        clken     => vcc,
                        xin       => result_r_tmp,
                        yout      => real_out_reg
            );  
          
        u1 : asj_fft_pround
          generic map (     
                        widthin   => mpr+twr,
                        widthout  => mpr,
                        pipe      => 1
            )
          port map  ( 
global_clock_enable => global_clock_enable,
                        clk       => clk,
                        clken     => vcc,
                        xin       => result_i_tmp,
                        yout      => imag_out_reg
            );  
      
      real_out <= real_out_reg;
      imag_out <= imag_out_reg;
  
    end generate gen_ma_mix_2m;         
              
end generate gen_dsp_only;

          
          
      
    
    
  

end;
