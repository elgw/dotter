function x=LH2(patch, sigma0)

% mu0 = (size(patch)+1)/2;
mu0 = [0,0];
bg0 = min(patch(:));
N0 = sum(sum(patch-bg0));

LL2 = @(x) LL2P(patch, sigma0, x);

%x = fminsearch(LL2, [mu0, bg0, N0], optimset('Display', 'final', 'TolX', 10^-9, 'TolFun', 10^-9));
x = fminsearch(LL2, [mu0, bg0, N0]);

x(1:2)=x(1:2)+(size(patch)+1)/2;

end

