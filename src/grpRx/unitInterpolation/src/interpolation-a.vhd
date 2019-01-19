library work;
use work.UpSampling.all;

architecture Rtl of Interpolation is

	----------------------------------------------------------
	-- 						TYPES 							--
	----------------------------------------------------------

	type aState is (Init, WaitSample2, WaitSample3, CalcDerived, UpSampling, Done);

	type aComplexSample is record
		I : signed(sample_bit_width_g - 1 downto 0);	
		Q : signed(sample_bit_width_g - 1 downto 0);
	end record;

	type aData is record
		x0 : aComplexSample;	
		x1 : aComplexSample;	
		x2 : aComplexSample;
	end record;

	type aDerives is record
		Q : signed(31 downto 0);		
		Q_i : signed(31 downto 0);		--erste Ableitung
		Q_ii : signed(31 downto 0);		-- zweite Ableitung
		I : signed(31 downto 0);		
		I_i : signed(31 downto 0);
		I_ii : signed(31 downto 0);	
	end record;

	type aInterpolationReg is record
		State : aState;
		Derives : aDerives;
		Data : aData;
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
	elsif rising_edge(sys_clk_i) then
		if sys_init_i = '1' then
			Reg <= cInitReg;
		else
			Reg <= NxrReg;
		end if;
	end if;
  end process;

	fsm: process (Reg, rx_data_valid_i, rx_data_q_i, rx_data_i_i)
	begin
		NxrReg <= Reg;	   


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
				NxrReg.Derives.Q <= resize(Reg.Data.x2.Q,32);
				NxrReg.Derives.I <= resize(Reg.Data.x2.I,32);
				NxrReg.Derives.Q_i <= Sub32(Reg.Data.x1.Q,Reg.Data.x2.Q)/(2**osr_g); -- erste Ableitung real
				NxrReg.Derives.I_i <= Sub32(Reg.Data.x1.I,Reg.Data.x2.I)/(2**osr_g);	-- erste Ableitung imag
				NxrReg.Derives.I_ii <= Add32(Sub32(Reg.Data.x0.Q,2*Reg.Data.x1.Q),Reg.Data.x2.Q)/((2**osr_g)*(2**osr_g)); -- zweite Ableitung real
				NxrReg.Derives.Q_ii <= Add32(Sub32(Reg.Data.x0.Q,2*Reg.Data.x1.Q),Reg.Data.x2.Q)/((2**osr_g)*(2**osr_g)); -- zweite Ableitung imag


				NxrReg.State <= Upsampling;



			when Upsampling => -- Outputs all UpSamples for detecting Coarse ALignment

					if Reg.Count = (shift_left(to_unsigned(1,osr_g),osr_g) - 1) then
						NxrReg.Valid <= '0';
						NxrReg.State <= Done;   												 	
					end if;
					

					--y_out(k) = f0 + (f1-f2/2*osr)*(k-1) + (f2/2) * (k-1)^2;
					NxrReg.Result.Q <= GetSample(Reg.Count,osr_g,sample_bit_width_g,Reg.Derives.Q,Reg.Derives.Q_i,Reg.Derives.Q_ii);
					NxrReg.Result.I <= GetSample(Reg.Count,osr_g,sample_bit_width_g,Reg.Derives.I,Reg.Derives.I_i,Reg.Derives.I_ii);
					NxrReg.Valid <= '1';
					NxrReg.Count <= Reg.Count + 1;


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
rx_data_osr_valid_o <= Reg.Valid;


end architecture;