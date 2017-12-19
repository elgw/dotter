%% Purpose: Find pairs of dots in two channels
%
% Will look pairs of strong signals, then export to cvs-files
% that will be analyzed with presentPairs.m

%% Dependencies
addpath('/Users/erikw/code/cluster3e/')
close all

%% Settings
if 0
folder = '/Users/erikw/data/iJC63_160915_003_calc/';
d0 = 15; % Distance between dots to be considered as connected
d0nm = 18*130; % The same in NM
naDots = 15; % Number of dots to consider for the clustering analysis from each channel
dapival = 1.6*10^10; % Nuclei with higher DAPI sum than this will be discarded
dotMinIntensityA = 11; % Exclude dots which are less bright than this
dotMinIntensityB = 12;
end

if 0
folder = '/Users/erikw/data/iJC65_160915_001_calc/';
d0 = 15; % Distance between dots to be considered as connected
d0nm = 18*130; % The same in NM
naDots = 15; % Number of dots to consider for the clustering analysis from each channel
dapival = 1.6*10^10; % Nuclei with higher DAPI sum than this will be discarded
dotMinIntensityA = 5; % Exclude dots which are less bright than this
dotMinIntensityB = 9;
end

if 1
folder = '/Users/erikw/data/121212_calc/';
d0 = 15; % Distance between dots to be considered as connected
d0nm = 18*130; % The same in NM
naDots = 15; % Number of dots to consider for the clustering analysis from each channel
dapival = 1.6*10^10; % Nuclei with higher DAPI sum than this will be discarded
dotMinIntensityA = 8; % Exclude dots which are less bright than this
dotMinIntensityB = 11;
end

NDotsA = [];
NDotsT = [];

%% GO
D = []; % To store output data

outFolder = [folder 'pairs/'];

fprintf('Loading directory %s\n', folder);
files = dir([folder '*.NM']);
fprintf('%d files to look into\n', numel(files));

try
    mkdir(outFolder)
end

for kk = 1:numel(files) % Per file
    load([folder files(kk).name], '-mat')
    
    for nn =  1:numel(N) % Per nuclei
        fprintf('File: %d, nuclei: %2d\n', kk, nn);
        dots=[]; dotsnm=[];
        
        if N{nn}.dapisum < dapival
            fprintf('dapi ok, ');
            % Load the Alexa dots
            dots = N{nn}.dots{cc};            
            
            NDots = [NDots; dots];
                        
            dots = dots(dots(:,4)>M.threshold(cc), :);
            
            D = [D; [kk, nn, size(dotsA,1)];
            
            dotsnm(:,1:3) = [dots(:,1:2)*130, dots(:,3)*200];
                        
            if size(dots,1)>0 && size(dotsB,1)>0
                
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
            end            
        end                
    end            
end

% We might want to run it again with another threshold for the dot
% intensities, then load volume and set something resonable in dotterSlide


figure
hist(D(:,3), [1:25])
axis([0,25,0,25])
xlabel('dots per nuclei')
ylabel('#')
title('Probe 13')

%print -dpng dotsPerNuclei_13_14.png

figure

hist(NDotsA(:,4), linspace(0,100, 1000))
title('NDotsA')
