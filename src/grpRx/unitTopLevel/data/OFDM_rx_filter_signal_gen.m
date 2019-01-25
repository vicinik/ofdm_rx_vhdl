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
TxShiftExponent = 3;

NumberOfGuardChips = BaseRatio*32;
NumberOfSymbols = BaseRatio*128;
NumberOfBits=2*NumberOfSymbols;
NumberOfSyncSamples = BaseRatio*80;
NumberOfRuns=15;
NumberOfFiles=3;

%% Tx Signal Generation
% In this section the TX signal is generated, which will later be sent
% by using the TX filter.

l = 0;
while l < NumberOfFiles
allTx = [];
allTxBits = [];
allTxModSymbols = [];
allRxModSymbols = [];
allExpIfft = [];
allRxChips = [];

for k=1:NumberOfRuns

% First, we generate a random sequence of bits
TxBits=round(rand(NumberOfBits,1));
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

% Set the unused subcarriers to 0
ModulationSymbols(NumberOfSymbols/4+1:NumberOfSymbols/4*3) = 0;

% OFDM Tx
% We calculate the IFFT and add some GuardChips at the beginning of the
% sequence. Note that we upsample directly by using the FFT, as we perform
% it directly using double the amount of symbols
[TxChips, exp_ifft]=fft_hw(ModulationSymbols.', NumberOfSymbols, 1);
GuardChips=TxChips(NumberOfSymbols-NumberOfGuardChips+1:end);
TxAntennaChips=[GuardChips, TxChips].';

% Cut out the unused bits
allTxBits = [allTxBits; TxBits(1:NumberOfBits/4); TxBits(NumberOfBits/4*3+1:end)];
allTx = [allTx; TxAntennaChips];
allTxModSymbols = [allTxModSymbols; ModulationSymbols];
allExpIfft = [allExpIfft, exp_ifft];
end

if mean(allExpIfft) > -8.0
    fprintf('Skipping these symbols because of wrong exponent\n');
    continue;
else
    l = l + 1;
end

exp_ifft_s = round(mean(allExpIfft) + TxShiftExponent);

% Write bits to file
csvwrite(sprintf('result_bits%i.csv', l-1), allTxBits)

%% Add synchronization symbol
% Add a synchronization symbol (Schmiedl's Method)
SyncSymbol = randn(NumberOfSyncSamples, 1)*2^6 + 1i*randn(NumberOfSyncSamples, 1)*2^6;
rx_in = round([SyncSymbol; SyncSymbol; allTx]*2^TxShiftExponent);
allTx = round(allTx*2^TxShiftExponent);

fprintf('Max: %d, Min: %d\n', max(real(rx_in)), min(real(rx_in)));
% Write RX signal to file
dlmwrite(sprintf('rx_in_signal%i.csv', l-1), [real(rx_in), imag(rx_in)], 'precision', '%i')

%% CP removal and FFT
for k=1:NumberOfRuns
% Cut out the CP and the relevant symbols for this run
lower = (k-1)*NumberOfSymbols + k*NumberOfGuardChips + 1;
upper = k*NumberOfSymbols + k*NumberOfGuardChips;
RxChips=allTx(lower:upper).';

% Calculate FFT
[RxModSymbols, exp_fft]=fft_hw(RxChips, NumberOfSymbols, 0);
% Cut out not used symbols
RxModSymbols = [RxModSymbols(1:NumberOfSymbols/4), RxModSymbols(NumberOfSymbols/4*3+1:end)];
RxModSymbols = RxModSymbols*2^(-exp_ifft_s-exp_fft(1))*(1/NumberOfSymbols);

allRxChips = [allRxChips, RxChips];
allRxModSymbols = [allRxModSymbols, RxModSymbols];
end

dlmwrite(sprintf('cp_removal_signal%i.csv', l-1), [real(allRxChips); imag(allRxChips)], 'precision', '%i')
dlmwrite(sprintf('fft_signal%i.csv', l-1), [real(allRxModSymbols); imag(allRxModSymbols)], 'precision', '%i')

fprintf('Finished #%i, Exponent: %f\n', l-1, exp_ifft_s);

end