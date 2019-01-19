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
--  version    : $Version: 1.0 $ 
--  revision      : $Revision: #1 $ 
--  designer name    : $Author: psgswbuild $ 
--  company name     : altera corp.
--  company address  : 101 innovation drive
--                     san jose, california 95134
--                     u.s.a.
-- 
--  copyright altera corp. 2003
-- 
-- 
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_dft_bfp.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all; 
use work.fft_pack.all;
library lpm;
use lpm.lpm_components.all;
library altera_mf;
use altera_mf.altera_mf_components.all;


entity asj_fft_dft_bfp is
   generic (
      device_family : string;
      nps : integer :=256;
      nume : integer :=1;
      bfp  : integer :=1;
      mpr : integer := 16;  
      fpr : integer := 4;  
      arch : integer :=0;
      mult_type : integer:=0;   
      mult_imp : integer:=0;                             
      dsp_arch : integer :=0;
      rbuspr : integer := 64; -- 4*mpr
      twr : integer := 16;
      nstages: integer := 7; -- pipe + 7
      pipe: integer := 1;
      cont : integer :=0
   );
   port (
      global_clock_enable : in std_logic;
      clk                : in std_logic;
      clken         : in std_logic;
      reset              : in std_logic;
      next_pass     : in std_logic;
      next_blk      : in std_logic;
      blk_done      : in std_logic;
      alt_slb_i       : in std_logic_vector(2 downto 0);
      data_1_real_i : in std_logic_vector(mpr-1 downto 0);
      data_2_real_i : in std_logic_vector(mpr-1 downto 0);
      data_3_real_i : in std_logic_vector(mpr-1 downto 0);
      data_4_real_i : in std_logic_vector(mpr-1 downto 0);
      data_1_imag_i : in std_logic_vector(mpr-1 downto 0);
      data_2_imag_i : in std_logic_vector(mpr-1 downto 0);
      data_3_imag_i : in std_logic_vector(mpr-1 downto 0);
      data_4_imag_i : in std_logic_vector(mpr-1 downto 0);
      twid_1_real   : in std_logic_vector(twr-1 downto 0);
      twid_2_real   : in std_logic_vector(twr-1 downto 0);
      twid_3_real   : in std_logic_vector(twr-1 downto 0);
      twid_1_imag   : in std_logic_vector(twr-1 downto 0);
      twid_2_imag   : in std_logic_vector(twr-1 downto 0);
      twid_3_imag   : in std_logic_vector(twr-1 downto 0);
      data_1_real_o : out std_logic_vector(mpr-1 downto 0);
      data_2_real_o : out std_logic_vector(mpr-1 downto 0);
      data_3_real_o : out std_logic_vector(mpr-1 downto 0);
      data_4_real_o : out std_logic_vector(mpr-1 downto 0);
      data_1_imag_o : out std_logic_vector(mpr-1 downto 0);
      data_2_imag_o : out std_logic_vector(mpr-1 downto 0);
      data_3_imag_o : out std_logic_vector(mpr-1 downto 0);
      data_4_imag_o : out std_logic_vector(mpr-1 downto 0);
      alt_slb_o       : out std_logic_vector(2 downto 0)
    );
end asj_fft_dft_bfp;

