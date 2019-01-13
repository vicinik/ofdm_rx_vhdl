close all;
clear all;
clc;

up_ratio = 16;
y = [1800;1700;1000;1700;2040;1700;1600;1500;1400];
x = [1,17,33,49,65,81,97,113,129];
tx_in=zeros(1,length(y)*up_ratio);
for k=1:length(y)-2
    tx_in((k-1)*up_ratio+1:k*up_ratio)=interp_taylor(y(k:k+2),up_ratio);
end

figure(1);
plot(tx_in, 'g*');
hold on;
plot(x,y, 'r+');
title('Matlab');