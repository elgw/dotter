function [M,N] = df_nm_load(fileName, varargin)
%% function [M,N] = df_nm_load(fileName, varargin)
% Load nuclei and metadata from folder or file

M = [];
N = [];

s.nmax = -1;   % Max number of nuclei to load
s.ccFile = []; % Correction file name

for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'n')
        s.nmax = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'cc')
        s.ccFile = varargin{kk+1};
    end
end

if strcmp(s.ccFile, 'ccFile')
    keyboard
end

if isdir(fileName)
    folder = [fileName filesep()];
    files = dir([fileName filesep() '*.NM']);
    if numel(files) == 0
        error('No NM files in folder');
    end
    if s.nmax>0
        files = files(1:min(numel(files), s.nmax));
    end
else
    folder = '';
    files(1).name=fileName;
end

for kk = 1:numel(files)
    D = load([folder files(kk).name], '-mat');
    
    if ~isfield(D, 'M')
        error('No meta data available');
    end
    
    if ~isfield(D, 'N')
        error('No nuclei available');
    end
    
    for nn = 1:numel(D.N)
        D.N{nn}.metaNo = kk;
        D.N{nn}.nucleiNr = nn;
    end
    
    if numel(s.ccFile)>0
        fprintf('Applying cc from %s', s.ccFile);
        D.N = df_cc_apply_n(D.M, D.N, 'ccFile', s.ccFile);
        D.M = df_cc_apply_m(D.M, 'ccFile', s.ccFile);
    end
    
    M = [M, {D.M}];
    N = [N, D.N];    
end


end