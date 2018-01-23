function [P, m] = twomeans(X, K)
%% function P = twomeans(D)
% Purpose: k-means clustering, k=2

verbose = 0;

if nargin == 0
    X = rand(90,2);
    verbose = 1;
end

conv = 0; % Convergence
maxiter = 100;
if ~exist('K','var')
    K = 2;  % Number of clusters to detect
end

if K == 1
    m = mean(X, 1);
    P = ones(size(X,1),1);
    return
end

% Initialization: Random assignment

if size(X,1) == 1
    P = 0;
else
    P = round(linspace(1, K, size(X,1)))';
    P = P(randperm(numel(P)))
end

P0 = P;
niter = 0;
while(niter<maxiter && ~conv)
    niter = niter + 1;
    
    % update step
    for kk = 1:K
        m(kk,:) = mean(X(P==kk,:), 1);
    end
    
    if verbose
       figure(1)
       clf
       plot(X(P==1,1), X(P==1,2), 'ro');
       hold on
       plot(X(P==2,1), X(P==2,2), 'ko');
       plot(m(1,1), m(1,2), 'rx');
       plot(m(2,1), m(2,2), 'kx');
       pause
    end
                
    % assignment step, assign each dot to its closest mean    
    for kk = 1:K
        D(:, kk) = eudist(m(kk, :), X);
    end
         
    [~, P] = min(D,[], 2);    
    
    if sum(P~=P0) == 0
        conv = 1;
    end
    P0 = P;
end
