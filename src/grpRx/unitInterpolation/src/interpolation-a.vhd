architecture Rtl of Interpolation is
	signal data_q_fi : signed(sample_bit_width_g downto 0);	-- erste Ableitung real
	signal data_q_fii : signed((sample_bit_width_g + 2) downto 0);	-- zweite Ableitung real
	signal data_i_fi : signed(sample_bit_width_g downto 0);	-- erste Ableitung imaginär
	signal data_i_fii : signed((sample_bit_width_g + 2) downto 0);	-- zwite Ableitung imaginär


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
		Q_i : signed(sample_bit_width_g downto 0);		--erste Ableitung imag
		Q_ii : signed(sample_bit_width_g + 2 downto 0);	-- zweite Ableitung imag
		I_i : signed(sample_bit_width_g downto 0);		-- erste Ableitung real
		I_ii : signed(sample_bit_width_g + 2 downto 0);	-- zweite Ableitung real
	end record;

	type aInterpolationReg is record
		State : aState;
		Derives : aDerives;
		Data : aData;
		Delay : unsigned(3 downto 0);
		Offset : unsigned(3 downto 0);
		Count : unsigned(3 downto 0);
	end record;

	----------------------------------------------------------
	-- 						CONSTANTS 						--
	----------------------------------------------------------

	-- constant cInitReg : aDerives := (others => '0');

	----------------------------------------------------------
	-- 						SIGNALES 						--
	----------------------------------------------------------

	signal Reg, NxrReg : aInterpolationReg;

begin


  Interpolation1 : process (sys_clk_i, sys_rstn_i)
  begin
	if sys_rstn_i = '0' then 
	-- TODO Init System
	elsif rising_edge(sys_clk_i) then
		if sys_init_i = '1' then
			-- TODO Init System
		elsif  then
			Reg <= NxrReg;
		end if;
	end if;
  end process;

	fsm: process ()
	begin
		NxrReg <= Reg;
		case Reg.State is


			when Init =>
				if rx_data_valid_i = '1' then
					Reg.Data_f_x0.Q <= rx_data_q_i;
					Reg.Data_f_x0.I <= rx_data_i_i;
					Reg.State = WaitSample2;
				end if;


			when WaitSample2 => 
				if rx_data_valid_i = '1' then
					Reg.Data_f_x0.Q <= rx_data_q_i;
					Reg.Data_f_x0.I <= rx_data_i_i;
					Reg.Data_f_x1 <= Reg.Data_f_x0;
					Reg.State = WaitSample3;
				end if;


			when WaitSample3 =>
				if rx_data_valid_i = '1' then
					Reg.Data_f_x0.Q <= rx_data_q_i;
					Reg.Data_f_x0.I <= rx_data_i_i;
					Reg.Data_f_x1 <= Reg.Data_f_x0;
					Reg.Data_f_x2 <= Reg.Data_f_x1;
					Reg.State = CalcDerived;
				end if;


			when CalcDerived =>
				Reg.Derives.Q_i <= Reg.Data.x1.Q + Reg.Data.x0.Q; -- erste Ableitung real
				Reg.Derives.I_i <= Reg.Data.x1.I + Reg.Data.x0.I;	-- erste Ableitung imag
				Reg.Derives.Q_ii <= Reg.Data.x2.Q - (Reg.Data.x1.Q << 1) + Reg.Data.x0.Q; -- zweite Ableitung real
				Reg.Derives.I_ii <= Reg.Data.x2.I - (Reg.Data.x1.I << 1) + Reg.Data.x0.I; -- zweite Ableitung imag
				Reg.State <= UpSampling;


			when Upsampling => -- Outputs all UpSamples for detecting Coarse ALignment

					if Count =  then
					end if;

			when CalcSample => -- Outputs only one Sample with XY Delay From FineAlignment


			when Done =>
				if rx_data_valid_i = '1' then
					Reg.Data_f_x0.Q <= rx_data_q_i;
					Reg.Data_f_x0.I <= rx_data_i_i;
					Reg.Data_f_x1 <= Reg.Data_f_x0;
					Reg.Data_f_x2 <= Reg.Data_f_x1;
				end if;

				if interp_mode_i = '0' then -- OversamplingRate necessary
					Reg.State <= Upsampling;
				else -- no oversampling necessary, because alignment has been done yet
					Reg.State <= CalcSample;
				end if;

			when others => NULL;
		end case;

	end process fsm;



--sDerives.Q_i <= sData_f_x1.Q + rx_data_q_i; -- erste Ableitung real
--sDerives.I_i <= sData_f_x1.I + rx_data_i_i;	-- erste Ableitung imag
--sDerives.Q_ii <= sData_f_x2.Q - (sData_f_x1.Q << 1) + rx_data_q_i; -- zweite Ableitung real
--sDerives.I_ii <= sData_f_x2.I - (sData_f_x1.I << 1) + rx_data_i_i; -- zweite Ableitung imag





  Interpolation2 : process (sys_clk_i, sys_rstn_i)
  begin
	if sys_rstn_i = '0' then 
	-- TODO Init System
	elsif rising_edge(sys_clk_i) then
	


	end if;
  end process;


end architecture;