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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_cmult_can.vhd#1 $ 
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
-- Complex Multiplier utilizing Canonic Reduction
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

entity asj_fft_cmult_can is 
generic( mpr    : integer :=18;
         twr    : integer :=18;
         opr    : integer :=36;
         oprp1  : integer :=37;
         oprp2  : integer :=38;
         pipe   : integer :=1;
         mult_imp  : integer  :=0
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

end asj_fft_cmult_can;
architecture model of asj_fft_cmult_can is 

  function sgn_ex(inval : std_logic_vector; w : integer; b : integer) return std_logic_vector is
  -- sign extend input std_logic_vector of width w by b bits
  variable temp :   std_logic_vector(w+b-1 downto 0);
  begin
    temp(w+b-1 downto w-1):=(w+b-1 downto w-1 => inval(w-1));
    temp(w-2 downto 0) := inval(w-2 downto 0);
  return temp;
  end sgn_ex;
  
  
  constant new_scaling  : integer :=0;
  constant full_rnd : integer := 1;
  constant m_p : integer := 3;
  constant add_p : integer := 1;

  
   
signal vcc : std_logic;
signal gnd : std_logic;


signal result_a_c : std_logic_vector(opr-1 downto 0);
signal result_b_d : std_logic_vector(opr-1 downto 0);
signal result_a_c_se : std_logic_vector(opr downto 0);
signal result_b_d_se : std_logic_vector(opr downto 0);
signal result_real_1_tmp : std_logic_vector(oprp1-1 downto 0);
signal result_real_1 : std_logic_vector(oprp2-1 downto 0);

signal ase,bse : std_logic_vector(mpr downto 0);
signal cse,dse : std_logic_vector(twr downto 0);
signal addresult_a_b : std_logic_vector(mpr downto 0);
signal addresult_c_d : std_logic_vector(twr downto 0);
signal result_a_b_c_d : std_logic_vector(mpr+twr+1 downto 0);
signal result_a_b_c_d_se : std_logic_vector(oprp2-1 downto 0);
 
signal addresult_ac_bd : std_logic_vector(opr downto 0);
signal addresult_ac_bd_se : std_logic_vector(oprp1 downto 0);
signal result_imag_1 : std_logic_vector(oprp2-1 downto 0);

signal real_out_reg : std_logic_vector(mpr-1 downto 0);
signal real_out_tmp : std_logic_vector(mpr-1 downto 0);
signal imag_out_reg : std_logic_vector(mpr-1 downto 0);

signal result_r_tmp : std_logic_vector(mpr+twr-1 downto 0);   
signal result_i_tmp : std_logic_vector(mpr+twr-1 downto 0);   

begin
  
  gnd <= '0';
  vcc <= '1';

-- compute real output
-- ac-bd
-- sign extend dataa,datab,datac and datad

  gen_ded_m1 : if(mult_imp=0) generate
  
    gen_ext_m_ac_4m : if(mpr>18 and twr>18) generate
    
          m_ac :  asj_fft_lcm_mult
        generic map(mpr=>mpr,
                    twr=>twr,
                    use_dedicated_for_all => 0,
                    pipe => 0
              )
          port map  ( clk =>clk,
global_clock_enable => global_clock_enable,
              dataa =>dataa,
              datab =>datac,
              result =>result_a_c
          );
          
    end generate gen_ext_m_ac_4m;     
    
    gen_ext_m_ac_2m : if(mpr>18 and twr<=18) generate
    
      m_ac :  asj_fft_lcm_mult_2m
        generic map(mpr=>mpr,
                    twr=>twr,
                    use_dedicated_for_all => 0,
                    pipe => 0
              )
          port map  ( clk =>clk,
global_clock_enable => global_clock_enable,
              dataa =>dataa,
              datab =>datac,
              result =>result_a_c
          );
          
    end generate gen_ext_m_ac_2m;     
    
    
    gen_ext_m_bd_4m : if(mpr>18 and twr>18) generate
      
        m_bd :  asj_fft_lcm_mult
        generic map(mpr=>mpr,
                    twr=>twr,
                    use_dedicated_for_all => 0,
                    pipe => 0
              )
        port map (  clk =>clk,
global_clock_enable => global_clock_enable,
              dataa =>datab,
              datab =>datad,
              result =>result_b_d
            );
            
    end generate gen_ext_m_bd_4m;
    
    gen_ext_m_bd_2m : if(mpr>18 and twr<=18) generate
      
        m_bd :  asj_fft_lcm_mult_2m
        generic map(mpr=>mpr,
                    twr=>twr,
                    use_dedicated_for_all => 0,
                    pipe => 0
              )
        port map (  clk =>clk,
global_clock_enable => global_clock_enable,
              dataa =>datab,
              datab =>datad,
              result =>result_b_d
            );
            
    end generate gen_ext_m_bd_2m;
    
    gen_ext_m_a_b_c_d_4m : if(mpr>17 and twr>17) generate
            
        m_a_b_c_d :   asj_fft_lcm_mult
        generic map(mpr=>mpr+1,
                    twr=>twr+1,
                    use_dedicated_for_all => 0,
                    pipe => 0
              )
        port map (  clk =>clk,
global_clock_enable => global_clock_enable,
              dataa =>addresult_a_b,
              datab =>addresult_c_d,
              result =>result_a_b_c_d
            );    
    
    end generate gen_ext_m_a_b_c_d_4m;
    
    gen_ext_m_a_b_c_d_2m : if(mpr>17 and twr<=17) generate
            
        m_a_b_c_d :   asj_fft_lcm_mult_2m
        generic map(mpr=>mpr+1,
                    twr=>twr+1,
                    use_dedicated_for_all => 0,
                    pipe => 0
              )
        port map (  clk =>clk,
global_clock_enable => global_clock_enable,
              dataa =>addresult_a_b,
              datab =>addresult_c_d,
              result =>result_a_b_c_d
            );    
    
    end generate gen_ext_m_a_b_c_d_2m;
    
    
    gen_unext_m_ac : if(mpr<=18 and twr<=18) generate
    
        m_ac :  lpm_mult
        generic map(LPM_WIDTHA=>mpr,
                    LPM_WIDTHB=>twr,
                    LPM_WIDTHP=>opr,
                    LPM_WIDTHS=>1,
                    LPM_REPRESENTATION => "SIGNED",
                    LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=6",
                    LPM_PIPELINE=>m_p
              )
          port map  ( clock =>clk,
clken => global_clock_enable,
              dataa =>dataa,
              datab =>datac,
              result =>result_a_c
          );
    end generate gen_unext_m_ac;
        
  gen_unext_m_bd : if(mpr<=18 and twr<=18) generate
        
    
      m_bd :  lpm_mult
      generic map(lpm_widtha=>mpr,
                  lpm_widthb=>twr,
                  lpm_widthp=>opr,
                  LPM_WIDTHS=>1,
                  LPM_REPRESENTATION => "SIGNED",
                  LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=6",
                  LPM_PIPELINE=>m_p
            )
      port map (  clock =>clk,
clken => global_clock_enable,
            dataa =>datab,
            datab =>datad,
            result =>result_b_d
          );
          
  end generate gen_unext_m_bd;

  gen_unext_m_a_b_c_d : if(mpr<=17 and twr<=17) generate          
  
      m_a_b_c_d :   lpm_mult
      generic map(lpm_widtha=>mpr+1,
            lpm_widthb=>twr+1,
            lpm_widthp=>oprp2,
            LPM_WIDTHS=>1,
            lpm_representation => "SIGNED",
            lpm_hint => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=6",
            lpm_pipeline=>m_p
            )
      port map (  clock =>clk,
clken => global_clock_enable,
            dataa =>addresult_a_b,
            datab =>addresult_c_d,
            result =>result_a_b_c_d
          );    
          
  end generate gen_unext_m_a_b_c_d;       
          
  end generate gen_ded_m1;
  
  -----------------------------------------------------------------------------------------------
  -- Logic Element Implementations
  ----------------------------------------------------------------------------------------------- 
    
  gen_lcell_m1 : if(mult_imp=1) generate
  
      m_ac :  lpm_mult
      generic map(LPM_WIDTHA=>mpr,
                  LPM_WIDTHB=>twr,
                  LPM_WIDTHP=>opr,
                  LPM_WIDTHS=>1,
                  LPM_REPRESENTATION => "SIGNED",
                  LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=NO,MAXIMIZE_SPEED=6",
                  LPM_PIPELINE=>m_p
            )
        port map  ( clock =>clk,
clken => global_clock_enable,
            dataa =>dataa,
            datab =>datac,
            result =>result_a_c
        );
    
      m_bd :  lpm_mult
      generic map(lpm_widtha=>mpr,
                  lpm_widthb=>twr,
                  lpm_widthp=>opr,
                  LPM_WIDTHS=>1,
                  LPM_REPRESENTATION => "SIGNED",
                  LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=NO,MAXIMIZE_SPEED=6",
                  LPM_PIPELINE=>m_p
            )
      port map (  clock =>clk,
clken => global_clock_enable,
            dataa =>datab,
            datab =>datad,
            result =>result_b_d
          );
          
      m_a_b_c_d :   lpm_mult
      generic map(lpm_widtha=>mpr+1,
            lpm_widthb=>twr+1,
            lpm_widthp=>oprp2,
                LPM_WIDTHS=>1,    
            lpm_representation => "SIGNED",
            lpm_hint => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=NO,MAXIMIZE_SPEED=6",
            lpm_pipeline=>m_p
            )
      port map (  clock =>clk,
clken => global_clock_enable,
            dataa =>addresult_a_b,
            datab =>addresult_c_d,
            result =>result_a_b_c_d
          );    
          
          
  end generate gen_lcell_m1;
    
  -----------------------------------------------------------------------------------------------
  -- DSP Block Only Implementations
  ----------------------------------------------------------------------------------------------- 
    
  gen_dsp_only : if(mult_imp=2) generate
  
      m_ac :  lpm_mult
      generic map(LPM_WIDTHA=>mpr,
                  LPM_WIDTHB=>twr,
                  LPM_WIDTHP=>opr,
                      LPM_WIDTHS=>1,
                  LPM_REPRESENTATION => "SIGNED",
                  LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=6",
                  LPM_PIPELINE=>m_p
            )
        port map  ( clock =>clk,
clken => global_clock_enable,
            dataa =>dataa,
            datab =>datac,
            result =>result_a_c
        );
    
      m_bd :  lpm_mult
      generic map(lpm_widtha=>mpr,
                  lpm_widthb=>twr,
                  lpm_widthp=>opr,
                      LPM_WIDTHS=>1,
                  LPM_REPRESENTATION => "SIGNED",
                  LPM_HINT => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=6",
                  LPM_PIPELINE=>m_p
            )
      port map (  clock =>clk,
clken => global_clock_enable,
            dataa =>datab,
            datab =>datad,
            result =>result_b_d
          );
          
      m_a_b_c_d :   lpm_mult
      generic map(lpm_widtha=>mpr+1,
            lpm_widthb=>twr+1,
            lpm_widthp=>oprp2,
                LPM_WIDTHS=>1,
            lpm_representation => "SIGNED",
            lpm_hint => "INPUT_B_IS_CONSTANT=NO,DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=6",
            lpm_pipeline=>m_p
            )
      port map (  clock =>clk,
clken => global_clock_enable,
            dataa =>addresult_a_b,
            datab =>addresult_c_d,
            result =>result_a_b_c_d
          );    
          
          
  end generate gen_dsp_only;    
      
  -- sign extend ac and bd      
  gen_se_register : if(pipe=1) generate
reg_mult:process(clk,global_clock_enable,result_a_c,result_b_d)is
  begin
if((rising_edge(clk) and global_clock_enable='1'))then
      result_a_c_se <= sgn_ex(result_a_c,opr,1);
      result_b_d_se <= sgn_ex(result_b_d,opr,1);
    end if;
  end process;
  end generate gen_se_register;
  
  gen_se : if(pipe=0) generate
      result_a_c_se <= sgn_ex(result_a_c,opr,1);
      result_b_d_se <= sgn_ex(result_b_d,opr,1);
  end generate gen_se;
    
  
--   s_ac_bd :   lpm_add_sub
--   generic map(lpm_width=> oprp1,
--         lpm_pipeline => add_p,
--         lpm_representation=>"SIGNED"
--         )
--   port map(   clock=>clk,
--         dataa=>result_a_c_se,
--         datab=>result_b_d_se,
--         add_sub=> gnd,
--         result=>result_real_1_tmp
--       );

adder_s_ac_bd:process(clk,global_clock_enable,reset)is
  begin  -- process adder_s_ac_bd
      if reset = '1' then               -- asynchronous reset (active high)
          result_real_1_tmp <= (others => '0');
elsif(rising_edge(clk) and global_clock_enable='1')then--risingclockedge
          result_real_1_tmp <= result_a_c_se - result_b_d_se;
      end if;
  end process adder_s_ac_bd;
      
      result_real_1 <= result_real_1_tmp(oprp1-1) & result_real_1_tmp(oprp1-1 downto 0);

-- compute imaginary output
-- (a+b)*(c+d) - (ac+bd)
-- sign extend dataa,datab,datac and datad

ase <= sgn_ex(dataa,mpr,1);
bse <= sgn_ex(datab,mpr,1);
cse <= sgn_ex(datac,twr,1);
dse <= sgn_ex(datad,twr,1);

-----------------------------------------------------------------------------
-- compute  (a+b)*(c+d)

--   a_ab :  lpm_add_sub
--   generic map(lpm_width=> mpr+1,
--         lpm_pipeline => add_p,
--         lpm_representation=>"SIGNED"
--         )
--   port map(   clock=>clk,
--         dataa=>ase,
--         datab=>bse,
--         add_sub=> vcc,
--         result=>addresult_a_b
--       );

add_a_ab:process(clk,global_clock_enable,reset)is
  begin  -- process add_a_ab
      if reset = '1' then               -- asynchronous reset (active high)
          addresult_a_b <= (others => '0');
elsif(rising_edge(clk) and global_clock_enable='1')then--risingclockedge
          addresult_a_b <= ase + bse;
      end if;
  end process add_a_ab;

--   a_cd :  lpm_add_sub
--   generic map(lpm_width=> twr+1,
--         lpm_pipeline => add_p,
--         lpm_representation=>"SIGNED"
--         )
--   port map(   clock=>clk,
--         dataa=>cse,
--         datab=>dse,
--         add_sub=> vcc,
--         result=>addresult_c_d
--       );

add_a_cd:process(clk,global_clock_enable,reset)is
  begin  -- process add_a_cd
      if reset = '1' then               -- asynchronous reset (active high)
          addresult_c_d <= (others => '0');
elsif(rising_edge(clk) and global_clock_enable='1')then--risingclockedge
          addresult_c_d <= cse + dse;
      end if;
  end process add_a_cd;
      
      
--------------------------------------------------------------------------------      

-- ac + bd

--   a_ac_bd :   lpm_add_sub
--   generic map(lpm_width=> oprp1,
--         lpm_pipeline => add_p,
--         lpm_representation=>"SIGNED"
--         )
--   port map(   clock=>clk,
--         dataa=>result_a_c_se,
--         datab=>result_b_d_se,
--         add_sub=> vcc,
--         result=>addresult_ac_bd
--       );

add_a_ac_bd:process(clk,global_clock_enable,reset)is
  begin  -- process add_a_ac_bd
      if reset = '1' then               -- asynchronous reset (active high)
          addresult_ac_bd <= (others => '0');
elsif(rising_edge(clk) and global_clock_enable='1')then--risingclockedge
          addresult_ac_bd <= result_b_d_se + result_a_c_se;
      end if;
  end process add_a_ac_bd;

-- subtract (ac+bd) from (a+b)*(c+d)
addresult_ac_bd_se<=sgn_ex(addresult_ac_bd,oprp1,1);

  gen_4w_register : if(pipe=1) generate
reg_mult:process(clk,global_clock_enable,result_a_b_c_d)is
  begin
if((rising_edge(clk) and global_clock_enable='1'))then
        result_a_b_c_d_se <= sgn_ex(result_a_b_c_d,oprp1,1);
    end if;
  end process;
  end generate gen_4w_register;
  
  gen_4w : if(pipe=0) generate
        result_a_b_c_d_se <= sgn_ex(result_a_b_c_d,oprp1,1);
  end generate gen_4w;

--   a_a_b_c_d_ac_bd :   lpm_add_sub
--   generic map(lpm_width=> oprp2,
--         lpm_pipeline => add_p,
--         lpm_representation=>"SIGNED"
--         )
--   port map(   clock=>clk,
--         dataa=>result_a_b_c_d_se,
--         datab=>addresult_ac_bd_se,
--         add_sub=> gnd,
--         result=>result_imag_1
--       );


sub_a_a_b_c_d_ac_bd:process(clk,global_clock_enable,reset)is
  begin  -- process sub_a_a_b_c_d_ac_bd
      if reset = '1' then               -- asynchronous reset (active high)
          result_imag_1 <= (others => '0');
elsif(rising_edge(clk) and global_clock_enable='1')then--risingclockedge
          result_imag_1 <= result_a_b_c_d_se - addresult_ac_bd_se;
      end if;
  end process sub_a_a_b_c_d_ac_bd;

  
  gen_unsc : if(new_scaling=0) generate
  
    result_r_tmp <=result_real_1(opr-1 downto 0) ;          
    result_i_tmp <=result_imag_1(opr-1 downto 0) ;          
    
    
    u0 : asj_fft_pround
      generic map (     
                    widthin   => opr,
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
                    widthin   => opr,
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
        
        
  end generate gen_unsc;
    
    -- delay real output until imaginary is ready
reg_real_output:process(clk,global_clock_enable,real_out_reg)is
  begin
if((rising_edge(clk) and global_clock_enable='1'))then
        real_out <= real_out_reg;
    end if;
  end process reg_real_output;
  
  imag_out <= imag_out_reg;

end;
