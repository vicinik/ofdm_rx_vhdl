library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.STD_LOGIC_SIGNED.all;

package UpSampling is
	function Multiply32 (L,R: UNSIGNED) return UNSIGNED;
	function Multiply32 (L : SIGNED; R : UNSIGNED) return SIGNED;
	function Add32 (L,R: SIGNED) return SIGNED;
	function Sub32 (L,R: SIGNED) return SIGNED;
	function GetSample (RegCount: UNSIGNED; osr_g,sample_bit_width_g: NATURAL; f, fi, fii : SIGNED) return SIGNED;

end UpSampling;

package body UpSampling is

	function Multiply32 (L,R: UNSIGNED) return UNSIGNED is
	begin
		return resize(L * R,32); 
	end Multiply32;


	function Multiply32 (L : SIGNED; R : UNSIGNED) return SIGNED is
		variable left, right : SIGNED(31 downto 0) := (others => '0');
		variable tmp : std_ulogic_vector(31 downto 0) := (others => '0');
	begin
		left := L;
		tmp(R'length-1 downto 0) := std_ulogic_vector(R);
		right := signed(tmp);
		return resize(left * right,32);
	end Multiply32;


	function Add32 (L,R: SIGNED) return SIGNED is
	begin
		return resize(L+R,32);
	end Add32;


	function Sub32 (L,R: SIGNED) return SIGNED is
	begin
		return resize(L-R,32);
	end Sub32;


	
	function GetSample (RegCount: UNSIGNED; osr_g,sample_bit_width_g: NATURAL; f, fi, fii : SIGNED) return SIGNED is
		variable tmp1, tmp2 : signed(31 downto 0) := (others => '0');
		variable count : unsigned(31 downto 0) := (others => '0');	
		variable oversamplingRate : unsigned(osr_g downto 0) := (others => '0');
	begin

		--count := (others => '0');
		--tmp1 := (others => '0');
		--tmp2 := (others => '0');
		 count(osr_g-1 downto 0) := RegCount;
		 oversamplingRate := to_unsigned(2**osr_g,oversamplingRate'length);

		 --y_out(k) = f0 + (f1-f2/2*osr)*(k-1) + (f2/2) * (k-1)^2;

		 --(f1-f2/2*osr)*(k-1)
		 -- f2/2
		 tmp1 := shift_right(fii,1);
		 --f2/2*osr
		 tmp1 := Multiply32(tmp1,oversamplingRate);
		 --(f1-f2/2*osr)
		 tmp1 := Sub32(fi,tmp1);
		 --(f1-f2/2*osr)*(k-1)
		 tmp1 := Multiply32(tmp1, Count);


		 --(f2/2) * (k-1)^2;
		 tmp2 := Multiply32(shift_right(fii,1),Multiply32(Count,Count));
	 


		 --y_out(k) = f0 + (f1-f2/2*osr)*(k-1) + (f2/2) * (k-1)^2;
		 return resize(Add32(f,Add32(tmp1,tmp2)),sample_bit_width_g);

	end GetSample;
	
    
end UpSampling;