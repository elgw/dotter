function [M,N] = df_nm_load(fileName, varargin)
% Load nuclei and metadata from folder or file

M = [];
N = [];

nmax = -1;
for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'n')
        nmax = varargin{kk+1};
    end
end

if isdir(fileName)
    folder = [fileName filesep()];
    files = dir([fileName filesep() '*.NM']);
    if numel(files) == 0
        error('No NM files in folder');
    end
    if nmax>0
        files = files(1:min(numel(files), nmax));
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
end

M = [M, {D.M}];
N = [N, D.N];
end

end
