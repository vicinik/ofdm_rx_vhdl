import argparse
import sys
import ast

try:
    import numpy as np
    from matplotlib import pyplot as plt
except:
    exitMsgCode('You need to install the Python modules numpy and matplotlib (pip install numpy matplotlib)', 1)

parser = argparse.ArgumentParser(description='Script for verifying the OFDM RX output signals')
parser.add_argument('--signal_idx', dest='signal_idx', type=int, action='store', required=True, help='The index of the signal to verify')
parser.add_argument('--result_file', dest='result_file', type=str, action='store', required=True, help='File with the result signals')
parser.add_argument('--plot_file', dest='plot_file', type=str, action='store', required=True, help='File for saving the scatter plot to')
args = parser.parse_args()

data_folder = '../data'
bit_file = '{}/result_bits{}.csv'.format(data_folder, args.signal_idx)
result_file = args.result_file
plot_file = args.plot_file

rx_symbols_out = []
bitstream_exp = []
bitstream_out = []

def exitMsgCode(msg, code):
	print('{}\n{}\n'.format(code, msg))
	sys.exit(0)

def getSignals():
    global rx_symbols_out, bitstream_exp, bitstream_out

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
    global rx_symbols_out, bitstream_exp, bitstream_out

    try:
        getSignals()
    except Exception as e:
        exitMsgCode(str(e), 12)
    
    # Calculate BER and EVM
    bit_range = range(int(len(bitstream_out)/4*3), len(bitstream_out))
    sym_range = range(int(len(rx_symbols_out)/4*3), len(rx_symbols_out))
    ber = calculateBER(bitstream_exp, bitstream_out, bit_range)
    evm = calculateEVM(rx_symbols_out, sym_range)

    # Scatter plot the modulation symbols
    plt.figure(), plt.suptitle('Modulation symbols scatter plot')
    plt.title('BER: {:.3f}, EVM: {:.3f} dB'.format(ber, evm), fontsize=9), plt.grid()
    plt.xlabel('Inphase'), plt.ylabel('Quadrature')
    plt.scatter(np.real(rx_symbols_out[sym_range]), np.imag(rx_symbols_out[sym_range]), c='black', marker='x')
    plt.savefig(plot_file)

    # Return code and message
    retcode = 0
    if ber > 0.2: retcode = 10
    exitMsgCode('BER={:.3f},EVM={:.3f}dB'.format(ber, evm), retcode)

if __name__ == '__main__':
    main()