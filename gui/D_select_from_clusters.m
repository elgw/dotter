%% Purpose: scan for nuclei with good cluster structure
% Used in conjuncture with NEdit for viewing

addpath('/Users/erikw/code/cluster3e/')

wfolder = '/Users/erikw/data/eleni/triplets_5min_002_calc/';
outFolder = [wfolder 'cluster_dots/'];
close all
files = dir([wfolder '*.NM']);


selected = [];
nSelected = 0;

d0 = 15; % Distance between dots to be considered as connected
d0nm = 18*130; % The same in NM

naDots = 15; % Number of dots to consider for the clustering analysis from each channel

dapival = 1.1*10^10; % Nuclei with higher DAPI sum than this will be discarded

if ~exist('nOpen', 'var')
    nOpen =  -1;
end

try
    mkdir(outFolder)
end

for kk = 1:numel(files) %% Per file
    load([wfolder files(kk).name], '-mat')
    M.nTrueDots = [5,5,4];
    
    %[M, N] = d_filter_dots(M,N);
    
    
    for nn =  1:numel(N)
        fprintf('File: %d, nuclei: %2d', kk, nn);
        %% Load the Alexa dots
        dots = N{nn}.dots{1};
        dots = dots(1:min(2*naDots, size(dots,1)), :);
        bbx = N{nn}.bbx;
        
        if size(dots,1)>2
            
            plot3(dots(:,2), dots(:,1), dots(:,3), 'rx')
            %plot3connectingLines(dots(:,2), dots(:,1), dots(:,3), bbx);
            
            dots = dots(1:min(size(dots,1), naDots), 1:3);
            dots0 = dots;
            %% Cluster, find clusters of 4 strong or more
            
            dots(:,1:2)=125*dots(:,1:2);
            dots(:,3)=200*dots(:,3);
            C = cluster3ec(dots', d0nm);
            H = df_histo16(uint16(C)); H = H(2:20);
            % imagesc(M.mask>0), colormap gray
            
            
            Hm1 = max(H(:));
            Hm1 = Hm1(1);
            if Hm1>0
                c1 = find(H==Hm1); c1=c1(1);
            else
                c1  = [];
            end
            Ht = H; Ht(c1)=0;
            Hm2 = max(Ht(:)); Hm2=Hm2(1);
            if Hm2 >0
                c2 = find(Ht==Hm2); c2 = c2(1);
            else
                c2 = [];
            end
            
            if numel(c1)>0
                C1 = dots0(C==c1,:);
            else
                C1 = [];
            end
            if numel(c2>0)
                C2 = dots0(C==c2,:);
            else
                C2 = [];
            end
            
            fprintf(' C1: %2d C2: %2d ', size(C1,1), size(C2,1));
            if size(C1,1)>2 && size(C1,1)<6
                fprintf('+');
            end
            if size(C2,1)>2 size(C2,1)<6
                fprintf('+');
            end
            
            cl1ch2=showDotsInCluster(N{nn}.dots{2}, C1, d0/2, 'noshow');
            cl1ch3=showDotsInCluster(N{nn}.dots{3}, C1, d0/2, 'noshow');
            cl2ch2=showDotsInCluster(N{nn}.dots{2}, C2, d0/2, 'noshow');
            cl2ch3=showDotsInCluster(N{nn}.dots{3}, C2, d0/2, 'noshow');
            
            
            fprintf(' 1: %2d-%2d, 2: %2d-%2d', size(cl1ch2,1), size(cl1ch3,1), size(cl2ch2,1), size(cl2ch3,1));
            
            if N{nn}.dapisum < dapival
                if size(cl1ch2,1)>3 && size(cl1ch3,1) > 3
                    if size(C1,1)>2 && size(C1,1)<6
                        fprintf(' X');
                        nSelected = nSelected+1;
                        selected = [selected ; [kk, nn, 1]];
                    end
                end
                
                if size(cl2ch2,1)>3 && size(cl2ch3,1) > 3
                    if size(C2,1)>2 && size(C2,1)<6
                        fprintf(' X');
                        nSelected = nSelected+1;
                        selected = [selected ; [kk, nn, 2]];
                    end
                end
            end
            
            %% Use the cluster points to find dots in the other channels
            N{nn}.C1 = C1;
            N{nn}.C2 = C2;
            
            %% If anything found, export
            if 0
                for cc = 1:numel(M.nTrueDots)
                    
                    dots = N{nn}.dots{cc};
                    fileName = sprintf('%s%03d_%03d_%03d.csv', outFolder, kk, nn, cc);
                    csvwrite(fileName, dots);
                    
                end
            end
        end
        fprintf('\n');
    end
    %save([wfolder files(kk).name], NM)
end

%save selected.mat selected