architecture dft_r4 of asj_fft_dft_bfp is

   ATTRIBUTE ALTERA_INTERNAL_OPTION : string;                                     
   ATTRIBUTE ALTERA_INTERNAL_OPTION OF dft_r4 : ARCHITECTURE IS "AUTO_SHIFT_REGISTER_RECOGNITION=OFF";           

   function sgn_ex(inval : std_logic_vector; w : integer; b : integer) return std_logic_vector is
   -- sign extend input std_logic_vector of width w by b bits
      variable temp :   std_logic_vector(w+b-1 downto 0);
   begin
      temp(w+b-1 downto w-1):=(w+b-1 downto w-1 => inval(w-1));
      temp(w-2 downto 0) := inval(w-2 downto 0);
      return temp;
   end   sgn_ex;

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
   constant fullrnd : integer :=1;
   constant new_scaling : integer :=0;


   constant opr : integer :=mpr+twr;
   constant oprp1 : integer :=mpr+twr+1;
   constant oprp2 : integer :=mpr+twr+2;      

   type   dft_state is (IDLE,BLOCK_DFT_I,WAIT_FOR_OUTPUT,ENABLE_DFT_O,ENABLE_BFP_O,DISABLE_DFT_O);
   signal sdft :  dft_state;

   type four_by_four_m  is array (0 to 3, 0 to 1) of std_logic_vector (mpr downto 0);
   type four_by_four_m1 is array (0 to 3, 0 to 1) of std_logic_vector (mpr+1 downto 0);
   type four_by_four_m2 is array (0 to 3, 0 to 1) of std_logic_vector (mpr-1 downto 0);

   type pipe_balancing_act is array (0 to nstages-1,0 to 1) of std_logic_vector (mpr-1 downto 0);

   type full_tdl is array (0 to 3,0 to 1,0 to 3) of std_logic_vector (mpr-1 downto 0);

   signal data_in : four_by_four_m2;
   signal data_in_sc : four_by_four_m2;

   signal do_tdl : full_tdl;


   signal butterfly_st1 : four_by_four_m;
   signal butterfly_st2 : four_by_four_m1;
   signal butterfly_out : four_by_four_m2;
   signal butterfly_rnd : four_by_four_m2;
   signal butterfly_out_reg_sc : four_by_four_m2;
   signal reg_no_twiddle : pipe_balancing_act;
   signal zero_vec : std_logic_vector(2 downto 0);
   signal dr1o,dr2o,dr3o,dr4o : std_logic_vector(mpr-1 downto 0);
   signal di1o,di2o,di3o,di4o : std_logic_vector(mpr-1 downto 0);


   signal data_1_real_o_int : std_logic_vector(mpr-1 downto 0);
   signal data_2_real_o_int : std_logic_vector(mpr-1 downto 0);
   signal data_3_real_o_int : std_logic_vector(mpr-1 downto 0);
   signal data_4_real_o_int : std_logic_vector(mpr-1 downto 0);
   signal data_1_imag_o_int : std_logic_vector(mpr-1 downto 0);
   signal data_2_imag_o_int : std_logic_vector(mpr-1 downto 0);
   signal data_3_imag_o_int : std_logic_vector(mpr-1 downto 0);
   signal data_4_imag_o_int : std_logic_vector(mpr-1 downto 0);



   signal slb                : std_logic_vector(2 downto 0);
   signal dual_eng_slb      : std_logic_vector(2 downto 0);
   signal slb_1pt           : std_logic_vector(2 downto 0);
   signal slb_nm1            : std_logic_vector(2 downto 0);
   signal gain_out_1pt      : std_logic_vector(fpr-1 downto 0);
   signal gain_out          : std_logic_vector(fpr-1 downto 0);
   signal gain_out_4pts     : std_logic_vector(fpr-1 downto 0);
   signal next_pass_d        : std_logic;
   signal next_pass_d2       : std_logic;
   signal next_pass_d_vec   : std_logic_vector(5 downto 0);
   signal next_pass_vec     : std_logic_vector(2 downto 0);
   signal blk_done_vec      : std_logic_vector(2 downto 0);
   signal next_blk_d        : std_logic;
   signal gap_reg           : std_logic;
   signal scale_dft_o_en    : std_logic;
   signal block_dft_i_en    : std_logic;
   signal block_dft_i_en_st : std_logic;  
   signal rnd               : std_logic;
   signal blk_exp_acc       : std_logic_vector(fpr-1 downto 0);
   signal blk_exp            : std_logic_vector(fpr-1 downto 0);
   signal state_cnt             : std_logic_vector(5 downto 0);
   signal enable_op          : std_logic;

   component cmult_can
   generic(mpr    : integer :=18;
           twr   : integer :=18;
           opr   : integer :=36;
           oprp1 : integer :=37;
           oprp2 : integer :=38;
           pipe  : integer :=0
        );
   port(    clk      : in std_logic;
            global_clock_enable : in std_logic;
            reset   : in std_logic;
            dataa    : in std_logic_vector(mpr-1 downto 0);
            datab    : in std_logic_vector(mpr-1 downto 0);
            datac    : in std_logic_vector(mpr-1 downto 0);
            datad    : in std_logic_vector(mpr-1 downto 0);
            real_out : out std_logic_vector(mpr-1 downto 0);
            imag_out : out std_logic_vector(mpr-1 downto 0)
         );

   end component;



begin
   zero_vec <= (others=>'0');

   -- Input vectors
   data_in(0,0) <= data_1_real_i;
   data_in(1,0) <= data_2_real_i;
   data_in(2,0) <= data_3_real_i;
   data_in(3,0) <= data_4_real_i;
   data_in(0,1) <= data_1_imag_i;
   data_in(1,1) <= data_2_imag_i;
   data_in(2,1) <= data_3_imag_i;
   data_in(3,1) <= data_4_imag_i;
