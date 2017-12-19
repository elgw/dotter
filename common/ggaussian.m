function g=ggaussian(size,sigma)
% function g=ggaussian(size,sigma)
% returns a gaussian function over the domain specified by size

assert(mod(size,2)==1);
s=(size-1)/2;

D=-s:s;

mu = 0;
%g=normpdf(D, 0, sigma); % Requires statistics toolbox
g = 1/(sigma*sqrt(2*pi))*exp(-(D-mu).^2/(sigma*sqrt(2)));

g=g./sum(g);



