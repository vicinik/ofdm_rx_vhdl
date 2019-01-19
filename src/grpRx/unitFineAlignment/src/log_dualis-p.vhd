package LogDualisPack is
    function LogDualis(cNumber : natural) return natural;
end LogDualisPack;

package body LogDualisPack is

	function LogDualis(cNumber : natural) return natural is
		-- Initialize explicitly (will have warnings for uninitialized variables
		-- from Quartus synthesis otherwise).
		variable vClimbUp : natural := 1;
		variable vResult  : natural := 0;
    begin
		while vClimbUp < cNumber loop
			vClimbUp := vClimbUp * 2;
			vResult  := vResult+1;
		end loop;
		return vResult;
    end LogDualis;
    
end LogDualisPack;