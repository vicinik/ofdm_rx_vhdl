quietly quit -sim

#-------------------------------------------
# Compile HDL
do com.do

# start simulation
vsim work.top

# disable unnecessary warnings
quietly set StdArithNoWarnings 1

# run simulation till end
run -a

#WaveRestoreZoom {0 us} $now