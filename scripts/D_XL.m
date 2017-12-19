% Obsolete, instead, use:
% 1. setUserDotsDNA
% 2. DNA_channelOverlapAnalysis
%

% Run in _calc-folder
clear all
close all
debug = 0;

%folder = uigetdir('~/Desktop/iXL34_35_36/', 'Pick a calc folder');
folder = '/home/erikw/Desktop/iXL34_35_36/iXL034_100816_001_calc';

files = dir([folder '/*.NM']);
fprintf('Found %d NM files\n', numel(files));

clear CAP

% 1. Run only once. Redo the Nuclei definitions 
% There was a bug in create_nuclei_from_mask before
% Also re-base the images to the correct folders under
% /data/current_images/iXL...


for kk =1:numel(files)   
    load([folder '/' files(kk).name], '-mat');
    if ~ isfield(M, 'patch435689745')
        M.patch435689745 = 1;
        N = create_nuclei_from_mask(M.mask, 0*M.mask);
        fo = M.dapifile;
        fo = strsplit(fo, '/');
        fo = ['/home/erikw/Desktop/' fo{end-1} '/' fo{end}];
        M.dapifile = fo;
        save([folder '/' files(kk).name], '-mat', 'M', 'N');
    end
end


% TO do: set user dots
for kk =1:numel(files)    
    %load([folder '/' files(kk).name], '-mat');        
	setUserDots([folder '/' files(kk).name])
end


%% Per nuclei
for kk =1:numel(files)
    kk
    load([folder '/' files(kk).name], '-mat');
    
    N = create_nuclei_from_mask(M.mask, 0*M.mask);
    
    nChannels = numel(M.channels);
    channels = M.channels;
    
    if ~exist('CAP', 'var')
        CAP = cell(nChannels);
    end
    
    %% Load the images from each channel except DAPI
    if 0
        for cc = 1:nChannels
            I{cc} = df_readTif(channels{cc});
            I{cc} = sum(double(I{cc}), 3)/size(I{cc},3);
        end
    end
    
    %% Find dots and DILATE them
    % To do: do in 3D
    for cc = 1:nChannels
        D = M.dots{cc};
        th = dotThreshold_old(D(:,4));
        D = D(D(:,4)>th,:);
        ID = 0*zeros(1024,1024);
        ind = sub2ind(size(ID), round(D(:,1)), round(D(:,2)));
        ID(ind) = 1;
        ID2 = imdilate(ID, strel('disk', 4));
        R{cc} = ID2;
    end
    
    %% Extract data per nuclei
    for nn = 1:numel(N)
        
        %% Filter away outside cells
        for oo = 1:nChannels
            ROI{oo} = R{oo}(N{nn}.bbx(1):N{nn}.bbx(2), N{nn}.bbx(3):N{nn}.bbx(4)) ...
                .*(M.mask(N{nn}.bbx(1):N{nn}.bbx(2), N{nn}.bbx(3):N{nn}.bbx(4))==nn);
        end
        ROI_mask = M.mask(N{nn}.bbx(1):N{nn}.bbx(2), N{nn}.bbx(3):N{nn}.bbx(4))==nn;
        if max(ROI_mask(:)) == 1
        
        for pp = 1:nChannels
            for qq = 1:nChannels
                if pp == qq
                    % Percentage of the nuclei which is covered by the probes
                    CAP{pp,qq} = [CAP{pp,qq} ; sum(sum((ROI{pp}+ROI{qq})==2))/sum(sum(ROI_mask))];
                else
                    % Overlap between the probes
                    CAP{pp,qq} = [CAP{pp,qq} ; sum(sum((ROI{pp}+ROI{qq})==2))/sum(sum((ROI{pp}+ROI{qq})>0))];
                end
            end
        end
        
        if debug
            figure(1)
            %subplot(nChannels, nChannels)
            for pp = 1:nChannels
                for qq = 1:nChannels
                    subplot(nChannels, nChannels, qq+(pp-1)*nChannels);
                    I = ROI_mask;
                    I = max(ROI_mask, 2*ROI{pp});
                    I = max(I, 3*ROI{qq});
                    I = max(I, 4*((ROI{qq}+ROI{pp})==2));
                    imagesc(I)
                    colormap([0,0,0; .5,.5,.5; 1,0,0; 0,1,0; 1,1,0]);
                    title(sprintf('%.2f\n', CAP{pp,qq}(end)));
                    axis image
                end
            end
            pause
        end
        else
            fprintf('Skipping nuclei %d\n', nn)
        end
    end % for each nuclei
    kk
end


%% Plot the results
mCAP = zeros(nChannels); % Mean
sCAP = mCAP; % standard deviation
for kk = 1:nChannels
    for ll = 1:nChannels
        mea = CAP{kk,ll};
        mea = mea(~isnan(mea)); % Exclude NANs (no probes of either kind)
        mCAP(kk,ll) = mean(mea);
        sCAP(kk,ll) = std(mea);
    end
end

nCells = numel(mea)
csvwrite(sprintf('%s_mean_overlap.csv', folder), mCAP)
csvwrite(sprintf('%s_std_overlap.csv', folder), sCAP)
