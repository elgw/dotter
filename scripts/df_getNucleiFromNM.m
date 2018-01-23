function [N, M] = df_getNucleiFromNM(varargin)
% function [N, M] = df_getNucleiFromNM()
% Extract all nuclei from selected NM files
% N{kk}.metaNo says which Meta data that belongs to the nuclei
% i.e., Nuclei N{1} belongs to field M{N{1}.metaNo}

verbose = 0;
N = [];
M = [];

maxFiles = [];

nMissingUD = 0; % Count the number of nuclei without userDots, these will not be returned

ccFile = '';
folder = '';


for kk = 1:nargin
    if strcmpi(varargin{kk}, 'folder')
        folder = varargin{kk+1};
        files = dir([folder '*.NM']);
        files = df_fileStructToFileList(files);
    end
    if strcmpi(varargin{kk}, 'maxFiles')
        maxFiles = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'ccFile')
        ccFile = varargin{kk+1};
    end
end

if numel(folder) == 0
    folder = df_getConfig('df_getNucleiFromNM', 'folder', pwd);
    files = uipickfiles('FilterSpec', folder, ...
        'Prompt', 'Select NM files(s)', 'REFilter', '.NM$');
    if isnumeric(files)
        disp('No NM files selected')
        N = [];
        return
    end
    df_setConfig('df_getNucleiFromNM', 'folder', fileparts(files{1}));
    folder = '';
    fprintf('%d files selected\n', numel(files));
end


if numel(maxFiles)>0
    maxFiles = min(maxFiles, numel(files));
    files = files(1:maxFiles);
end

if numel(files) == 0
    error('No NM files to read\n');        
end

N = {};
M = {};

channels = [];
w = waitbar(0, 'Loading files');

for ff = 1:numel(files)
    waitbar((ff-1)/numel(files), w);
    fname = files{ff};
    if verbose
        fprintf('Loading %s\n', fname);
    end
    D = load([folder fname], '-mat');
    
    if(isfield(D.M, 'channels') == 0)
           errordlg(sprintf('Can not load the NM. No channels specified in %s', fname));           
           M = {};
           N = {};
           return
    end    
    
    if(ff==1)
        channels = D.M.channels;
    else
       if ~isequal(channels, D.M.channels)           
           errordlg('Can not load the NM files since the channels does not match!');           
           M = {};
           N = {};
           return;
       end       
    end
    
    M{ff} = D.M;    
    
    for nn = 1:numel(D.N)
        D.N{nn}.file = fname;
        D.N{nn}.nucleiNr = nn;
        D.N{nn}.metaNo = ff;
    end
    
    if numel(ccFile) > 0
        ccData = load(ccFile, '-mat');
        disp('Applying CC')
        for nn = 1:numel(D.N)
            for cc = 1:numel(D.M.channels)                
                D.N{nn}.userDots{cc} = ...
                    df_cc_apply_dots('dots', D.N{nn}.userDots{cc}, ...
                        'from', D.M.channels{cc}, ... % From
                        'to', 'dapi', ... % To
                        'ccData', ccData);
            end
        end
        disp('Done!')
    end
    
    % If the first nuclei has userDots, all have
    if isfield(D.N{nn}, 'userDots')
        N = [N D.N];
    else
        nMissingUD = nMissingUD +numel(D.N);
    end
    
    
end
close(w);

nClusters = 0;
n2clusters = 0;

%% Extract the clusters, per nuclei, and put them below N
for nn = 1:numel(N)
    nuc = N{nn};
    if isfield(nuc, 'userDotsLabels')
        labels = cell2mat(nuc.userDotsLabels(:));
        nuc.nClusters = numel(unique(labels(:)));
        if(nuc.nClusters == 2)
            n2clusters = n2clusters + 1;
        end
        % For each channel and each cluster, copy dots to nuc.clusters
        for ll = 1:2
            if ll<=nuc.nClusters
                for cc = 1:numel(M{nuc.metaNo}.channels)
                    nuc.clusters{ll}.dots{cc} = nuc.userDots{cc}(nuc.userDotsLabels{cc} == ll, :);
                end
                nClusters = nClusters + 1;
            else % If no cluster, create empty structures
                for cc = 1:numel(M{nuc.metaNo}.channels)
                    nuc.clusters{ll}.dots{cc} = {};
                end
            end
        end
        N{nn} = nuc;
        
    else
        if verbose
            fprintf('no userDotsLabels for nuclei %d in %s\n', nn, nuc.file)
        end
    end
end

if(nMissingUD>0)
    warning('%d nuclei did not have any userDots, these are not returned\n', nMissingUD);
end

fprintf('Loaded %d files, %d nuclei, %d clusters into M and N\n', numel(files), numel(N), nClusters);
fprintf('%d nuclei has two clusters\n', n2clusters);

end