-- 4 Point DFT



   dft_of_4_pts:process(clk,global_clock_enable,reset,data_1_real_i,data_2_real_i,data_3_real_i,data_4_real_i,data_1_imag_i,data_2_imag_i,data_3_imag_i,data_4_imag_i,butterfly_st1)is
   begin
      if((rising_edge(clk) and global_clock_enable='1'))then
         if(reset='1') then
            for i in 0 to 3 loop
               for j in 0 to 1 loop
                  butterfly_st1(i,j)(mpr downto 0) <= (others=>'0');
                  butterfly_st2(i,j)(mpr+1 downto 0) <= (others=>'0');
               end loop;
            end loop;
         else
            butterfly_st1(0,0)(mpr downto 0) <= sgn_ex(data_in_sc(0,0),mpr,1) + sgn_ex(data_in_sc(2,0),mpr,1); --xr(1) + xr(3)
            butterfly_st1(1,0)(mpr downto 0) <= sgn_ex(data_in_sc(1,0),mpr,1) + sgn_ex(data_in_sc(3,0),mpr,1); --xr(2) + xr(4)
            butterfly_st1(2,0)(mpr downto 0) <= sgn_ex(data_in_sc(0,0),mpr,1) - sgn_ex(data_in_sc(2,0),mpr,1); --xr(1) - xr(3)
            butterfly_st1(3,0)(mpr downto 0) <= sgn_ex(data_in_sc(1,0),mpr,1) - sgn_ex(data_in_sc(3,0),mpr,1); --xr(2) - xr(4)
            butterfly_st1(0,1)(mpr downto 0) <= sgn_ex(data_in_sc(0,1),mpr,1) + sgn_ex(data_in_sc(2,1),mpr,1); --xi(1) + xi(3)
            butterfly_st1(1,1)(mpr downto 0) <= sgn_ex(data_in_sc(1,1),mpr,1) + sgn_ex(data_in_sc(3,1),mpr,1); --xi(2) + xi(4)
            butterfly_st1(2,1)(mpr downto 0) <= sgn_ex(data_in_sc(0,1),mpr,1) - sgn_ex(data_in_sc(2,1),mpr,1); --xi(1) - xi(3)
            butterfly_st1(3,1)(mpr downto 0) <= sgn_ex(data_in_sc(1,1),mpr,1) - sgn_ex(data_in_sc(3,1),mpr,1); --xi(2) - xi(4)
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
         end if;
      end if;
   end process dft_of_4_pts;



   gen_full_rnd : if(fullrnd=1) generate

      butterfly_out(0,0)(mpr-1 downto 0) <= butterfly_rnd(0,0)(mpr-1 downto 0);-- + ((mpr-1 downto 1 => '0') & butterfly_st2(0,0)(1));  
      butterfly_out(1,0)(mpr-1 downto 0) <= butterfly_rnd(1,0)(mpr-1 downto 0);-- + ((mpr-1 downto 1 => '0') & butterfly_st2(1,0)(1));
      butterfly_out(2,0)(mpr-1 downto 0) <= butterfly_rnd(2,0)(mpr-1 downto 0);-- + ((mpr-1 downto 1 => '0') & butterfly_st2(2,0)(1));
      butterfly_out(3,0)(mpr-1 downto 0) <= butterfly_rnd(3,0)(mpr-1 downto 0);-- + ((mpr-1 downto 1 => '0') & butterfly_st2(3,0)(1));
      butterfly_out(0,1)(mpr-1 downto 0) <= butterfly_rnd(0,1)(mpr-1 downto 0);-- + ((mpr-1 downto 1 => '0') & butterfly_st2(0,1)(1));  
      butterfly_out(1,1)(mpr-1 downto 0) <= butterfly_rnd(1,1)(mpr-1 downto 0);-- + ((mpr-1 downto 1 => '0') & butterfly_st2(1,1)(1));
      butterfly_out(2,1)(mpr-1 downto 0) <= butterfly_rnd(2,1)(mpr-1 downto 0);-- + ((mpr-1 downto 1 => '0') & butterfly_st2(2,1)(1));
      butterfly_out(3,1)(mpr-1 downto 0) <= butterfly_rnd(3,1)(mpr-1 downto 0);-- + ((mpr-1 downto 1 => '0') & butterfly_st2(3,1)(1));


      gen_rounding_blk : for i in 0 to 3 generate
         u0 : asj_fft_pround
         generic map (     
                        widthin     => mpr+2,
                        widthout => mpr,
                        pipe      => 1
                     )
         port map ( 
                     global_clock_enable => global_clock_enable,
                     clk       => clk,
                     clken     => clken,
                     xin            => butterfly_st2(i,0),
                     yout        => butterfly_rnd(i,0)
                  ); 

         u1 : asj_fft_pround
         generic map (     
                        widthin     => mpr+2,
                        widthout => mpr,
                        pipe      => 1
                     )
         port map ( 
                     global_clock_enable => global_clock_enable,
                     clk       => clk,
                     clken     => clken,
                     xin            => butterfly_st2(i,1),
                     yout        => butterfly_rnd(i,1)
                  ); 

      end generate gen_rounding_blk;

   end generate gen_full_rnd;

   gen_fast_rnd : if(fullrnd=0) generate

      reg_fast:process(clk,global_clock_enable,clken,butterfly_st2)is
      begin
         if((rising_edge(clk) and global_clock_enable='1'))then
            if(clken='1') then
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
      end process reg_fast;
   end generate gen_fast_rnd;

  -----------------------------------------------------------------------------------------------
  -- Non-continuos
  -- applies for all N and all architectures except Streaming 512,1024
  -----------------------------------------------------------------------------------------------

   gen_disc : if(cont=0) generate

      data_1_real_o <= dr1o;
      data_2_real_o <= dr2o;
      data_3_real_o <= dr3o;
      data_4_real_o <= dr4o;
      data_1_imag_o <= di1o;
      data_2_imag_o <= di2o;
      data_3_imag_o <= di3o;
      data_4_imag_o <= di4o;
      alt_slb_o <= slb;
      gain_out_1pt <= (others=>'0');


      delay_next_pass : asj_fft_tdl_bit 
      generic map( 
                    del   => 1
                 )
      port map(   
                 global_clock_enable => global_clock_enable,
                 clk   => clk,
                 data_in  => next_pass,
                 data_out    => next_pass_d
              );



      bfp_detect :asj_fft_bfp_o
      generic map(
                    nps      => nps,
                    bfp     => bfp,
                    nume    => nume,
                    arch    => arch,
                    mpr      => mpr,
                    fpr     => fpr,
                    rbuspr  => rbuspr
                 )
      port map (
                  global_clock_enable => global_clock_enable,
                  clk         => clk,
                  reset       => reset,
                  next_pass => next_pass,
                  next_blk  => next_blk,
                  blk_done  => '0',
                  data_rdy  => clken,
                  gain_in_1pt   => gain_out_1pt,
                  real_bfp_0_in => dr1o,
                  real_bfp_1_in => dr2o,
                  real_bfp_2_in => dr3o,
                  real_bfp_3_in => dr4o,
                  imag_bfp_0_in => di1o,
                  imag_bfp_1_in => di2o,
                  imag_bfp_2_in => di3o,
                  imag_bfp_3_in => di4o,
                  lut_out => slb
               );


      bfp_scale : asj_fft_bfp_i 
      generic map(
                    mpr => mpr,
                    rbuspr=> 4*mpr,
                    arch => 1,
                    fpr => fpr
                 )
      port map(  clk         => clk,
                 global_clock_enable => global_clock_enable,
                        --reset     => reset,
                 real_bfp_0_in =>data_in(0,0), 
                 real_bfp_1_in =>data_in(1,0), 
                 real_bfp_2_in =>data_in(2,0), 
                 real_bfp_3_in =>data_in(3,0), 
                 imag_bfp_0_in =>data_in(0,1), 
                 imag_bfp_1_in =>data_in(1,1), 
                 imag_bfp_2_in =>data_in(2,1), 
                 imag_bfp_3_in =>data_in(3,1),  
                 bfp_factor    => alt_slb_i,
                 real_bfp_0_out =>data_in_sc(0,0),
                 real_bfp_1_out =>data_in_sc(1,0), 
                 real_bfp_2_out =>data_in_sc(2,0), 
                 real_bfp_3_out =>data_in_sc(3,0), 
                 imag_bfp_0_out =>data_in_sc(0,1),
                 imag_bfp_1_out =>data_in_sc(1,1),
                 imag_bfp_2_out =>data_in_sc(2,1),
                 imag_bfp_3_out =>data_in_sc(3,1)
              );

   end generate gen_disc;
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  --Streaming 512,1024
  -----------------------------------------------------------------------------------------------
   gen_cont : if(cont=1) generate

      data_1_real_o <= data_1_real_o_int;
      data_2_real_o <= data_2_real_o_int;
      data_3_real_o <= data_3_real_o_int;
      data_4_real_o <= data_4_real_o_int;
      data_1_imag_o <= data_1_imag_o_int;
      data_2_imag_o <= data_2_imag_o_int;
      data_3_imag_o <= data_3_imag_o_int;
      data_4_imag_o <= data_4_imag_o_int;

      alt_slb_o <= slb;
  --alt_slb_o <= (others=>'0');

      bfp_scale : asj_fft_bfp_i 
      generic map(
                    mpr => mpr,
                    rbuspr=> 4*mpr,
                    arch => 0,
                    fpr => fpr
                 )
      port map(  clk         => clk,
                 global_clock_enable => global_clock_enable,
                     --reset     => reset,
                 real_bfp_0_in =>data_in(0,0), 
                 real_bfp_1_in =>data_in(1,0), 
                 real_bfp_2_in =>data_in(2,0), 
                 real_bfp_3_in =>data_in(3,0), 
                 imag_bfp_0_in =>data_in(0,1), 
                 imag_bfp_1_in =>data_in(1,1), 
                 imag_bfp_2_in =>data_in(2,1), 
                 imag_bfp_3_in =>data_in(3,1),  
                 bfp_factor    => slb_nm1,
                 real_bfp_0_out =>data_in_sc(0,0),
                 real_bfp_1_out =>data_in_sc(1,0), 
                 real_bfp_2_out =>data_in_sc(2,0), 
                 real_bfp_3_out =>data_in_sc(3,0), 
                 imag_bfp_0_out =>data_in_sc(0,1),
                 imag_bfp_1_out =>data_in_sc(1,1),
                 imag_bfp_2_out =>data_in_sc(2,1),
                 imag_bfp_3_out =>data_in_sc(3,1)
              );

      output_delay:process(clk,global_clock_enable,reset,dr1o,dr2o,dr3o,dr4o,di1o,di2o,di3o,di4o)is
      begin
         if((rising_edge(clk) and global_clock_enable='1'))then
            for i in 3 downto 1 loop
               for j in 0 to 1 loop
                  for k in 0 to 3 loop
                     do_tdl(k,j,i)(mpr-1 downto 0) <= do_tdl(k,j,i-1)(mpr-1 downto 0);
                  end loop;
               end loop;
            end loop;
            do_tdl(0,0,0)(mpr-1 downto 0) <= dr1o;
            do_tdl(1,0,0)(mpr-1 downto 0) <= dr2o;
            do_tdl(2,0,0)(mpr-1 downto 0) <= dr3o;
            do_tdl(3,0,0)(mpr-1 downto 0) <= dr4o;
            do_tdl(0,1,0)(mpr-1 downto 0) <= di1o;
            do_tdl(1,1,0)(mpr-1 downto 0) <= di2o;
            do_tdl(2,1,0)(mpr-1 downto 0) <= di3o;
            do_tdl(3,1,0)(mpr-1 downto 0) <= di4o;
         end if;
      end process output_delay;              

      bfp_scale_1pt : asj_fft_bfp_i 
      generic map(
                    mpr => mpr,
                    rbuspr=> 4*mpr,
                    arch => 0,
                    fpr => fpr
                 )
      port map(  clk         => clk,
                 global_clock_enable => global_clock_enable,
                     --reset     => reset,
                 real_bfp_0_in =>do_tdl(0,0,3), 
                 real_bfp_1_in =>do_tdl(1,0,3),
                 real_bfp_2_in =>do_tdl(2,0,3),
                 real_bfp_3_in =>do_tdl(3,0,3),
                 imag_bfp_0_in =>do_tdl(0,1,3),
                 imag_bfp_1_in =>do_tdl(1,1,3),
                 imag_bfp_2_in =>do_tdl(2,1,3),
                 imag_bfp_3_in =>do_tdl(3,1,3),
                 bfp_factor => slb_1pt,
                 real_bfp_0_out =>data_1_real_o_int,
                 real_bfp_1_out =>data_2_real_o_int, 
                 real_bfp_2_out =>data_3_real_o_int, 
                 real_bfp_3_out =>data_4_real_o_int, 
                 imag_bfp_0_out =>data_1_imag_o_int,
                 imag_bfp_1_out =>data_2_imag_o_int,
                 imag_bfp_2_out =>data_3_imag_o_int,
                 imag_bfp_3_out =>data_4_imag_o_int
              );

      bfp_detect :asj_fft_bfp_o
      generic map(
                    nps      => nps,
                    bfp     => bfp,
                    nume    => nume,
                    mpr      => mpr,
                    fpr     => fpr,
                    arch    => arch,
                    rbuspr  => rbuspr
                 )
      port map (
                  global_clock_enable => global_clock_enable,
                  clk         => clk,
                  reset       => reset,
                  next_pass => next_pass_vec(2),
                  next_blk  => next_blk,
                  blk_done  => blk_done_vec(2),
                  data_rdy  => clken,
                  gain_in_1pt   => gain_out_4pts,
                  real_bfp_0_in => dr1o,
                  real_bfp_1_in => dr2o,
                  real_bfp_2_in => dr3o,
                  real_bfp_3_in => dr4o,
                  imag_bfp_0_in => di1o,
                  imag_bfp_1_in => di2o,
                  imag_bfp_2_in => di3o,
                  imag_bfp_3_in => di4o,
                  lut_out => slb
               );

      bfp_detect_1pt :asj_fft_bfp_o_1pt
      generic map(
                    mpr      => mpr,
                    bfp     => bfp,
                    fpr     => fpr,
                    rbuspr  => rbuspr
                 )
      port map (
                  global_clock_enable => global_clock_enable,
                  clk         => clk,
                  reset       => reset,
                  next_pass => next_pass_vec(1),
                  data_rdy  => enable_op,
                  real_bfp_0_in => data_1_real_o_int,
                  real_bfp_1_in => data_2_real_o_int,
                  real_bfp_2_in => data_3_real_o_int,
                  real_bfp_3_in => data_4_real_o_int,
                  imag_bfp_0_in => data_1_imag_o_int,
                  imag_bfp_1_in => data_2_imag_o_int,
                  imag_bfp_2_in => data_3_imag_o_int,
                  imag_bfp_3_in => data_4_imag_o_int,
                  gain_out => gain_out
               );


      gain_four_points:process(clk,global_clock_enable,sdft,gain_out)is
      begin
         if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
               gain_out_4pts <=(others=>'0');
            else
               case sdft is
                  when ENABLE_DFT_O=>
                     gain_out_4pts <= (others=>'0');
                  when ENABLE_BFP_O=>
                     gain_out_4pts <= gain_out_4pts or gain_out;
                  when DISABLE_DFT_O=> 
                     gain_out_4pts <= gain_out_4pts or gain_out;
                  when others=>
                     gain_out_4pts <= gain_out_4pts or gain_out;
               end case;   
            end if;
         end if;
      end process gain_four_points;




      slb_nm1 <= alt_slb_i and not(2 downto 0 => block_dft_i_en);
      slb_1pt <= alt_slb_i and (2 downto 0 => scale_dft_o_en);


      ctrl:process(clk,global_clock_enable,sdft)is
      begin
         if((rising_edge(clk) and global_clock_enable='1'))then
            enable_op<=scale_dft_o_en;
            case sdft is
               when IDLE =>
                  block_dft_i_en <= '0';
                  scale_dft_o_en <= '0';
               when BLOCK_DFT_I =>
                  block_dft_i_en <= '1';
                  scale_dft_o_en <= '0';
               when WAIT_FOR_OUTPUT =>
                  block_dft_i_en <= '1';
                  scale_dft_o_en <= '0';
               when ENABLE_DFT_O =>
                  if(gap_reg='1') then
                     block_dft_i_en <= '1';
                     scale_dft_o_en <= '0';
                  else
                     scale_dft_o_en <= '1';
                     block_dft_i_en <= '0';
                  end if;
               when ENABLE_BFP_O =>
                  scale_dft_o_en <= '1';
                  block_dft_i_en <= '0';
               when DISABLE_DFT_O =>
                  scale_dft_o_en <= '0';
                  block_dft_i_en <= '0';
               when others =>
                  block_dft_i_en <= '0';
                  scale_dft_o_en <= '0';
            end case;
         end if;
      end process ctrl;

