%% Test different estimators of FWHM
%
% Conditions:
% With/Without poisson noise
% Different number of photons
% Different signal shapes, i.e. Gaussian, Airy, ...
%
% To do:
%   - Implement Airy disk
%   - Create test images to run with FIJI
%   - Random/systematic offsets of the signals
%   - How is the measurement affected by noise? 
%     . Is the mean shifted?
%     . Is the variance changed?

%close all
%clear all

discrete = 0;

figure
N = 20;
side = 11;
[X, Y] = meshgrid(-side:side, -side:side);
r = (X(:).^2+Y(:).^2).^(1/2);
sigmas = linspace(.9, 2, N);
IT = [];
for kk=1:N
    sigma = sigmas(kk);
    I = df_gaussianInt2([0,0], sigma, 11);
    I = normpdf(X, 0, sigma).*normpdf(Y, 0, sigma);
    I = cat(3, I, I, I)
    t(kk) = sigma*2*sqrt(2*log(2));
   
    if 0
        % Sinc, FWHM = 2*1.89549
        I = sin(pi/sigma*r)./(pi/sigma*r);        
        I = reshape(I, size(X));
        I(12,12) = 1;
        I = I-min(I(:));
        I = I./sum(I(:));
        t(kk) = sigma*2*1.89549/pi;
    end
    
    if discrete
        I = I*10000;
        I = round(I);        
        I = imnoise(uint16(I), 'poisson');
    end
    I = double(I);
    
    IT = [IT I];
    %    imagesc(I)
    tic
    w(kk) = df_fwhm(I, [12,12,1]);
    toc
    tic
    F = dotFitting(I, [12,12,1]);
    toc
    f(kk) = F(6)*2*sqrt(2*log(2)); 
end

imwrite(double(IT)/max(IT(:)), 'dots.tif');

figure
%sim = 120*sigmas*2*sqrt(2*log(2));
sim = 131.08*t;
plot(sim, sim, 'k', 'LineWidth', 2)
hold on
plot(sim,  w*131.08, 'r:', 'LineWidth', 2)
plot(sim,  f*131.08, 'g--', 'LineWidth', 2)
%plot(sim(2:end), 2*120*[1.177, 1.177, 1.31, 1.329, 1.472, 1.490, 1.505, 1.520, 1.605], 'b')

legend({'Simulated', 'FWHM-New', 'FWHM-Old'})
%legend({'Simulated', 'FWHM-New', 'FWHM-Old', 'FIJI'})
grid on
axis equal
axis([000, 600, 000, 600])

figure,
imagesc(IT)
axis image
colormap gray

% title('PSF: Sampled Gaussian Profile, 10000 photons+Noise')
% print -dpng sampled_N.png

% title('PSF: Sampled Gaussian Profile')
% print -dpng sampled.png

%%
break
d = -11:11
figure,
plot(fspecial('gaussian', size(d), 4), 'r')
hold on
plot(normpdf(d, 0, 4), 'k')

Q = [
2.08536
2.04568
2.2723
2.16414
2.49224
2.55282
2.8248
2.87114
2.82424
3.14148
3.0592
3.32326
3.41528
3.09188
3.62802
3.6123
3.67438
3.68764
4.09936
4.27226]


%% 

%V = df_readTif('~/data/iEG78_111115_001/a594_001.tif');
files(1).name = '~/data/iJC60_071015_003/a594_quim_001.tif';
files(1).desc = 'iJC60/a594';
files(2).name = '~/data/iJC60_071015_003/tmr_quim_001.tif';
files(2).desc = 'iJC60/tmr';
files(3).name = '~/data/iJC60_071015_003/cy5_quim_001.tif';
files(3).desc = 'iJC60/cy5';
files(4).name = '~/data/iJC60_071015_003/dapi_quim_001.tif';
files(4).desc = 'iJC60/dapi';
files(5).name = '~/data/iEG78_111115_002/a594_001.tif';
files(5).desc = 'iEG78/a594';


for kk = 1:numel(files)
    files(kk).V = df_readTif(files(kk).name);
    files(kk).D = dotCandidates(files(kk).V);
    s.useClustering = 1;
    s.sigmafitXY = 1.5;
    s.sigmafitZ = 3;
    s.fitSigma = 0;
    s.verbose = 0;
    s.clusterMinDist = 7;
    files(kk).F = dotFitting(files(kk).V, files(kk).D(1:250,:), s);
    files(kk).H = df_fwhm(files(kk).V, files(kk).F(1:250,1:3));
end

for kk = 1:numel(files)
    files(kk).H = df_fwhm(files(kk).V, files(kk).F(:,1:3));
end

% Tetra beads:
% excitation/emission peaks 
% 360/430 nm (blue),  400 -- 600
% 505/515 nm (green), 
% 560/580 nm (orange), 550 -- 650
% 660/680 nm (dark red)

% Lasers:
% DAPI: 390 (blue, good)
% TMR:  560 (orange, perfect)
% A594, 555 (orange, good)
% Cy5:  640 (dark red good)

% Emission filters:
% DAPI 
% CY5
% TMR 
% A594

% https://www.thermofisher.com/se/en/home/life-science/cell-analysis/labeling-chemistry/fluorescence-spectraviewer.html
%       Excitation,       Emission    dx
% a594         590,  617-(570-750)    220-(203-268)

% dX = lambda/(2*n*sin(alpha)) = lambda/(2*NA)
% dX = 1.22*lambda/(NA_condenser+NA_objective)
% NA = 1.4

figure,
dom = linspace(1,1000,1000)
sp = 70;
sFiles = [2, 3, 5];
desc = {files(sFiles).desc};
for kk = 1:numel(sFiles)
    H = files(sFiles(kk)).H
    H = H(H>0);
    files(sFiles(kk)).fwhm = 131.08*H;
    plot(dom, kdeParzen(files(sFiles(kk)).fwhm, [], dom, sp), 'lineWidth', 2)
    hold all
    desc{kk} = sprintf('%s,\t %d', desc{kk}, numel(H));
end
legend(desc);

figure
plot(files(1).H, files(2).H, 'o')
plot(files(1).H, files(4).H, 'o')

%%
dotterSlide(files(1).V, files(1).F(1:100,:));
dotterSlide(files(5).V, files(5).D());

