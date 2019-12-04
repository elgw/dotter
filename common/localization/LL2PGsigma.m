function L=LL2PGsigma(patch,  x)
% ML estimation where the Poissonians are approximated by Gaussians,
% Fine for FISH-data since the photon count is high.
%mux = x(1); muy = x(2); bg = x(3); N = x(4);
if x(4)<0 || x(3)<0 
    L = 10^9;
else
    model = x(3)+x(4)*df_gaussianInt2([x(1), x(2)], [x(5), x(5)], (size(patch, 1)-1)/2);
    mask = disk2d((size(patch,1)-1)/2);
    %L = -sum(sum(-(patch-model).^2./model - .5*log(model)));
    L = -sum(sum(mask.*(-(patch-model).^2./model - .5*log(model))));
end

end