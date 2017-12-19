function x=gaussFit2multi(patch, sigma0, mu0)
% Gaussian fitting for sub pixel precision.
% mu0 : [mux1, muy1; mux2, muy2; ... ]
% x: NPoints x mux, muy, B

BG = min(patch(:));
Nphotons = sum(sum(patch-BG));
%mu0
Nphotons = ones(numel(mu0)/2,1)*Nphotons/numel(mu0)*2;

NLQ2Mh = @(x) NLQ2M(patch, sigma0, x);

x = fminsearch(NLQ2Mh, [mu0(:); Nphotons; BG], optimset('Display', 'none', 'TolX', 10^-9, 'TolFun', 10^-9));
%x(1:2)=x(1:2)+(size(patch)+1)/2;
end
