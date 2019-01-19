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
	int rx_data_output_cnt = 0;
	int rx_data_strobe_cnt = 0;
	logic rx_data_strobe = 0;
	logic rx_symbols_i[sample_bit_width_g-1:0];
	logic rx_symbols_q[sample_bit_width_g-1:0];
	logic rx_symbols_valid;
	logic rx_symbols_start;

	// Instantiations
	Verification verify = new(us);
	SimulationSignals signals = new();

	// Task for initializing signal spies
	task initSignalSpies();
		$init_signal_spy("/top/tbd_ofdm_rx/rx_symbols_i_v", "/top/tb_tbd_ofdm_rx/rx_symbols_i");
		$init_signal_spy("/top/tbd_ofdm_rx/rx_symbols_q_v", "/top/tb_tbd_ofdm_rx/rx_symbols_q");
		$init_signal_spy("/top/tbd_ofdm_rx/rx_symbols_valid_v", "/top/tb_tbd_ofdm_rx/rx_symbols_valid");
		$init_signal_spy("/top/tbd_ofdm_rx/rx_symbols_start_v", "/top/tb_tbd_ofdm_rx/rx_symbols_start");
	endtask;

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
		rx_data_output_cnt = 0;

		@(posedge sys_clk);
		ofdm_rx_if.sys_init = 1;
		@(posedge sys_clk);
		ofdm_rx_if.sys_init = 0;
	endtask

	// Task for stimulating the OFDM RX path with some signals
	task writeInputSignals();
		for (int i = 0; i < $size(signals.input_signal_i); i++) begin
			@(posedge rx_data_strobe);
			ofdm_rx_if.rx_data_i = signals.input_signal_i[i];
			ofdm_rx_if.rx_data_q = signals.input_signal_q[i];
			ofdm_rx_if.rx_data_valid = 1;
			@(posedge sys_clk);
			ofdm_rx_if.rx_data_valid = 0;
		end
	endtask

	// Task for testing a sequence of symbols
	task testSequence(input int idx);
		automatic logic received_bitstream = 0;
		automatic string rx_in_file = $psprintf("../data/rx_in_signal%0d.csv", idx);
		automatic string rx_bit_file = $psprintf("../data/result_bits%0d.csv", idx);
		automatic string result_file = "output_signals.log";
		automatic string python_file = "../src/verify_signals.py";
		automatic int retcode = 0;

		initSystem();
		verify.printSubHeader($psprintf("Testing RX chain with symbol sequence #%0d", idx));
		verify.printInfo("Loading input data and result bitstream from file");
		signals.readFiles(rx_in_file, rx_bit_file);
		verify.printInfo("Feeding system with RX symbols");
		writeInputSignals();

		// Wait until either half of the output bit stream was received or
		// a timeout occurs
		fork : f
			begin
				wait (rx_data_output_cnt >= $size(signals.output_signal)/2);
				received_bitstream = 1;
				verify.printInfo("Received half of the output bitstream");
				disable f;
			end
			begin
				#10ms;
				verify.printError("Didn't get any output bitstream after 10ms");
				disable f;
			end
		join

		// If we received any output bitstream, we verify it
		if (received_bitstream) begin
			verify.printInfo("Verifying RX chain output");
			signals.writeResultFile(result_file);
			retcode = $system($psprintf("python %s --bit_file=%s --result_file=%s", python_file, rx_bit_file, result_file));
			if (retcode == 0) begin
				verify.printInfo("Validation successful, BER > 0.9");
			end else if (retcode == 10) begin
				verify.printWarning("Validation not really successful, BER < 0.9");
			end else if (retcode == 11) begin
				verify.printError("Validation not successful, BER < 0.5");
			end else if (retcode == 12) begin
				verify.printError("Validation not successful, couldn't open or read from files");
			end else begin
				verify.printError("Validation not successful. Maybe you need to install Python3 and add it to your PATH variable.");
			end
		end
	endtask

	// Process which collects the rx bitstream
	always @(posedge ofdm_rx_if.rx_rcv_data_valid) begin
		signals.addRxBitstream(ofdm_rx_if.rx_rcv_data);
		rx_data_output_cnt += 2;
	end

	// Process which collects the rx symbols
	always @(posedge rx_symbols_valid) begin
		automatic int mod_i = int'(rx_symbols_i), mod_q = int'(rx_symbols_q);
		signals.addModSymbol(mod_i, mod_q);
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
		initSignalSpies();
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