%% Purpose: Find pairs and triplets, i.e., two or three
% distinct dots in one allele.
%
% Dots in the clusters are fitted using ML and then the values are
% corrected for chromatic aberrations (CA).

close all
clear all

%% Dependencies
addpath('/Users/erikw/code/cluster3e/')
addpath('~/code/cCorr/')

% Pixel size/resolution
rxy = 131.08;
rz = 200;

useFitting = 1;
fittingSettings.sigmafitXY = 1.3;
fittingSettings.sigmafitZ = 2.27;
fittingSettings.useClustering = 1;
fittingSettings.clusterMinDist = fittingSettings.sigmafitXY;
fittingSettings.fitSigma = 0;
fittingSettings.verbose = 1;


ex = 1;
%% Data set and data set specific settings
 % 1,2,13
E{ex}.folder = '/Users/erikw/data/iEG40_211019_002_calc/';
E{ex}.d0 = 15; % Distance between dots to be considered as connected, in pixels, times 120 in nm
E{ex}.dotRatio = .5; % exclude if other dot is more than dotRatio of the strongest
E{ex}.channels = [1,2,3];
ex = ex+1;

 % 1,2,13
E{ex}.folder = '/Users/erikw/data/iEG41_281015_002_calc/';
E{ex}.d0 = 15; % Distance between dots to be considered as connected, in pixels, times 120 in nm
E{ex}.dotRatio = .5; % exclude if other dot is more than dotRatio of the strongest
E{ex}.channels = [1,2,3];
ex = ex+1;

% 13, 14
E{ex}.folder = '/Users/erikw/data/iJC98_041115_001_calc/';
E{ex}.d0 = 15; % Distance between dots to be considered as connected, in pixels, times 120 in nm
E{ex}.dotRatio = .5; % exclude if other dot is more than dotRatio of the strongest
E{ex}.channels = [1,2];
ex = ex+1;

% 13, 14
E{ex}.folder = '/Users/erikw/data/iJC99_041115_002_calc/';
E{ex}.d0 = 15; % Distance between dots to be considered as connected, in pixels, times 120 in nm
E{ex}.dotRatio = .5; % exclude if other dot is more than dotRatio of the strongest
E{ex}.channels = [1,2];
ex = ex+1;

% 13, 14
E{ex}.folder = '/Users/erikw/data/iJC99_041115_003_calc/';
E{ex}.d0 = 15; % Distance between dots to be considered as connected, in pixels, times 120 in nm
E{ex}.dotRatio = .5; % exclude if other dot is more than dotRatio of the strongest
E{ex}.channels = [1,2];
ex = ex+1;

% 13, 14
E{ex}.folder = '/Users/erikw/data/iJC99_041115_004_calc/';
E{ex}.d0 = 15; % Distance between dots to be considered as connected, in pixels, times 120 in nm
E{ex}.dotRatio = .5; % exclude if other dot is more than dotRatio of the strongest
E{ex}.channels = [1,2];
ex = ex+1;


% 14, 3, 4
E{ex}.folder = '/Users/erikw/data/iEG40_211019_003_calc/';
E{ex}.d0 = 15; % Distance between dots to be considered as connected, in pixels, times 120 in nm
E{ex}.dotRatio = .5; % exclude if other dot is more than dotRatio of the strongest
E{ex}.channels = [1,2,3];
ex = ex+1;

% 14, 3, 4
E{ex}.folder = '/Users/erikw/data/iEG60_021115_001_calc/';
E{ex}.d0 = 15; % Distance between dots to be considered as connected, in pixels, times 120 in nm
E{ex}.dotRatio = .5; % exclude if other dot is more than dotRatio of the strongest
E{ex}.channels = [1,2,3];
ex = ex+1;

% 14, 3, 4
E{ex}.folder = '/Users/erikw/data/iEG60_021115_002_calc/';
E{ex}.d0 = 15; % Distance between dots to be considered as connected, in pixels, times 120 in nm
E{ex}.dotRatio = .5; % exclude if other dot is more than dotRatio of the strongest
E{ex}.channels = [1,2,3];
ex = ex+1;


% 5,6,7
E{ex}.folder = '/Users/erikw/data/iEG40_211019_004_calc/';
E{ex}.d0 = 15; % Distance between dots to be considered as connected, in pixels, times 120 in nm
E{ex}.dotRatio = .5; % exclude if other dot is more than dotRatio of the strongest
E{ex}.channels = [1,2,3];
ex = ex+1;

