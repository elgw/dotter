function [L] = twomeans_classify(m, X, maxDist)
% Classify the dots in D accoring to the means in m
% [~, m] = twomeans(D0);
% L = twomeans_classify(m, D1);
% if maxDist is given and the distance between a dot and the mean is above
% maxDist, label 0 is returned

K = size(m,1);
if K == 1
    D = eudist(m, X);
    L = ones(size(X,1),1);
    L(D>maxDist) = 0;
    return
end

assert(K==2);

D = zeros(size(X,1),1);

for kk = 1:K
        D(:, kk) = eudist(m(kk, :), X);
end

L = D(:,2)>D(:,1);
L = L + 1;

% Set dots with a too large distance to the mean to zero
if exist('maxDist', 'var')
    L(min(D,[],2)>maxDist) = 0;
end

end