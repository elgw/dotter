function [N, M] = df_getNucleiFromNM(varargin)
% function [N, M] = df_getNucleiFromNM()
%
% Extract all nuclei from selected NM files
% N{kk}.metaNo says which Meta data that belongs to the nuclei
% i.e., Nuclei N{1} belongs to field M{N{1}.metaNo}
% If one or more folders are selected, all NM files in the subdirectories
% are loaded. ONE .cc file per folder is also loaded.

s.verbose = 1;
s.noclusters = 0;
maxFiles = [];
nMissingUD = 0; % Count the number of nuclei without userDots, these will not be returned
ccFile = ''; % If only one cc file
ccFiles = {}; %
folder = [];
files = {};
folders = {};
s.recursive = 1;
s.waitdlg = 1;

for kk = 1:nargin
    if strcmpi(varargin{kk}, 'folder')
        files = varargin{kk+1};
        if ~iscell(files)
            files = {files};
        end
        %files = dir([folder '*.NM']);
        %files = df_fileStructToFileList(files);
    end
    if strcmpi(varargin{kk}, 'maxFiles')
        maxFiles = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'noClusters')
        s.noclusters = 1;
    end
    if strcmpi(varargin{kk}, 'ccFile')
        ccFile = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'recursive')
        s.recursive = 1;
    end
    if strcmpi(varargin{kk}, 'waitdlg')
        s.waitdlg = varargin{kk+1};
    end
end

% to be returned
N = [];
M = [];

% Get list of files, either from folder or from gui
if numel(files) == 0
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
end

if(isdir(files{1}))
    disp('Got directories')
    dirs = files;
    files = {};
    
    hasCC = 0;
    for ff = 1:numel(dirs)
        folder = [dirs{ff} filesep()];
        
        if s.recursive == 1
            fldrs = subdir(folder);
            fldrs{end+1} = folder; % Add base folder as well
            
            %keyboard
            % Is there a .cc2 files in any of the folders?
            ccFile = '';
            for kk = 1:numel(fldrs)
                fo = fldrs{kk};
                fi = dir([fo filesep() '*.cc']);
                if numel(fi) == 1
                    ccFile= [fo filesep() fi(1).name];
                    if hasCC == 1
                        errordlg(sprintf('More than one .cc file below %s', folder));
                        return
                    end
                    hasCC = 1;
                    fprintf('Found cc file: %s\n', ccFile);
                end
            end
            
            for kk = 1:numel(fldrs)
                fo = fldrs{kk};
                fi = dir([fo filesep() '*.NM']);
                for ff = 1:numel(fi)
                    ccFiles{end+1} = ccFile;
                    folders{end+1} = [fo filesep()];
                    files{end+1} =   [fi(ff).name];
                end
            end
        else
            files = dir([folder '*.NM']);
        end
    end
end

fprintf('%d files selected\n', numel(files));

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
if s.waitdlg
    w = waitbar(0, 'Loading files');
    drawnow()
end

for ff = 1:numel(files)
    if s.waitdlg
        waitbar((ff-1)/numel(files), w);
    end
    fname = files{ff};
    
    if numel(folders) == numel(files)
        folder = folders{ff};
    end
    if(numel(ccFiles) == numel(files))
        ccFile = ccFiles{ff};
    end
    
    if numel(ccFile) == 0
        warning('no cc file!');
    end
    
    if s.verbose
        fprintf('Loading %s\n', fname);
    end
    nmFile = [folder fname];
    D = load(nmFile, '-mat');
    
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
            errordlg('Can not load the NM files since the channels does not match! %s %s', folder, fname);
            M = {};
            N = {};
            return;
        end
    end
    
    M{ff} = D.M;
    M{ff}.nmFile = nmFile;
    
    for nn = 1:numel(D.N)
        D.N{nn}.file = fname;
        D.N{nn}.nucleiNr = nn;
        D.N{nn}.metaNo = ff;
    end
    
    if numel(ccFile) > 0
        ccData = load(ccFile, '-mat');
        disp('Applying CC')        
        D.N = df_cc_apply_n(D.M, D.N, 'ccData', ccData);        
        disp('Done!')
    end
    
    % If the first nuclei has userDots, all have
    if numel(D.N)>0
        if isfield(D.N{nn}, 'userDots')
            N = [N D.N];
        else
            if s.noclusters
                N = [N D.N];
            else
            nMissingUD = nMissingUD +numel(D.N);
        end
    end
    
    end
end

if s.waitdlg
    close(w);
end

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
        if s.verbose
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