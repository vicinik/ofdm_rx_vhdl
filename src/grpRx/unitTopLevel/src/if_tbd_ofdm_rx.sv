/*******************************************************************************
 * File        :  if_tbd_ofdm_rx.sv
 * Description :  Interface for the OFDM RX component
 * Author      :  Nikolaus Haminger
 *******************************************************************************/

interface IOfdmRx #(
	parameter int sample_bit_width_g
) (
	input bit sys_clk_i
);

	logic [sample_bit_width_g-1:0] rx_data_i;
	logic [sample_bit_width_g-1:0] rx_data_q;
	logic [1:0] rx_rcv_data;
	logic [15:0] min_level;
	logic sys_init, rx_data_valid, rx_rcv_data_valid, rx_rcv_data_start;

	modport sys_driver(
		output rx_data_i, output rx_data_q, output min_level, output sys_init, output rx_data_valid,
		input rx_rcv_data, input rx_rcv_data_valid, input rx_rcv_data_start
	);
	
endinterface