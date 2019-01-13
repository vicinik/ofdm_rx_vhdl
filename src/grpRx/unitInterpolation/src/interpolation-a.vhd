architecture Rtl of Interpolation is

	----------------------------------------------------------
	-- 						TYPES 							--
	----------------------------------------------------------

	type aState is (Init, WaitSample2, WaitSample3, CalcDerived, UpSampling, CalcSample, Done);

	type aComplexSample is record
		I : signed(sample_bit_width_g - 1 downto 0);	-- real Anteil
		Q : signed(sample_bit_width_g - 1 downto 0);	-- imag Anteil
	end record;

	type aData is record
		x0 : aComplexSample;	
		x1 : aComplexSample;	
		x2 : aComplexSample;
	end record;

	type aDerives is record
		Q : signed(sample_bit_width_g - 1 downto 0);		
		Q_i : signed(sample_bit_width_g downto 0);		--erste Ableitung imag
		Q_ii : signed(sample_bit_width_g + 2 downto 0);	-- zweite Ableitung imag
		I : signed(sample_bit_width_g - 1 downto 0);		
		I_i : signed(sample_bit_width_g downto 0);		-- erste Ableitung real
		I_ii : signed(sample_bit_width_g + 2 downto 0);	-- zweite Ableitung real
	end record;

	type aInterpolationReg is record
		State : aState;
		Derives : aDerives;
		Data : aData;
		--Delay : unsigned(3 downto 0);
		--Offset : unsigned(3 downto 0);
		Result : aComplexSample;
		Count : unsigned((osr_g - 1) downto 0);
		Valid : std_ulogic;
	end record;

	----------------------------------------------------------
	-- 						CONSTANTS 						--
	----------------------------------------------------------

	 constant cInitReg : aInterpolationReg := (
		State => Init,
		Derives => (others => ( others => '0')),
		Data => (others => (others => (others => '0'))),
		Result => (others => (others => '0')),
		Count => "0000",
		Valid => '0'

	);

	----------------------------------------------------------
	-- 						SIGNALES 						--
	----------------------------------------------------------

	signal Reg, NxrReg : aInterpolationReg;


