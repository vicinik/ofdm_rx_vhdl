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
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_dft_bfp_sgl.vhd#1 $ 
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


entity asj_fft_dft_bfp_sgl is
   generic (
      device_family : string;
      nps : integer :=1024;
      bfp : integer :=1;
      nume : integer :=1;
      mpr : integer := 16;  
      fpr : integer := 4;  
      mult_type : integer:=1;   
      mult_imp : integer:=0;                             
      dsp_arch : integer :=0;
      rbuspr : integer := 64; -- 4*mpr
      twr : integer := 16;
      nstages: integer := 7; -- pipe + 7
      pipe: integer := 1;
      rev : integer:=0;
      cont : integer :=0
   );
   port (
     global_clock_enable : in std_logic;
     clk                : in std_logic;
     clken         : in std_logic;
     reset              : in std_logic;
     next_pass     : in std_logic;
     next_blk      : in std_logic;
     sel_lpp       : in std_logic;
     alt_slb_i     : in std_logic_vector(2 downto 0);
     sel             : in std_logic_vector(1 downto 0);
     data_real_i : in std_logic_vector(mpr-1 downto 0);
     data_imag_i : in std_logic_vector(mpr-1 downto 0);
     twid_real  : in std_logic_vector(twr-1 downto 0);
     twid_imag  : in std_logic_vector(twr-1 downto 0);
     data_real_o : out std_logic_vector(mpr-1 downto 0);
     data_imag_o : out std_logic_vector(mpr-1 downto 0);
     alt_slb_o     : out std_logic_vector(2 downto 0)
     );
end asj_fft_dft_bfp_sgl;

architecture dft_r4 of asj_fft_dft_bfp_sgl is     

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


   -- last_pass_radix = 0 => radix 4
   -- last_pass_radix = 1 => radix 2
   constant last_pass_radix : integer :=(LOG4_CEIL(nps))-(LOG4_FLOOR(nps));

   constant switch : integer :=1;
   constant fullrnd : integer :=1;
   constant new_scaling : integer :=0;


   constant opr : integer :=mpr+twr;
   constant oprp1 : integer :=mpr+twr+1;
   constant oprp2 : integer :=mpr+twr+2;

   type   dft_state is (IDLE,ENABLE_DFT_O,ENABLE_BFP_O,DISABLE_DFT_O);
   signal sdft :  dft_state;

   type four_by_four_m  is array (0 to 3, 0 to 1) of std_logic_vector (mpr-1 downto 0);
   type four_by_four_m1 is array (0 to 1) of std_logic_vector (mpr+1 downto 0);
   type four_by_four_m2 is array (0 to 3, 0 to 1) of std_logic_vector (mpr+1 downto 0);

   type pipe_balancing_act is array (0 to nstages-1,0 to 1) of std_logic_vector (mpr-1 downto 0);
   type selector is array (0 to 15) of std_logic_vector (1 downto 0);
   signal butterfly_st1 : four_by_four_m;
   signal zero_vec : std_logic_vector(2 downto 0);
   signal dro : std_logic_vector(mpr-1 downto 0);
   signal dio : std_logic_vector(mpr-1 downto 0);


   signal data_1_real_o_int : std_logic_vector(mpr-1 downto 0);
   signal data_2_real_o_int : std_logic_vector(mpr-1 downto 0);
   signal data_3_real_o_int : std_logic_vector(mpr-1 downto 0);
   signal data_4_real_o_int : std_logic_vector(mpr-1 downto 0);
   signal data_1_imag_o_int : std_logic_vector(mpr-1 downto 0);
   signal data_2_imag_o_int : std_logic_vector(mpr-1 downto 0);
   signal data_3_imag_o_int : std_logic_vector(mpr-1 downto 0);
   signal data_4_imag_o_int : std_logic_vector(mpr-1 downto 0);

   signal data_real_i_sc : std_logic_vector(mpr-1 downto 0);
   signal data_imag_i_sc : std_logic_vector(mpr-1 downto 0);
   signal data_real_i_reg : std_logic_vector(mpr-1 downto 0);
   signal data_imag_i_reg : std_logic_vector(mpr-1 downto 0);


   signal x_1_real : std_logic_vector(mpr downto 0);
   signal x_2_real : std_logic_vector(mpr downto 0);
   signal x_3_real : std_logic_vector(mpr downto 0);
   signal x_4_real : std_logic_vector(mpr downto 0);
   signal x_1_imag : std_logic_vector(mpr downto 0);
   signal x_2_imag : std_logic_vector(mpr downto 0);
   signal x_3_imag : std_logic_vector(mpr downto 0);
   signal x_4_imag : std_logic_vector(mpr downto 0);
   signal x_1_real_held : std_logic_vector(mpr downto 0);
   signal x_1_real_held_1 : std_logic_vector(mpr downto 0);
   signal x_1_real_held_2 : std_logic_vector(mpr downto 0);
   signal x_1_real_held_3 : std_logic_vector(mpr downto 0);

   signal x_2_real_held : std_logic_vector(mpr downto 0);
   signal x_3_real_held : std_logic_vector(mpr downto 0);
   signal x_4_real_held : std_logic_vector(mpr downto 0);
   signal x_1_imag_held : std_logic_vector(mpr downto 0);
   signal x_2_imag_held : std_logic_vector(mpr downto 0);
   signal x_3_imag_held : std_logic_vector(mpr downto 0);
   signal x_4_imag_held : std_logic_vector(mpr downto 0);
   -- sign bits for butterfly add/subs
   -- Real Butterfly
   signal sr : std_logic_vector(2 downto 0);
   -- Imag Butterfly
   signal si : std_logic_vector(2 downto 0);
   -- temporary storage for Radix 2
   -- Real Butterfly
   signal srt : std_logic_vector(2 downto 0);
   -- Imag Butterfly
   signal sit : std_logic_vector(2 downto 0);

   signal result_x1_x3_real : std_logic_vector(mpr downto 0);
   signal result_x2_x4_real : std_logic_vector(mpr downto 0);
   signal result_x1_x3_imag : std_logic_vector(mpr downto 0);
   signal result_x2_x4_imag : std_logic_vector(mpr downto 0);

   signal result_x1_x3_real_se : std_logic_vector(mpr+1 downto 0);
   signal result_x2_x4_real_se : std_logic_vector(mpr+1 downto 0);
   signal result_x1_x3_imag_se : std_logic_vector(mpr+1 downto 0);
   signal result_x2_x4_imag_se : std_logic_vector(mpr+1 downto 0);

   signal butterfly_st_real : std_logic_vector(mpr+1 downto 0);
   signal butterfly_st_imag : std_logic_vector(mpr+1 downto 0);

   signal butterfly_real_rnd_r2 : std_logic_vector(mpr downto 0);
   signal butterfly_imag_rnd_r2 : std_logic_vector(mpr downto 0);   

   signal butterfly_real_rnd : std_logic_vector(mpr-1 downto 0);
   signal butterfly_imag_rnd : std_logic_vector(mpr-1 downto 0);   

   signal butterfly_real_sc : std_logic_vector(mpr-1 downto 0);
   signal butterfly_imag_sc : std_logic_vector(mpr-1 downto 0);   

   signal butterfly_real_reg_sc : std_logic_vector(mpr-1 downto 0);
   signal butterfly_imag_reg_sc : std_logic_vector(mpr-1 downto 0);   






   signal slb                : std_logic_vector(2 downto 0);
   signal slb_last          : std_logic_vector(2 downto 0);
   signal dual_eng_slb      : std_logic_vector(2 downto 0);
   signal slb_1pt           : std_logic_vector(2 downto 0);
   signal slb_nm1            : std_logic_vector(2 downto 0);
   signal gain_out_1pt      : std_logic_vector(fpr-1 downto 0);
   signal gain_out          : std_logic_vector(fpr-1 downto 0);
   signal next_pass_d        : std_logic;
   signal next_pass_d2       : std_logic;
   signal next_pass_d_vec       : std_logic_vector(5 downto 0) ;
   signal scale_dft_o_en    : std_logic;
   signal block_dft_i_en    : std_logic;


   signal rnd               : std_logic;
   signal blk_exp_acc       : std_logic_vector(fpr-1 downto 0);
   signal blk_exp            : std_logic_vector(fpr-1 downto 0);

   signal sel_arr           : selector;

   signal null_input_1        : std_logic;
   signal null_input_2        : std_logic;

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
   alt_slb_o <= slb;

   data_real_o <= dro;
   data_imag_o <= dio;

