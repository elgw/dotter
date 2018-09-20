function [x, val, exitflag, sigmafitted]=LH2G(patch, sigma0, fitSigma)
% Fit a gaussian to the 2D image 'patch'
% Parameters:
%   fitSigma - Fit sigma or not, 1=yes, 0=no
%   sigma0 = initial sigma to use (also final if fitSigma=0)
% Returns:
%   x - fitted coordinate
%   val - ?
%   exitflag - the return value from fminsearch

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