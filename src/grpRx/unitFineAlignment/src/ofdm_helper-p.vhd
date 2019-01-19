library ieee;
library uvvm_util;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;
use std.env.all;

context uvvm_util.uvvm_util_context;

package ofdm_helper is
	type aComplexSample is record
		I : signed(11 downto 0);
		Q : signed(11 downto 0);
	end record;
	
	constant cOfdmSignalLength : natural := 800;	
	
	type OFDMSignal is array (1 to cOfdmSignalLength) of aComplexSample;

	-- Function read a ofdm signal from a file and returns the signal as array of comples samples
	impure function read_ofdm_signal (
		file_name : in String
	) return OFDMSignal;

end package ofdm_helper;


package body ofdm_helper is
	impure function read_ofdm_signal (
		file_name : in String
	) return OFDMSignal is
		variable v_ofdm_signal : OFDMSignal;
		variable v_idx : natural := v_ofdm_signal'left;
		variable v_line : line;
		variable v_I : integer;
		variable v_space : character;
		variable v_Q : integer;
		file v_signal_file : text;
	begin
		-- open file to read ofdm signal
		file_open(v_signal_file, file_name, read_mode);
		
		-- read data from the given file as sequence of integers and store
		-- the results as OFDMSignal type (see above)
		while not endfile(v_signal_file) and (v_idx <= v_ofdm_signal'right) loop
			readline(v_signal_file, v_line);
			read(v_line, v_I);
			read(v_line, v_space);
			read(v_line, v_Q);
			
			-- store data in ofdm signal variable
			v_ofdm_signal(v_idx).I := to_signed(v_I, 12);
			v_ofdm_signal(v_idx).Q := to_signed(v_Q, 12);
			v_idx := v_idx + 1;
		end loop;
		
		-- close file and return read signal
		file_close(v_signal_file);		
		return v_ofdm_signal;
	end;

end package body ofdm_helper;