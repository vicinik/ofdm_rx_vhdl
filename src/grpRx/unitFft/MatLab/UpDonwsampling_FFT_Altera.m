close all;
clear all;
clc;
addpath '../Matlab_model'

load tx_filter.mat ;
load rx_filter.mat;

fft_sample_rate = 2e6;
up_ration=2;
tx_ratio=16;
rx_ratio=16;

rx_offset = 19;
tx_offset = 306;

down_ratio = up_ration*tx_ratio/rx_ratio;
tx_in_rate = up_ration*fft_sample_rate;
tx_out_rate = tx_ratio*tx_in_rate;
rx_in_rate = tx_out_rate;
rx_out_rate=rx_in_rate/rx_ratio;

%% settings and creating TX signals

intBitSize = 12;
intMin = -(2^(intBitSize-1));
intMax = (2^(intBitSize-1)-1);

NumberOfSubcarrier = 128;
NumberOfGuardChips = 32;
NumberOfSymbols=128;
NumberOfBits=2*NumberOfSymbols;


iterations = 50;


%% Preallocation

RxModSymbolReal = zeros(iterations*NumberOfSymbols,1);
RxModSymbolImag = zeros(iterations*NumberOfSymbols,1);
ModSymbolReal = zeros(iterations*NumberOfSymbols,1);
ModSymbolImag = zeros(iterations*NumberOfSymbols,1);

% LFSR
LFSRRandomVariable = true;

