clc;
close all;
clear all;
load rx_out_oversample.mat;

%% Settings
% Values from coarse alginment
rx_align_rough_start = 19575;
rx_align_rough_end = 22774;

% Fine alignment
sample_offset = 0;
phase_err_old = 0;

% Global settings
NumberOfSubcarrier = 128;
NumberOfGuardChips = 32;
up_ratio = 2;
Oversample = 10;
SymbolsUsedForPhase = 32


%% 0. FFT
rx_rough = rx_out_oversample(rx_align_rough_start + sample_offset:rx_align_rough_end+sample_offset);
rx_fft = rx_rough(NumberOfGuardChips*up_ratio*Oversample+1:Oversample*up_ratio:end);
RxModSymbols=fft(rx_fft)/sqrt(NumberOfSubcarrier);

% 1. Symbols to first quadrant
% 2. Sum first 32 I and Q values
% 3. Calculate phase shift
sum_real=0;
sum_imag=0;
for k=1:SymbolsUsedForPhase
    if ((real(RxModSymbols(k))>0) && (imag(RxModSymbols(k))<0)) %fourth quadrant
        sum_real=sum_real-imag(RxModSymbols(k));
        sum_imag=sum_imag+real(RxModSymbols(k));
        RxMeasSymb(k)=RxModSymbols(k)*(1i);
    elseif ((real(RxModSymbols(k))<=0) && (imag(RxModSymbols(k))<=0)) %third quadrant
        sum_real=sum_real-real(RxModSymbols(k));
        sum_imag=sum_imag-imag(RxModSymbols(k));
        RxMeasSymb(k)=RxModSymbols(k)*(-1);
    elseif ((real(RxModSymbols(k))<0) && (imag(RxModSymbols(k))>0)) %second quadrant
        sum_real=sum_real+imag(RxModSymbols(k));
        sum_imag=sum_imag-real(RxModSymbols(k));
        RxMeasSymb(k)=RxModSymbols(k)*(-1i);
    else  %first quadrant
        sum_real=sum_real+real(RxModSymbols(k));
        sum_imag=sum_imag+imag(RxModSymbols(k));
        RxMeasSymb(k)=RxModSymbols(k);
    end
end
sum_imag
sum_real
phase_err=sum_imag-sum_real

% 4. Decide which direction to turn
sample_offset_old = sample_offset;
min_achieved = 0;

if ((sign(phase_err)==sign(phase_err_old))) && (min_achieved==0)
    sample_offset_old=sample_offset;
    if (phase_err>0)
        sample_offset=sample_offset-1
    else
        sample_offset=sample_offset+1
    end
    min_achieved=0;
else
    if abs(phase_err) > abs(phase_err_old)
        sample_offset=sample_offset_old;
    end
    min_achieved=1;
    disp('Minimum phase error achieved');
end

phase_err_old=phase_err;

% 5. When symbol has gone through set inc/dec signals -> For sim plot
% result

% Modulation Symbols

ModulationSymbols(1)= 1/sqrt(2) + 1.0i*(1/sqrt(2));
ModulationSymbols(2)= -1/sqrt(2) + 1.0i*(1/sqrt(2));
ModulationSymbols(3)= 1/sqrt(2) - 1.0i*(1/sqrt(2));
ModulationSymbols(4)= -1/sqrt(2) - 1.0i*(1/sqrt(2));

% Plot constellation all
figure(1); clf; hold on;
plot(real(RxModSymbols),imag(RxModSymbols),'g*');
plot(real(ModulationSymbols),imag(ModulationSymbols),'r+');
xlabel('Inphase');
ylabel('Quadrature');
title('Constellation fine adjustment');
legend({'RX Symbols','Symbols'},'Location','best');
grid on;

% Plot constellation first quadrant of 32 symbols
figure(2); clf; hold on;
plot(real(RxMeasSymb),imag(RxMeasSymb),'g*');
plot(real(ModulationSymbols),imag(ModulationSymbols),'r+');
xlabel('Inphase');
ylabel('Quadrature');
title('Constellation first quadrant');
legend({'RX Symbols','Symbols'},'Location','best');
grid on;

% Plot phase 32 rx symbols
figure(3); clf; hold on;
plot(angle(RxMeasSymb),'g+');
xlabel('Symbol');
ylabel('Phase');
title('Phase of RX Symbols');
legend({'RX Symbols'},'Location','best');
grid on;
