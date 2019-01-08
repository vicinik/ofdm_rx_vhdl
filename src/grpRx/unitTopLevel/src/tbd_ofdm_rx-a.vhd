architecture Rtl of TbdOfdmRx is
    -- interpolation connection signals
    signal interp_mode_v       : std_ulogic := '0';
    signal rx_data_delay_v     : std_ulogic_vector(3 downto 0) := (others => '0');
    signal rx_data_offset_v    : std_ulogic_vector(3 downto 0) := (others => '0');
    signal rx_data_i_osr_v     : signed((sample_bit_width_g - 1) downto 0) := (others => '0');
    signal rx_data_q_osr_v     : signed((sample_bit_width_g - 1) downto 0) := (others => '0');
    signal rx_data_osr_valid_v : std_ulogic := '0';
    -- coarse alignment connection signals
    signal offset_inc_v           : std_ulogic := '0';
    signal offset_dec_v           : std_ulogic := '0';
    signal rx_data_i_coarse_v     : signed((sample_bit_width_g - 1) downto 0) := (others => '0');
    signal rx_data_q_coarse_v     : signed((sample_bit_width_g - 1) downto 0) := (others => '0');
    signal rx_data_coarse_valid_v : std_ulogic := '0';
    signal rx_data_coarse_start_v : std_ulogic := '0';
    -- cp removal connection signals
    signal rx_data_i_fft_v     : signed((sample_bit_width_g - 1) downto 0) := (others => '0');
    signal rx_data_q_fft_v     : signed((sample_bit_width_g - 1) downto 0) := (others => '0');
    signal rx_data_fft_valid_v : std_ulogic := '0';
    signal rx_data_fft_start_v : std_ulogic := '0';
    -- fft wrapper connection signals
    signal rx_symbols_i_fft_v     : signed((sample_bit_width_g - 1) downto 0) := (others => '0');
    signal rx_symbols_q_fft_v     : signed((sample_bit_width_g - 1) downto 0) := (others => '0');
    signal rx_symbols_fft_valid_v : std_ulogic := '0';
    signal rx_symbols_fft_start_v : std_ulogic := '0';
    -- fine alignment connection signals
    signal rx_symbols_i_v     : signed((sample_bit_width_g - 1) downto 0) := (others => '0');
    signal rx_symbols_q_v     : signed((sample_bit_width_g - 1) downto 0) := (others => '0');
    signal rx_symbols_valid_v : std_ulogic := '0';
    signal rx_symbols_start_v : std_ulogic := '0';