-- Signal Selector TDL
   sel_tdl:process(clk,global_clock_enable,reset,sel)is
   begin
      if((rising_edge(clk) and global_clock_enable='1'))then
         if(reset='1') then
            for i in 15 downto 0 loop
               sel_arr(i) <= (others=>'0');
            end loop;
         else
            for i in 15 downto 1 loop
               sel_arr(i) <= sel_arr(i-1);
            end loop;
            sel_arr(0) <= sel;
         end if;
      end if;
   end process sel_tdl;
      -----------------------------------------------------------------------------------------------
      -- Radix 4 Engine Input
      ----------------------------------------------------------------------------------------------- 
   gen_radix_4 : if(last_pass_radix=0) generate
         -----------------------------------------------------------------------------------------------
         -- For Single Engine, the outputs are read into the engine in normal order
         -- i.e. 0,N/4,N/2,3N/4
         -----------------------------------------------------------------------------------------------
      gen_normal_order : if(rev=0) generate

-- 4 Point DFT
         dft_of_4_pts_reg_demux:process(clk,global_clock_enable,reset,data_real_i,data_imag_i,sel)is
         begin
            if((rising_edge(clk) and global_clock_enable='1'))then
               if(reset='1') then
                  for i in 0 to 3 loop
                     for j in 0 to 1 loop
                        butterfly_st1(i,j)(mpr-1 downto 0) <= (others=>'0');
                     end loop;
                  end loop;
               else
                  case sel_arr(5)(1 downto 0) is
                     when "00" =>
                        butterfly_st1(0,0)(mpr-1 downto 0) <=   data_real_i_sc;--xr(1)
                        butterfly_st1(0,1)(mpr-1 downto 0) <=   data_imag_i_sc;--xi(1)
                     when "01" =>   
                        butterfly_st1(1,0)(mpr-1 downto 0) <=   data_real_i_sc;--xr(2)
                        butterfly_st1(1,1)(mpr-1 downto 0) <=   data_imag_i_sc;--xi(2)
                     when "10" =>
                        butterfly_st1(2,0)(mpr-1 downto 0) <=   data_real_i_sc;--xr(3)
                        butterfly_st1(2,1)(mpr-1 downto 0) <=   data_imag_i_sc;--xi(3)
                     when "11" =>
                        butterfly_st1(3,0)(mpr-1 downto 0) <=   data_real_i_sc;--xr(3)
                        butterfly_st1(3,1)(mpr-1 downto 0) <=   data_imag_i_sc;--xi(3)
                     when others =>
                        for i in 0 to 3 loop
                           for j in 0 to 1 loop
                              butterfly_st1(i,j)(mpr-1 downto 0) <= (others=>'0');
                           end loop;
                        end loop;
                  end case;
               end if;           
            end if;
         end process dft_of_4_pts_reg_demux;



         dft_of_4_pts_reg:process(clk,global_clock_enable,reset,data_real_i,data_imag_i,sel)is
         begin
            if((rising_edge(clk) and global_clock_enable='1'))then
               case sel_arr(9)(1 downto 0) is
                  when "00"=>
                     x_1_real_held <= sgn_ex(butterfly_st1(0,0),mpr,1);
                     x_2_real_held <= sgn_ex(butterfly_st1(1,0),mpr,1);
                     x_3_real_held <= sgn_ex(butterfly_st1(2,0),mpr,1);
                     x_4_real_held <= sgn_ex(butterfly_st1(3,0),mpr,1);
                     x_1_imag_held <= sgn_ex(butterfly_st1(0,1),mpr,1);
                     x_2_imag_held <= sgn_ex(butterfly_st1(1,1),mpr,1);
                     x_3_imag_held <= sgn_ex(butterfly_st1(2,1),mpr,1);
                     x_4_imag_held <= sgn_ex(butterfly_st1(3,1),mpr,1);
                  when "01"=>
                     x_1_real_held <=  x_1_real_held;
                     x_2_real_held <=  x_2_imag_held;
                     x_3_real_held <=  x_3_real_held;
                     x_4_real_held <=  x_4_imag_held;
                     x_1_imag_held <=  x_1_imag_held;
                     x_2_imag_held <=  x_2_real_held;
                     x_3_imag_held <=  x_3_imag_held;
                     x_4_imag_held <=  x_4_real_held;
                  when "10"=>
                     x_1_real_held <=  x_1_real_held;
                     x_2_real_held <=  x_2_imag_held;
                     x_3_real_held <=  x_3_real_held;
                     x_4_real_held <=  x_4_imag_held;
                     x_1_imag_held <=  x_1_imag_held;
                     x_2_imag_held <=  x_2_real_held;
                     x_3_imag_held <=  x_3_imag_held;
                     x_4_imag_held <=  x_4_real_held;
                  when "11"=>
                     x_1_real_held <=  x_1_real_held;
                     x_2_real_held <=  x_2_imag_held;
                     x_3_real_held <=  x_3_real_held;
                     x_4_real_held <=  x_4_imag_held;
                     x_1_imag_held <=  x_1_imag_held;
                     x_2_imag_held <=  x_2_real_held;
                     x_3_imag_held <=  x_3_imag_held;
                     x_4_imag_held <=  x_4_real_held;
                  when others=>
                     x_1_real_held <=  x_1_real_held;
                     x_2_real_held <=  x_2_imag_held;
                     x_3_real_held <=  x_3_real_held;
                     x_4_real_held <=  x_4_imag_held;
                     x_1_imag_held <=  x_1_imag_held;
                     x_2_imag_held <=  x_2_real_held;
                     x_3_imag_held <=  x_3_imag_held;
                     x_4_imag_held <=  x_4_real_held;
               end case;               
            end if;
         end process dft_of_4_pts_reg;
      end generate gen_normal_order;

         -----------------------------------------------------------------------------------------------
         -- For Dual Engine, for one of engines the RAM outputs are read into one engine 
         -- in normal order but in a reversed scheme for the second engine
         --
         -- i.e. N/2,3N/4,0,N/4 if rev=1
         -----------------------------------------------------------------------------------------------
      gen_rev_order : if(rev=1) generate

