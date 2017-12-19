function [P,Q] = correlatedDots(ndots, corrval, side)
% function [P,Q] = correlatedDots(ndots, corrval, side)
% see piccs

if nargin == 0    
    for alpha = linspace(0,1,5)
        figure
        [p,q] = correlatedDots(100,alpha);
        plot(p(:,1), p(:,2), 'x')
        hold on
        plot(q(:,1), q(:,2), 'o')
        title(sprintf('\\alpha=%1.1', alpha));
    end
    
end


fprintf('Square size: %d\n', side);

P = side*rand(ndots,3);
Q = side*rand(ndots,3);

ncorr = round(ndots*corrval);

Q(1:ncorr,:) = P(1:ncorr,:)+randn(ncorr,3);
Q = Q(randperm(size(Q,1)), :);

