-- (C) 2001-2018 Intel Corporation. All rights reserved.
-- Your use of Intel Corporation's design tools, logic functions and other 
-- software and tools, and its AMPP partner logic functions, and any output 
-- files from any of the foregoing (including device programming or simulation 
-- files), and any associated documentation or information are expressly subject 
-- to the terms and conditions of the Intel Program License Subscription 
-- Agreement, Intel FPGA IP License Agreement, or other applicable 
-- license agreement, including, without limitation, that your use is for the 
-- sole purpose of programming logic devices manufactured by Intel and sold by 
-- Intel or its authorized distributors.  Please refer to the applicable 
-- agreement for further details.


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
--  version		: $Version:	1.0 $ 
--  revision		: $Revision: #1 $ 
--  designer name  	: $Author: psgswbuild $ 
--  company name   	: altera corp.
--  company address	: 101 innovation drive
--                  	  san jose, california 95134
--                  	  u.s.a.
-- 
--  copyright altera corp. 2003
-- 
-- 
--  $Header: //acds/rel/18.0std/ip/dsp/altera_fft_ii/src/rtl/lib/old_arch/asj_fft_data_ram_dp.vhd#1 $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

LIBRARY ieee;
USE ieee.std_logic_1164.all;

use work.fft_pack.all;
library lpm;
use lpm.lpm_components.all;
library altera_mf;
use altera_mf.altera_mf_components.all;


ENTITY asj_fft_data_ram_dp IS
	GENERIC(
					device_family : string;
					dpr : integer :=32;-- 2*mpr
					apr : integer :=8;-- 2*mpr
					rfd : string :="AUTO" -- RAM Resource
	);
	PORT
	(
global_clock_enable : in std_logic;
		data_a		: IN STD_LOGIC_VECTOR (dpr-1 DOWNTO 0);
		wren_a		: IN STD_LOGIC  := '1';
		address_a		: IN STD_LOGIC_VECTOR (apr-1 DOWNTO 0);
		data_b		: IN STD_LOGIC_VECTOR (dpr-1 DOWNTO 0);
		address_b		: IN STD_LOGIC_VECTOR (apr-1 DOWNTO 0);
		wren_b		: IN STD_LOGIC  := '1';
		clock		: IN STD_LOGIC ;
		q_a		: OUT STD_LOGIC_VECTOR (dpr-1 DOWNTO 0);
		q_b		: OUT STD_LOGIC_VECTOR (dpr-1 DOWNTO 0)
	);
END asj_fft_data_ram_dp;


ARCHITECTURE SYN OF asj_fft_data_ram_dp IS

	SIGNAL sub_wire0	: STD_LOGIC_VECTOR (dpr-1 DOWNTO 0);
	SIGNAL sub_wire1	: STD_LOGIC_VECTOR (dpr-1 DOWNTO 0);



	--COMPONENT altsyncram
	--GENERIC (
	--	operation_mode		: STRING;
	--	width_a		: NATURAL;
	--	widthad_a		: NATURAL;
	--	numwords_a		: NATURAL;
	--	width_b		: NATURAL;
	--	widthad_b		: NATURAL;
	--	numwords_b		: NATURAL;
	--	lpm_type		: STRING;
	--	width_byteena_a		: NATURAL;
	--	width_byteena_b		: NATURAL;
	--	outdata_reg_a		: STRING;
	--	outdata_aclr_a		: STRING;
	--	outdata_reg_b		: STRING;
	--	indata_aclr_a		: STRING;
	--	wrcontrol_aclr_a		: STRING;
	--	address_aclr_a		: STRING;
	--	indata_reg_b		: STRING;
	--	address_reg_b		: STRING;
	--	wrcontrol_wraddress_reg_b		: STRING;
	--	indata_aclr_b		: STRING;
	--	wrcontrol_aclr_b		: STRING;
	--	address_aclr_b		: STRING;
	--	outdata_aclr_b		: STRING;
	--	read_during_write_mode_mixed_ports		: STRING;
	--	ram_block_type		: STRING;
	--	intended_device_family		: STRING
	--);
	--PORT (
	--		wren_a	: IN STD_LOGIC ;
	--		clock0	: IN STD_LOGIC ;
	--		wren_b	: IN STD_LOGIC ;
	--		address_a	: IN STD_LOGIC_VECTOR (apr-1 DOWNTO 0);
	--		address_b	: IN STD_LOGIC_VECTOR (apr-1 DOWNTO 0);
	--		q_a	: OUT STD_LOGIC_VECTOR (dpr-1 DOWNTO 0);
	--		q_b	: OUT STD_LOGIC_VECTOR (dpr-1 DOWNTO 0);
	--		data_a	: IN STD_LOGIC_VECTOR (dpr-1 DOWNTO 0);
	--		data_b	: IN STD_LOGIC_VECTOR (dpr-1 DOWNTO 0)
	--);
	--END COMPONENT;