-- 4 Point DFT
         dft_of_4_pts_reg_demux:process(clk,global_clock_enable,reset,data_real_i,data_imag_i,sel)is
         begin
            if((rising_edge(clk) and global_clock_enable='1'))then
               if(reset='1') then
                  for i in 0 to 3 loop
                     for j in 0 to 1 loop
                        butterfly_st1(i,j)(mpr-1 downto 0) <= (others=>'0');
                     end loop;
                  end loop;
               else
                  case sel_arr(5)(1 downto 0) is
                     when "00" =>
                        butterfly_st1(2,0)(mpr-1 downto 0) <=   data_real_i_sc;--xr(1)
                        butterfly_st1(2,1)(mpr-1 downto 0) <=   data_imag_i_sc;--xi(1)
                     when "01" =>   
                        butterfly_st1(3,0)(mpr-1 downto 0) <=   data_real_i_sc;--xr(2)
                        butterfly_st1(3,1)(mpr-1 downto 0) <=   data_imag_i_sc;--xi(2)
                     when "10" =>
                        butterfly_st1(0,0)(mpr-1 downto 0) <=   data_real_i_sc;--xr(3)
                        butterfly_st1(0,1)(mpr-1 downto 0) <=   data_imag_i_sc;--xi(3)
                     when "11" =>
                        butterfly_st1(1,0)(mpr-1 downto 0) <=   data_real_i_sc;--xr(3)
                        butterfly_st1(1,1)(mpr-1 downto 0) <=   data_imag_i_sc;--xi(3)
                     when others =>
                        for i in 0 to 3 loop
                           for j in 0 to 1 loop
                              butterfly_st1(i,j)(mpr-1 downto 0) <= (others=>'0');
                           end loop;
                        end loop;
                  end case;
               end if;           
            end if;
         end process dft_of_4_pts_reg_demux;



         dft_of_4_pts_reg:process(clk,global_clock_enable,reset,data_real_i,data_imag_i,sel)is
         begin
            if((rising_edge(clk) and global_clock_enable='1'))then
               case sel_arr(9)(1 downto 0) is
                  when "00"=>
                     x_1_real_held <= sgn_ex(butterfly_st1(0,0),mpr,1);
                     x_2_real_held <= sgn_ex(butterfly_st1(1,0),mpr,1);
                     x_3_real_held <= sgn_ex(butterfly_st1(2,0),mpr,1);
                     x_4_real_held <= sgn_ex(butterfly_st1(3,0),mpr,1);
                     x_1_imag_held <= sgn_ex(butterfly_st1(0,1),mpr,1);
                     x_2_imag_held <= sgn_ex(butterfly_st1(1,1),mpr,1);
                     x_3_imag_held <= sgn_ex(butterfly_st1(2,1),mpr,1);
                     x_4_imag_held <= sgn_ex(butterfly_st1(3,1),mpr,1);
                  when "01"=>
                     x_1_real_held <=  x_1_real_held;
                     x_2_real_held <=  x_2_imag_held;
                     x_3_real_held <=  x_3_real_held;
                     x_4_real_held <=  x_4_imag_held;
                     x_1_imag_held <=  x_1_imag_held;
                     x_2_imag_held <=  x_2_real_held;
                     x_3_imag_held <=  x_3_imag_held;
                     x_4_imag_held <=  x_4_real_held;
                  when "10"=>
                     x_1_real_held <=  x_1_real_held;
                     x_2_real_held <=  x_2_imag_held;
                     x_3_real_held <=  x_3_real_held;
                     x_4_real_held <=  x_4_imag_held;
                     x_1_imag_held <=  x_1_imag_held;
                     x_2_imag_held <=  x_2_real_held;
                     x_3_imag_held <=  x_3_imag_held;
                     x_4_imag_held <=  x_4_real_held;
                  when "11"=>
                     x_1_real_held <=  x_1_real_held;
                     x_2_real_held <=  x_2_imag_held;
                     x_3_real_held <=  x_3_real_held;
                     x_4_real_held <=  x_4_imag_held;
                     x_1_imag_held <=  x_1_imag_held;
                     x_2_imag_held <=  x_2_real_held;
                     x_3_imag_held <=  x_3_imag_held;
                     x_4_imag_held <=  x_4_real_held;
                  when others=>
                     x_1_real_held <=  x_1_real_held;
                     x_2_real_held <=  x_2_imag_held;
                     x_3_real_held <=  x_3_real_held;
                     x_4_real_held <=  x_4_imag_held;
                     x_1_imag_held <=  x_1_imag_held;
                     x_2_imag_held <=  x_2_real_held;
                     x_3_imag_held <=  x_3_imag_held;
                     x_4_imag_held <=  x_4_real_held;
               end case;               
            end if;
         end process dft_of_4_pts_reg;
      end generate gen_rev_order;      







      dft_of_4_pts_sign:process(clk,global_clock_enable,reset,sel_arr)is
      begin
         if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
               sr <= (others=>'0');
               si <= (others=>'0');
            else
               case sel_arr(9)(1 downto 0) is
                  when "00" =>
                     sr<="110";
                     si<="111";     
                  when "01" =>   
                     sr<="001";
                     si<="001";     
                  when "10" =>
                     sr<="111";
                     si<="110";     
                  when "11" =>
                     sr<="000";
                     si<="000";     
                  when others =>
                     sr<="000";
                     si<="000";     
               end case;
            end if;           
         end if;
      end process dft_of_4_pts_sign;

   end generate gen_radix_4;
   -----------------------------------------------------------------------------------------------
   -----------------------------------------------------------------------------------------------
   -- Radix 4 with Radix 2 last pass
   -----------------------------------------------------------------------------------------------
   -----------------------------------------------------------------------------------------------
   gen_radix_2 : if(last_pass_radix=1) generate

      -----------------------------------------------------------------------------------------------
      -- For Single Engine, the outputs are read into the engine in normal order
      -- i.e. 0,N/4,N/2,3N/4
      -----------------------------------------------------------------------------------------------
      -- 4 Point DFT
      gen_normal_order : if(rev=0) generate
         dft_of_4_pts_reg_demux:process(clk,global_clock_enable,reset,data_real_i,data_imag_i,sel)is
         begin
            if((rising_edge(clk) and global_clock_enable='1'))then
               if(reset='1') then
                  for i in 0 to 3 loop
                     for j in 0 to 1 loop
                        butterfly_st1(i,j)(mpr-1 downto 0) <= (others=>'0');
                     end loop;
                  end loop;
               else
                  case sel_arr(5)(1 downto 0) is
                     when "00" =>
                        butterfly_st1(0,0)(mpr-1 downto 0) <=   data_real_i_sc;--xr(1)
                        butterfly_st1(0,1)(mpr-1 downto 0) <=   data_imag_i_sc;--xi(1)
                     when "01" =>   
                        butterfly_st1(1,0)(mpr-1 downto 0) <=   data_real_i_sc;--xr(2)
                        butterfly_st1(1,1)(mpr-1 downto 0) <=   data_imag_i_sc;--xi(2)
                     when "10" =>
                        butterfly_st1(2,0)(mpr-1 downto 0) <=   data_real_i_sc;--xr(3)
                        butterfly_st1(2,1)(mpr-1 downto 0) <=   data_imag_i_sc;--xi(3)
                     when "11" =>
                        butterfly_st1(3,0)(mpr-1 downto 0) <=   data_real_i_sc;--xr(3)
                        butterfly_st1(3,1)(mpr-1 downto 0) <=   data_imag_i_sc;--xi(3)
                     when others =>
                        for i in 0 to 3 loop
                           for j in 0 to 1 loop
                              butterfly_st1(i,j)(mpr-1 downto 0) <= (others=>'0');
                           end loop;
                        end loop;
                  end case;
               end if;           
            end if;
         end process dft_of_4_pts_reg_demux;
      end generate gen_normal_order;

      gen_rev_order : if(rev=1) generate
         dft_of_4_pts_reg_demux:process(clk,global_clock_enable,reset,data_real_i,data_imag_i,sel)is
         begin
            if((rising_edge(clk) and global_clock_enable='1'))then
               if(reset='1') then
                  for i in 0 to 3 loop
                     for j in 0 to 1 loop
                        butterfly_st1(i,j)(mpr-1 downto 0) <= (others=>'0');
                     end loop;
                  end loop;
               else
                  case sel_arr(5)(1 downto 0) is
                     when "00" =>
                        butterfly_st1(2,0)(mpr-1 downto 0) <=   data_real_i_sc;--xr(1)
                        butterfly_st1(2,1)(mpr-1 downto 0) <=   data_imag_i_sc;--xi(1)
                     when "01" =>   
                        butterfly_st1(3,0)(mpr-1 downto 0) <=   data_real_i_sc;--xr(2)
                        butterfly_st1(3,1)(mpr-1 downto 0) <=   data_imag_i_sc;--xi(2)
                     when "10" =>
                        butterfly_st1(0,0)(mpr-1 downto 0) <=   data_real_i_sc;--xr(3)
                        butterfly_st1(0,1)(mpr-1 downto 0) <=   data_imag_i_sc;--xi(3)
                     when "11" =>
                        butterfly_st1(1,0)(mpr-1 downto 0) <=   data_real_i_sc;--xr(3)
                        butterfly_st1(1,1)(mpr-1 downto 0) <=   data_imag_i_sc;--xi(3)
                     when others =>
                        for i in 0 to 3 loop
                           for j in 0 to 1 loop
                              butterfly_st1(i,j)(mpr-1 downto 0) <= (others=>'0');
                           end loop;
                        end loop;
                  end case;
               end if;           
            end if;
         end process dft_of_4_pts_reg_demux;
      end generate gen_rev_order;




      dft_of_4_pts_reg:process(clk,global_clock_enable,reset,data_real_i,data_imag_i,sel)is
      begin
         if((rising_edge(clk) and global_clock_enable='1'))then
            if(sel_arr(9)(1 downto 0)="00") then
               x_1_real_held <= sgn_ex(butterfly_st1(0,0),mpr,1);
               x_2_real_held <= sgn_ex(butterfly_st1(1,0),mpr,1);
               x_3_real_held <= sgn_ex(butterfly_st1(2,0),mpr,1);
               x_4_real_held <= sgn_ex(butterfly_st1(3,0),mpr,1);
               x_1_imag_held <= sgn_ex(butterfly_st1(0,1),mpr,1);
               x_2_imag_held <= sgn_ex(butterfly_st1(1,1),mpr,1);
               x_3_imag_held <= sgn_ex(butterfly_st1(2,1),mpr,1);
               x_4_imag_held <= sgn_ex(butterfly_st1(3,1),mpr,1);
            else
               x_1_real_held <=  x_1_real_held;
               x_2_real_held <=  x_2_imag_held;
               x_3_real_held <=  x_3_real_held;
               x_4_real_held <=  x_4_imag_held;
               x_1_imag_held <=  x_1_imag_held;
               x_2_imag_held <=  x_2_real_held;
               x_3_imag_held <=  x_3_imag_held;
               x_4_imag_held <=  x_4_real_held;
            end if;
         end if;
      end process dft_of_4_pts_reg;


      -----------------------------------------------------------------------------------------------
      -- Sign bit for 3 adders
      -----------------------------------------------------------------------------------------------
      -- Note : Based on sel_arr(8) so that registered choice of last pass sign bits is possible
      -----------------------------------------------------------------------------------------------
      gen_se_ss : if(nume=1) generate
         sign_select:process(clk,global_clock_enable,srt,sit,sel_lpp)is
         begin
            if((rising_edge(clk) and global_clock_enable='1'))then
               if(sel_lpp='1') then
                  case sel_arr(8)(1 downto 0) is
                     when "00" =>
                        sr<="001";
                        si<="001";     
                     when "01" =>   
                        sr<="111";
                        si<="111";     
                     when "10" =>
                        sr<="111";
                        si<="111";     
                     when "11" =>
                        sr<="001";
                        si<="001";     
                     when others =>
                        sr<="111";
                        si<="111";           
                  end case;
               else
                  sr<=srt;
                  si<=sit;
               end if;
               null_input_1 <= not(sel_lpp) or srt(2);
            end if;
         end process sign_select;
      end generate gen_se_ss;

      gen_de_ss : if(nume=2) generate
         sign_select:process(clk,global_clock_enable,srt,sit,sel_lpp)is
         begin
            if((rising_edge(clk) and global_clock_enable='1'))then
               if(sel_lpp='1') then
                  case sel_arr(8)(1 downto 0) is
                     when "00" =>
                        sr<="001";
                        si<="001";     
                     when "01" =>   
                        sr<="111";
                        si<="111";     
                     when "10" =>
                        sr<="111";
                        si<="111";     
                     when "11" =>
                        sr<="000";
                        si<="001";     
                     when others =>
                        sr<="111";
                        si<="111";           
                  end case;
               else
                  sr<=srt;
                  si<=sit;
               end if;
               null_input_1 <= not(sel_lpp) or srt(2);
            end if;
         end process sign_select;
      end generate gen_de_ss;



      dft_of_4_pts_sign:process(clk,global_clock_enable,reset,sel_arr)is
      begin
         if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
               srt(2 downto 1) <= (others=>'0');
               sit(2 downto 1) <= (others=>'0');
            else
               case sel_arr(8)(1 downto 0) is
                  when "00" =>
                     srt(2 downto 1)<="11";
                     sit(2 downto 1)<="11";     
                  when "01" =>   
                     srt(2 downto 1)<="00";
                     sit(2 downto 1)<="00";     
                  when "10" =>
                     srt(2 downto 1)<="11";
                     sit(2 downto 1)<="11";     
                  when "11" =>
                     srt(2 downto 1)<="00";
                     sit(2 downto 1)<="00";     
                  when others =>
                     srt(2 downto 1)<="00";
                     sit(2 downto 1)<="00";           
               end case;
            end if;           
         end if;
      end process dft_of_4_pts_sign;

      dft_of_4_pts_sign_lsb:process(clk,global_clock_enable,reset,sel_arr)is
      begin
         if((rising_edge(clk) and global_clock_enable='1'))then
            if(reset='1') then
               srt(0) <= '1';
               sit(0) <= '1';
            else
               case sel_arr(9)(1 downto 0) is
                  when "00" =>
                     srt(0)<='0';
                     sit(0)<='1';      
                  when "01" =>   
                     srt(0)<='1';
                     sit(0)<='1';      
                  when "10" =>
                     srt(0)<='1';
                     sit(0)<='0';      
                  when "11" =>
                     srt(0)<='0';
                     sit(0)<='0';      
                  when others =>
                     srt(0)<='1';
                     sit(0)<='1';            
               end case;
            end if;           
         end if;
      end process dft_of_4_pts_sign_lsb;

   end generate gen_radix_2;


