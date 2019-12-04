function df_resetUserDots_fromNN(folder)
% Purpose:
% Import tsv table created by tflow/classify.py and set the selected dots
% as userDots.

folder = '/data/current_images/iEG/iEG458_171304_004_calc_nn'
folder = '/data/current_images/iEG/iEG613_190120_001_calc/';
channelString = 'a594';

fprintf('Folder to process: %s\n', folder);
warning('Highly experimental, press a key to continue')

files = dir([folder filesep() '*.NM']);

for ff = 1:numel(files)
    file = files(ff).name;
    nmfile = [folder filesep() file];
    fprintf('Loading nm file: %s\n', nmfile)
    
    [M, N] = df_nm_load(nmfile);
    M = M{1};
    
    
    
    fieldString = file(1:3);
    
    
    dotTableName = [folder fieldString '_' channelString '_metapatches.tsv'];
    
    fprintf('Loading dot table: %s\n', dotTableName)
    
    dots = tdfread(dotTableName, '\t');
    vdots = struct2array(dots);
    
    vdots = vdots(vdots(:,end)>.5, :);
    
    channelNumber = getChannelNumber(channelString, M.channels);
    assert(strcmp(M.channels{channelNumber}, channelString) == 1)
    
    % Reset userDots for the specified channel
    for dd = 1:numel(N)
    for cc = 1:numel(M.channels)
        if cc == channelNumber
            N{dd}.userDots{cc} = zeros(0,4);
            N{dd}.userDotsLabels{cc} = zeros(0,4);
            N{dd}.userDotsExtra{cc} = zeros(0,4);
        else
             N{dd}.userDots{cc} = zeros(0,4);
            N{dd}.userDotsLabels{cc} = zeros(0,4);
            N{dd}.userDotsExtra{cc} = zeros(0,4);
        end
    end
    end
    
    % Import as userDots
    
    for dd = 1:size(vdots,1)
        nuclei = interpn(M.mask, vdots(dd,1), vdots(dd,2), 'nearest');
        if nuclei>0
        N{nuclei}.userDots{channelNumber} = ...
            [N{nuclei}.userDots{channelNumber}; vdots(dd,[1:3, 5])];
        N{nuclei}.userDotsLabels{channelNumber} = ...
            [N{nuclei}.userDotsLabels{channelNumber}; 1];
        end
    end
        
    fprintf('Saving nm file\n')
    df_nm_save(M, N, nmfile);
    
end

end

function channelNumber = getChannelNumber(channelString, channels)
%
% Typically called like:
% getChannelNumber('a594', M.channels)
channelNumber = 0;

for kk = 1:numel(channels)
    if strcmpi(channelString, channels{kk})
        channelNumber = kk;
    end
end
end