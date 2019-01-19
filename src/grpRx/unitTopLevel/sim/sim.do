quietly quit -sim

#-------------------------------------------
# Compile HDL
do com.do

# start simulation
vsim work.top

if {[file exists wave.do] == 1} {
	echo "Load wave window"
	do wave.do
}

# disable unnecessary warnings
quietly set StdArithNoWarnings 1

# run simulation till end
run -a

#WaveRestoreZoom {0 us} $now