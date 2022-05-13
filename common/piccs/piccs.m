function [alpha] = piccs(D1, D2, lmin, lmax, imSize)
%% function [Ccum] = piccs(D1, D2, lmin, lmax, imSize)
% Particle Cross-Correlation Spectroscopy (PICCS)
% Implementation of semrau2011quantification
%
% Notes:
% - takes 3D coordinates as input but uses only the first two dimensions
% (i.e. 2D).
%
% Input: 
% D1, D2 : dots from channel 1 and 2
% lmin and lmax : indicates the region to measure the slope. lmin is
% optional
% imSize: size of the image from which the dots were extracted.
% Please make sure that all inputs have the same units.
%
% Output:
% alpha, see the paper
%
% Example 1: simulated data
% ndots = 500;
% cval = 1; % Perfect correlation
% imSize = 256;
% [P,Q] = correlatedDots(ndots, cval, imSize);
% lmax = 5;
% piccs(P,Q,[], lmax, [imSize, imSize])
%
% cval = .5; % Poor correlation
% [P,Q] = correlatedDots(ndots, cval, imSize);
% piccs(P,Q,[], lmax, [imSize, imSize])
%
% Example 2: real data
% 
% Assume that there are two image files in the current folder,
% a594_001.tif and cy5_001.tif and that there is no chromatic aberrations:
%  I1 = df_readTif('a594_001.tif');
%  D1 = dotCandidates(I1);
%  th1 = dotThreshold(D1(:,4))
%  ndots1 = sum(D1(:,4)>th1);
%  % F1 = dotFitting(I1(1:ndots,:), D1);
%  I2 = df_readTif('cy5_001.tif');
%  D2 = dotCandidates(I2);
%  th2 = dotThreshold(D2(:,4))
%  ndots2 = sum(D2(:,4)>th2);
%  % F2 = dotFitting(I2(1:ndots,:), D2);  
%  lmax = 10;
%  a = piccs(D1(1:ndots, 1:3), D2(1:ndots, 1:3), [], lmax, size(I1))
%  % or 
%  piccs(D1(1:ndots, 1:3), D2(1:ndots, 1:3), [], lmax, size(I1))
%  To show some plots

% If no input, start GUI
if nargin==0
    piccs_gui
    return
end

if nargin<5
    disp('Too few input arguments')
    help piccs
    return
end

% Validate input
if size(D1,1)>size(D1,2)
    D1 = D1';
end
if size(D2,1)>size(D2,2)
    D2 = D2';
end

if (size(D1,2)<4)
    disp('To few points in D1')
    return
end

if (size(D2,2)<4)
    disp('To few points in D2')
    return
end

if size(D1,1)==2
    D1 = [D1; 0*D1(1,:)];
end
 
if size(D2,1)==2
    D2 = [D2; 0*D2(1,:)];
end
    
if size(D1,1)~=3
    disp('Wrong size of D1')
    return
end

if size(D2,1)~=3
    disp('Wrong size of D2')
    return
end

if numel(lmin)==0
    lmin = lmax*sqrt(5)/3;
end

fprintf('%d dots in D1\n', size(D1,2));
fprintf('%d dots in D2\n', size(D2,2));
fprintf('lmin: %f nm\n', lmin);
fprintf('lmax: %f nm\n', lmin);
fprintf('Image size: %d x %d\n', imSize(1), imSize(2));

fprintf('Calculating C_{cum}\n');
keyboard
tic
C = ccum_mex(D1, D2, imSize, lmax);
tcorr=toc;
fprintf('done, took %f s\n', tcorr);

% Define the corresponding domain
D = linspace(0, lmax^2, numel(C));

lminLocation = lmin^2/lmax^2*numel(C);
lmaxLocation = lmax^2/lmax^2*numel(C);

locmax = round(lmaxLocation);
locmin = round(lminLocation);

% TODO: Mean square fitting instead of just looking at
% the end points
slope = (C(locmax)-C(locmin))/(D(locmax)-D(locmin));
alpha = C(locmin)-D(locmin)*slope;

if nargout == 0

figure
scatter(D1(1,:), D1(2,:), 'x')
hold on
scatter(D2(1,:), D2(2,:), 'o')
hold on
d = linspace(0,2*pi);
m = imSize/2;

plot(m(1)+lmin*sin(d), m(2)+lmin*cos(d), 'k')
plot(m(1)+lmax*sin(d), m(2)+lmax*cos(d), 'k')
axis([0, imSize(1), 0, imSize(2)])
axis image

figure
clf
plot(D, C) 
grid on
ax = axis;
hold on
ax(1)=0;
ax(3)=0;
axis(ax);
xlabel('l^2 [au^2]')
ylabel('Average # of P2 dots around P1 dots')

plot([1,1]*lmin^2, ax(3:4))
plot([1,1]*lmax^2, ax(3:4))

hold on
ax = axis;
plot(D,D*slope+alpha, 'k--')
legend({'C_{cum}', 'l_{min}', 'l_{max}', 'linear contribution'}, ...
    'Location', 'SouthEast')

title(sprintf('\\alpha=%1.2f', alpha), 'Interpreter', 'TeX');
end

end

