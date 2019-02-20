#-------------------------------------------
# set Root as relative path
if {![info exists Root]} {
  set Root ../../
}

echo "------------------------------------------------"
echo "Compile HDL"
echo "------------------------------------------------"

# create work library when not exists
if {[file exists work] == 0} {
	echo "no library 'work' found. Creating..."
	vlib work
	vmap work work
}

# Integrate the FFT IP core
if {[file exists libraries/fft_ii_0] == 0} {
	echo "No library 'fft_ii_0' found. Compiling..."
	source ${Root}/unitTopLevel/sim/msim_setup.tcl
	com_fft
}

# Compile all units
vcom -work work ${Root}/unitInterpolation/src/Upsampling-p.vhd
vcom -work work ${Root}/unitInterpolation/src/interpolation-e.vhd
vcom -work work ${Root}/unitInterpolation/src/interpolation-a.vhd
vcom -work work ${Root}/unitCoarseAlignment/src/log_dualis-p.vhd
vcom -work work ${Root}/unitCoarseAlignment/src/coarse_alignment-e.vhd
vcom -work work ${Root}/unitCoarseAlignment/src/coarse_alignment-a.vhd
vcom -work work ${Root}/unitCpRemoval/src/cp_removal-e.vhd
vcom -work work ${Root}/unitCpRemoval/src/cp_removal-a.vhd
vcom -work work ${Root}/unitFft/src/fft_wrapper-e.vhd
vcom -work work ${Root}/unitFft/src/fft_wrapper-a.vhd
vcom -work work ${Root}/unitFineAlignment/src/fine_alignment-e.vhd
vcom -work work ${Root}/unitFineAlignment/src/fine_alignment-a.vhd
vcom -work work ${Root}/unitDemodulation/src/demodulation-e.vhd
vcom -work work ${Root}/unitDemodulation/src/demodulation-a.vhd

# Compile testbed
vcom -work work ${Root}/unitTopLevel/src/tbd_ofdm_rx-e.vhd
vcom -work work ${Root}/unitTopLevel/src/tbd_ofdm_rx-a.vhd

# Compile testbench files
vlog -work work ${Root}/unitTopLevel/src/if_tbd_ofdm_rx.sv
vlog -work work ${Root}/unitTopLevel/src/tb_tbd_ofdm_rx.sv
vlog -work work ${Root}/unitTopLevel/src/top.sv
