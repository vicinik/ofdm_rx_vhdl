import argparse
import sys
import ast

try:
    import numpy as np
    from matplotlib import pyplot as plt
except:
    exitMsgCode('You need to install the Python modules numpy and matplotlib (pip install numpy matplotlib)', 1)

parser = argparse.ArgumentParser(description='Script for verifying the OFDM RX output signals')
parser.add_argument('--bit_file', dest='bitfile', type=str, action='store', required=True, help='File with the expected bitstream')
parser.add_argument('--result_file', dest='resultfile', type=str, action='store', required=True, help='File with the result signals')
parser.add_argument('--plot_file', dest='plotfile', type=str, action='store', required=True, help='File for saving the scatter plot to')
args = parser.parse_args()

def exitMsgCode(msg, code):
	print('{}\n{}\n'.format(code, msg))
	sys.exit(0)

def getSignals():
    exp_bitstream = []
    with open(args.bitfile, 'r') as f:
        for line in f:
            exp_bitstream.append(int(line))

    rx_symbols_i = []
    rx_symbols_q = []
    rx_bitstream = []
    with open(args.resultfile, 'r') as f:
        rx_symbols_i = ast.literal_eval(f.readline())
        rx_symbols_q = ast.literal_eval(f.readline())
        rx_bitstream = ast.literal_eval(f.readline())

    return np.array(exp_bitstream), np.array(rx_bitstream), np.array(rx_symbols_i) + 1j*np.array(rx_symbols_q)

def main():
    try:
        exp_bitstream, rx_bitstream, rx_symbols = getSignals()
    except Exception as e:
        exitMsgCode(str(e), 12)
    
    error_cnt = 0
    for i in range(len(rx_bitstream)):
        error_cnt += 0 if exp_bitstream[i] == rx_bitstream[i] else 1

    ber = error_cnt/len(rx_bitstream) if len(rx_bitstream) > 0 else 0
    plt.figure(), plt.suptitle('Modulation symbols scatter plot')
    plt.title('BER: {:.3f}'.format(ber), fontsize=9), plt.grid()
    plt.xlabel('Inphase'), plt.ylabel('Quadrature')
    plt.scatter(np.real(rx_symbols), np.imag(rx_symbols), c='black', marker='x')
    plt.savefig(args.plotfile)

    retcode = 0
    if ber < 0.8: retcode = 10
    
    exitMsgCode('BER={:.3f}'.format(ber), retcode)

if __name__ == '__main__':
    main()