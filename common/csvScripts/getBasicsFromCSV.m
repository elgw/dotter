% This script is for iMB31--iMB36
% based on the scripts for iJC202 -- iJC207
% now under common/csvScripts (DRY!)
%
% To be run in the folder with all csv files

folder = pwd();

nChan = zeros(5,1);

%% Read data from csv and calculate pairwise distances
if ~exist('files', 'var')
    files = dir([folder '/*.csv']);
end

% Histogram for number of alleles with kk dots
nAlleles = zeros(5,1);

for ff = 1:numel(files)
    fprintf('Loading %s\n', files(ff).name);
    
    if files(ff).name(2) == 'J'
        % if iJC204 ...
        channels = {'a594', 'tmr', 'gfp', 'cy5', 'cy7'};
    end
    
    if files(ff).name(2) == 'M'
        channels = {'a594','tmr', 'a488', 'cy5', 'cy7'};
    end
    
    t = readtable(files(ff).name);
    t = table2cell(t);
        
    startPos = 1;
    P = getAllele(t, startPos);    
    
    while numel(P)>0
        
        if size(P,1)>5
            disp('Too many dots in this file');
        else
            % Here is where valid alleles go
            nAlleles(size(P,1)) = nAlleles(size(P,1))+1;
            for kk = 1:size(P,1)
                chan = find(strcmp(P(kk,4), channels));
                nChan(chan) = nChan(chan)+1;
            end
            
        end
        startPos = startPos+size(P,1);
        P = getAllele(t, startPos);
    end    
end


%% Basic information about the data
fprintf('\n');
fprintf('Summary for %s\n', folder)
fprintf('%d alleles\n', sum(nAlleles));
fprintf('%d dots\n', sum(nAlleles.*(1:numel(nAlleles))'));
fprintf('%d pairs\n', sum(nAlleles.*[0, 1, 3, 6, 10]'));



figure,
bar(nAlleles)
title('Dots per allele')

figure,
b = bar(nChan);
set(gca, 'XTickLabel', channels)
title('Dots per channel')


