# File:			compile.do
# Description:	This script compiles the DataInterface and
#				all needed packages
				
echo " "
echo "------------------------------------------------"
quietly quit -sim

# clean all libraries
do ./clean_all.do

# compile uvvm
#set comperror ""
#catch {
#	do ../../../scripts/compile_uvvm.do
#} comperror

#if [expr {${comperror} != ""}] then {
#	echo "Error compiling libraries"
#	#quit -code 2
#}

# create work library
vlib work
vmap work work 

set comperror ""
catch {
	# compile packages
	vcom -2008 -check_synthesis -work work ../src/coarse_alignment-p.vhd
	
	#compile design
	vcom -2008 -check_synthesis -work work ../src/coarse_alignment-e.vhd
	vcom -2008 -check_synthesis -work work ../src/coarse_alignment-a.vhd
} comperror

if [expr {${comperror} != ""}] then {
	echo "Error compiling design"
}

#compile testbench
set comperror ""
catch {
	vcom -2008 -work work ../src/tb_coarse_alignment-ea.vhd
} comperror

if [expr {${comperror} != ""}] then {
	echo "Error compiling design"
}

echo "DONE!"
echo "------------------------------------------------"
