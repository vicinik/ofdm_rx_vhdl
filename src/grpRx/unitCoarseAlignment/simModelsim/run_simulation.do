# File:			run_simulation.do
# Description:	This script compiles the DataInterface and
#				all needed packages

# quit previous simulation
quietly quit -sim

# start testbench
vsim work.tbCoarseAlignment

# load wave window
#do wave.do

# run simulation
run -all

set returncode [coverage attribute -name TESTSTATUS -concise]

if { $returncode > 2 } then {
	echo "Exiting because of errors during simulation!"
}

quit -sim