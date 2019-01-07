# File:			compile.do
# Description:	This script compiles the alu and the testbench
				
quietly quit -sim

# create work library
if {[file exists work] == 0} {
	echo "Create library work"
	vlib work
    vmap work work
}

#compile design
vcom -check_synthesis -work work ../src/log_dualis-p.vhd
vcom -check_synthesis -work work ../src/coarse_alignment-p.vhd
vcom -check_synthesis -work work ../src/coarse_alignment-e.vhd
vcom -check_synthesis -work work ../src/coarse_alignment-a.vhd

#compile testbench
vcom -2008 -work work ../src/ofdm_helper-p.vhd
vcom -2008 -work work ../src/tb_coarse_alignment-ea.vhd