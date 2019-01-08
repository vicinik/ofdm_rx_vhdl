#!/bin/bash

pushd ./src/grpRx/unitTopLevel/sim
vsim -c -do "do sim.do"
popd
