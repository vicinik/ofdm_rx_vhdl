@echo off

cd .\src\grpRx\unitTopLevel\sim

if "%1"=="cmd" (
    vsim -c -do "do sim_cmd.do"
) else if "%1"=="gui" (
    vsim -do "do sim.do"
) else if "%1"=="clean" (
    rd /s /q work
    rd /s /q libraries
    del /q transcript
    del /q vsim.wlf
    del /q *.hex
    del /q *.vstf
    del /q *.log
    del /q *.png
    del /q *.csv
) else (
    echo You need to specify the mode: %0 ^<cmd^|gui^|clean^>
    echo ---
    echo cmd: Runs the simulation in command line mode
    echo gui: Runs the simulation in GUI mode ^(useful for wave debugging^)
    echo clean: Cleans all the simulation artifacts
    echo.
    pause
)

cd ..\..\..\..\
echo All done!