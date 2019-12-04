function [P, D] = kdeParzen(X, W ,D, sigma, varargin)
%% function [P, D] = kdeParzen(X, W, Domain, sigma)
% A 1D Parzen KDE estimator for the points X at Y with weight W
% Domain, D, either [min, max] or a linspace.
% example:
% P = randn(100,1);
% [K, D] = kdeParzen(P, [], [-5,5], .1);
% figure, plot(D,K)
% hold on
% plot(P, zeros(size(P)), 'o');
% 
% Further options:
% 'boundary', 'soft' or 'hard'
% 'normalize', 0 or 1


s.normalize = 1;

s.boundary = 'soft';

for kk =1:numel(varargin)
   if ischar(varargin{kk})
    if strcmp(varargin{kk}, 'boundary')
       s.boundary = varargin{kk+1};
    end
    if strcmp(varargin{kk}, 'normalize')
       s.normalize = varargin{kk+1};
    end
   end
   
end

if nargin == 0
    P = [2+randn(100,1); randn(100,1)-2];
    whos P
    [K, D] = kdeParzen(P, [], [-5,5], .3);
    figure, plot(D,K)
    hold on
    plot(P, zeros(size(P)), 'o');
    return 
end

if ~exist('sigma', 'var') | numel(sigma)==0
    sigma = (4*std(X)^5/3/numel(X)).^(1/5);
    fprintf('Sigma set using Silverman''s rule of thumb: %f\n', sigma);
end
if ~exist('D', 'var')
    D = [];
end

if numel(D)==0
    D(1) = min(X(:))-2*sigma;
    D(2) = max(X(:))+2*sigma;
end
    
if numel(D)==2
    D = linspace(D(1), D(2), 1024);
end

D2 = [D-D(end)-D(2)+D(1) D D+D(end)+D(2)+D(1)];

if ~exist('W', 'var')
    W=[];
end

if numel(W)==0
    W = ones(1, numel(X));
end

P = zeros(1, numel(D2));

for kk = 1:numel(X)
    %P = P + W(kk)*normpdf(D2,X(kk),sigma);    
    P = P + W(kk)*1/(sigma*sqrt(2*pi))*exp(-(D2-X(kk)).^2/(2*sigma^2));
end

if s.normalize
    P = P/sum(P);
else
    %disp('kdeParzen.m: Not normalized')
end

if strcmp(s.boundary, 'hard')
    n = numel(D2)/3;
    D = D2(n+1:2*n);
    P = fliplr(P(1:n))+P(n+1:2*n)+fliplr(P(2*n+1:end));
end

if strcmp(s.boundary, 'soft')
    n = numel(D2)/3;
    D = D2(n+1:2*n);
    P = P(n+1:2*n);
end