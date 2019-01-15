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
	
	type OFDMSignal is array (natural range <>) of aComplexSample;

	-- Function read a ofdm signal from a file and returns the signal as array of comples samples
	impure function read_ofdm_signal (
		fileName : in String;
		signalLength : in natural
	) return OFDMSignal;

end package ofdm_helper;


package body ofdm_helper is
	impure function read_ofdm_signal (
		fileName : in String;
		signalLength : in natural
	) return OFDMSignal is
		variable vOfdmSignal : OFDMSignal(1 to signalLength);
		variable vIdx : natural := vOfdmSignal'left;
		variable vLine : line;
		variable vI : integer;
		variable vSpace : character;
		variable vQ : integer;
		file vSignalFile : text;
	begin
		-- open file to read ofdm signal
		file_open(vSignalFile, fileName, read_mode);
		
		-- read data from the given file as sequence of integers and store
		-- the results as OFDMSignal type (see above)
		while not endfile(vSignalFile) and (vIdx <= vOfdmSignal'right) loop
			readline(vSignalFile, vLine);
			read(vLine, vI);
			read(vLine, vSpace);
			read(vLine, vQ);
			
			-- store data in ofdm signal variable
			vOfdmSignal(vIdx).I := to_signed(vI, 12);
			vOfdmSignal(vIdx).Q := to_signed(vQ, 12);
			vIdx := vIdx + 1;
		end loop;
		
		-- close file and return read signal
		file_close(vSignalFile);		
		return vOfdmSignal;
	end;

end package body ofdm_helper;