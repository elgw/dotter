close all
clear all

bgsigma = 100;

H = 100; % Height 
W = 120; % Width

N = 10000; % Number of photons in signal
fbsigma = 2; % Width of the signal

x = W*rand(1);
y = H*rand(1);

% Create a test image
I = bgsigma*randn(H,W);

[XX,YY]=meshgrid(1:W, 1:H);
XXYY = [XX(:) YY(:)];

pdf = mvnpdf(XXYY, [x,y], eye(2)*fbsigma);
pdf = reshape(pdf, size(XX));

% This creates a perfect gaussian for the signal, 
% To make it more relistic, it should be sampled.
I = I+N*pdf;

figure,
imshow2(I)
hold on
plot(x,y,'rx')

%% Part 2, localization

l.bgmu = 0;
l.bgsigma = bgsigma;
l.x = x;
l.y = y;
l.sigma = 2;
l.N = 10000;

ML2A(I, l)