-----------------------------------------------------------------------------------------------
-- Compute Gr[,]
-----------------------------------------------------------------------------------------------
--    add_x1r_x3r :  lpm_add_sub
--          generic map(lpm_width=> mpr+1,
--                            lpm_pipeline => 1,
--                            lpm_representation=>"SIGNED"
--                   )
--          port map(   clock=>clk,
--                            dataa=>x_1_real_held,
--                            datab=>x_3_real_held,
--                            add_sub=> sr(2),
--                            --cout=>cout,
--                            result=>result_x1_x3_real
--                      );

   add_x1r_x3r:process(clk,global_clock_enable,reset)is
   begin  -- process add_x1r_x3r
      if reset = '1' then             -- asynchronous reset (active high)
         result_x1_x3_real <= (others => '0');
      elsif(rising_edge(clk) and global_clock_enable='1')then--risingclockedge
         if sr(2) = '1' then
            result_x1_x3_real <= x_1_real_held + x_3_real_held;
         else
            result_x1_x3_real <= x_1_real_held - x_3_real_held;
         end if;
      end if;
   end process add_x1r_x3r;

--    add_x2r_x4r :  lpm_add_sub
--          generic map(lpm_width=> mpr+1,
--                            lpm_pipeline => 1,
--                            lpm_representation=>"SIGNED"
--                   )
--          port map(   clock=>clk,
--                            dataa=>x_2_real_held,
--                            datab=>x_4_real_held,
--                            add_sub=> sr(1),
--                            --cout=>cout,
--                            result=>result_x2_x4_real
--                      );

   add_x2r_x4r:process(clk,global_clock_enable,reset)is
   begin  -- process add_x2r_x4r
      if reset = '1' then             -- asynchronous reset (active high)
         result_x2_x4_real <= (others => '0');
      elsif(rising_edge(clk) and global_clock_enable='1')then--risingclockedge
         if sr(1) = '1' then
            result_x2_x4_real <= x_2_real_held + x_4_real_held;
         else
            result_x2_x4_real <= x_2_real_held - x_4_real_held;
         end if;
      end if;
   end process add_x2r_x4r;

   gen_res_xr_r4 : if(last_pass_radix=0) generate              
      result_x1_x3_real_se <= sgn_ex(result_x1_x3_real,mpr+1,1);
      result_x2_x4_real_se <= sgn_ex(result_x2_x4_real,mpr+1,1);                       
   end generate gen_res_xr_r4;


   gen_res_xr_r2 : if(last_pass_radix=1) generate  
      lpp_sw_r:process(clk,global_clock_enable,result_x1_x3_real,result_x2_x4_real,null_input_1,sel_lpp)is
      begin
         if((rising_edge(clk) and global_clock_enable='1'))then
            if(sel_lpp='0') then
               result_x1_x3_real_se <= sgn_ex(result_x1_x3_real,mpr+1,1);     
               result_x2_x4_real_se <= sgn_ex(result_x2_x4_real,mpr+1,1);        
            else
               if(null_input_1='0') then
                  result_x1_x3_real_se <= (result_x1_x3_real & '0');     
                  result_x2_x4_real_se <= (others=> '0');         
               else
                  result_x1_x3_real_se <= (others=> '0');     
                  result_x2_x4_real_se <= (result_x2_x4_imag & '0');       
               end if;
            end if;
         end if;
      end process lpp_sw_r;
   end generate gen_res_xr_r2;

