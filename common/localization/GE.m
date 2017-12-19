function E = GE(y, muu, sigma, N, lambda)
% Sum of square errors
s = round(N*normpdf(1:numel(y), muu, sigma));
res = y-s;

E = sum(res.^2);

end