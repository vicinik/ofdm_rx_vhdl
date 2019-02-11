###################################################################################################
# File         : golden_model.py
# Author       : Nikolaus Haminger
# Description  : OFDM chain simulation with Python.
# Requirements : numpy, matplotlib
###################################################################################################
import sys
import argparse

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

parser = argparse.ArgumentParser(description='OFDM chain golden model script. Simulates an entire OFDM transmission without TX and RX filters.')
parser.add_argument('--rx_in_file', dest='rx_in_file', type=str, action='store', required=True, help='File to store the input signal for the RX chain in')
parser.add_argument('--result_bits_file', dest='result_bits_file', type=str, action='store', required=True, help='File to store the expected bit signal in')
parser.add_argument('--result_file', dest='result_file', type=str, action='store', required=True, help='File to store the result signals of this simulation in')
parser.add_argument('--sequence_len', dest='sequence_len', type=int, action='store', required=True, help='Length of the symbol sequence')
parser.add_argument('--num_symbols', dest='num_symbols', type=int, action='store', required=True, help='Length of one OFDM chip')
parser.add_argument('--bit_width', dest='bit_width', type=int, action='store', required=True, help='Bit width of the signals')
args = parser.parse_args()

rx_in_file = args.rx_in_file
result_bits_file = args.result_bits_file
result_file = args.result_file

def generate_tx_bits(num_symbols):
    """
    Generates some random bits.
    """
    return np.random.random_integers(0, 1, num_symbols*2)

def generate_tx_modulation_symbols(bits, bit_width):
    """
    Modulates the bits to modulation symbols in QPSK.
    """
    mod_symbols = []
    p = int((2**(bit_width-1)-1)/np.sqrt(2))
    for i in range(0, len(bits), 2):
        if bits[i] == 0 and bits[i+1] == 0: mod_symbols.append(np.complex(p, p))
        elif bits[i] == 1 and bits[i+1] == 0 : mod_symbols.append(np.complex(-p, p))
        elif bits[i] == 0 and bits[i+1] == 1 : mod_symbols.append(np.complex(p, -p))
        else: mod_symbols.append(np.complex(-p, -p))
    return np.array(mod_symbols)

def generate_tx_symbols(mod_symbols):
    """
    Calculates the IFFT and adds a cyclic prefix.
    """
    tx_symbols = np.fft.ifft(mod_symbols)
    tx_symbols = np.insert(tx_symbols, 0, tx_symbols[0:int(len(tx_symbols)/4)])
    return tx_symbols

def interp_taylor_part(symbols, oversampling, offset=0):
    """
    Interpolation with Taylor's method.
    """
    x = symbols
    y = np.zeros(int(len(symbols)*oversampling))
    if oversampling > 1:
        for i in range(len(symbols)-2):
            x0 = x[i]; x1 = x[i+1]; x2 = x[i+2]
            f1 = x1 - x0; f2 = x2 - 2*x1 + x0
            for j in range(oversampling):
                y[int(i*oversampling+j)] = x0 + (f1-f2/2)*((j+1)/oversampling) + (f2/2)*((j+1)/oversampling)
    else:
        y = x[offset::int(1/oversampling)]

    return np.round(y)

def interp_taylor(symbols, oversampling, offset=0):
    """
    Interpolates a complex signal with Taylor's method.
    """
    sym_i = interp_taylor_part(np.real(symbols), oversampling, offset)
    sym_q = interp_taylor_part(np.imag(symbols), oversampling, offset)
    return sym_i + 1j*sym_q

def coarse_align(symbols, num_symbols, oversampling):
    """
    Coarse Alignment: Calculates the auto correlation and finds the max peak.
    """
    l = int((num_symbols/2)*oversampling)
    C = []
    for i in range(l*6):
        C.append(np.sum(np.dot(symbols[i:i+l], np.conj(symbols[i+l:i+2*l]))))
    idx = np.argmax(np.real(C)) + 2*l
    return symbols[idx:], idx

def generate_rx_modulation_symbols(symbols, num_symbols):
    """
    Generates the RX modulation symbols and bits.
    """
    mod_symbols = np.round(np.fft.fft(symbols)*2**(-3))
    # Cut out unused subcarriers
    mod_symbols = np.concatenate((mod_symbols[0:int(num_symbols/4)], mod_symbols[int(num_symbols/4*3):]))
    bits = np.array([])

    sum_real = 0; sum_imag = 0
    for i in range(len(mod_symbols)):
        real = np.real(mod_symbols[i]); imag = np.imag(mod_symbols[i])
        if real > 0 and imag < 0:
            if i < int(num_symbols/8):
                sum_real = sum_real + np.abs(imag)
                sum_imag = sum_imag + np.abs(real)
            bits = np.append(bits, [0, 1])
        elif real < 0 and imag < 0:
            if i < int(num_symbols/8):
                sum_real = sum_real + np.abs(real)
                sum_imag = sum_imag + np.abs(imag)
            bits = np.append(bits, [1, 1])
        elif real < 0 and imag > 0:
            if i < int(num_symbols/8):
                sum_real = sum_real + np.abs(imag)
                sum_imag = sum_imag + np.abs(real)
            bits = np.append(bits, [1, 0])
        else:
            if i < int(num_symbols/8):
                sum_real = sum_real + np.abs(real)
                sum_imag = sum_imag + np.abs(imag)
            bits = np.append(bits, [0, 0])
    phase_err = sum_imag - sum_real

    return mod_symbols, bits, -1 if phase_err > 0 else 1

