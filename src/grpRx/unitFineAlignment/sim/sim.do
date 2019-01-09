#----------------------------------*-tcl-*-

##--------------------------------------
## Simulation start
##--------------------------------------

# quit previous simulation
quietly quit -sim

# start testbench
vsim work.tbCoarseAlignment

# load wave window
echo "load wave-file(s)"
 catch {do wave.do}
 catch {do wave-default.do}

# run simulation
run -all

set returncode [coverage attribute -name TESTSTATUS -concise]

if { $returncode > 2 } then {
	echo "Exiting because of errors during simulation!"
}

wave zoom full
#quit -sim