function df_A_generate_P_vs_E(varargin)
%

folder = '.';
fileNumbers = [];
allFiles = 1;

for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'folder')
        folder = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'fileNumbers')
        fileNumbers = varargin{kk+1};
        allFiles = 0;
    end
end

files = dir([folder '*.NM']);
if ~allFiles
    files = files(fileNumbers);
end

for kk = 1:numel(files)
    df_dotThresholdP('folder', folder, 'files', files);    


end