-----------------------------------------------------------------------------------------------
-- State Machine Controller for input/output switching to BFP_DETECT and SCALING
-----------------------------------------------------------------------------------------------
      state_transition_counter:process(clk,global_clock_enable,state_cnt,sdft)is
      begin
         if((rising_edge(clk) and global_clock_enable='1'))then
            case sdft is
               when IDLE=>
                  state_cnt <= (others=>'0');
               when BLOCK_DFT_I=>
                  state_cnt <= state_cnt + int2ustd(1,6);
               when WAIT_FOR_OUTPUT=>
                  state_cnt <= (others=>'0');
               when ENABLE_DFT_O =>
                  if(gap_reg='1') then
                     state_cnt <= state_cnt;
                  else
                     state_cnt <= state_cnt + int2ustd(1,6);
                  end if;
               when ENABLE_BFP_O =>
                  state_cnt <= state_cnt + int2ustd(1,6);
               when DISABLE_DFT_O =>
                  state_cnt <= state_cnt + int2ustd(1,6);
               when others=>
                  state_cnt <= state_cnt;
            end case;
         end if;
      end process state_transition_counter;

-- dft_state is (IDLE,BLOCK_DFT_I,WAIT_FOR_OUPUT,ENABLE_DFT_O,ENABLE_BFP_0,DISABLE_DFT_O);
      fsm_bfp_cont:process(clk,global_clock_enable,reset,next_pass,next_pass_vec,sdft)is
      begin
         if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
               sdft <= IDLE;
            else
               case sdft is
                  when IDLE =>
                     if(next_pass='1') then
                        sdft<=BLOCK_DFT_I;
                     else
                        sdft<=IDLE;
                     end if;
                  when BLOCK_DFT_I =>
                     if(state_cnt=int2ustd(13,6)) then
                        sdft<=WAIT_FOR_OUTPUT;
                     else
                        sdft<=BLOCK_DFT_I;
                     end if;
                  when WAIT_FOR_OUTPUT =>
                     sdft<=ENABLE_DFT_O;
                  when ENABLE_DFT_O =>
                     if(gap_reg='1') then
                        sdft<=ENABLE_DFT_O;
                     else
                        sdft<=ENABLE_BFP_O;
                     end if;
                  when ENABLE_BFP_O =>
                     if(state_cnt=int2ustd(14,6)) then
                        sdft<=DISABLE_DFT_O;
                     else
                        sdft<=ENABLE_BFP_O;
                     end if;
                  when DISABLE_DFT_O =>
                     sdft<=IDLE;
                  when others =>
                     sdft<=IDLE;
               end case;
            end if;
         end if;
      end process fsm_bfp_cont;
