function A_cells(folder, varargin)
% Finds dot candidates and segments the nuclei,
% Saves this data for further processing.
%
% The output data is in two structures:
% M : meta data
% N : nuclei information,
% which is finally written to a .NM file
%
% Then B_global has to be run and then
% ~/code/NEditor/NEditor.m can be used
% Files has to follow the naming convention channel_ABC.tif
% where ABC is a number, i.e., 001, 002, ...

%dbstatus
%dbstop if error
%dbstop if warning
%close all
%clear all

if nargin == 0 || ~ischar(folder)
    folder = uigetdir(pwd);
    if isa(folder, 'double')
        return
    end
end


s.folder = folder;
deconvolveVolumes = 0;
s.dapiGUI=1;
s.dapiWS=0;
s.maskDilation = 0;

%% I.A
if ~strcmp(folder(end), '/')
    folder = [folder '/'];
end

%% See what files there were in the folder
fprintf('Loading files in %s\n', folder);
chan = {};
files = dir([folder '*.tif']);
if numel(files)==0
    fprintf('No tif files files found in %s, quiting.\n', folder)
    return
end

files = dir([folder '*' files(1).name(end-6:end)]);

%% Identify channels and determine which to use
disp('Identifying channels')
for kk=1:numel(files)
    t = strsplit(files(kk).name, '_');
    t = t{1};
    if strcmp(t(end), '_')
        t = t(1:end-1);
    end
    fprintf('%s found\n', t);
    if numel(strfind(t, 'dapi'))==0
        chan{end+1} = t;
    else
        dapichan=t;
    end
end

if ~isfield(s, 'dapichannel')
    s.dapichannel = dapichan;
end

if isfield(s, 'channels')
    disp('Using user supplied channels')
else
    s.channels = chan;
    disp('Using automatically identified channels')
end

%% Determine number of dots per channel
if ~isfield(s, 'nTrueDots')
    s.nTrueDots = 2*ones(1, numel(files)-1);
end
%assignin('base', 's', s)
%return


qstring = sprintf('DAPI: %s\n', s.dapichannel);
for kk = 1:numel(s.channels);
    qstring = sprintf('%s\n%s (%d)', qstring, s.channels{kk}, s.nTrueDots(kk));
end

%% Let the user verify/change the parameters
s = A_settings(s);

%%
disp('Creating output folder')
wfolder = [folder(1:end-1) '_calc/']; % w. trailing /

if exist(wfolder, 'dir')~=7
    mkdir(wfolder)
end

% More specific
dapifiles = dir([folder 'dapi*.tif']);
% As well as the files where 'dapi' is replaced by
fprintf('%d images to load\n', numel(dapifiles));

psf_file = [wfolder 'psf.mat'];

% Localization settings for dotCandidates.m
dotSettings.sigmadog = [1.12,1.12,1.6]; % x, y (=x), z
dotSettings.xypadding = 5;
dotSettings.localization = 'DoG';
dotSettings.localization = 'intensity';
dotSettings.maxNpoints = 10000;

%% Initialization

NN = []; % Stores all the nuclei

if ~exist('kk', 'var')
    kk = 1;
end

Ntot = 0;

