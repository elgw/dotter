function J = removeDots(I, P, s)
% Create an image with all dots in P. This map can be removed from
% the image prior to fitting.

sigma0 = s.sigmafitXY;
sigma0 = 3;

dots = clearBoarders(I, 3);
imax = imdilate(dots, strel('square', 5));
imin = imerode(dots,strel('square', 5));
imax = clearBoarders(imax,5,-1);

maxpoints = imax==dots & imax>imin;

%figure, imagesc(maxpoints)

maxpoints = maxpoints.*(imax-imin);

J = gsmooth(maxpoints, s.sigmafitXY)/gsmooth(1, s.sigmafitXY);

figure, imagesc(I), axis image, colormap gray
figure, imagesc(I-J), axis image, colormap gray

if 0
J = zeros(1023, 1023);
for kk=1:size(P,1)
    progressbar(kk, size(P,1))
    mu0 = P(kk,1:2)-511;    
    J = J+df_gaussianInt2(mu0, sigma0, (size(I, 1)-2)/2);
end
end
