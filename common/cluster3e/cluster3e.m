function [C, P] = cluster3e(P, d0, varargin)
%%function [C, P] = cluster3e(P, d0, varargin)
% Clusters the ND dots in P by connecting
% dots within a Euclidean distance of d0
% Best case, one compact cluster, O(n)
% Worst case, O(n^2)
% Run without arguments to see a demo
% erikw 20150828

if nargin == 0
    
    P = rand(100,3);
    %P(:,3)=0; 
    d0 = .1;
    %C = cluster3e(P,2); max(C(:))
    %C=cluster3e(P,d0, 'verbose', 'showplots');    
    C1=cluster3ec(P', d0);
    tic, C1=cluster3ec(P', d0); t1=toc
    tic, C2=cluster3e(P, d0); t2=toc
    sum(abs(double(C1)-C2))
    
    if 0 % Complexity
        NS = 2.^(2:10);
        t = zeros(size(NS));
        t2 = t;
        for N = 1:numel(NS)
            P = rand(3,NS(N));
            d0 = .1; % Or a function of NS(N)
            tic
                C1=cluster3ec(P, d0);
                C1=cluster3ec(P, d0);                
            t1(N) = toc;
            tic
                C2=cluster3e(P', d0); 
            t2(N)=toc;
        end
        hold off
        plot(NS, t1)
        hold on
        plot(NS, t2)
        
    end
        
    return
end

showPlots = 0;
verbose = 0;
debug = 0;
for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'verbose')
        verbose = 1;
    end
    if strcmpi(varargin{kk}, 'debug')
        debug = 1;
    end
    if strcmpi(varargin{kk}, 'showplots')
        showPlots = 1;
    end
end

nView = 3;

if showPlots 
    figure
    subplot(1,2,1)
    plot3(P(:,1), P(:,2), P(:,3), 'o')
    view(nView)
end

if verbose
    tic
end
N = size(P,1);
Q = 1:N;
C = zeros(numel(Q),1);
cNum = 1; % Number of current cluster

cEnd = 0; % Initialization

while cEnd<N
    cStart = cEnd +1; % First element of cluster
    cEnd = cStart; % Last element of cluster
    cExp = cStart;    
    while cExp<=cEnd && cExp<N
        for pp = cEnd+1:N
            if debug
                printf('%d, %d, %d, %d', cStart, cExp, cEnd, pp);
            end
            if norm(P(Q(pp),1:3)-P(Q(cExp), 1:3))<=d0
                if debug
                    fprintf(' +')
                end
                cEnd = cEnd +1;
                % swap Q(ll) and Q(cEnd)
                t = Q(cEnd); Q(cEnd)=Q(pp); Q(pp)=t;
            end
            if debug
                fprintf('\n');
            end
        end 
        cExp = cExp + 1;
    end
    
    C(Q(cStart:cEnd)) = cNum;
    cNum = cNum+1;    
end
if verbose
    toc
end

if showPlots
subplot(1,2,2)
hold off
plot3(P(:,1), P(:,2), P(:,3), 'o')
hold on
plot3(P(1,1), P(1,2), P(1,3), 'rx');
for kk = 1:max(C(:))
    mC = mean(P(C==kk,:),1);
    ind = find(C==kk);
    disp('')
    for ll = 1:numel(ind)
       % fprintf('%d\n', ind(ll))
        plot3([mC(1), P(ind(ll),1)], ...
            [mC(2), P(ind(ll),2)], ...
            [mC(3), P(ind(ll),3)], 'r');
    end
end
view(nView)
end
end