function df_compareUserDots()
% Compare picked dots from NM files with the same segmentation.
% 

clear all
if ~exist('folderA', 'var')    
    if 0
        expName = 'iJC829a1';
        folderA = '/data/current_images/iJC/iJC829_20170918_001_calc_auto1/';
        [NA, MA] = df_getNucleiFromNM('folder', folderA);
        folderB = '/data/current_images/iJC/iJC829_20170918_001_calc_quim/';
        [NB, MB] = df_getNucleiFromNM('folder', folderB);
        channels = 1:3;
    end
    
     if 0
        expName = 'iJC829a2';
        folderA = '/data/current_images/iJC/iJC829_20170918_001_calc/';
        [NA, MA] = df_getNucleiFromNM('folder', folderA);
        folderB = '/data/current_images/iJC/iJC829_20170918_001_calc_quim/';
        [NB, MB] = df_getNucleiFromNM('folder', folderB);
        channels = 1:3;
    end
    
    if 0
        expName = 'iJC797';
        folderA = '/data/current_images/iJC/iJC797_20170829_001_calc/';
        [NA, MA] = df_getNucleiFromNM('folder', folderA);
        folderB = '/data/current_images/iJC/iJC797_20170829_001_calc_michi/';
        [NB, MB] = df_getNucleiFromNM('folder', folderB);
        channels = 1:3;
    end
    
    if 0
        expName = 'iJC849_001_002';
        folderA = '/data/current_images/iJC/iJC849_001_002_calc/';
        [NA, MA] = df_getNucleiFromNM('folder', folderA);
        folderB = '/data/current_images/iJC/iJC849_001_002_calc_xinge/';
        [NB, MB] = df_getNucleiFromNM('folder', folderB);
        channels = 2:3;
    end
if 1    
    expName = 'manual comparison';
        folderA = uigetdir('', 'Select first calc folder');
        %folderA = '/mnt/bicroserver2/microscopy_data_2/Temporal/GPSeq analysis/Analysis/IMR90/iJC793_20170823_001_calc/';
        folderB = uigetdir(folderA, 'Select second calc folder');
        %folderB = '/mnt/bicroserver2/microscopy_data_2/Temporal/GPSeq analysis/Analysis/IMR90/auto/iJC793_20170823_001_calc/';
        folderA = [folderA filesep()]
        folderB = [folderB filesep()]
        [NA, MA] = df_getNucleiFromNM('folder', folderA);        
        [NB, MB] = df_getNucleiFromNM('folder', folderB);
end

end



s.verbose = 0;
s.plot = 1;
s.savePlot = 1;
s.inspection = 1;

if exist('channels', 'var')
    s.channels = channels;
else
    s.channels = 1:numel(MA{1}.channels);
end



% for each nuclei, see how many of the dots that are
%    in A
%    in B
%    in A-B
%    in B-A
%    in A cap B / A u B

%assert(numel(NA) == numel(NB));
%assert(numel(MA) == numel(MB));


[T, nDots, C] = compareAllNuclei(NA, MA, MB, NB, s);


if s.plot
    channels = MA{NA{1}.metaNo}.channels;
    L = linspace(0,1,15);
    figure('Name', ...
        sprintf('%d nuclei, %d channels. Total %d', ...
        size(T,1), size(T,2), numel(T)))
    subplot(1, numel(channels)+1, 1);
    histogram(T(:), L)
    grid on
    xlabel('A\capB / A\cupB')
    title('Total');
    for cc = 1:numel(channels)
        subplot(1, numel(channels)+1, cc+1);
        histogram(T(:,cc), L)
        title({MA{1}.channels{cc}});
        grid on
        xlabel('A\capB / A\cupB')
    end
    
    if s.savePlot
        fname = [datestr(now, 'YYYYmmDD') '_' expName '.pdf'];
        fprintf('Saving plot to %s\n', fname);
        dprintpdf(fname, 'h', 5, 'w', 20);
    end
end

% Show some output
disp(['mean(T): ' num2str(mean(T))]);
disp(['mean(T(:))' num2str(mean(T(:)))])

