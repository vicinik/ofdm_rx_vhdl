clear all; close all; clc;

global k;

%% settings
storeToFile = true;
upsampling = true;
NumberIterations = 13;
TrainingsSymbolPosition = [2 7 10];
TrainingsSequence = []

NumberOfSubcarrier = 128;
NumberOfGuardChips = 32;
AntennaSampleRate = 1/0.5e-6;
ModulationMapperSampleRate = AntennaSampleRate * NumberOfSubcarrier / ...
    (NumberOfSubcarrier + NumberOfGuardChips);
SourceBitRate = 200000000;
NumberOfSymbols = 128;
NumberOfBits = 2*NumberOfSymbols;
NumberOfChips = NumberOfSymbols + NumberOfGuardChips;
AWGNGain = 0;
osr = 5;

allTx = [];
allModulationSymbols = [];
allTxAntennaChips = [];
allTxBits = [];
sum_err=0;

TxAntennaPower = zeros(NumberIterations, 1);
RxAntennaPower = zeros(NumberIterations, 1);
SignalPower = zeros(NumberIterations, 1);
NoisePower = zeros(NumberIterations, 1);
SNR = zeros(NumberIterations, 1);
EVM_rms = zeros(NumberIterations, 1);

BaseSampleRate = 2e6;

for k=1:NumberIterations
    %% Tx Signal Generation
    TxBits = round(rand(NumberOfBits,1));
    allTxBits = [allTxBits; TxBits];
    TxSymbols=zeros(NumberOfSymbols,2);
    for i=1:NumberOfSymbols
        TxSymbols(i,:)=TxBits((2*i-1):2*i)';
    end
    
    %% Modulation Mapper QPSK
    p=1/sqrt(2);
    ModulationSymbols=zeros(NumberOfSymbols,1);
    for j=1:NumberOfSymbols
        switch num2str(TxSymbols(j,:))
            case '0  0'
                ModulationSymbols(j)= complex(p, p);
            case '1  0'
                ModulationSymbols(j)= complex(-p, p);
            case '0  1'
                ModulationSymbols(j)= complex(p, -p);
            otherwise
                ModulationSymbols(j)= complex(-p, -p);
        end
    end
    allModulationSymbols = [allModulationSymbols ; ModulationSymbols];
    
    %% OFDM_Tx
    TxChips = ifft(ModulationSymbols) * sqrt(NumberOfSubcarrier);
    GuardChips = TxChips(NumberOfSubcarrier - NumberOfGuardChips + 1:end);
    TxAntennaChips = [GuardChips; TxChips];
    
    if ~isempty(TrainingsSymbolPosition(TrainingsSymbolPosition == k))
        if isempty(TrainingsSequence)
            re = -0.5 + rand((NumberOfChips)/2, 1);
            im = -0.5 + rand((NumberOfChips)/2, 1);

            TxAntennaChips(1:(NumberOfChips)/2) = re + 1i*im;
            TxAntennaChips((NumberOfChips/2)+1:NumberOfChips) = ...
                TxAntennaChips(1:NumberOfChips/2);
            TrainingsSequence = TxAntennaChips;
        else
            TxAntennaChips = TrainingsSequence; 
        end
    end
    allTxAntennaChips = [allTxAntennaChips; TxAntennaChips];
    
    %% AWGN Channel
    AWGN = sqrt(AWGNGain / 2) * randn(length(TxAntennaChips),1) + sqrt(AWGNGain / 2) * 1i *randn(length(TxAntennaChips),1);
    RxAntennaChips = TxAntennaChips + AWGN;
    
    allTx = [allTx; RxAntennaChips];
end

if upsampling
    % upsampling to 16 MS/s
    HighSampleRate = BaseSampleRate*(2^osr);
    
    allTx_BR_re=real(allTx);
    allTx_BR_im=imag(allTx);
    
    allTx_t_BR = [0:1/(BaseSampleRate):(length(allTx)-1)/(BaseSampleRate)];
    allTx_t_HR = [0:1/(HighSampleRate):(length(allTx)-1)/(BaseSampleRate)];
    allTx_HR_re = interp1(allTx_t_BR, allTx_BR_re, allTx_t_HR,'pchip');
    allTx_HR_im = interp1(allTx_t_BR, allTx_BR_im, allTx_t_HR,'pchip');
    allTx = allTx_HR_re + 1i*allTx_HR_im;
