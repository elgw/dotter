%% dotterscript.m
% Finds dots and plot them, see README.txt in this folder
% run setup.m to compile some code that is used.

%% Settings 

% Select a file to load
%s.file = '/Users/erikw/data/010312 caso 6927_11 N2/a594_012.tif';
%s.file = '/Users/erikw/data/010312 caso 6927_11 N2/a594_013.tif';
%s.file = '/Users/erikw/data/050313 caso 9291_12 N2/cy5_012.tif';

% 260713_4 (really good data)
%s.file =  '/Users/erikw/data/260713_4/a594_021.tif'; % 18--28
%s.file =  '/Users/erikw/data/260713_4/cy5_021.tif';
%s.file =  '/Users/erikw/data/260713_4/tmr_021.tif';

% Reza's images
%s.file = '/Users/erikw/Desktop/reza/IMG_2550.tif';
%s.file = '/Users/erikw/Desktop/reza/IMG_2551.tif';
%s.file = '/Users/erikw/Desktop/reza/5ul KBM7_4x-2.JPG'	
%s.sigmadog = 2.5;
%s.projection = 'sum';
%s.NPFIT = 0;
%s.file = '/Users/erikw/Desktop/reza/8ulKBM7-4x.JPG'
%s.file = '/Users/erikw/Desktop/reza/5ul KBM7_4x.JPG'	



if exist('path', 'var')
    %clearvars -except path
else        
    path = pwd;        
end
[file, path] = uigetfile({'*.tif'}, 'Select image to load', path);
s.file = [path file];
%s.file =  '/Users/erikw/data/260713_4/a594_021.tif'

% Images can be scanned for dots either 3D or in projection images or
% single slides. 
s.projection = 'none'; % 'none', 'max', 'sum'
%s.projection = 'sum';

% Localization method
s.localization = 'DoG'; % 'DoG', 'intensity'
s.localization = 'intensity';

% The number of points to fit with sub pixel precision.
% Since it takes some time to do the fitting, a possible strategy is to
% have a low value until it it known approximately how many dots that are
% interesting in the sample
s.NPFIT = 100;

% Initial sigma of the sub pixel precision fitting
s.sigmafitXY = 1.2;
s.sigmafitZ = 1.5;
% Fit sigma or use constant throughout the fitting
s.fitSigma = 1; 

% Remove dots that are close to the edge prior to sub pixel fitting
s.xypadding = 4;

% sigma of the dot detection DoG filter
s.sigmadog = s.sigmafitXY; % 1.2
% figure, imagesc(df_gaussianInt2([0,0], 2.5, 10)), colormap gray
s.useClustering = 0;
s.clusterMinDist = 2*s.sigmafitXY;
s.verbose = 0;

s.maxNpoints = 10000;
s.NCLUSTERPOINTS = min(s.maxNpoints, 50000); % Don't consider more than this in the clustering
s.nFitPoints = 1000;

disp('Settings: ')
disp(s)

%% Initialization
addpath('localization/')
%addpath('../df_gaussianInt2/')
%addpath('../common/')
%addpath('../volBucket/')

%% Read a TIF stack or a single image
disp('Reading image')
imageInfo = imfinfo(s.file);
if(strcmp(imageInfo(1).Format, 'tif'))
    V = df_readTif(s.file);
else
    V = double(imread(s.file));
end
V=double(V);
sumV = sum(V,3); % used when resolving overlapping points

if size(V,3)<15
    s.projection = 'sum';
end

%% Projection according to s.projection
if strcmp(s.projection, 'sum')
    I = sum(V, 3)/size(V,3);
end
if strcmp(s.projection, 'max')
    I = max(V, [], 3);
end
if strcmp(s.projection, 'none')
    I = V;
end

nsat = sum(I(:)==2^16-1);

if nsat
    fprintf('Warning: %d saturated pixels.\n', nsat);
end

%% candidates
P = dotCandidates(I, s);
fprintf('%d local maximas to consider\n', size(P,1));

if 0 % experimental, compare the response at two scales
% What linear filters to use?

% Create reference image.

TG = [];
for gsigma = .9:.1:2
    tg = 10000*df_gaussianInt2([0,0], gsigma, 11);
    tg = [tg; 10000*df_gaussianInt2([.5,.5], gsigma, 11)];
    TG = [TG, tg];
end

figure
subplot(2,1,1)
imagesc(TG), axis image
subplot(2,1,2)
plot(sum(TG, 1));
ax = axis();
ax(1) = 1; ax(2)=size(TG,2)
axis(ax)


    %[PX, PY, PZ]=ind2sub(size(I), P);
