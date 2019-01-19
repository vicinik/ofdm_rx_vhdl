/*******************************************************************************
 * File        :  verification.sv
 * Description :  Class for rudimentary verification
 * Author      :  Nikolaus Haminger
 *******************************************************************************/

`ifndef VERIFICATION_INCLUDED
`define VERIFICATION_INCLUDED

typedef enum {Warning, Error} eSeverity;
typedef enum {ps, ns, us} eTimeResolution;

class Verification;
	integer mNumChecks = 0;
	integer mNumSuccess = 0;
	integer mNumWarnings = 0;
	integer mNumErrors = 0;
	
	function new(eTimeResolution resolution = ns);
		//$timeformat(unit#, prec#, "unit", minwidth);
		if (resolution == ps) begin
			$timeformat(-12, 2, " ps", 10);
		end else if (resolution == ns) begin
			$timeformat(-9, 2, " ns", 10);
		end else if (resolution == us) begin
			$timeformat(-6, 2, " us", 10);
		end
	endfunction

	function void printHeader(string message);
		$display("==========================================");
		$display(message);
		$display("==========================================");
	endfunction

	function void printSubHeader(string message);
		$display("");
		$display(message);
		$display("------------------------------------------");
	endfunction;
	
	function void printInfo(string message);
		$display("[%10t] INFO    : %s", $realtime, message);
	endfunction

	function void printWarning(string message);
		check(0, Warning);
		$display("[%10t] WARNING : %s", $realtime, message);
	endfunction

	function void printError(string message);
		check(0, Error);
		$display("[%10t] ERROR   : %s", $realtime, message);
	endfunction
	
	function void assertNotEqual(int actValue, int nExpValue, string message, eSeverity severity = Error);
		string assertStr = check(actValue != nExpValue, severity);
		// Display message with timestamp
		$display("[%10t] %s %s, Act: 0x%8X, Not exp: 0x%8X", $realtime, assertStr, message, actValue, nExpValue);
	endfunction
	
	function void assertEqual(int actValue, int expValue, string message, eSeverity severity = Error);
		string assertStr = check(actValue == expValue, severity);
		// Display message with timestamp
		$display("[%10t] %s %s, Act: 0x%8X, Exp: 0x%8X", $realtime, assertStr, message, actValue, expValue);
	endfunction

	function string check(assertion, eSeverity severity);
		string assertStr = "";
		mNumChecks = mNumChecks + 1;

		// Check assertion
		if (assertion) begin
			assertStr = "PASSED  :";
			mNumSuccess = mNumSuccess + 1;
		end else begin
			if (severity == Warning) begin
				assertStr = "WARNING :";
				mNumWarnings = mNumWarnings + 1;
			end else if (severity == Error) begin
				assertStr = "ERROR   :";
				mNumErrors = mNumErrors + 1;
			end
		end

		return assertStr;
	endfunction

	function void printResult;
		$display("");
		$display("==========================================");
		$display("Simulation end @%t", $realtime);
		$display("==========================================");
		$display("Number of checks : %d", mNumChecks);
		$display("Successful       : %d", mNumSuccess);
		$display("Warnings         : %d", mNumWarnings);
		$display("Errors           : %d", mNumErrors);
		$display("==========================================");
		if (mNumErrors == 0) begin
			$display("SIMULATION SUCCESS");
		end else begin
			$display("SIMULATION FAILED");
		end
		$display("==========================================");
	endfunction;
endclass

`endif //!VERIFICATION_INCLUDED