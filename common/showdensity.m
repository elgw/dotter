function varargout = showdensity(X, varargin)
% Density estimation over a rectangular domain specified by R
% X is Nx2
%
% Example:
% showdensity(randn(100000,2), 'sigmax', 2, 'sigmay', 2)
% D = showdensity(randn(100000,2), 'N', 10)
% Note: N specifies the number of edges, so you probably want an even
% number

N = ceil(sqrt(size(X,1))/10);
sigmax = 0;
sigmay = 0;
maxnormy = 0;
useLog = 0;

for kk = 1:numel(varargin)
    if(strcmpi(varargin{kk}, 'domain'))
        R = varargin{kk+1};
    end
    if(strcmpi(varargin{kk}, 'sigmax') == 1)
        sigmax = varargin{kk+1};
    end
    if(strcmpi(varargin{kk}, 'sigmay'))
        sigmay = varargin{kk+1};
    end
    if(strcmpi(varargin{kk}, 'maxnormy'))
        maxnormy = 1;
    end
    if strcmpi(varargin{kk}, 'log')
        useLog = 1;
    end
    if(strcmpi(varargin{kk}, 'N'))
        N = varargin{kk+1};
    end
end

if ~exist('R', 'var')
    R(1) = min(X(:,1)); R(2) = max(X(:,1));
    R(3) = min(X(:,2)); R(4) = max(X(:,2));
end

[DX, DY] = meshgrid(linspace(R(1), R(2), N), ...
    linspace(R(3), R(4), N));

D = zeros(N, N);

%% Map to range [0,1]x[0,1]
A = X(:,1) - R(1);
A = A/(R(2)-R(1));

B = X(:,2) - R(3);
B = B/(R(4)-R(3));

A = round(A*N);
B = round(B*N);

for kk = 1:numel(A)    
    a = A(kk); b = B(kk);
    if(a>0 && a<=N)
        if(b>0 && b<= N)
            D(b, a) = D(b,a) + 1;
        end
    end
end


if sigmax > 0    
    D = convn(D, fspecial('gaussian', [1,2+round(sigmax)*2], sigmax), 'same');
end

if sigmay > 0
    D = convn(D, fspecial('gaussian', [2+round(sigmay)*2, 1], sigmay), 'same');
end


g = 0;
n = 0;
for kk = 1:size(D,2)
    g = g + sum(D(:,kk))*var(D(:,kk));
    n = n + sum(D(:,kk));
end
g = g/n;


if maxnormy
    for kk = 1:size(D,2)
        m = max(D(:,kk));
        if m>0
            D(:,kk) = D(:,kk)/m;
        end
    end
end

figure
if useLog == 1
    LD = log(D+1);
    %LD(~isfinite(LD)) = 0;
    surface(DX, DY, LD, 'EdgeColor', 'None');
else
    surface(DX, DY, D, 'EdgeColor', 'None');
end
axis xy
colormap gray
axis tight
legend(sprintf('vError=%f', g));

if nargout == 1
    varargout{1} = D;
end




end