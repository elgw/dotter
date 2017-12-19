function L=LL2PG(patch, sigma, x)
% ML estimation where the Poissonians are approximated by Gaussians,
% Fine for FISH-data since the photon count is high.
%mux = x(1); muy = x(2); bg = x(3); N = x(4);

if x(4)<1 % has to have at least one photon
    L = 10^9;
    return
end

if x(3)<0 % can not have negative background
    L = 10^9;
    return
end

if sigma<0
   L = 10^9;
    return
end 

%keyboard
model = x(3)+x(4)*df_gaussianInt2([x(1), x(2)], [sigma, sigma], (size(patch, 1)-1)/2);
%mask = disk2d((size(patch,1)-1)/2);
mask = ones(size(patch));
% -.5*log(model) should be constant under translations and only be a
% function of bg and n0

%L = sum(sum(mask.*( (patch-model).^2./model - .0*log(model)))); % least squares
L = sum(sum(mask.*( (patch-model).^2./model  -.5*log(model))));
%fprintf('%f %f\n', x(1), x(2));

if ~isfinite(L)
    L = 10^9;
end
%imagesc([model patch])
%pause
end