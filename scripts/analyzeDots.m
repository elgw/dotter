% Some analysis on the fitted dots

% number of fitted dots
% s.NPFIT 

NMAX = 100000;

figure, 
hist(P(1:NMAX, 4), 1024)
title('DoG at fitted dots')

figure, 
hist(P(:, 4), 1024)
title('DoG at all dots')

dogP = P(:,4);
dogP = dogP(dogP>0);
figure, hist(log(dogP), 1024)

figure, 
hist(P(:, 5), 2048)
title('Intensity at all dots')

figure,
hist(I(:), 2048)
title('Histogram of image')


figure,
plot(P(1:NMAX,4), P(1:NMAX,5), 'o');
xlabel('DoG')
ylabel('Intensity')

figure, 
hist(PFIT(1:s.NPFIT, 4), linspace(0, max(PFIT(1:s.NPFIT,4))))
title('DoG at fitted dots')

figure
plot(PFIT(1:s.NPFIT, 4), PFIT(1:s.NPFIT, 5), 'o');
xlabel('Number of photons')
ylabel('Fitting error')

figure,
plot(PFIT(1:s.NPFIT, 4), P(1:s.NPFIT,4), 'o')
xlabel('Number of photons')
ylabel('DoG')