-----------------------------------------------------------------------------------------------
-- Bit-Shift Register
-----------------------------------------------------------------------------------------------
      np_vec:process(clk,global_clock_enable,reset,next_pass,next_pass_vec)is
      begin
         if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
               for i in 2 downto 0 loop
                  next_pass_vec(i) <= '0';
               end loop;
            else
               for i in 2 downto 1 loop
                  next_pass_vec(i) <= next_pass_vec(i-1);
               end loop;
               next_pass_vec(0) <= next_pass;
            end if;
         end if;
      end process np_vec;

      bd_vec:process(clk,global_clock_enable,reset,blk_done,blk_done_vec)is
      begin
         if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
               for i in 2 downto 0 loop
                  blk_done_vec(i) <= '0';
               end loop;
            else
               for i in 2 downto 1 loop
                  blk_done_vec(i) <= blk_done_vec(i-1);
               end loop;
               blk_done_vec(0) <= blk_done;
            end if;
         end if;
      end process bd_vec;

      delay_next_blk : asj_fft_tdl_bit
      generic map(
                    del => 26
                 )
      port map (
                  global_clock_enable => global_clock_enable,
                  clk => clk,
                  data_in => next_blk,
                  data_out => next_blk_d
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


   end generate gen_cont;
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------





   gen_unsc : if(new_scaling=0) generate 

      pipe_delay:process(clk,global_clock_enable,reset,reg_no_twiddle,butterfly_out_reg_sc)is
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
               reg_no_twiddle(0,0)(mpr-1 downto 0)  <= (butterfly_out(0,0)(mpr-1) & butterfly_out(0,0)(mpr-1 downto 1))+((mpr-1 downto 1 => '0') & (not(butterfly_out(0,0)(mpr-1)) and butterfly_out(0,0)(0)));
               reg_no_twiddle(0,1)(mpr-1 downto 0)  <= (butterfly_out(0,1)(mpr-1) & butterfly_out(0,1)(mpr-1 downto 1))+((mpr-1 downto 1 => '0') & (not(butterfly_out(0,1)(mpr-1)) and butterfly_out(0,1)(0)));
            end if;
         end if;
      end process pipe_delay;

   end generate gen_unsc;

  --gen_sc : if(new_scaling=1) generate 
  --
  --pipe_delay:process(clk,global_clock_enable,reset,reg_no_twiddle,butterfly_out_reg_sc)is
  --begin
  --if((rising_edge(clk) and global_clock_enable='1'))then
  --     if(reset='1') then
  --        for i in nstages-1 downto 0 loop
  --           for j in 1 downto 0 loop
  --              reg_no_twiddle(i,j) <= (others=> '0');
  --           end loop;   
  --        end loop;
  --     else
  --        for i in nstages-1 downto 1 loop
  --              reg_no_twiddle(i,0)(mpr-1 downto 0) <= reg_no_twiddle(i-1,0)(mpr-1 downto 0);
  --              reg_no_twiddle(i,1)(mpr-1 downto 0) <= reg_no_twiddle(i-1,1)(mpr-1 downto 0);
  --        end loop;
  --        reg_no_twiddle(0,0)(mpr-1 downto 0)  <= butterfly_out_reg_sc(0,0)(mpr-1) & butterfly_out_reg_sc(0,0)(mpr-1 downto 1);
  --        reg_no_twiddle(0,1)(mpr-1 downto 0)  <= butterfly_out_reg_sc(0,1)(mpr-1) & butterfly_out_reg_sc(0,1)(mpr-1 downto 1);
  --     end if;
  --  end if;
  --end process pipe_delay;
  --        
  --end generate gen_sc;



   dr1o <= reg_no_twiddle(nstages-1,0);
   di1o <= reg_no_twiddle(nstages-1,1);




  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  --gen_switched : if (switch=1) generate

   gen_da0 : if(dsp_arch=0) generate

      gen_canonic : if(mult_type=0) generate

         cm1 : asj_fft_cmult_can
         generic map( 
                       mpr=>mpr,
                       twr=>twr,
                       opr=>opr,
                       oprp1=>oprp1,
                       oprp2=>oprp2,
                       pipe=>pipe,
                       mult_imp => mult_imp

                    )
         port map(   clk      => clk,
                     global_clock_enable => global_clock_enable,
                     reset   => reset,
                     dataa    => butterfly_out(1,1),
                     datab    => butterfly_out(1,0),
                     datac    => twid_1_real,
                     datad    => twid_1_imag,
                     real_out => di2o,
                     imag_out => dr2o
                  );

         cm2 : asj_fft_cmult_can
         generic map( 
                       mpr=>mpr,
                       twr=>twr,
                       opr=>opr,
                       oprp1=>oprp1,
                       oprp2=>oprp2,
                       pipe=>pipe,
                       mult_imp => mult_imp
                    )
         port map(   clk      => clk,
                     global_clock_enable => global_clock_enable,
                     reset   => reset,
                     dataa    => butterfly_out(2,1),
                     datab    => butterfly_out(2,0),
                     datac    => twid_2_real,
                     datad    => twid_2_imag,
                     real_out => di3o,
                     imag_out => dr3o
                  );

         cm3 : asj_fft_cmult_can
         generic map( 
                       mpr=>mpr,
                       twr=>twr,
                       opr=>opr,
                       oprp1=>oprp1,
                       oprp2=>oprp2,
                       pipe=>pipe,
                       mult_imp => mult_imp
                    )
         port map(   clk      => clk,
                     global_clock_enable => global_clock_enable,
                     reset   => reset,
                     dataa    => butterfly_out(3,1),
                     datab    => butterfly_out(3,0),
                     datac    => twid_3_real,
                     datad    => twid_3_imag,
                     real_out => di4o,
                     imag_out => dr4o
                  );
      end generate gen_canonic;
   -----------------------------------------------------------------------------------------------
   --
   -----------------------------------------------------------------------------------------------
      gen_std : if(mult_type=1) generate

         cm1 : asj_fft_cmult_std
         generic map( 
                       device_family=>device_family,
                       mpr=>mpr,
                       twr=>twr,
                       mult_imp => mult_imp,
                       pipe=>pipe
                    )
         port map(   clk      => clk,
                     global_clock_enable => global_clock_enable,
                     reset   => reset,
                     dataa    => butterfly_out(1,1),
                     datab    => butterfly_out(1,0),
                     datac    => twid_1_real,
                     datad    => twid_1_imag,
                     real_out => di2o,
                     imag_out => dr2o
                  );

         cm2 : asj_fft_cmult_std
         generic map( 
                       device_family=>device_family,
                       mpr=>mpr,
                       twr=>twr,
                       mult_imp => mult_imp,
                       pipe=>pipe
                    )
         port map(   clk      => clk,
                     global_clock_enable => global_clock_enable,
                     reset   => reset,
                     dataa    => butterfly_out(2,1),
                     datab    => butterfly_out(2,0),
                     datac    => twid_2_real,
                     datad    => twid_2_imag,
                     real_out => di3o,
                     imag_out => dr3o
                  );

         cm3 : asj_fft_cmult_std
         generic map( 
                       device_family=>device_family,
                       mpr=>mpr,
                       twr=>twr,
                       mult_imp => mult_imp,
                       pipe=>pipe
                    )
         port map(   clk      => clk,
                     global_clock_enable => global_clock_enable,
                     reset   => reset,
                     dataa    => butterfly_out(3,1),
                     datab    => butterfly_out(3,0),
                     datac    => twid_3_real,
                     datad    => twid_3_imag,
                     real_out => di4o,
                     imag_out => dr4o
                  );
      end generate gen_std;

   end generate gen_da0;

  --end generate gen_switched;

  --gen_unswitched : if (switch=0) generate 
  --cm1 : asj_fft_cmult_can
  --generic map( 
  --                mpr=>mpr,
  --                twr=>twr,
  --                opr=>opr,
  --                oprp1=>oprp1,
  --                oprp2=>oprp2,
  --                pipe=>pipe,
  --                mult_imp => mult_imp
  --)
  --port map(    clk      => clk,
  --                reset   => reset,
  --                dataa    => butterfly_out(1,0),
  --                datab    => butterfly_out(1,1),
  --                datac    => twid_1_real,
  --                datad    => twid_1_imag,
  --                real_out => dr2o,
  --                imag_out => di2o
  --);
  --
  --cm2 : asj_fft_cmult_can
  --generic map( 
  --                mpr=>mpr,
  --                twr=>twr,
  --                opr=>opr,
  --                oprp1=>oprp1,
  --                oprp2=>oprp2,
  --                pipe=>pipe,
  --                mult_imp => mult_imp
  --)
  --port map(    clk      => clk,
  --                reset   => reset,
  --                dataa    => butterfly_out(2,0),
  --                datab    => butterfly_out(2,1),
  --                datac    => twid_2_real,
  --                datad    => twid_2_imag,
  --                real_out => dr3o,
  --                imag_out => di3o
  --);
  --
  --cm3 : asj_fft_cmult_can
  --generic map( 
  --                mpr=>mpr,
  --                twr=>twr,
  --                opr=>opr,
  --                oprp1=>oprp1,
  --                oprp2=>oprp2,
  --                pipe=>pipe,
  --                mult_imp => mult_imp
  --)
  --port map(    clk      => clk,
  --                reset   => reset,
  --                dataa    => butterfly_out(3,0),
  --                datab    => butterfly_out(3,1),
  --                datac    => twid_3_real,
  --                datad    => twid_3_imag,
  --                real_out => dr4o,
  --                imag_out => di4o
  --);
  --
  --end generate gen_unswitched;


   gen_da1 : if (dsp_arch=1) generate

      cm1 : apn_fft_cmult_cpx
      generic map(
                    mpr=>mpr,
                    twr=>twr,
                    pipe=>pipe
                 )
      port map(
                 clk         => clk,
                 global_clock_enable => global_clock_enable,
                 reset       => reset,
                 dataa        => butterfly_out(1,1),
                 datab        => butterfly_out(1,0),
                 datac        => twid_1_real,
                 datad        => twid_1_imag,
                 real_out    => di2o,
                 imag_out    => dr2o
              );

      cm2 : apn_fft_cmult_cpx
      generic map(
                    mpr=>mpr,
                    twr=>twr,
                    pipe=>pipe
                 )
      port map(
                 clk       => clk,
                 global_clock_enable => global_clock_enable,
                 reset       => reset,
                 dataa        => butterfly_out(2,1),
                 datab        => butterfly_out(2,0),
                 datac    => twid_2_real,
                 datad       => twid_2_imag,
                 real_out    => di3o,
                 imag_out    => dr3o
              );

      cm3 : apn_fft_cmult_cpx
      generic map(
                    mpr=>mpr,
                    twr=>twr,
                    pipe=>pipe
                 )
      port map(
                 clk       => clk,
                 global_clock_enable => global_clock_enable,
                 reset       => reset,
                 dataa       => butterfly_out(3,1),
                 datab        => butterfly_out(3,0),
                 datac        => twid_3_real,
                 datad        => twid_3_imag,
                 real_out    => di4o,
                 imag_out    => dr4o
              );

   end generate gen_da1;

   gen_da2 : if (dsp_arch=2) generate

      cm1 : apn_fft_cmult_cpx2
      generic map(
                    mpr=>mpr,
                    twr=>twr,
                    pipe=>pipe
                 )
      port map(
                 clk         => clk,
                 global_clock_enable => global_clock_enable,
                 reset       => reset,
                 dataa       => butterfly_out(1,1),
                 datab       => butterfly_out(1,0),
                 datac       => twid_1_real,
                 datad       => twid_1_imag,
                 real_out    => di2o,
                 imag_out    => dr2o
              );

      cm2 : apn_fft_cmult_cpx2
      generic map(
                    mpr=>mpr,
                    twr=>twr,
                    pipe=>pipe
                 )
      port map(
                 clk         => clk,
                 global_clock_enable => global_clock_enable,
                 reset       => reset,
                 dataa       => butterfly_out(2,1),
                 datab       => butterfly_out(2,0),
                 datac       => twid_2_real,
                 datad       => twid_2_imag,
                 real_out    => di3o,
                 imag_out    => dr3o
              );

      cm3 : apn_fft_cmult_cpx2
      generic map(
                    mpr=>mpr,
                    twr=>twr,
                    pipe=>pipe
                 )
      port map(
                 clk         => clk,
                 global_clock_enable => global_clock_enable,
                 reset       => reset,
                 dataa       => butterfly_out(3,1),
                 datab       => butterfly_out(3,0),
                 datac       => twid_3_real,
                 datad       => twid_3_imag,
                 real_out    => di4o,
                 imag_out    => dr4o
              );

   end generate gen_da2;


end dft_r4;
