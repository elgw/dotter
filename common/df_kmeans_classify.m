function [L] = twomeans_classify(m, X, s)
% Classify the dots in D accoring to the means in m
% [~, m] = twomeans(D0);
% L = twomeans_classify(m, D1);
% if maxDist is given and the distance between a dot and the mean is above
% maxDist, label 0 is returned

if ~exist('s', 'var')
    warning('Using default settings');
    s.maxDist = inf;
    s.maxDots = inf;
    disp(s);
end

if ~exist('X','var')
    error('Wrong number of arguments');
end

K = size(m,1);

% if K == 1
%     L = ones(size(X,1),1);
%     if(s.maxDist == inf)
%         return
%     end
%
%     D = eudist(m, X);
%     L(D>s.maxDist) = 0;
%     return
% end

D = zeros(size(X,1),1);

for kk = 1:K
    D(:, kk) = eudist(m(kk, :), X);
end



% maxDots restriction. Only use the s.maxDots closests dots

if s.maxDots == inf
    [~, L] = min(D,[], 2);
else
    L = zeros(size(D,1), 1);
    [~, LL] = min(D,[], 2);
    
    
    for kk = 1:K
        DL = D(:,kk);
        DL(LL~=kk) = inf;
        
        [v,idx] = sort(DL);
        idx = idx(v~=inf);
        
        L(idx(1:min(s.maxDots, numel(idx)))) = kk;
    end
end

% maxDist restriction
% Set dots with a too large distance to the mean to zero

if s.maxDist < inf
    L(min(D,[],2)>s.maxDist) = 0;
end

end