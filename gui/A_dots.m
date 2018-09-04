function A_dots(varargin)
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
%
% See also: A_cells, A_settings

%% Parse input arguments
for kk = 1:numel(varargin)
    if strcmp(varargin{kk}, 'settings')
        s = varargin{kk+1};
    end
    if strcmp(varargin{kk}, 'dotSettings')
        s.dotSettings = varargin{kk+1};
    end
end

if nargin == 0
    warning('Depreciated usage')
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
    s.nkmers = 96;
end

if ~isfield(s, 'dotSettings')
    warning('Legacy mode')
    dotSettings.sigmadog = [1.12,1.12,1.6]; % x, y (=x), z
    dotSettings.xypadding = 5;
    dotSettings.localization = 'DoG';
    dotSettings.localization = 'intensity';
    dotSettings.maxNpoints = 10000;
    dotSettings.calcFWHM = 0;
    s.dotSettings = dotSettings;
end

if ~strcmp(s.folder(end), '/')
    s.folder = [s.folder '/'];
end

if isfield(s, 'dapifiles')
    dapifiles = s.dapifiles;
else
    disp(['Looking in ' s.folder]);
    dapifiles = dir([s.folder 'dapi*.tif']);
end

% As well as the files where 'dapi' is replaced by
ps = '';
if numel(dapifiles)>1
    ps = 's';
end

fprintf('%d field%s to load\n',numel(dapifiles), ps);
wfolder = [s.folder(1:end-1) '_calc/'];
psf_file = [wfolder 'psf.mat'];

%% For each image set consisting of several channels
for kk = 1:numel(dapifiles)
    dapif = dapifiles(kk).name;
    fprintf('-> Processing images related to %s\n', dapif);
    datafile = [wfolder dapifiles(kk).name(end-6:end-4) '.NM'];
    if ~exist(datafile)
        disp([datafile ' could not be loaded, aborting. Please run A_cellsSegmentation first (or A_cells)']);
        return
    end
    
    load(datafile, '-mat');
    
    %% Per channel
    for cc = 1:numel(s.channels)
        fprintf(' > %s\n', s.channels{cc});
        channelf = strrep([s.folder dapif], s.dapichannel, s.channels{cc});
        M.channelf{cc} = channelf;
        % Load the volumetric images, one per channel
        ichannel  = df_readTif(channelf);
        
        %% Deconvolution
        if s.deconvolveVolumes
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
            
            [dots, dotsMeta] = dotCandidates('image', dichannel, 'settings', s.dotSettings{cc});
        else
            [dots, dotsMeta] = dotCandidates('image', ichannel, 'settings', s.dotSettings{cc});
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
        N = associate_dots_to_nuclei(N, M.mask, dots, cc, 'dilation', s.maskDilation);
        % Properties:
        % dapi strength, centroid, contours,
        % type: S, G1, G2
        M.dots{cc} = dots;
        M.nkmers = s.nkmers;
    end
    
    if exist('PSF', 'var')
        M.PSF = PSF;
    end
    
    M.dotSettings = s.dotSettings;
    M.pixelSize = s.pixelSize;
    M.dotsMeta = dotsMeta;
    M.DOTTER_version = df_version();
    
    save(datafile, 'N', 'M');
end

fprintf('Done\n');

end