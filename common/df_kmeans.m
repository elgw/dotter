function [varargout] = df_kmeans(X, K, varargin)
%% function P = twomeans(D)
% Purpose: k-means clustering
% [P, m, sd] = df_kmeans(X,k,varargin);

s.verbose = 0;
s.plot = 0;
s.nTries = 3;

%% Determine the number of clusters automatically if K==0
if(K==0)
    if(s.verbose)
        disp('Trying to figure out the best K')
    end
    
    ee = zeros(1,3);
    
    [~, ~, e] = df_kmeans(X,1);
    E = e;
    [~, ~, e] = df_kmeans(X,2);
    E(2) = e;
    
    nk = 2;
    while(E(end)/E(end-1) < 0.85)
        nk = nk+1;
        [~, ~, e] = df_kmeans(X,nk);
        E(nk) = e;
    end
    if s.verbose
        disp('E')
        disp(E)
    end
    K = nk-1; %bestk;
end

%% Main method

if K == 1
    if s.verbose
        disp('K=1, setting all to 1')
    end
    P = ones(size(X,1),1);
    m = mean(X, 1);
    if nargout>0
        varargout{1} = P;
    end
    if nargout>1
        varargout{2} = m;
    end
    if nargout>2
        varargout{3} = sumD(X, P, m);
    end
    
    return
end

%% Perform s.nIterations and keep the best
mine = inf;
for kk = 1:s.nTries
    [P, m, e] = oneKmeans(X, K, s);
    if(e<mine)
        minP = P;
        minM = m;
        mine = e;
    end
    if s.verbose
        fprintf('Trial: %d Error: %f\n', kk, e)
    end
end

if nargout >0
    varargout{1} = minP;
end
if nargout >1
    varargout{2} = minM;
end
if nargout>2
    varargout{3} = mine;
end

end

function sumd = sumD(X,P,m)
% Calculate sum of distances from m

sumd = 0;

for kk = 1:size(m,1) % For each cluster center
    cm = m(kk,:);
    cP = X(P==kk,:);
    sumd = sumd + sum(eudist(cm , cP));
end

end

function [P, m, e] = oneKmeans(X, K, s)
% Initialization: Random assignment

conv = 0; % Convergence
maxiter = 100;

if size(X,1) == 1
    P = 0;
else
    P = round(linspace(1, K, size(X,1)))';
    P = P(randperm(numel(P)));
end

P0 = P;
niter = 0;
while(niter<maxiter && ~conv)
    niter = niter + 1;
    
    % update step
    for kk = 1:K
        m(kk,:) = mean(X(P==kk,:), 1);
    end
    
    if s.plot
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
    
    
    if sum(isnan(m(:))) == 0
        if sum(P~=P0) == 0
            conv = 1;
        end
    else
        for kk = 1:size(m,1)
            if isnan(m(kk,1))
                m(kk,:) = X(randi(size(X,1)),:);
            end
        end
    end
    P0 = P;
    
end

e = sumD(X,P,m);

end