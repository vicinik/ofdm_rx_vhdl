/*******************************************************************************
 * File        : tb_tbd_ofdm_rx.sv
 * Description : Testbench for testing the full OFDM RX path.
 * Author      : Nikolaus Haminger
 *******************************************************************************/
`include "verification.sv"
`include "simulation_signals.sv"

module TbTbdOfdmRx #(
	parameter int sample_bit_width_g,
	parameter int symbol_length_g,
	parameter int raw_symbol_length_g
) (
	input logic sys_clk,
	output logic sys_rstn,
	IOfdmRx.sys_driver ofdm_rx_if
);	
	// Global signals
	int rx_data_input_idx = 0, rx_data_output_idx = 0;
	int rx_data_strobe_cnt = 0;
	logic rx_data_strobe = 0;

	// Instantiations
	Verification verify = new(us);
	SimulationSignals signals = new();

	// Task for resetting all output signals
	task resetAllSignals();
		ofdm_rx_if.rx_data_i = 0;
		ofdm_rx_if.rx_data_q = 0;
		ofdm_rx_if.rx_data_valid = 0;
		ofdm_rx_if.sys_init = 0;
		ofdm_rx_if.min_level = 10000;
	endtask

	// Task for system init
	task initSystem();
		@(posedge sys_clk);
		ofdm_rx_if.sys_init = 1;
		@(posedge sys_clk);
		ofdm_rx_if.sys_init = 0;
	endtask

	// Task for stimulating the OFDM RX path with some signals
	task writeInputSignals();
		while (rx_data_input_idx < $size(signals.input_signal_i)) begin
			@(posedge rx_data_strobe);
			ofdm_rx_if.rx_data_i = signals.input_signal_i[rx_data_input_idx];
			ofdm_rx_if.rx_data_q = signals.input_signal_q[rx_data_input_idx];
			ofdm_rx_if.rx_data_valid = 1;
			@(posedge sys_clk);
			ofdm_rx_if.rx_data_valid = 0;
			rx_data_input_idx++;
		end

		rx_data_input_idx = 0;
	endtask

	// Task for testing a sequence of symbols
	task testSequence(input int idx);
		initSystem();

		verify.printSubHeader($psprintf("Testing RX chain with symbol sequence #%0d", idx));
		verify.printInfo("Loading input data and result bitstream from file");
		signals.readFiles($psprintf("../data/rx_in_signal%0d.csv", idx), $psprintf("../data/result_bits%0d.csv", idx));
		verify.printInfo("Feeding system with RX symbols");
		writeInputSignals();

		// Wait until either half of the output bit stream was received or
		// a timeout occurs
		fork : f
			begin
				wait (rx_data_output_idx >= $size(signals.output_signal)/2);
				verify.printInfo("Received and verified half of the output bitstream");
				disable f;
			end
			begin
				#10ms;
				verify.printError("Didn't get any output bitstream after 10ms");
				disable f;
			end
		join
	endtask

	// Process which validates the received bitstream
	always @(posedge ofdm_rx_if.rx_rcv_data_valid) begin
		automatic int idx = rx_data_output_idx, exp = 0;
		if (ofdm_rx_if.rx_rcv_data_start) begin
			idx = 0;
		end

		exp = int'({signals.output_signal[idx+1], signals.output_signal[idx]});
		verify.assertEqual(ofdm_rx_if.rx_rcv_data, exp, $sprintf("Checking output value with index %d", idx/2), Warning);
		rx_data_output_idx = idx + 2;
	end

	// Process for generating the RX data strobe
	always @(posedge sys_clk) begin
		rx_data_strobe = 0;
		if (sys_rstn == 0) begin
			rx_data_strobe_cnt = 0;
		end else begin
			rx_data_strobe_cnt++;
			if (rx_data_strobe_cnt == 24) begin
				rx_data_strobe = 1;
				rx_data_strobe_cnt = 0;
			end
		end
	end

	// Stimulus
	initial begin : stimuli
		verify.printHeader("Test the OFDM RX path");
		sys_rstn = 0;
		resetAllSignals();
		#100ns;
	
		// Run that wonderful system
		sys_rstn = 1;
		
		// Tests
		for (int i = 0; i < 5; i++) begin
			testSequence(i);
		end
		
		// End of the tests
		verify.printResult();
		$stop();
	end : stimuli

endmodule