BEGIN
	q_a    <= sub_wire0(dpr-1 DOWNTO 0);
	q_b    <= sub_wire1(dpr-1 DOWNTO 0);

	altsyncram_component : altsyncram
	GENERIC MAP (
		operation_mode => "BIDIR_DUAL_PORT",
		width_a => dpr,
		widthad_a => apr,
		numwords_a => 2**apr,
		width_b => dpr,
		widthad_b => apr,
		numwords_b => 2**apr,
		lpm_type => "altsyncram",
		width_byteena_a => 1,
		width_byteena_b => 1,
		outdata_reg_a => "CLOCK0",
		outdata_aclr_a => "NONE",
		outdata_reg_b => "CLOCK0",
		indata_aclr_a => "NONE",
		wrcontrol_aclr_a => "NONE",
		address_aclr_a => "NONE",
		indata_reg_b => "CLOCK0",
		address_reg_b => "CLOCK0",
		wrcontrol_wraddress_reg_b => "CLOCK0",
		indata_aclr_b => "NONE",
		wrcontrol_aclr_b => "NONE",
		address_aclr_b => "NONE",
		outdata_aclr_b => "NONE",
		read_during_write_mode_mixed_ports => "OLD_DATA",
		ram_block_type => rfd,
		intended_device_family => device_family 
	)
	PORT MAP (
clocken0 => global_clock_enable,
		wren_a => wren_a,
		clock0 => clock,
		wren_b => wren_b,
		address_a => address_a,
		address_b => address_b,
		data_a => data_a,
		data_b => data_b,
		q_a => sub_wire0,
		q_b => sub_wire1
	);



END SYN;

