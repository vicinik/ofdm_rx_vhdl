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
	int rx_data_input_cnt = 0;
	int rx_data_strobe_cnt = 0;
	logic rx_data_strobe = 0;
	logic[sample_bit_width_g-1:0] rx_symbols_i;
	logic[sample_bit_width_g-1:0] rx_symbols_q;
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
		ofdm_rx_if.min_level = 42752;
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
			rx_data_input_cnt = i;
			ofdm_rx_if.rx_data_i = signals.input_signal_i[i];
			ofdm_rx_if.rx_data_q = signals.input_signal_q[i];
			ofdm_rx_if.rx_data_valid = 1;
			@(posedge sys_clk);
			ofdm_rx_if.rx_data_valid = 0;
		end
	endtask

	// Task for verifying the output signals
	task verifyOutputSignals(input string rx_in_file, input string rx_bit_file, input string plot_file);
		automatic string result_file = "output_signals.log";
		automatic string python_file = "../src/verify_signals.py";
		automatic string python_log_file = "python.log";
		automatic string python_message;
		automatic int retcode = 0;
		automatic int fd = 0;

		// Write a file with the output modulation symbols and the output bitstream
		signals.writeResultFile(result_file);
		// Now we call a python script which calculates the BER and writes a scatter plot
		retcode = $system($psprintf("python %s --bit_file=%s --result_file=%s --plot_file=%s > %s", python_file, rx_bit_file, result_file, plot_file, python_log_file));
		if (retcode == 0) begin
			fd = $fopen(python_log_file, "r");
			if (!fd) begin
				python_message = $psprintf("Could not open file %s", python_log_file);
				retcode = 1;
			end else begin
				$fscanf(fd, "%d\n", retcode);
				$fscanf(fd, "%s\n", python_message);
				$fclose(fd);
			end
		end else begin
			python_message = "Maybe you need to install Python3 and add it to your PATH environment variable";
		end

		// Return code evaluation
		if (retcode == 0) begin
			verify.printInfo($psprintf("Validation successful: %s", python_message));
			verify.printInfo($psprintf("Scatter plot file written: %s", plot_file));
		end else if (retcode == 10) begin
			verify.printError($psprintf("Validation not really successful: %s", python_message));
			verify.printInfo($psprintf("Scatter plot file written: %s", plot_file));
		end else begin
			verify.printError($psprintf("Validation not successful: %s", python_message));
		end
	endtask

	// Task for testing a sequence of symbols
	task testSequence(input int idx);
		automatic logic received_bitstream = 0;
		automatic string rx_in_file = $psprintf("../data/rx_in_signal%0d.csv", idx);
		automatic string rx_bit_file = $psprintf("../data/result_bits%0d.csv", idx);
		automatic string plot_file = $psprintf("scatter_plot%0d.png", idx);

		initSystem();
		verify.printSubHeader($psprintf("Testing RX chain with symbol sequence #%0d", idx));
		verify.printInfo($psprintf("Loading input data and expected bitstream from files %s and %s", rx_in_file, rx_bit_file));
		signals.readFiles(rx_in_file, rx_bit_file);
		verify.printInfo("Feeding system with RX symbols, this might take a while");
		writeInputSignals();

		// Wait until either half of the output bit stream was received or
		// a timeout occurs
		fork : f
			begin
				// Wait until we have about 12 Symbols
				wait (rx_data_output_cnt >= raw_symbol_length_g*12);
				received_bitstream = 1;
				verify.printInfo("Received enough output bits");
				disable f;
			end
			begin
				#10ms;
				verify.printError("Didn't get enaugh output bits after 10ms");
				disable f;
			end
		join

		// If we received any output bitstream, we verify it
		if (received_bitstream) begin
			verify.printInfo("Verifying RX chain output");
			verifyOutputSignals(rx_in_file, rx_bit_file, plot_file);
		end
	endtask

	// Process which collects the rx bitstream
	always @(posedge ofdm_rx_if.rx_rcv_data_valid) begin
		if (rx_data_output_cnt % raw_symbol_length_g == 0) begin
			verify.printInfo($psprintf("Received %0d output bits", rx_data_output_cnt));
		end
		signals.addRxBitstream(ofdm_rx_if.rx_rcv_data);
		rx_data_output_cnt += 2;
	end

	// Process which collects the rx symbols
	always @(posedge rx_symbols_valid) begin
		signals.addModSymbol(signed'(rx_symbols_i), signed'(rx_symbols_q));
	end

	// Process for generating the RX data strobe
	always @(posedge sys_clk) begin
		rx_data_strobe = 0;
		if (sys_rstn == 0) begin
			rx_data_strobe_cnt = 0;
		end else begin
			rx_data_strobe_cnt++;
			if (rx_data_strobe_cnt == 25) begin
				rx_data_strobe = 1;
				rx_data_strobe_cnt = 0;
			end
		end
	end

	// Stimulus
	initial begin : stimuli
		initSignalSpies();
		verify.printHeader("Test the OFDM RX path");
		verify.printInfo("Working in folder src/grpRx/unitTopLevel/sim");
		sys_rstn = 0;
		resetAllSignals();
		#100ns;
	
		// Run that wonderful system
		sys_rstn = 1;
		
		// Tests
		for (int i = 0; i < 3; i++) begin
			testSequence(i);
		end
		
		// End of the tests
		verify.printResult();
		$stop();
	end : stimuli

endmodule