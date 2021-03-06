onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider TopLevel
add wave -noupdate /top/tbd_ofdm_rx/sys_clk_i
add wave -noupdate /top/tbd_ofdm_rx/sys_rstn_i
add wave -noupdate /top/tbd_ofdm_rx/sys_init_i
add wave -noupdate -radix unsigned /top/tbd_ofdm_rx/min_level_i
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/rx_data_i_i
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/rx_data_q_i
add wave -noupdate /top/tbd_ofdm_rx/rx_data_valid_i
add wave -noupdate /top/tbd_ofdm_rx/rx_rcv_data_o
add wave -noupdate /top/tbd_ofdm_rx/rx_rcv_data_valid_o
add wave -noupdate /top/tbd_ofdm_rx/rx_rcv_data_start_o
add wave -noupdate /top/tb_tbd_ofdm_rx/rx_data_input_cnt
add wave -noupdate /top/tb_tbd_ofdm_rx/rx_data_output_cnt
add wave -noupdate -divider Interpolation
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/interpolation_inst/rx_data_i_i
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/interpolation_inst/rx_data_q_i
add wave -noupdate /top/tbd_ofdm_rx/interpolation_inst/rx_data_valid_i
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/interpolation_inst/rx_data_i_osr_o
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/interpolation_inst/rx_data_q_osr_o
add wave -noupdate /top/tbd_ofdm_rx/interpolation_inst/rx_data_osr_valid_o
add wave -noupdate -divider CoarseAlignment
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/coarse_alignment_inst/rx_data_i_osr_i
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/coarse_alignment_inst/rx_data_q_osr_i
add wave -noupdate /top/tbd_ofdm_rx/coarse_alignment_inst/rx_data_osr_valid_i
add wave -noupdate /top/tbd_ofdm_rx/coarse_alignment_inst/offset_inc_i
add wave -noupdate /top/tbd_ofdm_rx/coarse_alignment_inst/offset_dec_i
add wave -noupdate -radix unsigned /top/tbd_ofdm_rx/coarse_alignment_inst/min_level_i
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/coarse_alignment_inst/regCoarse.Threshold
add wave -noupdate -childformat {{/top/tbd_ofdm_rx/coarse_alignment_inst/regPValue.I -radix decimal} {/top/tbd_ofdm_rx/coarse_alignment_inst/regPValue.Q -radix decimal}} -expand -subitemconfig {/top/tbd_ofdm_rx/coarse_alignment_inst/regPValue.I {-format Analog-Step -height 150 -max 6860180000.0 -min -6860180000.0 -radix decimal} /top/tbd_ofdm_rx/coarse_alignment_inst/regPValue.Q {-format Analog-Step -height 150 -max 686018000.0 -min -686018000.0 -radix decimal}} /top/tbd_ofdm_rx/coarse_alignment_inst/regPValue
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/coarse_alignment_inst/rx_data_i_coarse_o
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/coarse_alignment_inst/rx_data_q_coarse_o
add wave -noupdate /top/tbd_ofdm_rx/coarse_alignment_inst/rx_data_coarse_valid_o
add wave -noupdate /top/tbd_ofdm_rx/coarse_alignment_inst/rx_data_coarse_start_o
add wave -noupdate -divider CpRemoval
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/cp_removal_inst/rx_data_i_coarse_i
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/cp_removal_inst/rx_data_q_coarse_i
add wave -noupdate /top/tbd_ofdm_rx/cp_removal_inst/rx_data_coarse_valid_i
add wave -noupdate /top/tbd_ofdm_rx/cp_removal_inst/rx_data_coarse_start_i
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/cp_removal_inst/counter
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/cp_removal_inst/rx_data_i_fft_o
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/cp_removal_inst/rx_data_q_fft_o
add wave -noupdate /top/tbd_ofdm_rx/cp_removal_inst/rx_data_fft_valid_o
add wave -noupdate /top/tbd_ofdm_rx/cp_removal_inst/rx_data_fft_start_o
add wave -noupdate -divider FftWrapper
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/fft_wrapper_inst/rx_data_i_fft_i
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/fft_wrapper_inst/rx_data_q_fft_i
add wave -noupdate /top/tbd_ofdm_rx/fft_wrapper_inst/rx_data_fft_valid_i
add wave -noupdate /top/tbd_ofdm_rx/fft_wrapper_inst/rx_data_fft_start_i
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/fft_wrapper_inst/rx_symbols_i_fft_o
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/fft_wrapper_inst/rx_symbols_q_fft_o
add wave -noupdate /top/tbd_ofdm_rx/fft_wrapper_inst/rx_symbols_fft_valid_o
add wave -noupdate /top/tbd_ofdm_rx/fft_wrapper_inst/rx_symbols_fft_start_o
add wave -noupdate -divider FineAlignment
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/fine_alignment_inst/rx_symbols_i_fft_i
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/fine_alignment_inst/rx_symbols_q_fft_i
add wave -noupdate /top/tbd_ofdm_rx/fine_alignment_inst/rx_symbols_fft_valid_i
add wave -noupdate /top/tbd_ofdm_rx/fine_alignment_inst/rx_symbols_fft_start_i
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/fine_alignment_inst/rx_symbols_i_o
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/fine_alignment_inst/rx_symbols_q_o
add wave -noupdate /top/tbd_ofdm_rx/fine_alignment_inst/rx_symbols_valid_o
add wave -noupdate /top/tbd_ofdm_rx/fine_alignment_inst/rx_symbols_start_o
add wave -noupdate /top/tbd_ofdm_rx/fine_alignment_inst/offset_inc_o
add wave -noupdate /top/tbd_ofdm_rx/fine_alignment_inst/offset_dec_o
add wave -noupdate -divider Demodulation
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/demodulation_inst/rx_symbols_i_i
add wave -noupdate -radix decimal /top/tbd_ofdm_rx/demodulation_inst/rx_symbols_q_i
add wave -noupdate /top/tbd_ofdm_rx/demodulation_inst/rx_symbols_valid_i
add wave -noupdate /top/tbd_ofdm_rx/demodulation_inst/rx_symbols_start_i
add wave -noupdate /top/tbd_ofdm_rx/demodulation_inst/rx_rcv_data_o
add wave -noupdate /top/tbd_ofdm_rx/demodulation_inst/rx_rcv_data_valid_o
add wave -noupdate /top/tbd_ofdm_rx/demodulation_inst/rx_rcv_data_start_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1840715000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {2772110250 ps}