begin


  Interpolation1 : process (sys_clk_i, sys_rstn_i)
  begin
	if sys_rstn_i = '0' then 
		Reg <= cInitReg;
	-- TODO Init System
	elsif rising_edge(sys_clk_i) then
		if sys_init_i = '1' then
			-- TODO Init System
		else
			Reg <= NxrReg;
		end if;
	end if;
  end process;

	fsm: process (Reg, rx_data_valid_i, rx_data_q_i, rx_data_i_i, interp_mode_i, rx_data_delay_i)
		variable f, fi, fii, count, tmp, result : signed((sample_bit_width_g + 2)*2+1 downto 0) := (others => '0');
		--variable tmp : signed((sample_bit_width_g + 2)*2+1 downto 0) := (others => '0');
		--variable fi : signed(sample_bit_width_g + 2 downto 0) := (others => '0'); 
		--variable fii : signed(sample_bit_width_g + 2 downto 0) := (others => '0');
	begin
		NxrReg <= Reg;	   

		rx_data_i_osr_o <= Reg.Result.I;    	
        rx_data_q_osr_o <= Reg.Result.Q;
        rx_data_osr_valid_o <= Reg.Valid;

		case Reg.State is


			when Init =>
				if rx_data_valid_i = '1' then
					NxrReg.Data.x0.Q <= rx_data_q_i;
					NxrReg.Data.x0.I <= rx_data_i_i;
					NxrReg.State <= WaitSample2;
				end if;


			when WaitSample2 => 
				if rx_data_valid_i = '1' then
					NxrReg.Data.x0.Q <= rx_data_q_i;
					NxrReg.Data.x0.I <= rx_data_i_i;
					NxrReg.Data.x1 <= Reg.Data.x0;
					NxrReg.State <= WaitSample3;
				end if;


			when WaitSample3 =>
				if rx_data_valid_i = '1' then
					NxrReg.Data.x0.Q <= rx_data_q_i;
					NxrReg.Data.x0.I <= rx_data_i_i;
					NxrReg.Data.x1 <= Reg.Data.x0;
					NxrReg.Data.x2 <= Reg.Data.x1;
					NxrReg.State <= CalcDerived;
				end if;


			when CalcDerived =>
				NxrReg.Derives.Q <= Reg.Data.x2.Q;
				NxrReg.Derives.I <= Reg.Data.x2.I;
				NxrReg.Derives.Q_i <= (('0' & Reg.Data.x1.Q) - ('0' & Reg.Data.x2.Q))/16; -- erste Ableitung real
				NxrReg.Derives.I_i <= ('0' & Reg.Data.x1.I) - ('0' & Reg.Data.x2.I);	-- erste Ableitung imag
				NxrReg.Derives.Q_ii <= (("000" & Reg.Data.x0.Q) - shift_left(("000" & Reg.Data.x1.Q),1) + ("000" & Reg.Data.x2.Q))/16/16; -- zweite Ableitung real
				NxrReg.Derives.I_ii <= ("000" & Reg.Data.x0.I) - shift_left(("000" & Reg.Data.x1.I),1) + ("000" & Reg.Data.x2.I); -- zweite Ableitung imag

				if interp_mode_i = '0' then -- OversamplingRate necessary
					NxrReg.State <= Upsampling;
				else -- no oversampling necessary, because alignment has been done yet
					NxrReg.State <= CalcSample;
				end if;



			when Upsampling => -- Outputs all UpSamples for detecting Coarse ALignment

					if Reg.Count = (shift_left(to_unsigned(1,osr_g),osr_g) - 1) then
						NxrReg.Valid <= '0';
						NxrReg.State <= Done;   												 	
					end if;
					
					f := (others => '0');	
					fi := (others => '0');
					fii := (others => '0');	
					count := (others => '0');
					tmp := (others => '0');

					f(sample_bit_width_g - 1 downto 0) := Reg.Derives.Q;	
					fi(sample_bit_width_g  downto 0) := Reg.Derives.Q_i;
					fii(sample_bit_width_g + 2 downto 0) := Reg.Derives.Q_ii;	
					count((osr_g - 1) downto 0) := signed(Reg.Count);


					--tmp := shift_right(fii,1)(sample_bit_width_g + 2 downto 0)  * count(sample_bit_width_g + 2 downto 0)-1 ;
					--tmp := tmp(sample_bit_width_g + 2 downto 0) *16;
					--result := f + fi + fii + count;
					--result := f + (fi-tmp(sample_bit_width_g + 2 downto 0));--;
					--tmp := tmp(sample_bit_width_g + 2 downto 0) * count(sample_bit_width_g + 2 downto 0)-1 ;
					--result := result + tmp;
					--(f1-f2/2*osr)*(k-1)
					tmp := (fi - fii/2);
					tmp := tmp((sample_bit_width_g + 2) downto 0) * count((sample_bit_width_g + 2) downto 0);
					result := f + tmp;
					--(f2/2) * (k-1)^2
					tmp := fii/2;
					tmp := tmp((sample_bit_width_g + 2) downto 0) * count((sample_bit_width_g + 2) downto 0);
					tmp := tmp((sample_bit_width_g + 2) downto 0) * count((sample_bit_width_g + 2) downto 0);
					 
					result := result + tmp;
					NxrReg.Result.Q <= result(sample_bit_width_g - 1 downto 0);
					--NxrReg.Result.Q <= result(sample_bit_width_g - 1 downto 0);
					--NxrReg.Result.Q <= Reg.Derives.Q + (("00" & Reg.Derives.Q_i)-shift_right(Reg.Derives.Q_ii,1))(sample_bit_width_g - 1 downto 0); -- * signed(Reg.Count)); -- + (shift_right(Reg.Derives.Q_ii,1)) * (signed(Reg.Count)*signed(Reg.Count));
					--NxrReg.Result.I <= Reg.Derives.I + ( Reg.Derives.I_i-shift_right(Reg.Derives.I_ii,1) * signed(Reg.Count))  + (shift_right(Reg.Derives.I_ii,1)) * (signed(Reg.Count)*signed(Reg.Count));

					NxrReg.Valid <= '1';
					NxrReg.Count <= Reg.Count + 1;


			when CalcSample => -- Outputs only one Sample with XY Delay From FineAlignment

					f := (others => '0');	
					fi := (others => '0');
					fii := (others => '0');	
					count := (others => '0');
					tmp := (others => '0');

					f(sample_bit_width_g - 1 downto 0) := Reg.Derives.Q;	
					fi(sample_bit_width_g  downto 0) := Reg.Derives.Q_i;
					fii(sample_bit_width_g + 2 downto 0) := Reg.Derives.Q_ii;	
					count((osr_g - 1) downto 0) := signed(rx_data_delay_i);

					tmp := (fi - fii/2);
					tmp := tmp((sample_bit_width_g + 2) downto 0) * count((sample_bit_width_g + 2) downto 0);
					result := f + tmp;
					--(f2/2) * (k-1)^2
					tmp := fii/2;
					tmp := tmp((sample_bit_width_g + 2) downto 0) * count((sample_bit_width_g + 2) downto 0);
					tmp := tmp((sample_bit_width_g + 2) downto 0) * count((sample_bit_width_g + 2) downto 0);
					 
					result := result + tmp;
					NxrReg.Result.Q <= result(sample_bit_width_g - 1 downto 0);
					--NxrReg.Result.Q <= result(sample_bit_width_g - 1 downto 0);
					--NxrReg.Result.Q <= Reg.Derives.Q + (("00" & Reg.Derives.Q_i)-shift_right(Reg.Derives.Q_ii,1))(sample_bit_width_g - 1 downto 0); -- * signed(Reg.Count)); -- + (shift_right(Reg.Derives.Q_ii,1)) * (signed(Reg.Count)*signed(Reg.Count));
					--NxrReg.Result.I <= Reg.Derives.I + ( Reg.Derives.I_i-shift_right(Reg.Derives.I_ii,1) * signed(Reg.Count))  + (shift_right(Reg.Derives.I_ii,1)) * (signed(Reg.Count)*signed(Reg.Count));

					NxrReg.Valid <= '1';
					NxrReg.State <= Done;

			when Done =>
				if rx_data_valid_i = '1' then
					NxrReg.Data.x0.Q <= rx_data_q_i;
					NxrReg.Data.x0.I <= rx_data_i_i;
					NxrReg.Data.x1 <= Reg.Data.x0;
					NxrReg.Data.x2 <= Reg.Data.x1;
					NxrReg.State <= CalcDerived;
				end if;	

				NxrReg.Count <= (others => '0');
				NxrReg.valid <= '0';	


			when others => NULL;
		end case;

	end process fsm;

rx_data_i_osr_o <= Reg.Result.I;
rx_data_q_osr_o <= Reg.Result.Q;




end architecture;