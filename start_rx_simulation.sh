#!/bin/bash

pushd ./src/grpRx/unitTopLevel/sim

if [ "$1" == "cmd" ]
then
    vsim -c -do "do sim_cmd.do"
elif [ "$1" == "gui" ]
then
    vsim -do "do sim.do"
elif [ "$1" == "clean" ]
then
    rm -rf work
    rm -rf libraries
    rm -rf transcript
    rm -rf vsim.wlf
    rm -rf *.hex
    rm -rf *.vstf
    rm -rf *.log
    rm -rf *.png
    rm -rf *.csv
else
    echo "You need to specify the mode: $0 <cmd|gui|clean>"
    echo "---"
    echo "cmd: Runs the simulation in command line mode"
    echo "gui: Runs the simulation in GUI mode (useful for wave debugging)"
    echo "clean: Cleans all the simulation artifacts"
fi

popd
echo "All done!"
