clear all; close all; clc;
load('tx_filter_4MS.mat');
load('rx_filter_4MS.mat');

%% Parameters and Variables
FilterSR = 4e6;
BaseSR = 2e6;
PhaseCorrSR = 40e6;
BaseRatio = FilterSR/BaseSR;
PhaseCorrRatio = PhaseCorrSR/FilterSR;
SourceBitRate = 100e6;
AWGNGain = 0.;

NumberOfGuardChips = BaseRatio*32;
NumberOfSymbols = BaseRatio*128;
NumberOfBits=2*NumberOfSymbols;
NumberOfSyncSamples = BaseRatio*80;
NumberOfRuns=10;
NumberOfFiles=10;

%% Tx Signal Generation
% In this section the TX signal is generated, which will later be sent
% by using the TX filter.

l = 0;
while l < NumberOfFiles
allTx = [];
allTxBits = [];
allRxBits = [];
allTxModSymbols = [];
allRxModSymbols = [];
allExpIfft = [];

for k=1:NumberOfRuns

% First, we generate a random sequence of bits
TxBits=round(rand(NumberOfBits,1));
allTxBits = [allTxBits; TxBits];
TxSymbols=zeros(NumberOfSymbols,2);
for i=1:NumberOfSymbols
  TxSymbols(i,:)=TxBits((2*i-1):2*i)';
end

% Modulation Mapper QPSK
% We map the generated bits onto modulation symbols
ampl = 2047/sqrt(2);
p=fi(ampl, 1, 12, 0);
ModulationSymbols=zeros(NumberOfSymbols,1);
for j=1:NumberOfSymbols
   switch num2str(TxSymbols(j,:))
        case '0  0'
            ModulationSymbols(j)= complex(p,p);
        case '1  0'
            ModulationSymbols(j)= complex(-p,p);
        case '0  1'
            ModulationSymbols(j)= complex(p,-p);
        otherwise
            ModulationSymbols(j)= complex(-p,-p);
   end
end

% OFDM Tx
% We calculate the IFFT and add some GuardChips at the beginning of the
% sequence. Note that we upsample directly by using the FFT, as we perform
% it directly using double the amount of symbols
[TxChips, exp_ifft]=fft_hw(ModulationSymbols.', NumberOfSymbols, 1);
GuardChips=TxChips(NumberOfSymbols-NumberOfGuardChips+1:end);
TxAntennaChips=[GuardChips, TxChips].';

% AWGN Channel
% We add some white gaussion noise to simulate the transmission losses.
AWGN=AWGNGain*randn(length(TxAntennaChips),1)+1i*AWGNGain*randn(length(TxAntennaChips),1);
AWGN_Scaled=AWGN*2^(15 + exp_ifft(1)); % Scaling of the AWGN
TxAntennaChips=TxAntennaChips+AWGN_Scaled;

allTx = [allTx; TxAntennaChips];
allTxModSymbols = [allTxModSymbols; ModulationSymbols];
allExpIfft = [allExpIfft, exp_ifft];
end

if mean(allExpIfft) > -9.0
    fprintf('Skipping these symbols because of wrong exponent\n');
    continue;
else
    l = l + 1;
end

%% TX Filter
% In this section, we add a synchronization symbol,
% up-sample the generated Tx Chips and send them
% through a TX filter.

% Add a synchronization symbol (Schmiedl's Method)
SyncSymbol = randn(NumberOfSyncSamples, 1)*2^6 + 1i*randn(NumberOfSyncSamples, 1)*2^6;
allTx = [SyncSymbol; SyncSymbol; allTx];
allTx_t = 0:1/(FilterSR):(length(allTx)-1)/FilterSR;
tx_in = allTx;

% TX filter
factor = 8;
tx_out=factor*filter(AD9361_Tx_Filter_object, tx_in);
tx_out_t=[0:1/(factor*FilterSR):(length(tx_out)-1)/(factor*FilterSR)];

%% RX Filter
% In this section, we first filter the Tx out signal with the Rx filter and
% write the generated signal to a CSV file.

% RX filtering
rx_in = filter(AD9361_Rx_Filter_object, tx_out);
rx_in = double(rx_in).';
rx_in_t = 0:1/FilterSR:(length(rx_in)-1)/FilterSR;

rx_in = round(rx_in*2^3);

%plot(rx_in_t, rx_in)
dlmwrite(sprintf('rx_in_signal%i.csv', l-1), [real(rx_in).', imag(rx_in).'], 'precision', '%i')
csvwrite(sprintf('result_bits%i.csv', l-1), allTxBits)

fprintf('Finished #%i, Exponent: %f\n', l-1, mean(allExpIfft)+3);

end