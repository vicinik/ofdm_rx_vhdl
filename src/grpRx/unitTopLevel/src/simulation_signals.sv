/*******************************************************************************
 * File        :  simulation_signals.sv
 * Description :  Class for handling the input and output signals of the OFDM
 *                RX path, i.e. reading them from a file and providing them
 *                in a native data format.
 * Author      :  Nikolaus Haminger
 *******************************************************************************/

`ifndef SIMULATION_SIGNALS_INCLUDED
`define SIMULATION_SIGNALS_INCLUDED

class SimulationSignals;
    int input_signal_i[];
    int input_signal_q[];
    logic output_signal[];

    function void readFiles(input string input_file, input string output_file);
        automatic int fd = 0, i = 0, res = 0;

        // Reset signals
        input_signal_i.delete();
        input_signal_q.delete();
        output_signal.delete();

        // Read input signal file (I and Q values)
        fd = $fopen(input_file, "r");
        while (!$feof(fd)) begin
            input_signal_i = new[i+1](input_signal_i);
            input_signal_q = new[i+1](input_signal_q);
            $fscanf(fd, "%d,%d\n", input_signal_i[i], input_signal_q[i]);
            i++;
        end
        $fclose(fd);

        // Read output signal file (bitstream)
        fd = $fopen(output_file, "r");
        i = 0;
        while (!$feof(fd)) begin
            output_signal = new[(i+1)](output_signal);
            $fscanf(fd, "%d\n", res);
            output_signal[i] = res;
            i++;
        end
        $fclose(fd);
    endfunction

endclass

`endif //!SIMULATION_SIGNALS_INCLUDED