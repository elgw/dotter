function [x,fval]=gaussFit2(patch, sigma0)
% Gaussian fitting for sub pixel precision.
% x: mux, muy, B

mu0 = [0,0];

BG = min(patch(:))*numel(patch);
Nphotons = sum(sum(patch-BG));

NLQ2h = @(x) NLQ2(patch, sigma0, x);

[x, fval] = fminsearch(NLQ2h, [mu0, Nphotons, BG], optimset('Display', 'none'));
x(1:2)=x(1:2)+(size(patch)+1)/2;
end