if LFSRRandomVariable
    polynom = [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    seed = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    assert(length(seed) == length(polynom)-1);
    RandomNumber = zeros(size(seed));
    for i=1:5000 % initialization
        seed = ShiftSR(seed, polynom);
    end
else
    polynom = 0; seed = 0;
end


sum_err=0;
allTx=[];

for k=1:iterations

    
%% Tx Signal Generation
TxBits=round(rand(NumberOfBits,1));
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
            ModulationSymbols(j)= intMax/sqrt(2) + intMax*1i*(1/sqrt(2));
        case '1  0'
            ModulationSymbols(j)= intMin/sqrt(2) + intMax*1i*(1/sqrt(2));
        case '0  1'
            ModulationSymbols(j)= intMax/sqrt(2) + intMin*1i*(1/sqrt(2));
        otherwise 
            ModulationSymbols(j)= intMin/sqrt(2) + intMin*1i*(1/sqrt(2));
   end
end 


Mods = zeros(2*NumberOfSymbols, 1);
Mods(1:NumberOfSymbols/2) = ModulationSymbols(1:NumberOfSymbols/2);
Mods(end-NumberOfSymbols/2+1:end) = ModulationSymbols(NumberOfSymbols/2+1:end);
ModulationSymbols = Mods.';

figure(1);
plot(real(ModulationSymbols));

%% OFDM_Tx
[TxChips,iFFTexp] = fft_ii_0_example_design_model(ModulationSymbols,2*NumberOfSymbols,1);
% TxChips= ifft(ModulationSymbols)*sqrt(NumberOfSubcarrier);
GuardChips= TxChips(end - (NumberOfGuardChips - 1):end);
TxAntennaChips= [GuardChips, TxChips];
allTx = [allTx,TxAntennaChips];

end


%% Filter Part

tx_in = allTx;
tx_out=tx_ratio*filter(AD9361_Tx_Filter_object, tx_in);
tx_out_t=[0:1/(tx_out_rate):(length(tx_out)-1)/(tx_out_rate)];
ratio=length(tx_out)/length(tx_in);


% alignment

tx_out(1:end-tx_offset) = tx_out(tx_offset+1:end);

% AWGN = pow2(256-1+iFFTexp).*sqrt(length(TxChips)).*(AWGNGain*randn(length(TxAntennaChips),1)+i.*AWGNGain.*randn(length(TxAntennaChips),1));

%% Leistungsdichtespektrum
%{
figure(200);
clf;
hold on;

[P1xx,F1] = pwelch(allTx,hanning(4096),2048,4096,fft_sample_rate, 'centered');
plot(F1(1:end),10*log10(P1xx(1:end)),'m')
% plot(-2e6+F1(end/2+1:end),10*log10(P1xx(end/2+1:end)),'m')
legend_PSD{1} = 'Leistungsdichtespektrum IFFT';

[P2xx,F2] = pwelch(tx_in,hanning(up_ration*4096),up_ration*2048,up_ration*4096,up_ration*fft_sample_rate,'centered');
plot(F2(1:end),10*log10(P2xx(1:end)),'g')
% plot(-4e6+F2(end/2+1:end),10*log10(P2xx(end/2+1:end)),'g')
legend_PSD{2} = 'Leistungsdichtespektrum Up-Sampling';

[P3xx,F3] = pwelch(tx_out,hanning(16*2*4096),tx_ratio*up_ration*2048,tx_ratio*up_ration*4096,tx_ratio*up_ration*2e6, 'centered');
plot(F3(1:end/2),10*log10(P3xx(1:end/2)),'r')
% plot(-16*4e6+F3(end/2+1:end),10*log10(P3xx(end/2+1:end)),'r')
legend_PSD{3} = 'Leistungsdichtespektrum Tx Filter';

%calculate RF Spectrum
F_lo=2.4e9;
F_rf_s=F_lo*10;

%interpolate tx_out to F_rf_s
Ts_rf=[0:1/F_rf_s:(length(allTx)-1)/(fft_sample_rate)];
rf_re = interp1(tx_out_t, real(tx_out), Ts_rf,'square');
rf_im = interp1(tx_out_t, imag(tx_out), Ts_rf,'square');
rf_mod_sig=rf_re+1i*rf_im;
%calc RF signal (I*sin(w*t)+Q*cos(w*t))
tx_rf=rf_re.*sin(mod(F_lo*2*pi*Ts_rf,2*pi)) + rf_im.*cos(mod(F_lo*2*pi*Ts_rf,2*pi));
%PSD of RF signal
figure(300);
clf;
[P7xx,F7] = pwelch(tx_rf,hanning(pow2(22)),pow2(20),pow2(20),F_rf_s);
plot(F7,10*log10(P7xx),'b');
legend('Leistungsspektrum Trägerfrequenz','Location','best'); 
xlabel('Frequency [Hz]');
ylabel('Magnitude [dB]'); 
title('POwer Baseband');
grid on;    

%}

%% RX Filter
rx_in = tx_out;
% rx_out=filter(AD9361_Rx_Filter_object, rx_in)/rx_ratio;
rx_out=filter(AD9361_Rx_Filter_object, rx_in);
rx_out_t=[0:1/(rx_out_rate):(length(rx_out)-1)/(rx_out_rate)];
ratio_rx=length(rx_in)/length(rx_out);

% Alignment

rx_out(1:end-rx_offset) = rx_out(rx_offset+1:end);
allRx = rx_out;



%% Power Calculation
%{
figure(200);
[P4xx,F4] = pwelch(allRx,hanning(4096),2048,4096,fft_sample_rate, 'centered');
plot(F4(1:end),10*log10(P4xx(1:end)),'y')
% plot(-2e6+F4(end/2+1:end),10*log10(P4xx(end/2+1:end)),'y')
legend_PSD{4} = 'Leistungsdichtespektrum FFT';

[P5xx,F5] = pwelch(rx_out,hanning(down_ratio*4096),down_ratio*2048,down_ratio*4096,down_ratio*fft_sample_rate, 'centered');
plot(F5(1:end),10*log10(P5xx(1:end)),'b')
% plot(-4e6+F5(end/2+1:end),10*log10(P5xx(end/2+1:end)),'b')
legend_PSD{5} = 'Leistungsdichtespektrum Down-Sampling';

[P6xx,F6] = pwelch(rx_in,hanning(rx_ratio*down_ratio*4096),rx_ratio*down_ratio*2048,16*down_ratio*4096,16*down_ratio*fft_sample_rate, 'centered');
plot(F6(1:end),10*log10(P6xx(1:end)),'c')
%plot(-16*4e6+F6(end/2+1:end),10*log10(P6xx(end/2+1:end)),'c')
legend_PSD{6} = 'Leistungsdichtespektrum Rx Filter';
legend(legend_PSD,'Location','best');
grid on;
xlabel('Frequency [Hz]');
ylabel('Magnitude[db]'); 
title('Power');

%}

%% OFDM_Rx



RxModSymbols = [];
for k=1:iterations
    [RxChips, FFTexp] = fft_ii_0_example_design_model(allRx(((k-1)*(2*NumberOfSubcarrier+NumberOfGuardChips)+1+NumberOfGuardChips):k*(2*NumberOfSubcarrier+NumberOfGuardChips)),2*NumberOfSymbols, 0);
    %RxChips= fft(allRx(((k-1)*(NumberOfSubcarrier+NumberOfGuardChips)+1+NumberOfGuardChips):k*(NumberOfSubcarrier+NumberOfGuardChips)))/sqrt(NumberOfSubcarrier);
    RxChips = (1/(2*NumberOfSymbols)).*RxChips.*2.^(-FFTexp-iFFTexp);
    RxModSymbols = [RxModSymbols; RxChips];
end

%% Modulation Demapper 
RxSymbols=zeros(length(RxModSymbols),2);
for j=1:length(RxSymbols(:,1))
   if real(RxModSymbols(j))>=0 
      RxSymbols(j,1)=0;
   else
      RxSymbols(j,1)=1;
   end  
   if imag(RxModSymbols(j))>=0 
      RxSymbols(j,2)=0;
   else
      RxSymbols(j,2)=1;
   end   
end    
RxBits=zeros(2*length(RxSymbols),1);
for j=1:length(RxSymbols(:,1))
   RxBits(j*2-1)=RxSymbols(j,1); 
   RxBits(j*2)=RxSymbols(j,2);
end 

%plot 
figure(400);clf;
plot(real(RxModSymbols),imag(RxModSymbols),'g*');
hold on; 
plot(real(ModulationSymbols),imag(ModulationSymbols),'r*');  
legend('Rx Symbol','Tx Symbol')
grid on;
xlabel('Inpahse');
ylabel('Quadrature'); 
title('Constellation');


