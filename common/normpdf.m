function y = normpdf(x, mu, sigma)
%% function y = normpdf(x, mu, sigma)

assert(numel(mu)==1);

y = 1/(sigma*sqrt(2*pi))*exp(-(x-mu).^2/(2*sigma^2));
