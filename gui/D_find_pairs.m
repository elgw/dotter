%% Purpose: Find pairs of dots in two channels
%
% Will look pairs of strong signals, then export to cvs-files
% that will be analyzed with presentPairs.m

%% Dependencies
addpath('/Users/erikw/code/cluster3e/')

fittingSettings.sigmafitXY = 1.3;
fittingSettings.sigmafitZ = 2.27;
fittingSettings.useClustering = 1;
fittingSettings.clusterMinDist = fittingSettings.sigmafitXY;
fittingSettings.fitSigma = 0;
fittingSettings.verbose = 1;

%% Settings
if 0
folder = '/Users/erikw/data/iJC63_160915_003_calc/';
d0 = 15; % Distance between dots to be considered as connected
d0nm = 18*130; % The same in NM
naDots = 15; % Number of dots to consider for the clustering analysis from each channel
dapival = 1.6*10^10; % Nuclei with higher DAPI sum than this will be discarded
dotMinIntensityA = 5; % Exclude dots which are less bright than this
dotMinIntensityB = 6;
channelA = 'a594';
channelB  = 'cy5';
end

if 1
folder = '/Users/erikw/data/iJC65_160915_001_calc/';
d0 = 15; % Distance between dots to be considered as connected
d0nm = 18*130; % The same in NM
naDots = 15; % Number of dots to consider for the clustering analysis from each channel
dapival = 1.6*10^10; % Nuclei with higher DAPI sum than this will be discarded
dotMinIntensityA = 5; % Exclude dots which are less bright than this
dotMinIntensityB = 6;
channelA = 'a594';
channelB  = 'cy5';
end


%% GO
np = 0; % number found pairs
outFolder = [folder 'pairs_a594_cy5/'];

fprintf('Loading directory %s\n', folder);
files = dir([folder '*.NM']);
fprintf('%d files to look into\n', numel(files));

try
    mkdir(outFolder)
end

for kk = 1:numel(files) % Per file
    load([folder files(kk).name], '-mat')
    VA = df_readTif(strrep(M.dapifile, 'dapi', channelA));
    VB = df_readTif(strrep(M.dapifile, 'dapi', channelB));
    for nn =  1:numel(N) % Per nuclei
        fprintf('File: %d, nuclei: %2d, ', kk, nn);
        dotsA=[]; dotsAnm=[];
        dotsB=[]; dotsBnm=[];
        if N{nn}.dapisum < dapival
            fprintf('dapi ok, ');
            % Load the Alexa dots
            dotsA = N{nn}.dots{1};
            dotsB = N{nn}.dots{3};
            
            dotsA = dotsA(dotsA(:,4)>dotMinIntensityA, :);
            dotsB = dotsB(dotsB(:,4)>dotMinIntensityB, :);
            
            dotsAnm(:,1:3) = [dotsA(:,1:2)*130, dotsA(:,3)*200];
            dotsBnm(:,1:3) = [dotsB(:,1:2)*130, dotsB(:,3)*200];
            
            if size(dotsA,1)>0 && size(dotsB,1)>0
                
                P1status = 0;
                P2status = 0;
                
                % First pair
                P1_A = dotsA(1,:);
                dotsA = dotsA(2:end,:);
                
                d = eudist(repmat(P1_A(:,1:3).*[130,130,200], [size(dotsB,1), 1]), dotsBnm(:,1:3));
                locB = find(d<d0nm);
                if numel(locB)>0
                    P1status = 1;
                    P1_B = dotsB(locB(1), :);
                    dotsB = dotsB(setdiff(1:size(dotsB,1), locB(1)), :);
                    dotsBnm = dotsBnm(setdiff(1:size(dotsBnm,1), locB(1)), :);
                end
                
                % Second pair
                P2_A = [];
                locA = 1;
                while locA<=size(dotsA,1)
                    if norm(P1_A(1:3)-dotsA(locA(:,1),1:3))>d0
                        P2_A = dotsA(locA,:);
                        break
                    end
                    locA = locA+1;
                end
                if numel(P2_A)>0
                    d = eudist(repmat(P2_A(:,1:3).*[130,130,200], [size(dotsB,1), 1]), dotsBnm(:,1:3));
                    locB = find(d<d0nm);
                    if numel(locB)>0
                        P2status = 1;
                        P2_B = dotsB(locB(1), :);
                    end
                else
                    P2status = 0;
                end
                
            fprintf('\n');        
                if P1status == 1                    
                    np= np+1;
                    x = datestr(now);
                    exportFilename = sprintf('%s%d_%d_%s_A_%s.cvs', outFolder, kk, nn, 'a594', x);
                    fprintf('Exporting P1-a594 to %s\n', exportFilename)
                    dots = dotFitting(double(VA), P1_A, fittingSettings);
                    dots = d_stickyz(dots, P1_A, 1);
                    csvwrite(exportFilename, dots)                    
                    exportFilename = sprintf('%s%d_%d_%s_A_%s.cvs', outFolder, kk, nn, 'tmr', x);
                    fprintf('Exporting P1-tmr to %s\n', exportFilename)
                    dots = dotFitting(double(VB), P1_B, fittingSettings);
                    dots = d_stickyz(dots, P1_B, 1);
                    csvwrite(exportFilename, dots)                    
                end
                
                if P2status == 1
                    np= np+1;
                    x = datestr(now);
                    exportFilename = sprintf('%s%d_%d_%s_B_%s.cvs', outFolder, kk, nn, 'a594', x);
                    fprintf('Exporting P2-a594 to %s\n', exportFilename)
                    dots = dotFitting(double(VA), P2_A, fittingSettings);
                    dots = d_stickyz(dots, P2_A, 1);
                    csvwrite(exportFilename, dots)                    
                    exportFilename = sprintf('%s%d_%d_%s_B_%s.cvs', outFolder, kk, nn, 'tmr', x);
                    fprintf('Exporting P2-tmr to %s\n', exportFilename)
                    dots = dotFitting(double(VB), P2_B, fittingSettings);
                    dots = d_stickyz(dots, P2_B, 1);
                    csvwrite(exportFilename, dots)                    
                end
                
            end            
        end
        
    end
end
 
fprintf('Found %d pairs\n', np);  
fprintf('Data written to %s\n', outFolder);  