def sim_transmitter(num_symbols, bit_width, sequence_len):
    """
    Simulates the transmitter part of the OFDM chain.
    """
    all_tx_bits = np.array([])
    all_tx_mod_symbols = np.array([])
    all_tx_symbols = np.array([])

    for i in range(sequence_len):
        # Generate bits for transmission
        tx_bits = generate_tx_bits(num_symbols)
        all_tx_bits = np.append(all_tx_bits, tx_bits[0:int(len(tx_bits)/4)])
        all_tx_bits = np.append(all_tx_bits, tx_bits[int(len(tx_bits)/4*3):])
        # Generate modulation symbols and cut out unused subcarriers
        tx_mod_symbols = generate_tx_modulation_symbols(tx_bits, bit_width)
        tx_mod_symbols[int(len(tx_mod_symbols)/4):int(len(tx_mod_symbols)/4*3)] = 0
        all_tx_mod_symbols = np.append(all_tx_mod_symbols, tx_mod_symbols[0:int(len(tx_mod_symbols)/4)])
        all_tx_mod_symbols = np.append(all_tx_mod_symbols, tx_mod_symbols[int(len(tx_mod_symbols)/4*3):])
        # Calculate IFFT and add cyclic prefix
        tx_symbols = generate_tx_symbols(tx_mod_symbols)
        all_tx_symbols = np.append(all_tx_symbols, tx_symbols)

    # Scale TX symbols in order to fully use the bit width
    all_tx_symbols = np.round(all_tx_symbols*2**3)

    # Generate and append the synchronization symbol (Schmidl's method)
    # It turns out, that a rectangle signal has a very good peak
    s_sym_len = int((num_symbols+num_symbols/4)/2)
    s_sym_par = np.ones(s_sym_len) * 1000
    sync_symbol = s_sym_par + s_sym_par*1j
    all_tx_symbols = np.concatenate((sync_symbol, sync_symbol, all_tx_symbols))

    return all_tx_bits, all_tx_mod_symbols, all_tx_symbols

def sim_receiver(tx_symbols, num_symbols, oversampling, sequence_len):
    """
    Simulates the receiver part of the OFDM chain.
    """
    # Upsampling
    rx_symbols = interp_taylor(tx_symbols, oversampling)
    # Coarse align and cut out the synchronization symbol
    all_rx_symbols, coarse_idx = coarse_align(rx_symbols, num_symbols, oversampling)
    all_rx_mod_symbols = np.array([])
    all_rx_bits = np.array([])

    offset = 0; last_delta = 0; sync_done = False; cp_len = int(num_symbols/4)
    for i in range(sequence_len):
        b = int(i*(num_symbols+cp_len)*oversampling); e = int((i+1)*(num_symbols+cp_len)*oversampling)
        # Downsample one chip
        rx_symbols_down = interp_taylor(all_rx_symbols[b:e], 1/oversampling, offset)
        # Remove cyclic prefix
        rx_symbols_down = rx_symbols_down[cp_len:]
        # Calculate FFT and detect if we should move the interpolation index
        rx_mod_symbols, rx_bits, delta_offset = generate_rx_modulation_symbols(rx_symbols_down, num_symbols)
        # Determine if the synchronization is done (phase is nearly horizontal)
        if not sync_done:
            offset = (offset + delta_offset) % oversampling
            if delta_offset != last_delta and i != 0:
                sync_done = True
            last_delta = delta_offset
        all_rx_mod_symbols = np.append(all_rx_mod_symbols, rx_mod_symbols)
        all_rx_bits = np.append(all_rx_bits, rx_bits)

    return all_rx_mod_symbols, all_rx_bits, coarse_idx

def write_files(tx_bits, tx_symbols, rx_bits, rx_symbols):
    with open(result_bits_file, 'w') as f:
        for bit in tx_bits:
            f.write('{:.0f}\n'.format(bit))
    with open(rx_in_file, 'w') as f:
        for sym in tx_symbols:
            f.write('{:.0f},{:.0f}\n'.format(np.real(sym), np.imag(sym)))
    with open(result_file, 'w') as f:
        f.write('{}\n'.format(np.real(rx_symbols).tolist()))
        f.write('{}\n'.format(np.imag(rx_symbols).tolist()))
        f.write('{}\n'.format(rx_bits.tolist()))

def main():
    num_symbols = args.num_symbols
    bit_width = args.bit_width
    sequence_len = args.sequence_len
    oversampling = 16
    coarse_idx = np.inf

    # Simulate a transmission
    while (num_symbols+num_symbols/4)*oversampling < coarse_idx:
        tx_bits, tx_mod_symbols, tx_symbols = sim_transmitter(num_symbols, bit_width, sequence_len)
        rx_mod_symbols, rx_bits, coarse_idx = sim_receiver(tx_symbols, num_symbols, oversampling, sequence_len)

    # Write data files
    try:
        write_files(tx_bits, tx_symbols, rx_bits, rx_mod_symbols)
    except Exception as e:
        exitMsgCode(str(e), 1)

    exitMsgCode('OK', 0)

if __name__ == '__main__':
    main()