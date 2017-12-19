function [x, val, exitflag, sigmafitted]=LH2G(patch, sigma0, fitSigma)
%whos, sigma0, fitSigma
%pause
% mu0 = (size(patch)+1)/2;
mu0 = [0,0];
if min(patch(:))<5
    bg_add = 5;
else
    bg_add = 0;
end

patch = patch+bg_add;
bg0 = min(patch(:));
N0 = sum(sum(patch-bg0));

% Initialize N0 so that the error is zero in the middle
GI = df_gaussianInt2(mu0, [sigma0,sigma0], (size(patch, 1)-1)/2);
N0 = (patch-bg0)./GI;
N0 = N0((size(patch,1)+1)/2, (size(patch,1)+1)/2);

if 0
    model = bg0+N0*df_gaussianInt2(mu0, sigma0, (size(patch, 1)-1)/2);
    figure,
    imagesc([patch, model, patch-model])
    pause
end
%x = fminsearch(LL2, [mu0, bg0, N0], optimset('Display', 'final', 'TolX', 10^-9, 'TolFun', 10^-9));
sigmafitted = NaN;
if fitSigma
    LL2 = @(x) LL2PGsigma(patch, x);
    [x, val, exitflag] = fminsearch(LL2, [mu0, bg0, N0, sigma0], optimset('display', 'off', 'display', 'off', 'MaxFunEvals', 5000, 'MaxIter', 5000));    
    %fprintf('Sigma: %f\n', x(5));
    sigmafitted = x(5);
else
    LL2 = @(x) LL2PG(patch, sigma0, x);
    [x, val, exitflag] = fminsearch(LL2, [mu0, bg0, N0], optimset('display', 'off', 'MaxFunEvals', 5000, 'MaxIter', 5000)); % 'display','iter'/'off'
end

x(1:2)=x(1:2)+(size(patch)+1)/2;
x(3) = x(3)-bg_add;

end

