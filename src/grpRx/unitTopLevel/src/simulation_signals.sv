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
    logic rx_rcv_bitstream[];
    int rx_rcv_mod_symbols_i[];
    int rx_rcv_mod_symbols_q[];

    function void readFiles(input string input_file, input string output_file);
        automatic int fd = 0, i = 0, res = 0;

        // Reset signals
        input_signal_i.delete();
        input_signal_q.delete();
        output_signal.delete();
        rx_rcv_bitstream.delete();
        rx_rcv_mod_symbols_i.delete();
        rx_rcv_mod_symbols_q.delete();

        // Read input signal file (I and Q values)
        fd = $fopen(input_file, "r");
        if (!fd) begin
            $error($psprintf("Could not open file %s", input_file));
        end
        while (!$feof(fd)) begin
            input_signal_i = new[i+1](input_signal_i);
            input_signal_q = new[i+1](input_signal_q);
            $fscanf(fd, "%d,%d\n", input_signal_i[i], input_signal_q[i]);
            i++;
        end
        $fclose(fd);

        // Read output signal file (bitstream)
        fd = $fopen(output_file, "r");
        if (!fd) begin
            $error($psprintf("Could not open file %s", output_file));
        end
        i = 0;
        while (!$feof(fd)) begin
            output_signal = new[(i+1)](output_signal);
            $fscanf(fd, "%d\n", res);
            output_signal[i] = res;
            i++;
        end
        $fclose(fd);
    endfunction

    function void addModSymbol(input int mod_i, input int mod_q);
        automatic int len = $size(rx_rcv_mod_symbols_i);

        rx_rcv_mod_symbols_i = new[len+1](rx_rcv_mod_symbols_i);
        rx_rcv_mod_symbols_q = new[len+1](rx_rcv_mod_symbols_q);
        rx_rcv_mod_symbols_i[len] = mod_i;
        rx_rcv_mod_symbols_q[len] = mod_q;
    endfunction;

    function void addRxBitstream(input logic bitstream[]);
        automatic int len = $size(rx_rcv_bitstream);

        rx_rcv_bitstream = new[len+2](rx_rcv_bitstream);
        rx_rcv_bitstream[len] = bitstream[0];
        rx_rcv_bitstream[len+1] = bitstream[1];
    endfunction;

    function void dumpVectorInt(input int fd, input int vector[]);
        automatic int len = $size(vector);

        $fwrite(fd, "[");
        for (int i = 0; i < len; i++) begin
            $fwrite(fd, "%d", vector[i]);
            if (i != len-1) begin
                $fwrite(fd, ",");
            end
        end
        $fwrite(fd, "]\n");
    endfunction;

    function void dumpVectorLogic(input int fd, input logic vector[]);
        automatic int len = $size(vector);

        $fwrite(fd, "[");
        for (int i = 0; i < len; i++) begin
            $fwrite(fd, "%d", vector[i]);
            if (i != len-1) begin
                $fwrite(fd, ",");
            end
        end
        $fwrite(fd, "]\n");
    endfunction;

    function void writeResultFile(input string result_file);
        automatic int fd = 0;

        // Open output file
        fd = $fopen(result_file, "w");
        if (!fd) begin
            $error($psprintf("Could not open file %s", result_file));
        end

        // Write signals
        dumpVectorInt(fd, rx_rcv_mod_symbols_i);
        dumpVectorInt(fd, rx_rcv_mod_symbols_q);
        dumpVectorLogic(fd, rx_rcv_bitstream);

        $fclose(fd);
    endfunction;

endclass

`endif //!SIMULATION_SIGNALS_INCLUDED