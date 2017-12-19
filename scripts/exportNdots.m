%%
% main.m -> analyzeDataset.m -> selectDots.m -> showResults.m
%                               exportNDots.m
%
% Loads all .twocolor files within a folder
% each of them contains the structures
% M: meta information
% N: nuclei
%
% Output:
% A single mat file with the structure 
% Nuclei: all ok nuclei and their dots and some meta data 

%% Settings
folder = '/Users/erikw/data/290113/290113_samplesOF280113/4/';
interactive = 0;
s.maxSeparation = 20; %pixels*125 nm
s.nc1dots = 32;
s.nc2dots = 44;
s.dapival = 3*10^9; % get from analyzeDataset
% Fitting
fittingSettings.sigmafitXY = 1;
fittingSettings.sigmafitZ = 1;
fittingSettings.useClustering = 1;
fittingSettings.clusterMinDist = 2*fittingSettings.sigmafitXY;
fittingSettings.fitSigma = 0;
fittingSettings.verbose = 0;   
    
%% Initialization
files = dir([folder '*twocolor']);
addpath('../dotter')
addpath('../deconv/')
Nuclei = [];
numOkNuclei = 0;

try
    mkdir([folder '/analysis'])
end

%% Dot analysis per nuclei
for kk = 1:numel(files) %% Per file
 

    F = [];
    load([folder files(kk).name], '-mat')
    
    mask = M.mask;
    idapi = df_readTif(M.dapifile);
    ic1 = df_readTif(M.c1file);
    ic2 = df_readTif(M.c2file);
    
    
    %% For each nuclei and each channel, select dots
    for ll = 1:numel(N)        
        fprintf('Image %d:nuclei %d =============================================\n', kk, ll)
        if N{ll}.dapisum < s.dapival           
            if N{ll}.area < 15000
           
    % Get the dots and discard those with too low intensity
    % also truncate if more than we are looking for
    c1dots = double(N{ll}.c1dots);   
    if size(c1dots,1)>s.nc1dots
        c1dots = c1dots(1:s.nc1dots, :);
    end
    
    c2dots = double(N{ll}.c2dots); 
    if size(c2dots,1)>s.nc2dots
        c2dots = c2dots(1:s.nc2dots, :);
    end
    
    if numel(c1dots)>0
        if numel(c2dots)>0
        
    
    %% High quality fitting
    c1fit = dotFitting(double(ic1), c1dots, fittingSettings);
    c2fit = dotFitting(double(ic2), c2dots, fittingSettings);
        
    %% Visualization
    d1 = c1fit(:,1:3);
    d2 = c2fit(:,1:3);
    
    if 0
    nmask = double(mask==ll);
    nmask = gsmooth(nmask, 1);
    
    nmask = repmat(nmask, 1,1,size(idapi,3));
    %nmask = nmask.*double(idapid);
    
    [faces, vertices] = isosurface(nmask, .5);
    vertices = vertices(:, [2,1,3]);
    md = mean([d1;d2]); % Centroid of the dots
    vertices(:,1) = (vertices(:,1)-md(1))*125;
    vertices(:,2) = (vertices(:,2)-md(2))*125;
    vertices(:,3) = (vertices(:,3)-md(3))*200;
    end
    
    % remove mean
    d1(:,1) = d1(:,1)-md(1);
    d1(:,2) = d1(:,2)-md(2);
    d1(:,3) = d1(:,3)-md(3);
    d2(:,1) = d2(:,1)-md(1);
    d2(:,2) = d2(:,2)-md(2);
    d2(:,3) = d2(:,3)-md(3);
    % scale x and y
    d1(:,1:2) = d1(:,1:2)*125;
    d1(:,3) = d1(:,3)*200;
    
    d2(:,1:2) = d2(:,1:2)*125;
    d2(:,3) = d2(:,3)*200;
    
    if 0
    fig = figure;
    p = patch('faces', faces, 'vertices', vertices, 'edgecolor', 'none', 'facealpha', .1);
    reducepatch(p, .1);
    hold on
    plot3(d1(:,1), d1(:,2), d1(:,3), 'ko', 'MarkerFaceColor', 'r');
    plot3(d2(:,1), d2(:,2), d2(:,3), 'ko', 'MarkerFaceColor', 'g');
    axis vis3d
    view(3)
    set(fig, 'color', 'white')  
    end
    
    % Possible ways to go:
    % blitting the signals separately and rendering with dapi - volumetric
   
    %% Save data
    disp('ok')
      F{ll}.c1fit = c1fit;
      F{ll}.c2fit = c2fit;        
      numOkNuclei = numOkNuclei + 1;
     
      NN = [];
      NN.c1dots = d1;
      NN.c2dots = d2;
      NN.c1name = M.channel1;
      NN.c2name = M.channel2;
      NN.dapifile = M.dapifile;
      NN.imageCentroid = N{ll}.centroid;
      Nuclei{numOkNuclei} = NN;           
        end
             end
            end
    
        end
    end
end

save([folder 'Nuclei.mat'], 'Nuclei')