% 5,6,7
E{ex}.folder = '/Users/erikw/data/iEG43_281015_002_calc/';
E{ex}.d0 = 15; % Distance between dots to be considered as connected, in pixels, times 120 in nm
E{ex}.dotRatio = .5; % exclude if other dot is more than dotRatio of the strongest
E{ex}.channels = [1,2,3];
ex = ex+1;

% 5,6,7
E{ex}.folder = '/Users/erikw/data/iEG61_031115_001_calc/';
E{ex}.d0 = 15; % Distance between dots to be considered as connected, in pixels, times 120 in nm
E{ex}.dotRatio = .5; % exclude if other dot is more than dotRatio of the strongest
E{ex}.channels = [1,2,3];
ex = ex+1;

% 5,6,7
E{ex}.folder = '/Users/erikw/data/iJC96_041115_001_calc/';
E{ex}.d0 = 15; % Distance between dots to be considered as connected, in pixels, times 120 in nm
E{ex}.dotRatio = .5; % exclude if other dot is more than dotRatio of the strongest
E{ex}.channels = [1,2,3];
ex = ex+1;


% 8, 9, 10
E{ex}.folder = '/Users/erikw/data/iEG40_211019_005_calc/';
E{ex}.d0 = 15; % Distance between dots to be considered as connected, in pixels, times 120 in nm
E{ex}.dotRatio = .5; % exclude if other dot is more than dotRatio of the strongest
E{ex}.channels = [1,2,3];
ex = ex+1;

 % 11,12
E{ex}.folder = '/Users/erikw/data/iEG45_281015_001_calc/';
E{ex}.d0 = 15; % Distance between dots to be considered as connected, in pixels, times 120 in nm
E{ex}.dotRatio = .5; % exclude if other dot is more than dotRatio of the strongest
E{ex}.channels = [1,2];
ex= ex+1;

% 11,12
E{ex}.folder = '/Users/erikw/data/iEG45_281015_002_calc/';
E{ex}.d0 = 15; % Distance between dots to be considered as connected, in pixels, times 120 in nm
E{ex}.dotRatio = .5; % exclude if other dot is more than dotRatio of the strongest
E{ex}.channels = [1,2];
ex = ex+1;

for kk = 1:numel(E)
    fprintf('%02d %s\n', kk, E{kk}.folder);
end

for ee = E(6)
    folder = ee{1}.folder
    d0 = ee{1}.d0;
    dotRatio = ee{1}.dotRatio;
    channels = ee{1}.channels;

%% GO
np = 0; % number found pairs

fprintf('Loading directory %s\n', folder);
files = dir([folder '*.NM']);
fprintf('%d files to look into\n', numel(files));

D1_2 = []; % Distances
D1_3 = [];
D2_3 = [];
L1_2 = []; % Locations -- coordinates
L1_3 = [];
L2_3 = [];
M1_2 = []; % Measurements 
M1_3 = [];
M2_3 = [];


nTripletsTot = 0;
nPairsTot = 0;

