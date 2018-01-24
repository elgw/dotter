function A_cellSegmentation(varargin)
%% Segments nuclei in DAPI images
%
% Usually called by A_cells which later on calls A_dots
% 'settings', s.folder, s.dapiGUI, s.maskDilation, s.dapiWS
% This scripts creates and changes dir to

if nargin == 0
    disp('No arguments, looking for dapi*.tif in current folder and using default settings')
    s.folder = uigetdir(pwd);
    if isa(s.folder, 'double')
        disp('Aborting')
        return
    end
    s.dapiGUI = 1;
    s.maskDilation = 0;
    s.dapiWS = 0;
    s.deconvolveVolumes=0;
    s.nTrueDots = [];
    s.channels = [];
    s.threeD = 0;
end

%% Parse input arguments
for kk = 1:numel(varargin)
    if strcmp(varargin{kk}, 'settings')
        s = varargin{kk+1};
    end
end

%% Add trailing '/' to folder
if ~strcmp(s.folder(end), '/')
    s.folder = [s.folder '/'];
end

%% See what files there were in the folder
fprintf('Loading DAPI files in %s\n', s.folder);

if isfield(s, 'dapifiles')
    dapifiles = s.dapifiles;
else
    dapifiles = dir([s.folder 'dapi*.tif']);
    if numel(dapifiles)==0
        fprintf('No tif files files found in %s, quiting.\n', folder)
        return
    end
end

fprintf('%d images to load\n', numel(dapifiles));


%% Identify channels and determine which to use
s.dapichan = 'dapi';

%% Create the output folder
disp('Creating output folder')
wfolder = [s.folder(1:end-1) '_calc/']; % w. trailing /

if exist(wfolder, 'dir')~=7
    mkdir(wfolder)
end

%% Initialization
NN = []; % Stores all the nuclei
Ntot = 0; % Total number of nuclei

%% For each image set consisting of several channels
for kk = 1:numel(dapifiles)
    fprintf('Loading %s ... ', dapifiles(kk).name);
    dapif = [s.folder dapifiles(kk).name];
    
    M = []; % Meta data, for all the nuclei
    
    M.dapifile = dapif;
    M.nTrueDots = s.nTrueDots;
    M.channels = s.channels;
    M.nkmers = s.nkmers;
    M.pixelSize = s.pixelSize;
    
    %% Things on DAPI
    idapi = df_readTif(dapif);
    fprintf('ok\n');
    
    M.imageSize = size(idapi);
    dapisettings.useWatershed = s.dapiWS;
    
    if isfield(s, 'masks')
        mask = s.masks{kk};
    else
        P = idapi; % Projection, might be updated by get_nuclei_dapi_ui
        if s.dapiGUI
            if s.threeD
                refine = 0;
                mask = get_nuclei_dapi_3_ui(idapi, dapisettings);
            else
                [mask, refine, P] = get_nuclei_dapi_ui(idapi, dapisettings);
            end
        else
            [mask] = get_nuclei_dapi(idapi, dapisettings);
        end
        
        if s.dapiManual || refine
            [mask] = get_nuclei_manual(mask, P);
        end
    end
    
    N = create_nuclei_from_mask(mask, idapi);
    
    Ntot = Ntot+numel(N);
    %dotterSlide_settings.mask = mask;
    %dotterSlide_settings.limitedCLIM = 1;
    %dotterSlide(idapi, dots, [], dotterSlide_settings);
    %pause
    
    ddapif = strrep([wfolder dapifiles(kk).name], 'dapi', 'd_dapi');
    ddapif = strrep(ddapif, '.tif', '.mat');
    
    % check if there is a file with deconvolution results, if not,
    % deconvolve the channel and write to disk before continuing.
    if s.deconvolveVolumes
        if ~exist(ddapif, 'file')
            disp('Deconvolving');
            didapi = deconvW3(idapi, PSF);
            save(ddapif, 'didapi');
        else
            load(ddapif, '-mat');
        end
    end
    
    M.mask = mask;
    datafile = [wfolder dapifiles(kk).name(end-6:end-4) '.NM'];
    save(datafile, 'N', 'M');
end

fprintf('Found %d nuclei\n', Ntot');
fprintf('Done\n');

end