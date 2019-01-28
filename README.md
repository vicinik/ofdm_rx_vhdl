# OFDM RX Path in VHDL

This repository aims to create an OFDM RX implementation according to [this specification](doc/OFDM_Rx_Specification.pdf). An overview of the architecture can be obtained from the following figure.

![Big Picture](img/big_picture.png "Big picture of the OFDM RX implementation")

## TopLevel Simulation
### Requirements
- Mentor Modelsim or Questa
- [Python3](https://www.python.org/downloads/) ([added to the PATH environment variable](https://stackoverflow.com/questions/3701646/how-to-add-to-the-pythonpath-in-windows))
- Python modules: numpy and matplotlib (`pip install numpy matplotlib`)

### How to start
Just call the script `start_rx_simulation.bat <command>` where `command` is one of the following:
- `gui`: Starts the simulation in GUI mode (useful for wave window debugging)
- `cmd`: Starts the simulation in command line mode
- `clean`: Cleans all the simulation artifacts

There is also a bash script `start_rx_simulation.sh` with the same name and commands.

### Simulation Artifacts
The simulation will generate a scatter plot of the modulation symbols using a Python script. The plot contains the BER and EVM values and can be found at `src/grpRx/unitTopLevel/sim/scatter_plot#.png`, where `#` is the number of the symbol sequence processed. The plot is only available when the simulation of one symbol sequence is finished. **Pay attention to the console output** of Modelsim/Questa in order to obtain the current simulation status and result of the verification.
