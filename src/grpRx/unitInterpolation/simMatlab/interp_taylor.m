function [y_out]=interp_taylor(y,osr)
%function [yout]=interp_taylor(y,osr)
%function for quadratic interpolation using taylors theorem
%osr=oversampling ratio of interpolation grid

f0 = y(1);
f1 = (y(2) - y(1))/osr ;
f2 = (y(3) - 2*y(2) + y(1))/(osr^2);
y_out = zeros(osr,1);

y_out(1) = y(1);

for k=2:osr
    fi = (f1-f2/2*osr)*(k-1);
    fii = (f2/2) * (k-1)^2;
    y_out(k) = f0 + fi + fii;
    % y_out(k) = f0 + (f1-f2/2*osr)*(k-1) + (f2/2) * (k-1)^2;
end


end