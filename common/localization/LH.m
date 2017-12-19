function L = LH(y, muu, sigma, N)

% model:
s = 10+(N*normpdf(1:numel(y), muu, sigma));
% outcome:
% y

%L = prod(lambda.^res*exp(-lambda)./factorial(res));
%L = sum( res.*log10(lambda)*exp(-lambda)./ logfactorial(res));
L = -sum( -s*log10(exp(1)) + y.*log10(s) -logfactorial(y));
end
