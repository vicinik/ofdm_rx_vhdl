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


%% RX Filter
rx_in = tx_out;
% rx_out=filter(AD9361_Rx_Filter_object, rx_in)/rx_ratio;
rx_out=filter(AD9361_Rx_Filter_object, rx_in);
rx_out_t=[0:1/(rx_out_rate):(length(rx_out)-1)/(rx_out_rate)];
ratio_rx=length(rx_in)/length(rx_out);

% Alignment

rx_out(1:end-rx_offset) = rx_out(rx_offset+1:end);
allRx = rx_out;





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


