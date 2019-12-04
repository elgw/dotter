function dapiThres = df_getDapiThres(varargin)
%% function dapiThres = df_getDapiThres(varargin)
% Get DAPI threshold from folder/experiment.mat
% if it exists.
%
% > Example: 
% df_getDapiThres('folder', folder);
%

for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'folder')
        folder = varargin{kk+1};
    end
end

if ~exist('folder', 'var')
    folder = uigetdir();
end

fprintf('Folder: %s\n', folder);

confFile = [folder '/experiment.mat'];
fprintf('Conf file: %s\n', confFile);

if exist(confFile, 'file')
    t = load(confFile);
    conf = t.conf;
    
    if(isfield(conf, 'dapiThres'))
        dapiThres = conf.dapiThres;
        fprintf('Dapi threshold: %.2e\n', dapiThres);
        return
    end
else
    disp('No conf file')
    conf = [];
end

% If there was no config
dapi = getDapiFromFolders([], {folder});

if numel(dapi) == 0
    disp('No dapi available')
    return
end

figure
histogram(dapi, numel(dapi)/2);

dapiThres = inputdlg('Set DAPI threshold');

if ~isnumeric(dapiThres)
    dapiThres = str2num(dapiThres{1});
    fprintf('Dapi threshold: %.2e\n', dapiThres);
    conf.dapiThres = dapiThres;
    
    save(confFile, 'conf', '-mat');
end

end