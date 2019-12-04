function [th] = dotThreshold(d, s)
%% function dotThreshold(d)
% Purpose:
% Find a threshold that separates background dots from signal
% by fitting the background.
% Two approaches:
% 1) Not all dots provided, that means no good fit for the background.
%  An exponential distribution iteratively to the dot
%  intensities. Not that in this case only right side of the distribution
%  of background signals is used.
% 2) All dots provided. Then a Gaussian is used.
%
% Which algorithm is used should in the future be set as a parameter.
% In this case #1 is used for up to 100000 dots and #2 is used for more
% values
% Settings, default:
%  s.iter = 1-10^-2;
%  s.final = 1-10^-4; % Probability of a false negative
%
% Example:
%  To recreate the distribution, use
%  [th, subs, paramhat] = dotThreshold(d, s)
%  x = linspace(0, max(d(:)), 2^10);
%  y = exppdf(x-subs, paramhat);
%  plot(x,y)
%  Erik W, 20160411

debug = 0;

if numel(d)<100000
    % Alg #1
    if ~exist('s', 'var')
        s.iter = 1-10^-2;
        s.final = 1-10^-3;
    end
    
    d = double(d(:));
    
    subs = min(d(:)-10*eps); % Translate the zero level
    ld = d-subs;
    th = max(ld(:));
    
    % Iteratively fit an exponential distribution to the data,
    % exclude the dots above 1-s.iter and continue until convergence.
    
    th0  =-1;
    while th~=th0
        th0 = th;
        %lambda = expfit(ld(ld<th));
        lambda = expfit_dr(ld(ld<th));
        %th = expinv(s.iter, lambda); % exclude 5% tail in the fitting
        th = expinv_dr(s.iter, lambda);
    end
    th = expinv_dr(s.final, lambda);
    
    th = th+subs; % Add the zero level
else
    % Alg #2
    
    D0 = d; %log(D+1);
    for kk = 1:10
        mu = mean(D0);
        sigma = std(D0);
        D0 = D0(D0<mu+4*sigma);
        D0 = D0(D0>mu-4*sigma);
    end
    
    th = mu+6.64*sigma; % Pick of Magda
    
    %th = norminv(0.9999, mu, sigma);
    %nbg = sum(d<th);
    %th = norminv((nbg-1)/nbg, mu, sigma); % allow one background signal
    
    if debug == 1
        figure,
        x = linspace(-.5,.5);
        y = normpdf(x, mu, sigma);
        histogram(d)
        hold on
        plot(x,y/max(y(:))*20000)
        ax = axis;
        hold on
        plot([th,th], ax(3:4), 'r')
    end        
end