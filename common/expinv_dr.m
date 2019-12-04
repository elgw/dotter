function [x]=expinv_dr(p, lambda)
% returns the x for which the cdf of the exponential distribution is p


% CDF p=1-exp(-lambda*x)
x = - log(1-p)/lambda;