-- ============================================================
-- CNX file retrieval info
-- ============================================================
-- Retrieval info: PRIVATE: VarWidth NUMERIC "0"
-- Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
-- Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
-- Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
-- Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
-- Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
-- Retrieval info: PRIVATE: Clock NUMERIC "0"
-- Retrieval info: PRIVATE: rden NUMERIC "0"
-- Retrieval info: PRIVATE: BYTE_ENABLE_A NUMERIC "0"
-- Retrieval info: PRIVATE: BYTE_ENABLE_B NUMERIC "0"
-- Retrieval info: PRIVATE: BYTE_SIZE NUMERIC "8"
-- Retrieval info: PRIVATE: Clock_A NUMERIC "0"
-- Retrieval info: PRIVATE: Clock_B NUMERIC "0"
-- Retrieval info: PRIVATE: REGdata NUMERIC "1"
-- Retrieval info: PRIVATE: REGwraddress NUMERIC "1"
-- Retrieval info: PRIVATE: REGwren NUMERIC "1"
-- Retrieval info: PRIVATE: REGrdaddress NUMERIC "0"
-- Retrieval info: PRIVATE: REGrren NUMERIC "0"
-- Retrieval info: PRIVATE: REGq NUMERIC "1"
-- Retrieval info: PRIVATE: INDATA_REG_B NUMERIC "1"
-- Retrieval info: PRIVATE: WRADDR_REG_B NUMERIC "1"
-- Retrieval info: PRIVATE: OUTDATA_REG_B NUMERIC "1"
-- Retrieval info: PRIVATE: CLRdata NUMERIC "0"
-- Retrieval info: PRIVATE: CLRwren NUMERIC "0"
-- Retrieval info: PRIVATE: CLRwraddress NUMERIC "0"
-- Retrieval info: PRIVATE: CLRrdaddress NUMERIC "0"
-- Retrieval info: PRIVATE: CLRrren NUMERIC "0"
-- Retrieval info: PRIVATE: CLRq NUMERIC "0"
-- Retrieval info: PRIVATE: BYTEENA_ACLR_A NUMERIC "0"
-- Retrieval info: PRIVATE: INDATA_ACLR_B NUMERIC "0"
-- Retrieval info: PRIVATE: WRCTRL_ACLR_B NUMERIC "0"
-- Retrieval info: PRIVATE: WRADDR_ACLR_B NUMERIC "0"
-- Retrieval info: PRIVATE: OUTDATA_ACLR_B NUMERIC "0"
-- Retrieval info: PRIVATE: BYTEENA_ACLR_B NUMERIC "0"
-- Retrieval info: PRIVATE: enable NUMERIC "0"
-- Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "1"
-- Retrieval info: PRIVATE: BlankMemory NUMERIC "1"
-- Retrieval info: PRIVATE: MIFfilename STRING ""
-- Retrieval info: PRIVATE: UseLCs NUMERIC "0"
-- Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
-- Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
-- Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_A"
-- Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "0"
-- Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "3"
-- Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
-- Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
-- Retrieval info: CONSTANT: OPERATION_MODE STRING "BIDIR_DUAL_PORT"
-- Retrieval info: CONSTANT: WIDTH_A NUMERIC "8"
-- Retrieval info: CONSTANT: WIDTHAD_A NUMERIC "5"
-- Retrieval info: CONSTANT: NUMWORDS_A NUMERIC "32"
-- Retrieval info: CONSTANT: WIDTH_B NUMERIC "8"
-- Retrieval info: CONSTANT: WIDTHAD_B NUMERIC "5"
-- Retrieval info: CONSTANT: NUMWORDS_B NUMERIC "32"
-- Retrieval info: CONSTANT: LPM_TYPE STRING "altsyncram"
-- Retrieval info: CONSTANT: WIDTH_BYTEENA_A NUMERIC "1"
-- Retrieval info: CONSTANT: WIDTH_BYTEENA_B NUMERIC "1"
-- Retrieval info: CONSTANT: OUTDATA_REG_A STRING "CLOCK0"
-- Retrieval info: CONSTANT: OUTDATA_ACLR_A STRING "NONE"
-- Retrieval info: CONSTANT: OUTDATA_REG_B STRING "CLOCK0"
-- Retrieval info: CONSTANT: INDATA_ACLR_A STRING "NONE"
-- Retrieval info: CONSTANT: WRCONTROL_ACLR_A STRING "NONE"
-- Retrieval info: CONSTANT: ADDRESS_ACLR_A STRING "NONE"
-- Retrieval info: CONSTANT: INDATA_REG_B STRING "CLOCK0"
-- Retrieval info: CONSTANT: ADDRESS_REG_B STRING "CLOCK0"
-- Retrieval info: CONSTANT: WRCONTROL_WRADDRESS_REG_B STRING "CLOCK0"
-- Retrieval info: CONSTANT: INDATA_ACLR_B STRING "NONE"
-- Retrieval info: CONSTANT: WRCONTROL_ACLR_B STRING "NONE"
-- Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
-- Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
-- Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "OLD_DATA"
-- Retrieval info: CONSTANT: RAM_BLOCK_TYPE STRING "AUTO"
-- Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Stratix"
-- Retrieval info: USED_PORT: data_a 0 0 8 0 INPUT NODEFVAL data_a[7..0]
-- Retrieval info: USED_PORT: wren_a 0 0 0 0 INPUT VCC wren_a
-- Retrieval info: USED_PORT: q_a 0 0 8 0 OUTPUT NODEFVAL q_a[7..0]
-- Retrieval info: USED_PORT: q_b 0 0 8 0 OUTPUT NODEFVAL q_b[7..0]
-- Retrieval info: USED_PORT: address_a 0 0 5 0 INPUT NODEFVAL address_a[apr-1..0]
-- Retrieval info: USED_PORT: data_b 0 0 8 0 INPUT NODEFVAL data_b[7..0]
-- Retrieval info: USED_PORT: address_b 0 0 5 0 INPUT NODEFVAL address_b[4..0]
-- Retrieval info: USED_PORT: wren_b 0 0 0 0 INPUT VCC wren_b
-- Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
-- Retrieval info: CONNECT: @data_a 0 0 8 0 data_a 0 0 8 0
-- Retrieval info: CONNECT: @wren_a 0 0 0 0 wren_a 0 0 0 0
-- Retrieval info: CONNECT: q_a 0 0 8 0 @q_a 0 0 8 0
-- Retrieval info: CONNECT: q_b 0 0 8 0 @q_b 0 0 8 0
-- Retrieval info: CONNECT: @address_a 0 0 5 0 address_a 0 0 5 0
-- Retrieval info: CONNECT: @data_b 0 0 8 0 data_b 0 0 8 0
-- Retrieval info: CONNECT: @address_b 0 0 5 0 address_b 0 0 5 0
-- Retrieval info: CONNECT: @wren_b 0 0 0 0 wren_b 0 0 0 0
-- Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
-- Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
