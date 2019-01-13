clc
clear all

data = importdata('output_results.m');

ySample = data(4:6);
yUpSampled = data(7:22);
ySample = [ySample;data(23)];
yUpSampled = [yUpSampled;data(24:39)];
ySample = [ySample;data(40)];
yUpSampled = [yUpSampled;data(41:56)];
ySample = [ySample;data(57)];
yUpSampled = [yUpSampled;data(58:73)];

xSample = [1,17,33,49,65,81];
figure(2);
plot(yUpSampled,'g*')
hold on;
plot(xSample, ySample, 'r*');
title('VHDL');




