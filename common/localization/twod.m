%% Two dimensional localization
close all
%clear all

%% Settings
% Constant sigma, known from the PSF
sigma = 1.1;
gridsize = 65;

% A random position
% mu = [6.9, 5.2];
mu(1) = 10+rand(1)*(gridsize-20); mu(2) = 10+rand(1)*(gridsize-20);

% Parameters that determine the signal to noise ratio
N = 5000;
bg = 500;
normsigma = 4; % gaussian noise of detector

gridmid = (gridsize+1)/2;

%% Initialize
addpath('../df_gaussianInt2/')
[Y,X] = meshgrid(1:gridsize, 1:gridsize);

%s = round(N*mvnpdf([X(:), Y(:)], mu, sigma*eye(2)));
%s = reshape(s, size(X));
s = bg + N*df_gaussianInt2([mu(1)-gridmid, mu(2)-gridmid], sigma, gridmid-1);

f1 = figure;
subplot(1,2,1)
imagesc(s), colormap gray, axis image

y = poissrnd(s)+round(normsigma*randn(size(s)));
subplot(1,2,2)
imagesc(y), colormap gray, axis image
hold on,
plot(mu(2), mu(1), 'go');

muA = round(mu(1)); muB = round(mu(2));
patch = y( (muA-3):(muA+3), (muB-3):(muB+3) );
f2=figure, imagesc(patch), colormap gray, axis image


disp('Method 1')
tic
    x=LH2(patch, sigma);
toc
disp('Method 2')
tic
    %x2=gaussFit2(patch, sigma);
    x2 = LH2G(patch, sigma);
toc


figure(f2)
hold on
plot(x(2), x(1), 'gx')
hold on
plot(x(2), x(1), 'gx')


figure(f1)
subplot(1,2,2)
plot(x(2)+muB-4, x(1)+muA-4, 'ro')
plot(x2(2)+muB-4, x2(1)+muA-4, 'rx')
legend({'true', 'M1', 'M2'})

fprintf('Parameter \t True \t M1 \t M2 \n');
fprintf('x         \t %2.2f \t %2.2f \t %2.2f \n', mu(1), x(1)+muA-4, x2(1)+muA-4)
fprintf('y         \t %2.2f \t %2.2f \t %2.2f \n', mu(2), x(2)+muB-4, x2(2)+muB-4)
%fprintf('sigma     \t %2.2f \t %2.2f \n', sigma, x(3))
fprintf('bg        \t %d \t %d \t %d \n', bg, round(x(3)), round(x2(3)));
fprintf('N         \t %d \t %d \t %d \n',  N, round(x(4)), round(x2(4)));


sest = round(N*mvnpdf([X(:), Y(:)], mu, sigma^2*eye(2)));
sest=reshape(sest, size(X));

figure, 
subplot(2,2,1)
imagesc(bg+s(muA-4:muA+4, muB-4:muB+4)), hold on
%view(3)
title('true')
axis image

subplot(2,2,2)
imagesc(y(muA-4:muA+4, muB-4:muB+4)), hold on
%view(3)
title('measured')
axis image

subplot(2,2,3)
imagesc(df_gaussianInt2([x(1)-4, x(2)-4], sigma, 4)), hold on
%view(3)
title('estimated -- 1')
axis image

subplot(2,2,4)
imagesc(df_gaussianInt2([x2(1)-4, x2(2)-4], sigma, 4)), hold on
%view(3)
title('estimated -- 2')
axis image

