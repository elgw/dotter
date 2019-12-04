function [D,A] = getDapiFromFolders(startfolder, folders)
% Extract integral DAPI from all nuclei in all NM files in a folder
% Also extracts areas from the mask image.

% 2017-08-21
% Clarifies that it wants a folder as input
% Also extracts the area of each nuclei from the mask (M.mask)

if ~exist('startfolder', 'var')
    startfolder = '';
end

if ~exist('folders', 'var')
% Note, uipickfiles not good with '~' - tilde.
folders = uipickfiles('FilterSpec', startfolder, 'Prompt', 'Select FOLDER(s) with NM files');
end

D = []; % sum of DAPI intensities
A = []; % Area of nuclei
for kk = 1:numel(folders)
    folder = folders{kk};
    files = dir([folder '/*.NM']);
    fprintf('Reading %d files\n', numel(files));
    for ll = 1:numel(files)
        Meta = load([folder '/' files(ll).name], '-mat');
        if ll == 1
        M = Meta.M;
        if isfield(M, 'dapiTh')
            fprintf('Existing dapiTh: %d\n', M.dapiTh);
        end
        end
        for nn = 1:numel(Meta.N)            
            D = [D, Meta.N{nn}.dapisum];
            A = [A, sum(Meta.M.mask(:)==nn)];
        end
    end
end

end