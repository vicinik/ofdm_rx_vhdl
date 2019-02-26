library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.STD_LOGIC_SIGNED.all;

package UpSampling is
	function Multiply32 (L,R: UNSIGNED) return UNSIGNED;
	function Multiply32 (L : SIGNED; R : UNSIGNED) return SIGNED;
	function Multiply16 (L,R: UNSIGNED) return UNSIGNED;
	function Multiply16 (L : SIGNED; R : UNSIGNED) return SIGNED;
	function Add32 (L,R: SIGNED) return SIGNED;
	function Add16 (L,R: SIGNED) return SIGNED;
	function Sub32 (L,R: SIGNED) return SIGNED;
	function Sub16 (L,R: SIGNED) return SIGNED;
	function GetSample (RegCount: UNSIGNED; osr_g,sample_bit_width_g: NATURAL; f, fi, fii : SIGNED) return SIGNED;

end UpSampling;

package body UpSampling is

	function Multiply32 (L,R: UNSIGNED) return UNSIGNED is
		variable tmp : UNSIGNED(63 downto 0) := (others => '0');
	begin
		tmp := L*R;
		return tmp(31 downto 0);
	end Multiply32;


	function Multiply32 (L : SIGNED; R : UNSIGNED) return SIGNED is
		variable left, right : SIGNED(31 downto 0) := (others => '0');
		variable res : SIGNED(63 downto 0) := (others => '0');
		variable tmp : std_ulogic_vector(31 downto 0) := (others => '0');
	begin
		left := resize(L,32);
		tmp(R'length-1 downto 0) := std_ulogic_vector(R);
		right := signed(tmp);
		res := left * right;
		return res(31 downto 0);
		
		--return resize(left * right,32);
	end Multiply32;
	
	function Multiply16 (L,R: UNSIGNED) return UNSIGNED is
		variable tmp : UNSIGNED(31 downto 0) := (others => '0');
	begin
		tmp := L*R;
		return tmp(15 downto 0);
	end Multiply16;
	
	function Multiply16 (L : SIGNED; R : UNSIGNED) return SIGNED is
		variable left, right : SIGNED(15 downto 0) := (others => '0');
		variable res : SIGNED(31 downto 0) := (others => '0');
		variable tmp : std_ulogic_vector(15 downto 0) := (others => '0');
	begin
		left := resize(L,16);
		tmp(R'length-1 downto 0) := std_ulogic_vector(R);
		right := signed(tmp);
		res := left * right;
		return res(15 downto 0);
		
		--return resize(left * right,32);
	end Multiply16;


	function Add32 (L,R: SIGNED) return SIGNED is
	begin
		return resize(L+R,32);
	end Add32;
	
	function Add16 (L,R: SIGNED) return SIGNED is
	begin
		return resize(L+R,16);
	end Add16;


	function Sub32 (L,R: SIGNED) return SIGNED is
	begin
		return resize(L-R,32);
	end Sub32;
	
		function Sub16 (L,R: SIGNED) return SIGNED is
	begin
		return resize(L-R,16);
	end Sub16;


	
	function GetSample (RegCount: UNSIGNED; osr_g,sample_bit_width_g: NATURAL; f, fi, fii : SIGNED) return SIGNED is
		variable tmp1, tmp2 : signed(31 downto 0) := (others => '0');
		variable tmp1_16, tmp2_16 : signed(15 downto 0) := (others => '0');
		variable count : unsigned(31 downto 0) := (others => '0');	
		variable oversamplingRate : unsigned(osr_g downto 0) := (others => '0');
	begin

		 count(osr_g-1 downto 0) := RegCount;

		 --y_out(k) = f0 + (f1-f2/2*osr)*(k-1) + (f2/2) * (k-1)^2;

		 --(f1-f2/2*osr)*(k-1)
		 -- f2/2
		 tmp1 := shift_right(fii,1);
		 --f2/2*osr
		 tmp1 := shift_left(tmp1,osr_g);
		 --(f1-f2/2*osr)
		 tmp1 := Sub32(fi,tmp1);
		 --(f1-f2/2*osr)*(k-1)
		 tmp1_16 := Multiply16(tmp1(15 downto 0), Count(15 downto 0));


		 --(f2/2) * (k-1)^2;
		 tmp2_16 := Multiply16(shift_right(fii,1)(15 downto 0),Multiply16(Count(15 downto 0),Count(15 downto 0))(15 downto 0));
	 
		 --y_out(k) = f0 + (f1-f2/2*osr)*(k-1) + (f2/2) * (k-1)^2;
		 return resize((Add16(f(15 downto 0),Add16(tmp1_16,tmp2_16))),sample_bit_width_g);

	end GetSample;
	
    
end UpSampling;