function [kde, D] = kdeCurve(x, y, sig, N, from, to)
% Kernel density estimator from unsorted paired measurements
% i.e. non-parameteric curve estimation.
%
% Input:
% (x,y) -- paired coordinates
% sig: smoothing sigma
% Optional:
% N: number of points to use in the domain (default 100)
% from: start of domain to evaluate in
% to: end of domain to evaluate in
% run without any arguments for an example
%
% Output:
% kde: estimated x-value 
% D: domain or y-value

if ~exist('x', 'var')
    npoints = 1000;
    gridpoints = 512;
 from = 0;
 to = 2*pi;
 x = to*rand(npoints,1);
 y = sin(x.^2) + 0.2*randn(size(x));
 figure
 
 sigmas = [0.01, 0.05, 0.25];
 subplot(2,2,1)
 scatter(x,y, 'kx')
 hold on
 plot(linspace(from, to, gridpoints), sin(linspace(from, to,gridpoints).^2), 'g', 'LineWidth', 2)
 legend({'Sampled with noise', 'True signal sin^2(x)'});
 
 for kk = 1:3
     sigma = sigmas(kk);
     subplot(2,2,kk+1) 
    [kde, D] = kdeCurve(x,y, sigma, 1024);
    scatter(x,y, 'kx')
    hold on
 
 plot(D, kde, 'r','lineWidth', 2)
 legend({'Sampled with noise',['KDE estimate, \sigma=', sprintf('%.3f', sigma)]}, ...
     'Location', 'SouthWest')
 kde = [];
 end
 
 return
end

if ~exist('from', 'var')
    from = min(x);
end

if ~exist('to', 'var')
    to = max(x);
end

if ~exist('N', 'var')
    N = 100;
end

% subsample if you have to many points
if 0
idx = randperm(numel(x));
idx = idx(1:min(10000, numel(x)));
x = x(idx);
y = y(idx);
end

% domain
D = linspace(from, to, N);
D = D(:);
w = 0*D;
t = 0*D;

for kk = 1:numel(x)   
    s = normpdf(D, x(kk), sig);
    w = w + s;
    t = t + y(kk)*s;
end
kde = t./w;
if(min(w) < 1e-9)
    warning('Some points without information, please increase sigma')
end

end

