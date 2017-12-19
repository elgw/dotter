function [x,fval]=gaussFit1(patch, mu0, sigma0)
% Gaussian fitting for sub pixel precision.
% x: mux, muy, B

BG = min(patch(:));
Nphotons = sum(sum(patch-BG));

NLQ1h = @(x) NLQ1(patch, sigma0, x);

[x, fval] = fminsearch(NLQ1h, [mu0, Nphotons, BG], optimset('Display', 'none', 'TolX', 10^-9, 'TolFun', 10^-9));
%x(1:2)=x(1:2)+(size(patch)+1)/2;
end