begin
    -- interpolation instantiation
    interpolation_inst : entity work.Interpolation
        generic map(
            symbol_length_g      => symbol_length_g,
            sample_bit_width_g   => sample_bit_width_g
        )
        port map(
            sys_clk_i            => sys_clk_i,
            sys_rstn_i           => sys_rstn_i,
            sys_init_i           => sys_init_i,
            rx_data_i_i          => rx_data_i_i,
            rx_data_q_i          => rx_data_q_i,
            rx_data_valid_i      => rx_data_valid_i,
            interp_mode_i        => interp_mode_v,
            rx_data_delay_i      => rx_data_delay_v,
            rx_data_offset_i     => rx_data_offset_v,
            rx_data_i_osr_o      => rx_data_i_osr_v,
            rx_data_q_osr_o      => rx_data_q_osr_v,
            rx_data_osr_valid_o  => rx_data_osr_valid_v
        );

    -- coarse alignment instantiation
    coarse_alignment_inst : entity work.CoarseAlignment
        generic map(
            symbol_length_g      => symbol_length_g,
            sample_bit_width_g   => sample_bit_width_g
        )
        port map(
            sys_clk_i               => sys_clk_i,
            sys_rstn_i              => sys_rstn_i,
            sys_init_i              => sys_init_i,
            rx_data_i_osr_i         => rx_data_i_osr_v,
            rx_data_q_osr_i         => rx_data_q_osr_v,
            rx_data_osr_valid_i     => rx_data_osr_valid_v,
            offset_inc_i            => offset_inc_v,
            offset_dec_i            => offset_dec_v,
            interp_mode_o           => interp_mode_v,
            rx_data_delay_o         => rx_data_delay_v,
            rx_data_offset_o        => rx_data_offset_v,
            min_level_i             => min_level_i,
            rx_data_i_coarse_o      => rx_data_i_coarse_v,
            rx_data_q_coarse_o      => rx_data_q_coarse_v,
            rx_data_coarse_valid_o  => rx_data_coarse_valid_v,
            rx_data_coarse_start_o  => rx_data_coarse_start_v
        );

    -- cp removal instantiation
    cp_removal_inst : entity work.CpRemoval
        generic map(
            symbol_length_g      => symbol_length_g,
            raw_symbol_length_g  => raw_symbol_length_g,
            sample_bit_width_g   => sample_bit_width_g
        )
        port map(
            sys_clk_i              => sys_clk_i,
            sys_rstn_i             => sys_rstn_i,
            sys_init_i             => sys_init_i,
            rx_data_i_coarse_i     => rx_data_i_coarse_v,
            rx_data_q_coarse_i     => rx_data_q_coarse_v,
            rx_data_coarse_valid_i => rx_data_coarse_valid_v,
            rx_data_coarse_start_i => rx_data_coarse_start_v,
            rx_data_i_fft_o        => rx_data_i_fft_v,
            rx_data_q_fft_o        => rx_data_q_fft_v,
            rx_data_fft_valid_o    => rx_data_fft_valid_v,
            rx_data_fft_start_o    => rx_data_fft_start_v
        );

    -- fft wrapper instantiation
    fft_wrapper_inst : entity work.FftWrapper
        generic map(
            raw_symbol_length_g  => raw_symbol_length_g,
            sample_bit_width_g   => sample_bit_width_g
        )
        port map(
            sys_clk_i              => sys_clk_i,
            sys_rstn_i             => sys_rstn_i,
            sys_init_i             => sys_init_i,
            rx_data_i_fft_i        => rx_data_i_fft_v,
            rx_data_q_fft_i        => rx_data_q_fft_v,
            rx_data_fft_valid_i    => rx_data_fft_valid_v,
            rx_data_fft_start_i    => rx_data_fft_start_v,
            rx_symbols_i_fft_o     => rx_symbols_i_fft_v,
            rx_symbols_q_fft_o     => rx_symbols_q_fft_v,
            rx_symbols_fft_valid_o => rx_symbols_fft_valid_v,
            rx_symbols_fft_start_o => rx_symbols_fft_start_v
        );

    -- fine alignment instantiation
    fine_alignment_inst : entity work.FineAlignment
        generic map(
            raw_symbol_length_g  => raw_symbol_length_g,
            sample_bit_width_g   => sample_bit_width_g
        )
        port map(
            sys_clk_i              => sys_clk_i,
            sys_rstn_i             => sys_rstn_i,
            sys_init_i             => sys_init_i,
            rx_symbols_i_fft_i     => rx_symbols_i_fft_v,
            rx_symbols_q_fft_i     => rx_symbols_q_fft_v,
            rx_symbols_fft_valid_i => rx_symbols_fft_valid_v,
            rx_symbols_fft_start_i => rx_symbols_fft_start_v,
            rx_symbols_i_o         => rx_symbols_i_v,
            rx_symbols_q_o         => rx_symbols_q_v,
            rx_symbols_valid_o     => rx_symbols_valid_v,
            rx_symbols_start_o     => rx_symbols_start_v,
            offset_inc_o           => offset_inc_v,
            offset_dec_o           => offset_dec_v
        );

    -- demodulation instantiation
    demodulation_inst : entity work.Demodulation
        generic map(
            raw_symbol_length_g  => raw_symbol_length_g,
            sample_bit_width_g   => sample_bit_width_g
        )
        port map(
            sys_clk_i           => sys_clk_i,
            sys_rstn_i          => sys_rstn_i,
            sys_init_i          => sys_init_i,
            rx_symbols_i_i      => rx_symbols_i_v,
            rx_symbols_q_i      => rx_symbols_q_v,
            rx_symbols_valid_i  => rx_symbols_valid_v,
            rx_symbols_start_i  => rx_symbols_start_v,
            rx_rcv_data_o       => rx_rcv_data_o,
            rx_rcv_data_valid_o => rx_rcv_data_valid_o,
            rx_rcv_data_start_o => rx_rcv_data_start_o
        );
end architecture;