--    add_x1r_x2r_x3r_x4r : lpm_add_sub
--          generic map(lpm_width=> mpr+2,
--                            lpm_pipeline => 1,
--                            lpm_representation=>"SIGNED"
--                   )
--          port map(   clock=>clk,
--                            dataa=>result_x1_x3_real_se,
--                            datab=>result_x2_x4_real_se,
--                            add_sub=> sr(0),
--                            result=>butterfly_st_real
--                      );

   add_x1r_x2r_x3r_x4r:process(clk,global_clock_enable,reset)is
   begin  -- process add_x1r_x2r_x3r_x4r
      if reset = '1' then             -- asynchronous reset (active high)
         butterfly_st_real <= (others => '0');
      elsif(rising_edge(clk) and global_clock_enable='1')then--risingclockedge
         if sr(0) = '1' then
            butterfly_st_real <= result_x1_x3_real_se + result_x2_x4_real_se;
         else
            butterfly_st_real <= result_x1_x3_real_se - result_x2_x4_real_se;
         end if;
      end if;
   end process add_x1r_x2r_x3r_x4r;

-----------------------------------------------------------------------------------------------
-- Compute Gi[,]
-----------------------------------------------------------------------------------------------

--       add_x1i_x3i :  lpm_add_sub
--          generic map(lpm_width=> mpr+1,
--                            lpm_pipeline => 1,
--                            lpm_representation=>"SIGNED"
--                   )
--          port map(   clock=>clk,
--                            dataa=>x_1_imag_held,
--                            datab=>x_3_imag_held,
--                            add_sub=> si(2),
--                            result=>result_x1_x3_imag
--                      );

   add_x1i_x3i:process(clk,global_clock_enable,reset)is
   begin  -- process add_x1i_x3i
      if reset = '1' then             -- asynchronous reset (active high)
         result_x1_x3_imag <= (others => '0');
      elsif(rising_edge(clk) and global_clock_enable='1')then--risingclockedge
         if si(2) = '1' then
            result_x1_x3_imag <= x_1_imag_held + x_3_imag_held;
         else
            result_x1_x3_imag <= x_1_imag_held - x_3_imag_held;
         end if;
      end if;
   end process add_x1i_x3i;

