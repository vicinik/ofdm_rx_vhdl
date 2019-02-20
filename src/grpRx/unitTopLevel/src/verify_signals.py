###################################################################################################
# File         : verify_signals.py
# Author       : Nikolaus Haminger
# Description  : Verifies an OFDM simulation result.
# Requirements : numpy, matplotlib
###################################################################################################
import argparse
import sys
import ast

def exitMsgCode(msg, code):
	print('{}\n{}\n'.format(code, msg))
	sys.exit(0)

try:
    import numpy as np
    import matplotlib
    matplotlib.use('agg')
    from matplotlib import pyplot as plt
except:
    exitMsgCode('You need to install the Python modules numpy and matplotlib (pip install numpy matplotlib)', 1)

parser = argparse.ArgumentParser(description='Script for verifying the OFDM RX output signals')
parser.add_argument('--result_bits_file', dest='result_bits_file', type=str, action='store', required=True, help='File with the expected result bits')
parser.add_argument('--result_file', dest='result_file', type=str, action='store', required=True, help='File with the result signals')
parser.add_argument('--python_sim_file', dest='python_sim_file', type=str, action='store', required=True, help='File with the python simulation data')
parser.add_argument('--plot_file', dest='plot_file', type=str, action='store', required=True, help='File for saving the scatter plot to')
args = parser.parse_args()

bit_file = args.result_bits_file
result_file = args.result_file
python_sim_file = args.python_sim_file
plot_file = args.plot_file

rx_symbols_out = []
rx_symbols_py = []
bitstream_exp = []
bitstream_out = []
bitstream_py = []

def getSignals():
    global rx_symbols_out, bitstream_exp, bitstream_out, rx_symbols_py, bitstream_py

    # Read expected bitstream file
    with open(bit_file, 'r') as f:
        for line in f:
            bitstream_exp.append(int(line))
    bitstream_exp = np.array(bitstream_exp)

    # Read result file
    rx_symbols_i = []
    rx_symbols_q = []
    rx_bitstream = []
    with open(result_file, 'r') as f:
        rx_symbols_i = ast.literal_eval(f.readline())
        rx_symbols_q = ast.literal_eval(f.readline())
        rx_bitstream = ast.literal_eval(f.readline())
    rx_symbols_out = np.array(rx_symbols_i) + 1j*np.array(rx_symbols_q)
    bitstream_out = np.array(rx_bitstream)

    # Read python simulation result file
    rx_symbols_py_i = []
    rx_symbols_py_q = []
    rx_bitstream_py = []
    with open(python_sim_file, 'r') as f:
        rx_symbols_py_i = ast.literal_eval(f.readline())
        rx_symbols_py_q = ast.literal_eval(f.readline())
        rx_bitstream_py = ast.literal_eval(f.readline())
    rx_symbols_py = np.array(rx_symbols_py_i) + 1j*np.array(rx_symbols_py_q)
    bitstream_py = np.array(rx_bitstream_py)

def calculateBER(signal_exp, signal_out, comp_range):
    error_cnt = 0
    for i in comp_range:
        error_cnt += 0 if signal_exp[i] == signal_out[i] else 1
    return error_cnt/len(comp_range) if len(comp_range) > 0 else 1.0

def calculateEVM(rx_symbols_out, comp_range):
    rx_symbols = rx_symbols_out[comp_range]
    ref_point = np.mean(np.abs(np.real(rx_symbols))) + 1j*np.mean(np.abs(np.imag(rx_symbols)))
    dist_vec = []
    for s in rx_symbols:
        res = (np.real(ref_point)-np.abs(np.real(s)))**2 + (np.imag(ref_point)-np.abs(np.imag(s)))**2
        dist_vec.append(res)
    return 10*np.log10(np.sqrt(np.sum(dist_vec)/len(dist_vec)))

def main():
    global rx_symbols_out, bitstream_exp, bitstream_out, rx_symbols_py, bitstream_py

    try:
        getSignals()
    except Exception as e:
        exitMsgCode(str(e), 12)
    
    # Calculate BER and EVM of VHDL simulation
    bit_range = range(int(len(bitstream_out)/4*3), len(bitstream_out))
    sym_range = range(int(len(rx_symbols_out)/4*3), len(rx_symbols_out))
    ber = calculateBER(bitstream_exp, bitstream_out, bit_range)
    evm = calculateEVM(rx_symbols_out, sym_range)

    # Calculate BER and EVM of Python simulation
    ber_py = calculateBER(bitstream_exp, bitstream_py, bit_range)
    evm_py = calculateEVM(rx_symbols_py, sym_range)

    # Scatter plot the modulation symbols
    plt.figure(figsize=(12, 6))
    plt.suptitle('Constellation diagram')
    plt.subplot(1, 2, 1)
    plt.title('[Python] BER: {:.3f}, EVM: {:.3f} dB'.format(ber_py, evm_py), fontsize=9), plt.grid()
    plt.xlabel('Inphase'), plt.ylabel('Quadrature')
    plt.scatter(np.real(rx_symbols_py[sym_range]), np.imag(rx_symbols_py[sym_range]), c='black', marker='x')
    plt.subplot(1, 2, 2)
    plt.title('[VHDL] BER: {:.3f}, EVM: {:.3f} dB'.format(ber, evm), fontsize=9), plt.grid()
    plt.xlabel('Inphase'), plt.ylabel('Quadrature')
    plt.scatter(np.real(rx_symbols_out[sym_range]), np.imag(rx_symbols_out[sym_range]), c='black', marker='x')
    plt.show()
    plt.savefig(plot_file)

    # Return code and message
    retcode = 0
    if ber > 0.2: retcode = 10
    exitMsgCode('BER={:.3f}, EVM={:.3f}db'.format(ber, evm), retcode)

if __name__ == '__main__':
    main()