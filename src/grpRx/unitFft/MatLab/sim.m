

NumberOfSymbols = 128;
test = 2000;
for i =1:255
  test = [test;2000];
end

[testChipsNachiFFT,iFFTexp] = fft_ii_0_example_design_model(test,2*NumberOfSymbols,1);

[RxChips, FFTexp] = fft_ii_0_example_design_model(testChipsNachiFFT,2*NumberOfSymbols, 0);
    
 %[RxChips, FFTexp] = fft_ii_0_example_design_model(allRx(((k-1)*(2*NumberOfSubcarrier+NumberOfGuardChips)+1+NumberOfGuardChips):k*(2*NumberOfSubcarrier+NumberOfGuardChips)),2*NumberOfSymbols, 0);
 %RxChips= fft(allRx(((k-1)*(NumberOfSubcarrier+NumberOfGuardChips)+1+NumberOfGuardChips):k*(NumberOfSubcarrier+NumberOfGuardChips)))/sqrt(NumberOfSubcarrier);
    
    
RxModSymbols = (1/(2*NumberOfSymbols)).*RxChips.*2.^(-FFTexp-iFFTexp);