for kk = 1:numel(files) % Per file
    nTripletsFile = 0;
    nPairsFile = 0;
    load([folder files(kk).name], '-mat')
    VA = [];
            
    for nn = 1:numel(N) % Per nuclei
        %fprintf('File: %d, nuclei: %2d\n', kk, nn);
        
        DN = [];
        if N{nn}.dapisum < M.dapival
            
            for cc = channels
                D = [];
                dots = N{nn}.dots{cc};
                dots = dots(dots(:,4)>M.threshold(1), :);
                dots = [dots, (1:size(dots,1))'];
                dots0 = dots;
                
                % First dots
                if size(dots,1)>0
                    D(1,:) = dots(1,:);
                    if size(dots,1)>1
                        dots = dots(2:end-1, :);
                        
                        % Second dot
                        d = eudist(repmat(D(1,1:3).*[1,1,rz/rxy], [size(dots,1), 1]), dots(:,1:3).*repmat([1,1,rz/rxy], [size(dots,1), 1]));
                        dotsFar = dots(dots(:,4)>d0, :);
                        if numel(dotsFar)>0
                            D(2,:) = dotsFar(1,:);
                        end
                    end
                    
                    % Verify integrity of the dots
                    for dd = size(D,1):-1:1
                        dots = dots0;
                        dots = dots(setdiff(1:size(dots,1), D(dd,6)) , :);
                        d = eudist(repmat(D(dd,1:3).*[1,1,rz/rxy], [size(dots,1), 1]), dots(:,1:3).*repmat([1,1,rz/rxy], [size(dots,1), 1]));
                        useDot = 1;
                        for ddd = 1:size(d,1)
                            if(d(ddd)<d0)
                                if dots(ddd,4)/D(dd,4)>dotRatio
                                    useDot  = 0;
                                end
                            end
                        end
                        if ~useDot
                            D = D(1:dd-1,:);
                        end
                    end
                end
                DN = [D, cc*ones(size(D,1),1); DN];
            end
            
            %% Look for triplets in DN, i.e. clustering
            
            if 0
                figure
                for dd=1:size(C1,1)
                    colors = {'ro', 'go', 'ko'};
                    plot3(DN(dd,2), DN(dd,1),C1(dd,3), colors{DN(dd,7)});
                    hold on
                end
            end
            
            C1 = []; C2 = [];
            if size(DN,1)>1
                C= cluster3e(DN(:,1:3).*repmat([1,1,rz/rxy], [size(DN,1), 1]), d0);
                
                C1 = DN(C==1, :);
                C2 = DN(C==2, :);
            end
            
            
            for C = {C1,C2}
                C = C{1};
                if size(C,1)>1
                    %% Fitting    
                    if useFitting
                    if numel(VA)==0
                        dapiname = strsplit(M.dapifile, '/');
                        dapiname = dapiname{end};
                        dapiname = dapiname(1:end-8);
                        VA = double(df_readTif(strrep(M.dapifile, dapiname, M.channels{1})));
                        VB = double(df_readTif(strrep(M.dapifile, dapiname, M.channels{2})));
                        if(numel(M.channels)>2)
                            VC = double(df_readTif(strrep(M.dapifile, dapiname, M.channels{3})));
                        end
                    end
                    F = [];
                    for dd = 1:size(C,1)         
                        if C(dd,7)==1
                            F(dd,:) = dotFitting(VA, C(dd,1:3), fittingSettings);
                        end
                        if C(dd,7)==2
                            F(dd,:) = dotFitting(VB, C(dd,1:3), fittingSettings);
                        end
                        if C(dd,7)==3
                            F(dd,:) = dotFitting(VC, C(dd,1:3), fittingSettings);
                        end
                    end
                    C(:,1:3) = F(:,1:3);
                    end
                
                if(size(C,1)==2) % one PAIR
                    fprintf('File: %d, nuclei: %2d\n', kk, nn);
                    [~,s] = sort(C(:,7), 1);                    
                    C = C(s, :);                    
                    nPairsFile = nPairsFile+1;
                    d = eudist(C(1,1:3).*[rxy,rxy,rz], C(2,1:3).*[rxy,rxy,rz]);
                    
                    if sum(union(C(1,7), C(2,7)) == [1,2])==2
                        D1_2 = [D1_2, d];
                        L1_2 = [L1_2; [C(1,1:3), C(2,1:3)]];
                        M1_2 = [M1_2; N{nn}.area];
                    end
                    if sum(union(C(1,7), C(2,7)) == [1,3])==2
                        D1_3 = [D1_3, d];
                        L1_3 = [L1_3; [C(1,1:3), C(2,1:3)]];
                        M1_3 = [M1_3; N{nn}.area];
                    end
                    if sum(union(C(1,7), C(2,7)) == [2,3])==2
                        D2_3 = [D2_3, d];
                        L2_3 = [L2_3; [C(1,1:3), C(2,1:3)]];
                        M2_3 = [M2_3; N{nn}.area];
                    end
                end
                
                if size(C,1)==3 % one TRIPLET
                    nPairsFile = nPairsFile+3;
                    nTripletsFile = nTripletsFile+1;
                    [~,s] = sort(C(:,7), 1);   
                    C = C(s, :);                    
                    d12 = eudist(C(1,1:3).*[rxy,rxy,rz], C(2,1:3).*[rxy,rxy,rz]);
                    d13 = eudist(C(1,1:3).*[rxy,rxy,rz], C(3,1:3).*[rxy,rxy,rz]);
                    d23 = eudist(C(2,1:3).*[rxy,rxy,rz], C(3,1:3).*[rxy,rxy,rz]);
                    D1_2 = [D1_2, d12];
                    D1_3 = [D1_3, d13];
                    D2_3 = [D2_3, d23];
                    L1_2 = [L1_2; [C(1,1:3), C(2,1:3)]];
                    L1_3 = [L1_3; [C(1,1:3), C(3,1:3)]];
                    L2_3 = [L2_3; [C(2,1:3), C(3,1:3)]];
                    M1_2 = [M1_2; N{nn}.area];
                    M1_3 = [M1_3; N{nn}.area];
                    M2_3 = [M2_3; N{nn}.area];
                end
                end
                
            end
            
        end                
    end
    
    
        
  
    %% Aggregate dots
    nTripletsTot = nTripletsTot+nTripletsFile;
    nPairsTot = nPairsTot+nPairsFile;
    
end

fprintf('Summary for %s\n', folder);

fprintf('Found %d pairs\n', nPairsTot);
fprintf('Found %d triplets\n', nTripletsTot);

fprintf('Pair\tMean\t #\n')
fprintf('1-2\t%f\t%f\n', mean(D1_2), size(L1_2,1));
fprintf('1-3\t%f\t%f\n', mean(D1_3), size(L1_3,1));
fprintf('2-3\t%f\t%f\n', mean(D2_3), size(L2_3,1));


if size(L1_2,1)>0
    L1_2(:,1:3) = cCorrI(L1_2(:,1:3), 'a594_quim', 'cy5_quim', '~/code/cCorr/cc_20151019.mat');
    L1_2(:,1)=L1_2(:,1)*rxy; L1_2(:,2)=L1_2(:,2)*rxy; L1_2(:,3)=L1_2(:,3)*rz;
    L1_2(:,4)=L1_2(:,4)*rxy; L1_2(:,5)=L1_2(:,5)*rxy; L1_2(:,6)=L1_2(:,6)*rz;
    D1_2 = eudist(L1_2(:,1:3), L1_2(:,4:6));
end

if size(L2_3,1)>0
    L2_3(:,4:6) = cCorrI(L2_3(:,4:6), 'tmr_quim', 'cy5_quim', '~/code/cCorr/cc_20151019.mat');
    L2_3(:,1)=L2_3(:,1)*rxy; L2_3(:,2)=L2_3(:,2)*rxy; L2_3(:,3)=L2_3(:,3)*rz;
    L2_3(:,4)=L2_3(:,4)*rxy; L2_3(:,5)=L2_3(:,5)*rxy; L2_3(:,6)=L2_3(:,6)*rz;
    D2_3 = eudist(L2_3(:,1:3), L2_3(:,4:6));
end

if size(L1_3,1)>0
    L1_3(:,1:3) = cCorrI(L1_3(:,1:3), 'a594_quim', 'tmr_quim', '~/code/cCorr/cc_20151019.mat');
    L1_3(:,1)=L1_3(:,1)*rxy; L1_3(:,2)=L1_3(:,2)*rxy; L1_3(:,3)=L1_3(:,3)*rz;
    L1_3(:,4)=L1_3(:,4)*rxy; L1_3(:,5)=L1_3(:,5)*rxy; L1_3(:,6)=L1_3(:,6)*rz;
    D1_3 = eudist(L1_3(:,1:3), L1_3(:,4:6));
end

fprintf('With CA\n');
fprintf('Pair\tMean\t #\n')
fprintf('1-2\t%f\t%f\n', mean(D1_2), size(L1_2,1));
fprintf('1-3\t%f\t%f\n', mean(D1_3), size(L1_3,1));
fprintf('2-3\t%f\t%f\n', mean(D2_3), size(L2_3,1));

% Normalize by cell radius -- calculated from area
Dn1_2 = D1_2 ./ ((M1_2/pi).^(1/2)/40); % 
Dn1_3 = D1_3 ./ ((M1_3/pi).^(1/2)/40); % 
Dn2_3 = D2_3 ./ ((M2_3/pi).^(1/2)/40); % 

fprintf('and normalization\n');
fprintf('Pair\tMean\t #\n')
fprintf('1-2\t%f\t%f\n', mean(Dn1_2), size(L1_2,1));
fprintf('1-3\t%f\t%f\n', mean(Dn1_3), size(L1_3,1));
fprintf('2-3\t%f\t%f\n', mean(Dn2_3), size(L2_3,1));

if 0
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

clear VA
clear VB
clear VC

savename = strsplit(folder, '/');
savename = savename{end-1};
savename = [savename '.mat'];
save(savename);

end

break


for ee = E
    folder = ee{1}.folder;
    loadname = strsplit(folder, '/');
    loadname =  loadname{end-1};
    loadname = [loadname '.mat'];
    load(loadname);
    disp(folder)
    disp('D1_2')
    disp(D1_2)
    disp('M1_2')
    disp(M1_2)
    disp('Dn1_2')
    disp(Dn1_2)
    pause
    disp(folder)
    disp('D1_3')
    disp(D1_3)
    disp('M1_3')
    disp(M1_3)
    disp('Dn1_3')
    disp(Dn1_3)    
    pause
    disp(folder)
    disp('D2_3')
    disp(D2_3)
    disp('M2_3')
    disp(M2_3)
    disp('Dn2_3')
    disp(Dn2_3)
    pause    
end