else
    % upsampling to 4 MS/s
    HighSampleRate = 2*BaseSampleRate;
    
    allTx_BR_re=real(allTx);
    allTx_BR_im=imag(allTx);
    
    allTx_t_BR = [0:1/(BaseSampleRate):(length(allTx)-1)/(BaseSampleRate)];
    allTx_t_HR = [0:1/(HighSampleRate):(length(allTx)-1)/(BaseSampleRate)];
    allTx_HR_re = interp1(allTx_t_BR, allTx_BR_re, allTx_t_HR,'pchip');
    allTx_HR_im = interp1(allTx_t_BR, allTx_BR_im, allTx_t_HR,'pchip');
    allTx = allTx_HR_re + 1i*allTx_HR_im;    
end

% limit data into [-2048 2047]
allTx = allTx * 1000;
reAllTx = min(real(allTx), 2047);
reAllTx = max(reAllTx, -2048);
imAllTx = max(imag(allTx), -2048);
imAllTx = min(imAllTx, 2047);
allTx = reAllTx + 1i*imAllTx;

if storeToFile
    fid = fopen("test_ofdm_symbols.txt", "w");
    for i=1:length(allTx)
        fprintf(fid, "%d ", int32(real(allTx(i))));
        fprintf(fid, "%d\n", int32(imag(allTx(i))));
    end
    fclose(fid);
end

P = zeros(length(allTx), 1);
R = zeros(length(allTx), 1);

P_iter = zeros(length(allTx), 1);
R_iter = zeros(length(allTx), 1);

for idx=1:length(P)-(NumberOfChips*2^osr)
    P(idx) = sum(conj(allTx(idx:idx + ((NumberOfChips * 2^osr)/2) - 1)).* ...
        allTx(idx + ((NumberOfChips * 2^osr)/2):idx + (NumberOfChips * 2^osr) - 1));
    R(idx) = sum(abs(allTx(idx + NumberOfChips * 2^osr/2:idx + NumberOfChips*2^osr - 1)).^2);
end

M = (abs(P).^2) ./ (R.^2);
[~, delay] = max(M);

fifo = zeros(1, (NumberOfChips * (2^osr))/2);
fifo_m = zeros(1, (NumberOfChips * (2^osr))/2);

for i=1:length(allTx)-NumberOfChips*(2^osr)
    % get r_d,m and r_d,m+L
    rdm_i = real(allTx(i));
    rdm_q = imag(allTx(i));
    rdmL_i = real(fifo(1));
    rdmL_q = imag(fifo(1));
    ptabL_i = real(fifo_m(1));
    ptabL_q = imag(fifo_m(1));
    
    ptab_i = (rdm_i * rdmL_i) - (-rdm_q * rdmL_q);
    ptab_q = (rdm_q * rdmL_i) + (rdm_i * -rdmL_q);
    
    if i == 1
        P_iter(i) = complex(ptab_i - ptabL_i, ptab_q - ptabL_q);
        R_iter(i) = (rdm_i^2 + rdm_q^2) - (rdmL_i^2 + rdmL_q^2);
    else
        P_iter(i) = P_iter(i-1) + complex(ptab_i - ptabL_i, ptab_q - ptabL_q);
        R_iter(i) = R_iter(i-1) + (rdm_i^2 + rdm_q^2) - (rdmL_i^2 + rdmL_q^2);
    end
    
    % shift new values in fifos
    fifo = [fifo(2:end) complex(rdm_i, rdm_q)];
    fifo_m = [fifo_m(2:end) complex(ptab_i, ptab_q)];
end

M_iter = (abs(P_iter).^2) ./ (R_iter.^2);

% plot p-signal sum
figure(1);
subplot(211);
plot(0:length(P_iter)-1, real(P_iter))
grid on
hold on
plot(0:length(P_iter)-1, imag(P_iter))
title('Coarse Alignment Iter')
xlabel('\rightarrow #Samples')
ylabel('\rightarrow Time metric')
legend('real', "imag")

% plot p-signal iterative
subplot(212);
plot(0:length(P)-1, real(P))
grid on
hold on
plot(0:length(P)-1, imag(P))
title('Coarse Alignment Sum')
xlabel('\rightarrow #Symbols')
ylabel('\rightarrow Time metric')
legend('real', "imag")

% plot timing metric
figure(3);
plot(0:length(P)-1, real(M))
grid on
hold on
plot(0:length(P_iter)-1, real(M_iter))
title('Coarse Alignment Timing metric')
xlabel('\rightarrow #Symbols')
ylabel('\rightarrow Time metric')
legend('Time metric', "Time metric iterativ")

    