%% For each image set consisting of several channels
for kk = 1:numel(dapifiles)
    M = []; % Meta data, for all the nuclei
    disp(dapifiles(kk).name)
    dapif = [folder dapifiles(kk).name];
    M.nTrueDots = s.nTrueDots;
    M.dotSettings = dotSettings;
    
    %% Things on DAPI
    idapi = df_readTif(dapif);
    
    M.imageSize = size(idapi);
    dapisettings.useWatershed = s.dapiWS;
    if s.dapiGUI
        [N, mask] = get_nuclei_dapi_ui(idapi, dapisettings);
    else
        [N, mask] = get_nuclei_dapi(idapi, dapisettings);
    end
    Ntot = Ntot+numel(N);
    dotterSlide_settings.mask = mask;
    dotterSlide_settings.limitedCLIM = 1;
    %dotterSlide(idapi, dots, [], dotterSlide_settings);
    %pause
    
    ddapif = strrep([wfolder dapifiles(kk).name], 'dapi', 'd_dapi');
    ddapif = strrep(ddapif, '.tif', '.mat');
    
    % check if there is a file with deconvolution results, if not,
    % deconvolve the channel and write to disk before continuing.
    if deconvolveVolumes
        if ~exist(ddapif, 'file')
            disp('Deconvolving');
            didapi = deconvW3(idapi, PSF);
            save(ddapif, 'didapi');
        else
            load(ddapif, '-mat');
        end
    end
    
    %% Per channel
    for cc = 1:numel(s.channels)
        fprintf(' > %s\n', s.channels{cc});
        channelf = strrep(dapif, s.dapichannel, s.channels{cc});
        M.channelf{cc} = channelf;
        % Load the volumetric images, one per channel
        ichannel  = df_readTif(channelf);
        
        
        %{ depreciated, PSF is estimated from nano beads
        if 0 % ~exist('PSF', 'var')
            dots = dotCandidates(ichannel, dotSettings);
            PSF = estimatePSF(ichannel, dots(1:20,:), 'side', 11);
            save(psf_file, 'PSF');
        end
        %}
        
        %% Deconvolution
        if deconvolveVolumes
            temp = [wfolder dapifiles(kk).name];
            dchannelf = strrep(temp, 'dapi', ['d_' s.channels{cc}]);
            dchannelf = strrep(dchannelf, '.tif', '.mat');
            
            % check if there is a file with deconvolution results, if not,
            % deconvolve the channel and write to disk before continuing.
            if ~exist(dchannelf, 'file')
                disp('Deconvolving');
                dichannel = deconvW3(ichannel, PSF);
                save(dchannelf, 'dichannel');
            else
                load(dchannelf);
            end
            
            dots = dotCandidates(dichannel, dotSettings);
        else
            dots = dotCandidates(ichannel, dotSettings);
        end
        %pause
        %dotterSlide(ichannel, dots)
        
        if 0
            disp('gaussianSize')
            gs.mode = 9;
            dots_g = gaussianSize(ichannel, dots, [1:.2:3.6], gs);
            [~, idx] = sort(dots_g(:,2), 'descend');
            %dotterSlide(ichannel, dots)
            %dotterSlide(ichannel, dots, dots_g(:,2))
            dots = dots(idx, :);
        end
        
        
        if 0 %% Figure out best sigmas for dot detection
            
            % X or Y
            sigmas = linspace(1,3);
            sigmasl = 0*sigmas;
            for hh = 1:numel(sigmas)
                [x, v]=gaussFit1(squeeze(PSF(:,7,7)), 7, sigmas(hh));
                sigmasl(hh)=v;
            end
            plot(sigmas,sigmasl);
            
            % Z
            sigmas = linspace(1,3);
            sigmasl = 0*sigmas;
            for hh = 1:numel(sigmas)
                [x, v]=gaussFit1(squeeze(PSF(7,7,:)), 7, sigmas(hh));
                sigmasl(hh)=v;
            end
            plot(sigmas,sigmasl);
            
            
        end
        
        %% Associate dots with nuclei
        N = associate_dots_to_nuclei(N, mask, dots, cc, 'dilation', s.maskDilation);
        % Properties:
        % dapi strength, centroid, contours,
        % type: S, G1, G2
    end
    
    M.channels = s.channels;
    M.dapichannel = s.dapichannel;
    M.dapifile = dapif;
    M.mask = mask;
    
    if exist('PSF', 'var')
        M.PSF = PSF;
    end
    datafile = [wfolder dapifiles(kk).name(end-6:end-4) '.NM'];
    save(datafile, 'N', 'M');
end

fprintf('Found %d nuclei\n', Ntot');
fprintf('Done\n');

%B_cells_global(wfolder);

end