disp('Number of dots')
disp(['A: ' num2str(nDots(:,1))])
disp(['B: ' num2str(nDots(:,2))])

disp('Error types:')
fprintf('Identical: %d (%.2f)\n', sum(C(:)==0), sum(C(:)==0)/numel(C));
fprintf('Missing  : %d (%.2f)\n', sum(C(:)==1), sum(C(:)==1)/numel(C));
fprintf('Different: %d (%.2f)\n', sum(C(:)==2), sum(C(:)==2)/numel(C));

end


%% Function that does not share globals below

function [T, Ndots, C] = compareAllNuclei(NA, MA, MB, NB, s)
% Compare the userDots, A vs B
% T: correspondence per channel, one row per nuclei
%    in [0,1]
% C: error types; 
%    0, identical dots (perfect
%    1, A\AcapB OR A\AcapB nonempty (non-serious)
%    2, A\AcapB AND A\AcapB nonempty (serious, different dots preferred)

channels = MA{NA{1}.metaNo}.channels;

ndotsA = zeros(1, numel(channels));
ndotsB = zeros(1, numel(channels));

T = [];
C = [];

nDotsSame = 0;
nDotsUnique = 0;
nOnlyA = 0;
nOnlyB = 0;

for nn = 1:min(numel(NA), numel(NB))
    
    A = NA{nn};
    B = NB{nn};
    
    
    assert(isequal(A.bbx, B.bbx));
    
    dotsA = {[], [], []};
    dotsB = {[], [], []};
    
    for aa = 1:2
        for cc = s.channels
            
            dA = A.clusters{aa}.dots{cc};
            if numel(dA) == 0
                dA = zeros(0,3);
            end
            dA = dA(:,1:3);
            dotsA{cc} = [dotsA{cc}; dA];
            
            dB = B.clusters{aa}.dots{cc};
            if numel(dB) == 0
                dB = zeros(0,3);
            end
            dB = dB(:,1:3);
            dotsB{cc} = [dotsB{cc}; dB];
        end
    end
    
    if s.verbose
        for cc = 1:numel(channels)
            disp(MA{1}.channels{cc})
            disp(dotsA{cc})
            disp('vs')
            disp(dotsB{cc})
        end
    end
    
    res = []; typ = 2*ones(1,numel(channels));
    for cc = 1:numel(channels)
        % Number of unique dots in A and B
        u = unique([dotsA{cc}; dotsB{cc}], 'rows');
        nUnique = size(u,1);
        % Number of dots in both
        b = intersect(dotsA{cc}, dotsB{cc}, 'rows');
        inBoth = size(b,1);
        
        nDotsSame = nDotsSame + inBoth;
        nDotsUnique = nDotsUnique+nUnique;
        nOnlyA = nOnlyA + size(setdiff(dotsA{cc}, b, 'rows'),1);
        nOnlyB = nOnlyB + size(setdiff(dotsB{cc}, b, 'rows'),1);
        
        % type of error        
        if inBoth == nUnique
            typ(cc) = 0;
        else             
            if isempty(setdiff(dotsA{cc}, b, 'rows')) || isempty(setdiff(dotsB{cc}, b, 'rows'))
                typ(cc) = 1;
            end
        end
        
        if 0
        disp('A')
        dotsA{cc}
        disp('B')
        dotsB{cc}        
        typ(cc)
        end
        %keyboard
        %pause
        
        res = [res, inBoth/nUnique];
        %T = [T; [nUnique, inBoth, size(dotsA,1), size(dotsB,1)]];
        ndotsA(cc) = ndotsA(cc) + size(dotsA{cc},1);
        ndotsB(cc) = ndotsB(cc) + size(dotsB{cc},1);
    end
    T = [T; res];
    C = [C; typ];
end

Ndots = [ndotsA, ndotsB];

fprintf('Total unique dots: %d\nDots in both: %d\nOnly in A: %d\nOnly in B: %d\n', ...
    nDotsUnique, ...
    nDotsSame, ...
    nOnlyA, ...
    nOnlyB);

% T is nan when there are 0 dots in each, that means perfect correspondence
T(isnan(T)) = 1;
end