dog1 = gsmooth(I, s.sigmadog)-gsmooth(I, s.sigmadog+0.01);
dog2 = gsmooth(I, s.sigmadog+.5)-gsmooth(I, s.sigmadog+0.51);
ind = sub2ind(size(I), P(:,1), P(:,2), P(:,3));
r1 = dog1(ind);
r2 = dog2(ind);

figure,
plot(r2./r1, 'x')

figure,
hist(r2./r1, linspace(-10,10))

figure,
plot(r1, r2, 'x')

figure,
subplot(1,3,3)
plot(r1-r2, 'x')
subplot(1,3,1)
plot(r1, 'x')
subplot(1,3,2)
plot(r2, 'x')


xlabel('1.2'); ylabel('1.7');
dotterSlide(I, P(r2./r1<.5, 1:3))

end

% The points can be visualized already here, but will be further analyzed
% below
if 0    
    figure
    dotterSlide(I, P)  
end

% Ird = removeDots(I, P) 

PFIT = dotFitting(I,P(1:s.NPFIT,1:3),s);

%% End of image analysis, what remains is meta analysis and 
% visualization.

% Se if any points converged, probaly coincides with the points that moved
% more than x pixels. These clusters of points should be joined
%SS = S(~isnan(S));
%figure, hist(SS, 100)
converged = bcluster(PFIT(1:s.NPFIT, 1:3), .5);
disp('code to write here')

%% How much are the positions moved by the fitting procedure?
if 0
DIFF = (P(1:s.NPFIT,1:3) -PFIT(1:s.NPFIT,1:3));
D = sum(DIFF.^2,2).^(1/2);
figure
hist(D, 100)
title(sprintf('XYZ-fitting, %d points', s.NPFIT))

DIFF = (P(1:s.NPFIT,1:2) -PFIT(1:s.NPFIT,1:2));
D = sum(DIFF.^2,2).^(1/2);
figure
hist(D, 100)
title(sprintf('XY-fitting, %d points', s.NPFIT))
end

if 0
    % Plot fitting error vs the fitted number of photons per signal
    figure, loglog(PFIT(1:s.NPFIT,4), PFIT(1:s.NPFIT,5), 'x')
    xlabel('# photons')
    ylabel('Fitting error')
    set(gcf,'Units','inches');
    screenposition = get(gcf,'Position');
    set(gcf,...
        'PaperPosition',[0 0 screenposition(3:4)],...
        'PaperSize',[screenposition(3:4)]);
    print -dpdf nPhotons_fittingError.pdf
end


% Mask for Reza's images.
%R = ((P(:,2)-1300).^(2)+(P(:,3)-1900).^(2)).^(1/2);
%P2 = P(R<1200, :);
%    dotterSlide(I, P2)

if 1
disp('Visualizing fitting -- how the dots moved')
dotterSlide(I, [PFIT(1:s.NPFIT,1:3), P(1:s.NPFIT, 1:3)])
end

if 0
disp('Visualizing, ordered by DoG')
dotterSlide(I, P(:,1:3))
end

%% Experimental
if 0
gs.mode = 9;
ge = gaussianSize(I, P, [1:.2:3.6], gs);
dotterSlide(I, P, ge(:,2));
end

if 0
% Visualization, ordering by likelihood - how are the points that are not
% fitted ordered?
dotterSlide(I, PFIT(1:s.NPFIT,1:3), PFIT(1:s.NPFIT,4))  % N Photons
dotterSlide(I, PFIT(1:s.NPFIT,1:3), PFIT(1:s.NPFIT,5))  % Fitting error
end

if 0
    % Average number of photons per pixel/average error per pixel
    % time function of number of photons to favor strong signals
    figure
    [~, IDX]=sort(PFIT(1:s.NPFIT,4).^(1.5)./sqrt(PFIT(1:s.NPFIT,5)), 'descend');
    PFITs = PFIT(IDX, :);
    dotterSlide(I, PFITs)  
   % set(gca, 'clim', [5000, 15000])
end

%% 
disp('also consider analyzeDots.m')

%figure
%dotterSlide(I, P(P(:,1)>t, :))

if 0
% Log log plot
values = P(:,1);
figure,
loglog(values)
figure,
hist(values, 1024)

obj = fitgmdist(values,2);
mu = obj.mu;
sigma = obj.Sigma;

figure
D = linspace(min(values(:)), max(values(:)),1000);
plot(D,normpdf(D, mu(1), sigma(1)))
hold on
plot(D,normpdf(D, mu(2), sigma(2)), 'r')
end
