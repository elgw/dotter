%% Two dimensional localization of multiple beads in close proximity

close all, clear all

%% Settings
% Constant sigma, known from the PSF
sigma = 1.2;
gridsize = 65;

% Position
% The first bead is random, and the other in close proximity
mu1(1) = 10+rand(1)*(gridsize-20); mu1(2) = 10+rand(1)*(gridsize-20);
theta = 2*pi*rand(1);
mu2 = mu1+(3+rand(1))*[cos(theta), sin(theta)];
muu = [mu1 mu2];

% Parameters that determine the signal to noise ratio
N = [15000, 15000];
lambda=7000;
gridmid = (gridsize+1)/2;


%% Initialize
addpath('../df_gaussianInt2/')
[Y,X] = meshgrid(1:gridsize, 1:gridsize);

%s = round(N*mvnpdf([X(:), Y(:)], mu, sigma*eye(2)));
%s = reshape(s, size(X));
s1 = N(1)*df_gaussianInt2([mu1(1)-gridmid, mu1(2)-gridmid], sigma, gridmid-1);
s2 = N(2)*df_gaussianInt2([mu2(1)-gridmid, mu2(2)-gridmid], sigma, gridmid-1);
s = s1+s2;

f1 = figure;
subplot(2,2,1)
imagesc(s), colormap gray, axis image

noise = poissrnd(lambda, size(X,1), size(X,2));

subplot(2,2,2)
imagesc(noise), colormap gray, axis image

y = noise+s;
subplot(2,2,3)
imagesc(y), colormap gray, axis image
hold on,
plot(muu(2), muu(1), 'go');
hold on
plot(muu(4), muu(3), 'gx');

% determine the region to cut out, i.e. patch
padding = 4;
rmuu = round(muu);
xmin = min(rmuu(1), rmuu(3))-4;
xmax = max(rmuu(1), rmuu(3))+4;
ymin = min(rmuu(2), rmuu(4))-4;
ymax = max(rmuu(2), rmuu(4))+4;
width = max(xmax-xmin, ymax-ymin);
patch = y( xmin:xmin+width, ymin:ymin+width );


% muup: muu for the patch
muup = muu; 
muup(1)=muup(1)-xmin+1;
muup(2)=muup(2)-ymin+1;
muup(3)=muup(3)-xmin+1;
muup(4)=muup(4)-ymin+1;

%f2=figure, imagesc(patch), colormap gray, axis image
%hold on
%plot(muup(2), muup(1), 'yx')
%plot(muup(4), muup(3), 'yx')

muup = muup-(size(patch,1)+1)/2;

tic
    x2=gaussFit2multi(patch, sigma, muup);
toc


figure(f1)
subplot(2,2,3)

plot(x2(2)+ymin+width/2, x2(1)+xmin+width/2, 'rx')
plot(x2(4)+ymin+width/2, x2(3)+xmin+width/2, 'ro')

if 0
    fprintf('Parameter \t True \t E ML \t E LQ\n');
    fprintf('x         \t %2.2f \t %2.2f \t %2.2f \n', mu(1), x(1)+muA-4, x2(1)+muA-4)
    fprintf('y         \t %2.2f \t %2.2f \t %2.2f \n', mu(2), x(2)+muB-4, x2(2)+muB-4)
    %fprintf('sigma     \t %2.2f \t %2.2f \n', sigma, x(3))
    fprintf('lambda    \t %d \t %d \n', lambda, round(x(3)));
    fprintf('N         \t %d \t %d \n', N, round(x(4)));
end

%sest = round(N*mvnpdf([X(:), Y(:)], mu, sigma^2*eye(2)));
%sest=reshape(sest, size(X));

figure, 
subplot(2,2,1)
imagesc(lambda+s(xmin:xmin+width, ymin:ymin+width)), hold on
%view(3)
title('true')
axis image

subplot(2,2,2)
imagesc(y(xmin:xmin+width, ymin:ymin+width)), hold on
%view(3)
title('measured')
axis image

subplot(2,2,3)

imagesc(x2(5)*df_gaussianInt2([x2(1), x2(2)], sigma, (size(patch,1)+1)/2)+ ...
        x2(6)*df_gaussianInt2([x2(3), x2(4)], sigma, (size(patch,1)+1)/2));
hold on
%view(3)
title('estimated -- Q')
axis image

