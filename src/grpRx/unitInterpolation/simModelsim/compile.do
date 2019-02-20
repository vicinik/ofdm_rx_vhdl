# File:			compile.do
# Description:	This script compiles the alu and the testbench
				
	quit -sim

# create work library
if {[file exists work] == 0} {
	echo "Create library work"
	vlib work
    vmap work work
}

#compile packages
vcom -check_synthesis -work work ../src/Upsampling-p.vhd


#compile design
vcom -check_synthesis -work work ../src/interpolation-e.vhd
vcom -check_synthesis -work work ../src/interpolation-a.vhd

#compile testbench
vcom -2008 -work work tbImpl_ea.vhd	