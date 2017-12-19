%% Demonstrates localization when only the position is unknown
% I.e., sigma, N, and lambda are known.

% To do: optimization for small patches to find optimal parameters,
% including correct integrals over the gaussians

%close all


D = 1:100;

mu = 22.5;
sigma = 1.1;
N = 500;
bg = 10; % fluorescent background

s = bg+round(N*normpdf(D, mu, sigma));

figure, 
subplot(4,1,1)
plot(s);
title('True (infinite average)')

y = poissrnd(s);

subplot(4,1,2)
plot(y)
title('Poisson noise')

mus = 1:.1:100;
for kk=1:numel(mus)
    muu = mus(kk);
    L(kk) = LH(y, muu, sigma, N);
end

subplot(4,1,3)
plot(mus(:), L(:))

title('ML')

mus = 1:.1:100;
for kk=1:numel(mus)
    muu = mus(kk);
    G(kk) = GE(y-bg, muu, sigma, N, lambda);
end

subplot(4,1,4)
plot(mus(:), G(:))
title('gaussian')

%% 2D Plots sigma -- mu

[MU, SIGMA] = meshgrid(linspace(22,23), linspace(.65,1.5));
for kk=1:numel(MU)
    LL(kk)=LH(y, MU(kk), SIGMA(kk), N);
end
LL = reshape(LL, size(MU));

figure, 
surface(MU, SIGMA, 500*LL/max(LL(:)), LL, 'edgecolor', 'none')
%axis equal
view(3)
grid on
xlabel('mu')
ylabel('sigma')