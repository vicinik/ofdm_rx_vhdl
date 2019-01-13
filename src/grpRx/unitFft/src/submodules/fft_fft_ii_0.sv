// (C) 2001-2018 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.



module fft_fft_ii_0 (
   input clk, 
   input reset_n,
	input	[0 : 0] inverse,
	input	sink_valid,
	input	sink_sop,
	input	sink_eop,
	input	logic [11 : 0] sink_real,
	input	logic [11 : 0] sink_imag,
	input	logic [1 : 0] sink_error,
	input	source_ready,
   output [5 : 0] source_exp,
	output sink_ready,
	output [1 : 0] source_error,
	output source_sop,
	output source_eop,
	output source_valid,
	output [11 : 0] source_real,
	output [11 : 0] source_imag
	);

	asj_fft_si_se_so_bb #(
		.device_family("Cyclone V"),
		.nps(128),
		.bfp(1),
		.nume(1),
		.mpr(12),
		.twr(12),
		.bpr(16),
		.bpb(4),
		.fpr(4),
		.mram(0),
		.m512(0),
		.mult_type(1),
		.mult_imp(0),
		.dsp_arch(2),
		.srr("AUTO_SHIFT_REGISTER_RECOGNITION=OFF"),
		.rfs1("fft_fft_ii_0_1n128sin.hex"),
		.rfs2("fft_fft_ii_0_2n128sin.hex"),
		.rfs3("fft_fft_ii_0_3n128sin.hex"),
		.rfc1("fft_fft_ii_0_1n128cos.hex"),
		.rfc2("fft_fft_ii_0_2n128cos.hex"),
		.rfc3("fft_fft_ii_0_3n128cos.hex")
	)
	asj_fft_si_se_so_bb_inst (
		.clk(clk),
		.clk_ena(1'b1),
		.reset_n(reset_n),
		.inverse(inverse),
		.sink_valid(sink_valid),
		.sink_sop(sink_sop),
		.sink_eop(sink_eop),
		.sink_real(sink_real),
		.sink_imag(sink_imag),
		.sink_ready(sink_ready),
		.sink_error(sink_error),
		.source_error(source_error),
		.source_ready(source_ready),
		.source_sop(source_sop),
		.source_eop(source_eop),
		.source_valid(source_valid),
		.source_exp(source_exp),
		.source_real(source_real),
		.source_imag(source_imag)
	);
endmodule

