/*******************************************************************************
 * File        :  top.sv
 * Description :  The top module for the OFDM RX path verification.
 * Author      :  Nikolaus Haminger
 *******************************************************************************/

module top;
	parameter symbol_length_c = 320;
	parameter raw_symbol_length_c = 256;
	parameter sample_bit_width_c = 12;
	parameter osr_c = 4;
	parameter fft_exp_c = 6;
	parameter coarse_alignment_level_c = 11000;  //32064;
	logic sys_clk = 0, sys_rstn;
	
	// Clk generator
	always #5ns sys_clk = ~sys_clk;
		
	// Instantiations
	IOfdmRx #(sample_bit_width_c) ofdm_rx_if(sys_clk);
	TbdOfdmRx #(
		sample_bit_width_c,
		symbol_length_c,
		raw_symbol_length_c,
		osr_c,
		fft_exp_c
	) tbd_ofdm_rx(
		sys_clk,
		sys_rstn,
		ofdm_rx_if.sys_init,
		ofdm_rx_if.min_level,
		ofdm_rx_if.rx_data_i,
		ofdm_rx_if.rx_data_q,
		ofdm_rx_if.rx_data_valid,
		ofdm_rx_if.rx_rcv_data,
		ofdm_rx_if.rx_rcv_data_valid,
		ofdm_rx_if.rx_rcv_data_start
	);
	TbTbdOfdmRx #(
		sample_bit_width_c,
		symbol_length_c,
		raw_symbol_length_c,
		coarse_alignment_level_c
	) tb_tbd_ofdm_rx(
		sys_clk,
		sys_rstn,
		ofdm_rx_if.sys_driver
	);
endmodule