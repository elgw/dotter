function wrong = df_ls_dapi(varargin)
% See what files have the wrong DAPI file

nFolders = 1;
folders{1} = pwd(); % By default, check current folder

s.recursive = 0;

for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, '-r')
        s.recursive = 1;
    end
end

if s.recursive
    folders0 = rdir(folders{1});
    nFolders = 0;
    for kk = 1:numel(folders0)        
        folders0{kk}(end-4:end)
        if strcmpi(folders0{kk}(end-5:end), '_calc/')
            nFolders = nFolders + 1;
            folders{nFolders} = folders0{kk};
        end
    end
end

if nFolders == 0
    disp('No calc-folders')
    return
end

n_files = 0;
n_duplicates = 0;
for kk = 1:numel(folders)
    [nf, nd] = check_folder(folders{kk});
    n_files = n_files + nf;
    n_duplicates = n_duplicates + nd;
end

fprintf('%d folders. %d nm_files, %d duplicates\n', ...
    numel(folders), ...
    n_files, ...
    n_duplicates);

end

function [n_files, n_duplicates] = check_folder(folder)

wrong = 0;
files = dir([folder filesep() '*.NM']);
n_files = numel(files);
dapi_files = {};

for kk = 1:n_files
    M = df_nm_load([folder filesep() files(kk).name]);
    
    dapi_files{kk} = M{1}.dapifile;
    fprintf('%s: %s ', files(kk).name, M{1}.dapifile);
        
    if strcmp(files(kk).name(1:3), M{1}.dapifile(end-6:end-4)) == 1
        fprintf('\n');
    else
        wrong = wrong + 1;
        fprintf(' E\n');
    end
        
end

n_duplicates = n_files - numel(unique(dapi_files));

end