function g=ggaussian(size,sigma)
% function g=ggaussian(size,sigma)
% returns a gaussian function over the domain specified by size

assert(mod(size,2)==1);
s=(size-1)/2;

D=-s:s;
mu = 0;

f = @(x) gauss1(x, mu, sigma);

% Redo with erf
for kk = 1:numel(D)
    g(kk) = integral(f, D(kk)-.5, D(kk)+.5);
end

g=g./sum(g);
end

function g = gauss1(D, mu, sigma)
    g = 1/(sigma*sqrt(2*pi))*exp(-(D-mu).^2/(sigma^2*2));
end