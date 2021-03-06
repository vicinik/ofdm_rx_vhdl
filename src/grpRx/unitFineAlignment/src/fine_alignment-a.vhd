library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.LogDualisPack.all;

architecture Rtl of FineAlignment is

  constant cSymbolsUsedForPhase : natural := 32;
  
  type aState is (Init, Phase);
  
  type aFineAlignmentRegSet is record
    State   : aState;
    SumReal : signed(sample_bit_width_g + LogDualis(cSymbolsUsedForPhase) - 1 downto 0); 
    SumImag : signed(sample_bit_width_g + LogDualis(cSymbolsUsedForPhase) - 1 downto 0); 
    SymbolCounter : unsigned(LogDualis(raw_symbol_length_g) - 1 downto 0);
  end record aFineAlignmentRegSet;

  constant cInitFineAlignmentRegSet : aFineAlignmentRegSet := (
    State => Init,
    SumReal => (others => '0'),
    SumImag => (others => '0'),
    SymbolCounter => (others => '0')
    );

  signal R, NxR : aFineAlignmentRegSet;
  signal sPhase : signed(sample_bit_width_g + LogDualis(cSymbolsUsedForPhase) downto 0);
  
 begin
 
  Combinatorial: process(R, rx_symbols_i_fft_i, rx_symbols_q_fft_i, rx_symbols_fft_valid_i, rx_symbols_fft_start_i) is

    procedure pSumQuadrantValue (
      constant rx_symbol_i : in signed((sample_bit_width_g - 1) downto 0);
      constant rx_symbol_q : in signed((sample_bit_width_g - 1) downto 0);
      constant R : in aFineAlignmentRegSet;
      signal NxR : out aFineAlignmentRegSet
    ) is
      variable vSumReal : signed(sample_bit_width_g + LogDualis(cSymbolsUsedForPhase) - 1 downto 0) := (others => '0'); 
      variable vSumImag : signed(sample_bit_width_g + LogDualis(cSymbolsUsedForPhase) - 1 downto 0) := (others => '0');
    begin

      -- Check for new symbol -> init registers with new value
      if R.State = Init then
        vSumReal := (others => '0');
        vSumImag := (others => '0');
      else
        vSumReal := R.SumReal;
        vSumImag := R.SumImag;
      end if;

       -- first quadrant
      if (rx_symbol_i > 0) and (rx_symbol_q < 0) then
        NxR.SumReal <= vSumReal - rx_symbol_i;
        NxR.SumImag <= vSumImag + rx_symbol_q;
      -- third quadrant
      elsif (rx_symbol_i <= 0) and (rx_symbol_q <= 0) then
        NxR.SumReal <= vSumReal - rx_symbol_i;
        NxR.SumImag <= vSumImag - rx_symbol_q;
      -- second quadrant
      elsif (rx_symbol_i < 0) and (rx_symbol_q > 0) then
        NxR.SumReal <= vSumReal + rx_symbol_i;
        NxR.SumImag <= vSumImag - rx_symbol_q;
      else -- first quadrant
        NxR.SumReal <= vSumReal + rx_symbol_i;
        NxR.SumImag <= vSumImag + rx_symbol_q;
      end if;
    end pSumQuadrantValue;

  begin  -- process Combinatorial
    NxR <= R;

    case R.State is
      
      when Init  =>
        if rx_symbols_fft_start_i = '1' and rx_symbols_fft_valid_i = '1' then
          NxR.SymbolCounter <= (others => '0');
          pSumQuadrantValue(rx_symbols_i_fft_i, rx_symbols_q_fft_i, R, NxR);  
          NxR.State <= Phase;
        end if;
        
      when Phase =>
        -- Only look at cSymbolsUsedForPhase number of symbols for phase calculation
        if rx_symbols_fft_valid_i = '1' then
          if R.SymbolCounter /= (cSymbolsUsedForPhase - 1) then
            NxR.SymbolCounter <= R.SymbolCounter + to_unsigned(1, NxR.SymbolCounter'length);
            pSumQuadrantValue(rx_symbols_i_fft_i, rx_symbols_q_fft_i, R, NxR);  
          else
            NxR.State <= Init;
          end if;
        end if;
      when others => null;
    end case;
    
    
  end process Combinatorial;

  Registering: process (sys_clk_i, sys_rstn_i) is
  begin  -- process Registering
    if sys_rstn_i = '0' then            -- asynchronous reset (active low)
      R <= cInitFineAlignmentRegSet;
    elsif sys_clk_i'event and sys_clk_i = '1' then  -- rising clock edge
       R <= NxR;
      if sys_init_i = '1' then
        R <= cInitFineAlignmentRegSet;
      end if;
    end if;
  end process Registering;

  rx_symbols_i_o <= rx_symbols_i_fft_i;
  rx_symbols_q_o <= rx_symbols_q_fft_i;
  rx_symbols_valid_o <= rx_symbols_fft_valid_i;
  rx_symbols_start_o <= rx_symbols_fft_start_i;

  sPhase <= resize(R.SumImag - R.SumReal, sPhase'length);
  offset_inc_o <= '1' when (sPhase(sPhase'left) = '1') else '0';
  offset_dec_o <= '0' when (sPhase(sPhase'left) = '1') else '1';

end architecture;