--    add_x2i_x4i :  lpm_add_sub
--          generic map(lpm_width=> mpr+1,
--                            lpm_pipeline => 1,
--                            lpm_representation=>"SIGNED"
--                   )
--          port map(   clock=>clk,
--                            dataa=>x_2_imag_held,
--                            datab=>x_4_imag_held,
--                            add_sub=> si(1),
--                            result=>result_x2_x4_imag
--                      );

-- purpose: 
   add_x2i_x4i:process(clk,global_clock_enable,reset)is
   begin  -- process add_x2i_x4i
      if reset = '1' then             -- asynchronous reset (active high)
         result_x2_x4_imag <= (others => '0');
      elsif(rising_edge(clk) and global_clock_enable='1')then--risingclockedge
         if si(1) = '1' then
            result_x2_x4_imag <= x_2_imag_held + x_4_imag_held;
         else
            result_x2_x4_imag <= x_2_imag_held - x_4_imag_held;
         end if;
      end if;
   end process add_x2i_x4i;

   gen_res_xi_r4 : if(last_pass_radix=0) generate                 
      result_x1_x3_imag_se <= sgn_ex(result_x1_x3_imag,mpr+1,1);
      result_x2_x4_imag_se <= sgn_ex(result_x2_x4_imag,mpr+1,1);                       
   end generate gen_res_xi_r4;

   gen_res_xi_r2 : if(last_pass_radix=1) generate  

      lpp_sw_i:process(clk,global_clock_enable,result_x1_x3_imag,result_x2_x4_imag,null_input_1,sel_lpp)is
      begin
         if((rising_edge(clk) and global_clock_enable='1'))then
            if(sel_lpp='0') then
               result_x1_x3_imag_se <= sgn_ex(result_x1_x3_imag,mpr+1,1);     
               result_x2_x4_imag_se <= sgn_ex(result_x2_x4_imag,mpr+1,1);        
            else
               if(null_input_1='0') then
                  result_x1_x3_imag_se <= (result_x1_x3_imag & '0');     
                  result_x2_x4_imag_se <= (others=> '0');         
               else
                  result_x1_x3_imag_se <= (others=> '0');     
                  result_x2_x4_imag_se <= (result_x2_x4_real & '0');       
               end if;
            end if;
         end if;
      end process lpp_sw_i;
   end generate gen_res_xi_r2;


