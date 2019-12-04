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

% Known improvements to do:
% - Cluster locations in 3D
% - Look out for points that converge to the same location during fitting.
% - Add condition on DAPI? Or can we select G1 cells based on the analysis 
%   of aggretates of signals in the images?
% - Compare the two clusters, if they are dissimilar (in some sense) don't
%   continue.
% - Other ways to do the clustering into homologs besides the Euclidean 
%   distance to the cluster centre?

%% Settings
folder = '/Users/erikw/data/290113/290113_samplesOF280113/4/';
interactive = 0;
s.maxSeparation = 20; %pixels*125 nm
s.nc1dots = 32; % Number of dots in channel 1, per nuclei
s.nc2dots = 44;

s.clusterMinDist = 40;

% Fitting
fittingSettings.sigmafitXY = 1;
fittingSettings.sigmafitZ = 1;
fittingSettings.useClustering = 1;
fittingSettings.clusterMinDist = 2*fittingSettings.sigmafitXY;
fittingSettings.fitSigma = 0;
fittingSettings.verbose = 0;   


%% Initialization
files = dir([folder '*twocolor2']);
addpath('../dotter')
addpath('../deconv/')
Nuclei = [];
numOkNuclei = 0;

outFolder = '2Ndots/';

try
    mkdir([folder outFolder])
end

%% Dot analysis per nuclei
for kk = 1:numel(files) %% Per file
 

    F = [];
    load([folder files(kk).name], '-mat')
    
    mask = M.mask;
    idapi = df_readTif(M.dapifile);
    ic1 = df_readTif(M.c1file);
    ic2 = df_readTif(M.c2file);
    
    % sum projection and smoothing to get the clusters of each channel
    ic1c = gsmooth(sum(ic1,3), 5);
    ic2c = gsmooth(sum(ic2,3), 5);
    
    cLocus1 = dot_candidates(ic1c);
    % sort by pixel value
    [~, IDX]=sort(cLocus1(:,5), 'descend');
    cLocus1 = cLocus1(IDX, :);
    
    cLocus2 = dot_candidates(ic2c);
    [~, IDX]=sort(cLocus2(:,5), 'descend');
    cLocus2 = cLocus2(IDX, :);
   
    
    if 0
        ts.mask = mask;
        ts.limitedCLIM=0;
        dotterSlide(ic1c, cLocus1, [], ts);
    end
    
    cLocus1N = associateDots(mask, cLocus1);
    cLocus2N = associateDots(mask, cLocus2);
    
    
    %% For each nuclei and each channel, select dots
    for ll = 1:numel(N)        
        fprintf('Image %d:nuclei %d =============================================\n', kk, ll)
        
        clusterC1 = find(cLocus1N==ll);
        clusterC2 = find(cLocus2N==ll);
        disp('Clusters:')
        fprintf('In %s: %d\n', M.channel1, numel(clusterC1)); 
        fprintf('In %s: %d\n', M.channel2, numel(clusterC2));
        
        clustersok = 0;
        if numel(clusterC1)>1
            if numel(clusterC2)>1
                c1clusters = cLocus1(clusterC1(1:2), 1:2);
                c2clusters = cLocus2(clusterC2(1:2), 1:2);
                
                cd1 = distance22(c1clusters(1:2,1:2));
                cd2 = distance22(c2clusters(1:2, 1:2));
                
                if cd1>s.clusterMinDist
                    if cd2>s.clusterMinDist
                        clustersok = 1;
                    end
                end
            end
        end
        pause
        if clustersok
            disp('Cluster centers fine, continuing')
            % this means that there were at least to maximas in the nuclei
            % and that the strongest ones were separated by at least
            % s.clusterMinDist
            
            %% Take dots from channel1 to each cluster
            c1dots = double(N{ll}.c1dots);        
            [c1dotsClusters] = dotsToClusters(c1dots, c1clusters(1,1:2), c1clusters(2,1:2), s.clusterMinDist);
            clusterAdots = c1dots(c1dotsClusters==1,:);
            if size(clusterAdots,1)> s.nc1dots/2
                ch1dotsA = clusterAdots(1:s.nc1dots/2, : );
            end
            
            clusterBdots = c1dots(c1dotsClusters==2,:);
            if size(clusterBdots,1)> s.nc1dots/2
                ch1dotsB = clusterBdots(1: s.nc1dots/2, :);
            end
            
            
            %% Take dots from channel2 to each cluster.
            c2dots = double(N{ll}.c2dots);        
            [c2dotsClusters] = dotsToClusters(c2dots, c2clusters(1,1:2), c2clusters(2,1:2), s.clusterMinDist);
            clusterAdots = c2dots(c2dotsClusters==1,:);
            if size(clusterAdots,1) > s.nc2dots/2
                ch2dotsA = clusterAdots(1:s.nc2dots/2, : );
            end
            
            clusterBdots = c2dots(c2dotsClusters==2,:);
            if size(clusterBdots,1)> s.nc2dots/2
                ch2dotsB = clusterBdots(1: s.nc2dots/2, :);
            end
            
            %% sanity check on ch1dotsA, ch1dotsB, ch2dotsA, ch2dotsB
            
            %% High quality fitting
            ch1dotsAfit = dotFitting(double(ic1), ch1dotsA, fittingSettings);
            ch1dotsBfit = dotFitting(double(ic1), ch1dotsB, fittingSettings);
            
            ch2dotsAfit = dotFitting(double(ic2), ch2dotsA, fittingSettings);
            ch2dotsBfit = dotFitting(double(ic2), ch2dotsB, fittingSettings);
            
            %% Export 
            
            savename = sprintf('%s%s%d_%d.mat', folder, outFolder, kk, ll);
            save(savename, 'ch1dotsAfit', 'ch1dotsBfit', 'ch2dotsAfit', 'ch2dotsBfit', 'M', 'N')
        
            
            fig0 = figure;
            hold on
            plot3(ch1dotsAfit(:,2), ch1dotsAfit(:,1), ch1dotsAfit(:,3), 'o', ...
                'MarkerEdgeColor','k',...
                       'MarkerFaceColor','r');
            plot3(ch1dotsBfit(:,2), ch1dotsBfit(:,1), ch1dotsAfit(:,3), 'o', ...
                'MarkerEdgeColor','k',...
                       'MarkerFaceColor', 'yellow');
            plot3(ch2dotsAfit(:,2), ch2dotsAfit(:,1), ch2dotsBfit(:,3), 'o', ...
                'MarkerEdgeColor','k',...
                       'MarkerFaceColor','blue');
            plot3(ch2dotsBfit(:,2), ch2dotsBfit(:,1), ch2dotsBfit(:,3), 'o', ...
                'MarkerEdgeColor','k',...
                       'MarkerFaceColor','green');
            view(3)
            [faces, vertices]=isosurface(repmat(mask==ll, [1,1,3]));
            vertices(:,3) = vertices(:,3)+size(ic1, 3)/2-1;
            patch('faces', faces, 'vertices', vertices, 'EdgeColor', 'none', 'FaceColor', [.5,.5,.5], 'FaceAlpha', .5);
            axis equal
            savename = sprintf('%s%s%d_%d.fig', folder, outFolder, kk, ll);
            savenamepng = sprintf('%s%s%d_%d.png', folder, outFolder, kk, ll);
            
            savefig(savename);
            print('-dpng', savenamepng);
            close(fig0)
        end
   end
end
    
