%%
% main.m -> analyzeDataset.m -> selectDots.m -> showResults.m
%
% Loads all .twocolor files within a folder
% each of them contains the structures
% M: meta information
% N: nuclei
%
% Output:
% F: a subselection of dots, with probabilities assigned to them
%
% First all nuclei are loaded to see their DAPI strength and area

% To do:
% - gaussian blitting for visualization.
% - assign probabilities to all dots, that they are probes,
%   based on P(probe)/P(noise), and clustering properties.
% - check with magda that the spacings are correct, i.e. 125 vs 200 (z)

folder = '/Users/erikw/data/121212_5/';
files = dir([folder '*NM']);
addpath('../dotter')
addpath('../deconv/')
addpath('../common/')
addpath('../volBucket/')

try
    mkdir([folder '/analysis'])
end

interactive = 0;
s.maxSeparation = 20; %pixels*125 nm
s.nc1dots = 32;
s.nc2dots = 44;
s.dapival = 2.8*10^9; % get from analyzeDataset

logfilename = [folder 'analysis/' 'log.txt'];
fprintf('Log file: %s\n', logfilename);

%% Dot analysis per nuclei
for kk = 1:numel(files) %% Per file
 
    numOkNuclei = 0;
    F = [];
    load([folder files(kk).name], '-mat')
    
    
    mask = M.mask;
    idapi = df_readTif(M.dapifile);    
    
    if interactive
    %% Select Nuclei to use
    H = .2*ones(size(mask));
    S = double(mask>0);
    V = sum(idapi,3);
    V = normalisera(V);    
    for ll = 1:numel(N)
        if N{ll}.dapisum > s.dapival
            H(mask == ll) = 0;
        end
    end
    figure, imshow(hsv2rgb(H,S,V));
    for rr = 1:numel(N)
        text(N{rr}.centroid(2), N{rr}.centroid(1), num2str(rr), 'FontSize', 20, 'Color', 'w');
    end
    end
    
    %% For each nuclei and each channel, select dots
    for ll = 1:numel(N)
    
        
        fprintf('Image %d:nuclei %d =============================================\n', kk, ll)
        if N{ll}.dapisum > s.dapival
            fprintf('Too high much DAPI, skipping nuclei\n');
        break
        end
           
    if N{ll}.area > 150000
       fprintf('To large area, skipping nuclei \n');
       break
    end
    
    for cc = 1:numel(M.channels)
    ichannel = df_readTif(M.channelf{cc});
        
    % Get the dots and discard those with too low intensity
    % also truncate if more than we are looking for
    dots = double(N{ll}.dots{cc});
    
    %C=df_bcluster(dots(:,1:3), s.maxSeparation);
    %figure, df_bcluster_plot(C, dots);
    %pause
    
    %c1dots = c1dots(c1dots(:,4)>c1val, :); 
    if size(dots,1)>M.nTrueDots(cc);
        c1dots = c1dots(1:M.nTrueDots(cc), :);
    end
    
    if numel(dots)==0
        fprintf('No dots\n')
        break
    end

    pause
    if 0
    % Cluster analysis
    C1=df_bcluster(c1dots(1:min(size(c1dots,1), nc1dots),1:3), s.maxSeparation);
    if numel(C1)==14 && sum(C1==0)==0
        disp('channel 1 ok');
        ok1  =1;
    else
        disp('channel 1 bad');
        ok1 = 0;
    end
    
    C2=df_bcluster(c2dots(1:14,1:3), s.maxSeparation);
    if numel(C2)==14 && sum(C2==0)==0
        %disp('channel 2 ok');
        ok2 = 1;
    else 
        %disp('channel 2 bad');
        ok2 = 0;
    end
    
    if ok1*ok2
        fprintf('Both channels fine in nuclei %d\n', ll)
    else
        fprintf('Rejecting nuclei %d from initial clustering (%d, %d)\n', ll, ok1, ok2)
    end
    end
    
    if interactive
    dotterSlide(ic1, c1dots);
    figure
    dotterSlide(ic2, c2dots);

    dotterSlide(ic1, c1fit);
    end
    
    %% High quality fitting
    %if ok1*ok2
    fittingSettings.sigmafitXY = 1;
    fittingSettings.sigmafitZ = 1;
    fittingSettings.useClustering = 1;
    fittingSettings.clusterMinDist = 2*fittingSettings.sigmafitXY;
    fittingSettings.fitSigma = 0;
    fittingSettings.verbose = 0;   
    c1fit = dotFitting(double(ic1), c1dots, fittingSettings);
    c2fit = dotFitting(double(ic2), c2dots, fittingSettings);
    %end
    
    
    %% Visualization
    d1 = c1fit(:,1:3);
    d2 = c2fit(:,1:3);
    
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
    
    fig = figure;
    p = patch('faces', faces, 'vertices', vertices, 'edgecolor', 'none', 'facealpha', .1);
    reducepatch(p, .1);
    hold on
    plot3(d1(:,1), d1(:,2), d1(:,3), 'ko', 'MarkerFaceColor', 'r');
    plot3(d2(:,1), d2(:,2), d2(:,3), 'ko', 'MarkerFaceColor', 'g');
    axis vis3d
    view(3)
    set(fig, 'color', 'white')  
    
    % Possible ways to go:
    % blitting the signals separately and rendering with dapi - volumetric
   
    %% Save data
    %if ok1*ok2
        F{ll}.c1fit = c1fit;
        F{ll}.c2fit = c2fit;
        %F{ll}.quality = quality;
        numOkNuclei = numOkNuclei + 1;
        logfile = fopen(logfilename, 'a');
        fprintf(logfile, '%d: %s, numOkNuclei: %d\n', kk, files(kk).name, numOkNuclei);
        fclose(logfile);
    %end
        close(fig);
    end
    
    % Per file again.
    if numel(F)>0
        save([folder files(kk).name], 'N','M','F')   
    end
    end
    end