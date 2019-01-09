#----------------------------------*-tcl-*-

##--------------------------------------
## Compilation started
##--------------------------------------

## Creating library work ...
vlib work

## Compiling VHDL files ...
vcom -check_synthesis -work work ../src/log_dualis-p.vhd
vcom -check_synthesis -work work ../src/fine_alignment-e.vhd
vcom -check_synthesis -work work ../src/fine_alignment-a.vhd

## Compiling Testbench
do comp_uvvm.do
vcom -2008 -work work ../src/ofdm_helper-p.vhd
vcom -2008 -work work ../src/tb_fine_alignment-ea.vhd