function df_createNM(varargin)
% function df_createNM(varargin)
% Purpose: Create NM files from images
%
% Create NM files from tif images.
% NM files are simly mat-files with a specific structure
% One NM file corresponds to one field of view
% and each file should contain a struct
% called M (for meta) that contains information about the
% field of view such as where the files can be found etc.
% Then there should be a cell called N that contains
% one struct per nuclei.
%
% Input argments:
% None required, will interactively ask for a folder to process.

% 20190219 This replaces A_cells

s = getArguments(varargin, nargin);
if numel(s) == 0
    disp('Missing settings. Quitting.');
    return
end

% Localization settings for dotCandidates.m
dotSettings.xypadding = 5;
dotSettings.localization = 'DoG';
dotSettings.localization = 'intensity';
dotSettings.maxNpoints = 10000;
dotSettings.calculateFWHM = 0;
s.dotSettings = dotSettings;
s.NA = 1.45;

%% Identify channels and determine which to use
disp('Identifying channels based on *.tif files')
[chan, dapichan, dapifiles] = df_channelsFromFileNames(s.folder);
if numel(chan) == 0
    disp('No channels detected')
    return
end

if isfield(s, 'channels')
    disp('Using user supplied channels')
else
    s.channels = unique(chan);
    disp('Using automatically identified channels')
end

if ~isfield(s, 'dapichannel')
    s.dapichannel = dapichan;
end

if numel(dapifiles) == 0
    warndlg('No DAPI files found!');
    return
end

% Make a selection of fields to use
fnums = listdlg('Name', 'Select Fields To use', 'ListString', dapifiles, 'InitialValue', 1:numel(dapifiles));
dapifiles = dapifiles(fnums);

s.dapifiles = dapifiles;

if numel(dapifiles) == 0
    disp('No Fields to process')
    return
end

fprintf('%d fields selected\n', numel(dapifiles));

if ~isfield(s, 'nTrueDots')
    s.nTrueDots = 2*ones(1, numel(s.channels));
end

qstring = sprintf('DAPI: %s\n', s.dapichannel);
for kk = 1:numel(s.channels)
    qstring = sprintf('%s\n%s (%d)', qstring, s.channels{kk}, s.nTrueDots(kk));
end

%% Let the user verify/change the parameters
% Note that the nuclei detection is not mandatory
% and hence settings has to be stored in meta data
% by the dot detection routine

s.threeD = 0;
disp('s = df_createNM_gui(s);');
s = df_createNM_gui(s);

if numel(s) == 0
    disp('Got no settings, quiting')
    return
else
    disp('Got settings, continuing');
end

%% Find cells/nuclei/objects
% Three alternatives:
%  - Segment cells
%  - Use existing segmentation already in NM files
%  - Load segmentation mask from files, s.askForSegmentationMasks

if s.useExistingSegmentation
    fprintf('Using existing segmentation\n');
end

if s.askForSegmentationMasks
    s.maskFiles = uipickfiles('Prompt', 'Select nuclei mask files', 'REFilter', '\.png$|\.tif$');
    if(isnumeric(s.maskFiles))
        warndlg('Got no mask to use. Aborting.');
        return;
    end
    
    s.maskFiles = sort(s.maskFiles);
    for kk = 1:numel(s.maskFiles)
        s.masks{kk} = df_readExternalMask(s.maskFiles{kk});
    end
    A_cellSegmentation('settings', s);
end

if s.segmentNuclei
    fprintf('Running A_cellSegmentation to segment nuclei\n');
    A_cellSegmentation('settings', s);
end

calcFolder = [s.folder(1:end-1) '_calc' filesep()];

%% Set DAPI
% Load all nuclei and interactively ask for threshold to 
% separate G1 from G2
df_setDapiForFolder(calcFolder);

%% Find dots
%  and write NM files to _calc folder
disp('>>> Running A_dots to find dots')
% save([calcFolder 'settingsA.mat'], 's');  % Not needed
df_createNM_getDots('settings', s, 'dotSettings', s.dotSettings);

%% Generate preview images 
% Purpose: 
% showing segmented cells and their numbers for
% future reference
generate_preview_images(s, calcFolder)
    
disp('All Done')
end

function generate_preview_images(s, calcFolder)
disp('>>> Generating segmentataion preview images')
A_cells_generate_segmentation_preview(calcFolder)

disp('>>> Generating segmentataion preview images')
A_cells_generate_dot_curves(calcFolder)

if isfield(s, 'experimentType')
    if strcmpi(s.experimentType, 'dnafish') == 1
        if s.generatePvsE
            disp('>>> Generating PvsE pdfs for each channel')
            df_dotThresholdP('folder', calcFolder, 'saveFig', 1);
        end
    end
end
end

function s = getArguments(varargin, nargin)

folder = [];
for kk = 1:numel(varargin)
    if strcmp(varargin{kk}, 'folder')
        folder = varargin{kk+1};
    end
end

if numel(folder)==0
    folder = df_getConfig('df_createNM', 'folder', '~/Desktop/');
    if nargin == 0 || ~ischar(folder)
        folder = uigetdir(folder);
        if isa(folder, 'double')
            disp('No folder selected quiting')
            s = [];
            return;
        end
        folder = folder;
    end
end

fprintf('Folder: %s\n', folder);

% Add trailing filesep() if not there (usually a '/')
if ~strcmp(folder(end), filesep())
    folder = [folder filesep()];
end

df_setConfig('df_createNM', 'folder', folder);

s.folder = folder;
s.deconvolveVolumes = 0;
s.dapiGUI=1;
s.dapiWS=0;
s.maskDilation = 0;
s.dapiManual = 0;

return;
end