--    add_x1i_x2i_x3i_x4i : lpm_add_sub
--          generic map(lpm_width=> mpr+2,
--                            lpm_pipeline => 1,
--                            lpm_representation=>"SIGNED"
--                   )
--          port map(   clock=>clk,
--                            dataa=>result_x1_x3_imag_se,
--                            datab=>result_x2_x4_imag_se,
--                            add_sub=> si(0),
--                            result=>butterfly_st_imag
--                      );

   add_x1i_x2i_x3i_x4i:process(clk,global_clock_enable,reset)is
   begin  -- process add_x1i_x2i_x3i_x4i
      if reset = '1' then             -- asynchronous reset (active high)
         butterfly_st_imag <= (others => '0');
      elsif(rising_edge(clk) and global_clock_enable='1')then--risingclockedge
         if si(0) = '1' then
            butterfly_st_imag <= result_x1_x3_imag_se + result_x2_x4_imag_se;
         else
            butterfly_st_imag <= result_x1_x3_imag_se - result_x2_x4_imag_se;
         end if;
      end if;
   end process add_x1i_x2i_x3i_x4i;

  -----------------------------------------------------------------------------------------------                   
  -----------------------------------------------------------------------------------------------


   gen_full_rnd : if(fullrnd=1) generate

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
                  xin            => butterfly_st_real,
                  yout        => butterfly_real_rnd
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
                  xin            => butterfly_st_imag,
                  yout        => butterfly_imag_rnd
               ); 



   end generate gen_full_rnd;



     -----------------------------------------------------------------------------------------------
     -- Block Floating Point Dynamic Range Detection
     -----------------------------------------------------------------------------------------------

   gain_out_1pt <= (others=>'0'); 

   bfp_detect :asj_fft_bfp_o
   generic map(
                 nps      => nps,
                 bfp     => bfp,
                 nume    => nume,
                 mpr      => mpr,
                 fpr     => fpr,
                 arch    => 3,
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
               real_bfp_0_in => dro,
               real_bfp_1_in => (others=>'0'),
               real_bfp_2_in => (others=>'0'),
               real_bfp_3_in => (others=>'0'),
               imag_bfp_0_in => dio,
               imag_bfp_1_in => (others=>'0'),
               imag_bfp_2_in => (others=>'0'),
               imag_bfp_3_in => (others=>'0'),
               lut_out => slb
            );

     -----------------------------------------------------------------------------------------------
     -- Block Floating Point Barrel Shifter
     -----------------------------------------------------------------------------------------------

   bfp_scale : asj_fft_bfp_i 
   generic map(
                 mpr => mpr,
                 arch => 3,
                 rbuspr=> 4*mpr,
                 fpr => fpr
              )
   port map(  clk         => clk,
              global_clock_enable => global_clock_enable,
                        --reset     => reset,
              real_bfp_0_in =>data_real_i, 
              real_bfp_1_in =>(others=>'0'), 
              real_bfp_2_in =>(others=>'0'), 
              real_bfp_3_in =>(others=>'0'), 
              imag_bfp_0_in =>data_imag_i, 
              imag_bfp_1_in =>(others=>'0'), 
              imag_bfp_2_in =>(others=>'0'), 
              imag_bfp_3_in =>(others=>'0'),  
              bfp_factor    =>alt_slb_i,  
              real_bfp_0_out =>data_real_i_sc,
              real_bfp_1_out =>open, 
              real_bfp_2_out =>open, 
              real_bfp_3_out =>open, 
              imag_bfp_0_out =>data_imag_i_sc,
              imag_bfp_1_out =>open,
              imag_bfp_2_out =>open,
              imag_bfp_3_out =>open
           );


   gen_da0 : if(dsp_arch=0) generate

  -----------------------------------------------------------------------------------------------
  -- Canonically Reduced Complex Multiplier 
  -----------------------------------------------------------------------------------------------

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
                     dataa    => butterfly_imag_rnd,
                     datab    => butterfly_real_rnd,
                     datac    => twid_real,
                     datad    => twid_imag,
                     real_out => dio,
                     imag_out => dro
                  );


      end generate gen_canonic;
   -----------------------------------------------------------------------------------------------
   -- Standard (4-mult) Complex Multiplier
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
                     dataa    => butterfly_imag_rnd,
                     datab    => butterfly_real_rnd,
                     datac    => twid_real,
                     datad    => twid_imag,
                     real_out => dio,
                     imag_out => dro
                  );

      end generate gen_std;

   end generate gen_da0;

  -----------------------------------------------------------------------------------------------
  -- Stratix V Complex Multiplier
  -----------------------------------------------------------------------------------------------

   gen_da1 : if (dsp_arch=1) generate

      cm1 : apn_fft_cmult_cpx
      generic map( 
                    mpr=>mpr,
                    twr=>twr,
                    pipe=>pipe
                 )
      port map(
                 clk   => clk,
                 global_clock_enable => global_clock_enable,
                 reset   => reset,
                 dataa    => butterfly_imag_rnd,
                 datab    => butterfly_real_rnd,
                 datac    => twid_real,
                 datad    => twid_imag,
                 real_out => dio,
                 imag_out => dro
              );

   end generate gen_da1;

  -----------------------------------------------------------------------------------------------
  -- Arria V / Cyclone V Complex Multiplier
  -----------------------------------------------------------------------------------------------

   gen_da2 : if (dsp_arch=2) generate

      cm1 : apn_fft_cmult_cpx2
      generic map( 
                    mpr=>mpr,
                    twr=>twr,
                    pipe=>pipe
                 )
      port map(
                 clk   => clk,
                 global_clock_enable => global_clock_enable,
                 reset   => reset,
                 dataa    => butterfly_imag_rnd,
                 datab    => butterfly_real_rnd,
                 datac    => twid_real,
                 datad    => twid_imag,
                 real_out => dio,
                 imag_out => dro
              );

   end generate gen_da2;

end dft_r4;











