function NEditor(rfolder)
%% Display and Edit Nuclear dots
% 
% Purpose:
% - Look for the predefined number of dots in a nuclei at a time
% - Cluster the dots
% - Export directly
%
% Notes:
% - This viewer does not care about the userDots and does not change the NM
% files

% Bugs:
% - xz view lost after zooming
%
% To do:
%  - Slider or other method to select the number of dots to show
%  - Harmonize the clustering functions so that the use the same parameters
%  - Identify large dots as possibly two
%  - Try to split large dots (post processing)
%  - Change default behaviour not to show any annotations
%  - A few more things to reset when loading new nuclei.
%  - Export to selection to .mat for post processing.
%  - Deconvolution per cell to minimize the effect of the spatially varying
%  PSF
%  - Can properties of individual dots be changed when plotted as
%  line? Then it would be easy to update the selection interactively.
%
% For this sample - 310715_iMB2:
% Expected dots 14 per homologue, i.e. 28 in total.
% TMR: 4, a594: 5, cy5: 5. But, at least two broken probes, 11 and 12,
% which gives 4,4,4 dots to expect.
%

% Clustering functions:
% NE_inital_clusters, NE_show_clusters, populateClusters

%dbstop if all error


% For debug
debugMode = 1;
if debugMode
    close all
end

% Initialization

if ~exist('rfolder', 'var')
    rfolder = uigetdir(pwd());
    if rfolder == 0
        disp('No _calc folder selected, returning')
        return
    else
        rfolder = [rfolder '/'];
    end
else
    if ~strcmp(rfolder(end), '/')
        rfolder = [rfolder '/'];
    end
end

NE.rfolder = rfolder;
fprintf('Reading from %s\n', NE.rfolder);

files = dir([NE.rfolder '*.NM']);
if(numel(files)<1)
    fprintf('No files %s, quiting\n', NE.rfolder);
    return
end
fprintf('%d files available\n', numel(files));

NE.wfolder = [rfolder 'NE1/'];

if ~exist(NE.wfolder, 'dir')
    mkdir(NE.wfolder)
end

fprintf('Writing to %s\n', NE.wfolder);

fittingSettings.sigmafitXY = 1.3;
fittingSettings.sigmafitZ = 2.27;
fittingSettings.useClustering = 1;
fittingSettings.clusterMinDist = fittingSettings.sigmafitXY;
fittingSettings.fitSigma = 0;
fittingSettings.verbose = 1;
% Appearance
NE.dotStyles = {'ro', 'go', 'bo', 'ko', 'cx'};
NE.dotColors = ['r', 'g', 'b', 'k', 'c'];
NE.dotSize = [5,7,9, 11, 4];
NE.clusterColors={.75*[1,1,0], .75*[1,0,1]};
% States
NE.file = 1;
NE.nuclei = 6;
NE.gFileLoaded = 0;
NE.gCellLoaded = 0;
NE.gChannel = 'a594';
NE.gChannelNo = 1;
NE.dChannel = '';
NE.gMinMax = {};
NE.dots = [];
NE.showLabels = [];
NE.maxDotsPerChannel = 15; % Cut off the other dots
NE.gIDLoaded = 0;
NE.nDotsShow = 40; % Number of dots in the plot
NE.mipXY={};
NE.mipXZ={};
NE.mipYZ={};
NE.cLimChannel = {[],[],[],[],[],[],[],[],[],[]};
NE.zFirst = 1;
NE.zLast = 20;

NE.LP = 0; % Apply a Low Pass Filter on the Images
NE.LP_Sigma = 25; % Sigma of the low pass filter

% Clustering varables/settings
NE.resolution = [131.08,131.08,200];
NE.deconv = 0;

fprintf('Resolution: %.2f x %.2f x %.2f nm\n', NE.resolution(1), NE.resolution(2), NE.resolution(3));

%NE.d0 = 18;
NE.d0nm = 15*NE.resolution(1);

NE.thresholdFactor = 0.1; % 1==at threshold, <1 below (more dots)

NE.clusterChannel = 1; % Which channel to identify clusters in
NE.dChannel = 'a594'; % dot channel
NE.dChannelNo = 1;
NE.dShowNumbers = 1;
NE.showOnlySelected = 1;
NE.showClusterDots = 1;
NE.showClusterContours = 1;
% Variables that will be loaded
NE.R1 = {[],[],[],[],[]}; % Contains the selected regions/dots
NE.R2 = {[],[],[],[],[]};

NE.fig_rdots1=[0,0,0];
NE.fig_rdots2=[0,0,0];
NE.fig_c1objects = [];
NE.fig_c2objects = [];
NE.fig_xy = [];
NE.fig_xz = [];
NE.fig_zy = [];
NE.fig_dots= {[],[],[],[],[]};
NE.fig_labels = {};
% Temporary variables
bbx = [];
dots = []; dots0 = [];
exportFilename = [];
% From initial_clusters, rewrite as function
C = []; C1 = []; C2 = [];
Ht = []; Hm1 = []; Hm2 = []; H = [];
c1 = []; c2 = [];
x = [];
y = [];
z = [];
r = [];
ss = [];
labels = [];
kk = [];
ll =[];

%% Initiate GUI
% For components, see these sections in the MATLAB manual
% 'uicontrol', 'programmatic components'

NE.menu = figure('Position', [0,200,400,600], 'Menubar', 'none', ...
    'Color', [.8,1,.8], ...
    'NumberTitle','off', ...
    'Name', 'Nuclei Editor');

tabgp = uitabgroup(NE.menu,'Position',[.0 .0 1 .95]);
tab1 = uitab(tabgp,'Title','Load');
tab2 = uitab(tabgp,'Title','View');
%tab3 = uitab(tabgp,'Title','Controls');
%tab4 = uitab(tabgp,'Title','Edit');

% Components in Tab 1
tabB0 = 100; % Vertical offset
uicontrol(tab1,'Style','text',...
    'String','File',...
    'Position',[30 320+tabB0 150 30]);
guiFileNames = uicontrol(tab1,'Style','popupmenu',...
    'String',{files.name},...
    'Value',1,'Position',[30 300+tabB0 150 20]);
guiFileLoad = uicontrol(tab1,'Style','pushbutton','String','Load',...
    'Position',[30 250+tabB0 150 30], ...
    'Callback', @gui_LoadFile);
uicontrol(tab1, 'Style', 'pushbutton', ...
    'String', 'Show DAPI and Cells', ...
    'Position',[30 170+tabB0 150 30], ...
    'Callback', @gui_ShowDapi);

uicontrol(tab1, 'Style', 'pushbutton', ...
    'String', 'Show Channels', ...
    'Position',[30 130+tabB0 150 30], ...
    'Callback', @gui_ShowChannels);

uicontrol(tab1,'Style','text',...
    'String','Nuclei',...
    'Position',[30 70+tabB0 150 30]);
guiNuclei = uicontrol(tab1,'Style','popupmenu',...
    'String',{'-'},...
    'Value',1,'Position',[30 40+tabB0 150 20]);
uicontrol(tab1,'Style','pushbutton','String','Load',...
    'Position',[30 tabB0 150 30], ...
    'Callback', @gui_LoadNuclei);

%% Components in Tab 2

% Add/remove to Clusters
tabB0 = 100; % Vertical offset
NE.fig_b1 = uicontrol(tab2, 'Style','edit','String',num2str(NE.d0nm),...
    'Position',[155 350+tabB0 50 30], ...
    'Callback', @gui_changeD0NM);
NE.fig_b1 = uicontrol(tab2, 'Style','text','String','Cluster distance (nm), default 2340',...
    'Position',[30 350+tabB0 120 30], ...
    'Callback', @gui_changeD0NM);

uicontrol(tab2,'Style','pushbutton',...
    'String','Clusters',...
    'Position',[30 310+tabB0 80 30], ...
    'Callback', @NE_FindClusters);

uicontrol(tab2,'Style','pushbutton',...
    'String','Strongest',...
    'Position',[120 310+tabB0 80 30], ...
    'Callback', @NE_FindStrongest);


%uicontrol(tab2, 'Style', 'text', ...
%    'String', 'Cluster start', ...
%    'Position', [200, 40+tabB0, 150, 20]);

NE.clusterChannelSelector = uicontrol(tab2, 'Style', 'popupmenu', ...
    'String', {'-'}, ...
    'Value', 1, 'Position', [220, 310+tabB0, 100, 30], ...
    'Callback', @NE_changeClusterChannel);

if 0
    uicontrol(tab2,'Style','pushbutton',...
        'String','101',...
        'Position',[115 310+tabB0 40 30], ...
        'Callback', @NE_FindClusters101);
    uicontrol(tab2,'Style','pushbutton',...
        'String','110',...
        'Position',[155 310+tabB0 40 30], ...
        'Callback', @NE_FindClusters110);
    uicontrol(tab2,'Style','pushbutton',...
        'String','Triplets',...
        'Position',[200 310+tabB0 80 30], ...
        'Callback', @NE_FindClusters111);
end

% Populate R1 and R2
uicontrol(tab2,'Style','pushbutton',...
    'String','Snap To Clusters',...
    'Position',[30 270+tabB0 120 30], ...
    'Callback', @NE_AssociateToClusters);

% Save/Load buttons
%uicontrol(tab2,'Style','pushbutton','String','Save CR',...
%    'Position',[30 150+tabB0 60 30], 'Callback', @NE_SaveCR);
%uicontrol(tab2,'Style','pushbutton','String','Load CR',...
%    'Position',[100 150+tabB0 60 30], 'Callback', @NE_LoadCR);

% To set the first and last slice to show
uicontrol(tab2, 'Style', 'text', 'String', 'First and last z-slice', 'Position', [30, 190+tabB0, 150, 30]);
NE.zFirstEdit = uicontrol(tab2, 'Style', 'edit', 'String', '1', 'Position', [30, 160+tabB0, 60, 30]);
NE.zLastEdit =  uicontrol(tab2, 'Style', 'edit', 'String', '2', 'Position', [100, 160+tabB0, 60, 30]);
NE.zRange =     uicontrol(tab2, 'Style', 'text', 'String', '', 'Position', [180, 160+tabB0, 60, 30]);


uicontrol(tab2,'Style','pushbutton','String','Show',...
    'Position',[30 100+tabB0 130 30], ...
    'Callback', @NE_InitWindows);


% Export buttons
uicontrol(tab2,'Style','pushbutton','String','Exp R1',...
    'Position',[30 30+tabB0 60 30], 'Callback', @NE_ExpTR1);
uicontrol(tab2,'Style','pushbutton','String','Exp R2',...
    'Position',[100 30+tabB0 60 30], 'Callback', @NE_ExpTR2);

uicontrol(tab2,'Style','pushbutton','String','Command Line',...
    'Position',[200 tabB0 120 30], 'Callback', @NE_DBG);

if 0
    % Tab 3 - Plot options
    
    % Cluster/selection visualization
    NE.cPanel = uipanel(tab3,  'Title', 'Clusters', ...
        'FontSize', 16, ...
        'BackgroundColor','white', ...
        'Position', [0,.67,1, .2]);
    
    NE.fig_b1 = uicontrol(NE.cPanel, 'Style','pushbutton','String','C1',...
        'BackgroundColor', NE.clusterColors{1}, ...
        'Position',[5 5 30 30], ...
        'Callback', @gui_visC1);
    
    % Views
    % DO: change so that it updates the right window
    NE.pPanel = uipanel(tab3,  'Title', 'Projection', ...
        'FontSize', 16, ...
        'BackgroundColor','white', ...
        'Position', [0,.45,1, .15]);
    
    NE.fig_b2 = uicontrol(NE.pPanel, 'Style','pushbutton','String','XZ',...
        'Position',[35 5 30 30], ...
        'Callback', 'view([90,0]);');
    NE.fig_b1 = uicontrol(NE.pPanel, 'Style','pushbutton','String','XY',...
        'Position',[5 5 30 30], ...
        'Callback', 'view([0,90]);');
    NE.fig_b3 = uicontrol(NE.pPanel, 'Style','pushbutton','String','YZ',...
        'Position',[65 5 30 30], ...
        'Callback', 'view([0,00]);');
    NE.fig_b3 = uicontrol(NE.pPanel, 'Style','pushbutton','String','3D',...
        'Position',[95 5 30 30], ...
        'Callback', 'view(3);');
    
    % Buttons for MIP images
    NE.gPanel = uipanel(tab3,  'Title', 'Graphics Channel', ...
        'FontSize', 16, ...
        'BackgroundColor','white', ...
        'Position', [0,.2,1, .15]);
    NE.gui_cLimA = uicontrol(NE.gPanel, 'Style', 'slider',...
        'Min',1,'Max',50,'Value',41,...
        'Position', [140 35 120 20],...
        'Callback', @gui_sliderClim);
    NE.gui_cLimB = uicontrol(NE.gPanel, 'Style', 'slider',...
        'Min',1,'Max',50,'Value',41,...
        'Position', [140 5 120 20],...
        'Callback', @gui_sliderClim);
    
    
    uicontrol(tab3, 'Style','pushbutton','String','EXP',...
        'Position',[ 270 0 30 30], ...
        'Callback', 'assignin(''base'', ''NE'', NE)');
    
    
    % Tab 4
    uicontrol(tab4,'Style','pushbutton','String','C1',...
        'Position',[0 0 60 30], ...
        'Callback', 'set(NE.guiTab3Edit, ''Data'', NE.C1)');
    uicontrol(tab4,'Style','pushbutton','String','C2',...
        'Position',[70 0 60 30], ...
        'Callback', 'set(NE.guiTab3Edit, ''Data'', NE.C2)');
    
    NE.guiTab3Edit = uitable(tab4, 'Data', NE.resolution, 'Position', [0,60,300,500], ...
        'ColumnEditable', [true]);
end

%% Functions

    function gui_LoadFile(varargin)
        NE.file = get(guiFileNames, 'Value');
        S = load([NE.rfolder files(NE.file).name], '-mat');
        NE.M = S.M;
        NE.Nall = S.N;
        NE.gFileLoaded = 0;
        % Update GUI Components
        
        x=[];
        
        for kk=1:numel(S.N)
            if isfield(S.M, 'dapival')
                t = (S.N{kk}.dapisum > S.M.dapival);
            else
                t = 0;
            end
            if (t)
                x{kk} = sprintf('%d (G2)', kk);
            else
                x{kk} = sprintf('%d', kk);
            end
        end
        set(guiNuclei, 'Value', 1);
        set(guiNuclei, 'String', x);
        
        %% Load the channel names and put into the clusterChannelSelector
        
        set(NE.clusterChannelSelector, 'string', NE.M.channels)
        set(NE.clusterChannelSelector, 'value', 1);
        
    end

    function NE_DBG(varargin)
        keyboard
    end


    function gui_ShowDapi(varargin)
        NE.idapi = df_readTif(strrep(NE.M.dapifile, 'erikw', getenv('USER')));
        figure,
        imagesc(sum(NE.idapi, 3));
        colormap gray
        hold on
        contour(NE.M.mask, [.5,.5], 'r')
        
        
        for tt = 1:numel(NE.Nall)
            if(isfield(NE.M, 'dapival'))
                x = NE.Nall{tt}.dapisum<NE.M.dapival;
            else
                x = 1;
            end
            plotbbx(NE.Nall{tt}, sprintf('%d', tt), x)
        end
        
        
        axis image
        axis xy
    end

    function gui_ShowChannels(varargin)
        r = strsplit(NE.M.dapifile, '/');
        r= r{end};
        r = r(1:end-8);
        NE.idapi = df_readTif(strrep(NE.M.dapifile, 'erikw', getenv('USER')));
        
        x = zeros(size(NE.idapi, 1), size(NE.idapi, 2), 3);
        % Load channels and sum them
        for kk = 1:numel(NE.M.channels)
            y = df_readTif(strrep(NE.M.dapifile, r, NE.M.channels{kk}));
            x(:,:,kk) = max(y, [], 3);
        end
        
        if numel(NE.M.channels)==3
            x = double(x);
            x = x-min(x(:));
            x = x/max(x(:));
            x = x*1.5;
            x(x>1) = 1;
            
            figure,
            imshow(x);
            colormap gray
            hold on
            contour(NE.M.mask, [.5,.5], 'r')
            for kk = 1:numel(NE.Nall)
                plotbbx(NE.Nall{kk}, sprintf('%d', kk), NE.Nall{kk}.dapisum<NE.M.dapival)
            end
            axis image
            axis xy
        else
            for kk=1:numel(NE.M.channels)
                figure, imagesc(x(:,:,kk))
                title(NE.M.channels(kk))
                axis image
                colormap gray
            end
        end
    end

    function plotbbx(N, label, color)
        if color == 1
            x = 'g';
        else
            x = 'b';
        end
        plot([N.bbx(3), N.bbx(3)], [N.bbx(1), N.bbx(2)], x);
        plot([N.bbx(4), N.bbx(4)], [N.bbx(1), N.bbx(2)], x);
        plot([N.bbx(3), N.bbx(4)], [N.bbx(1), N.bbx(1)], x);
        plot([N.bbx(3), N.bbx(4)], [N.bbx(2), N.bbx(2)], x);
        text(N.bbx(3), N.bbx(1), label, 'Color', [1,0,0], 'FontSize', 14);
    end

    function gui_LoadNuclei(varargin)
        NE.nuclei = get(guiNuclei, 'value');
        NE.N=NE.Nall{NE.nuclei};
        fprintf('File: %d, nuclei: %2d\n', NE.file, NE.nuclei);
        NE.N = NE.Nall{NE.nuclei};
        assignin('base', 'NE', NE)
        for kk = 1:numel(NE.M.channels)
            NE.N.dots{kk} = NE.N.dots{kk}(1:min(NE.maxDotsPerChannel, size(NE.N.dots{kk}, 1)), :);
            %NE.N.dots{kk} = NE.N.dots{kk}(NE.N.dots{kk}(:,4)>NE.M.threshold(kk)*NE.thresholdFactor, :);
        end
        % Create selection
        for kk = 1:numel(NE.M.channels)
            NE.dSelected{kk} = 1:min(NE.M.nTrueDots(kk)*3, size(NE.N.dots{kk},1));
        end
        NE.gCellLoaded = 0;
        NE.mipXY={};
        NE.mipXZ={};
        NE.mipYZ={};
        NE.R1 = {[],[],[], [],[]}; % Contains the selected regions/dots
        NE.R2 = {[],[],[], [],[]};
        NE.C1 = [];
        NE.C2 = [];
        NE.fig_c1objects = [];
        NE.fig_c2objects = [];
        
        % Propose first and last slice for the z-projection and update the
        % GUI
        z = 10^6;
        x = -1;
        for kk = 1:numel(NE.N.dots)
            z = min(z, min(NE.N.dots{kk}(:,3)));
            x = max(x, max(NE.N.dots{kk}(:,3)));
        end
        
        set(NE.zLastEdit, 'string', num2str(min(NE.M.imageSize(3), x+4)) );
        set(NE.zFirstEdit, 'string', num2str(max(1,z-4)));
        set(NE.zRange, 'string', sprintf('[1, %d]', NE.M.imageSize(3)));
        
        
        fprintf('done.\n');
    end

    function gui_changeD0NM(hObject, callbackdata)
        NE.d0nm =  str2num(get(hObject, 'String'));
        fprintf('d0nm: %d\n', NE.d0nm);
    end

    function NE_changeClusterChannel(varargin)
        NE.clusterChannel = get(NE.clusterChannelSelector, 'value');
        disp(['Cluster channel is now set to ' NE.M.channels(NE.clusterChannel)]);
    end

    function NE_FindClusters(varargin)
        fprintf('Finding clusters based on channel: %s\n', NE.M.channels{NE.clusterChannel});
        % populates NE.C1 and NE.C2  if they don't exist, otherwise nothing
        % Looks for the clusters with most dots, not necessarily the
        % strongest dots.
                
        dots = NE.N.dots{NE.clusterChannel}(:,1:3);
        
        dots = dots(NE.dSelected{NE.clusterChannel}, 1:3);
        dots0 = dots;
        
        % Scale to nm, required since the resolution is anisotropic
        dots(:,1:2)=NE.resolution(1)*dots(:,1:2);
        dots(:,3)=NE.resolution(3)*dots(:,3);
        
        C = cluster3ec(dots', NE.d0nm);
        H = histo16(uint16(C)); H = H(2:20);
        
        Hm1 = max(H(:));
        Hm1 = Hm1(1);
        if Hm1>0
            c1 = find(H==Hm1); c1=c1(1);
        else
            c1  = [];
        end
        Ht = H; Ht(c1)=0;
        Hm2 = max(Ht(:)); Hm2=Hm2(1);
        if Hm2 >0
            c2 = find(Ht==Hm2); c2 = c2(1);
        else
            c2 = [];
        end
        
        if numel(c1)>0
            C1 = dots0(C==c1,:);
        else
            C1 = [];
        end
        if numel(c2>0)
            C2 = dots0(C==c2,:);
        else
            C2 = [];
        end
        
        NE.C1 = C1;
        NE.C2 = C2;
    end

function NE_FindStrongest(varargin)
        fprintf('Finding clusters based on channel: %s\n', NE.M.channels{NE.clusterChannel});
        % populates NE.C1 and NE.C2  if they don't exist, otherwise nothing
        % Looks for the clusters with most dots, not necessarily the
        % strongest dots.
        
        
        dots = NE.N.dots{NE.clusterChannel}(:,1:3);
        
        dots = dots(NE.dSelected{NE.clusterChannel}, 1:3);
        dots0 = dots;
        
        % Scale to nm, required since the resolution is anisotropic
        dots(:,1:2)=NE.resolution(1)*dots(:,1:2);
        dots(:,3)=NE.resolution(3)*dots(:,3);
        
        C = cluster3ec(dots', NE.d0nm);
        % Find cluster with strongest dot
        
        
        C1 = dots0(C==1,:);               
        C2 = dots0(C==2,:);        
        
        NE.C1 = C1;
        if size(C1,1)>NE.M.nTrueDots(NE.clusterChannel)/2;
            C1 = C1(1:NE.M.nTrueDots(NE.clusterChannel)/2, :);
        end
        NE.C2 = C2;
        if size(C2,1)>NE.M.nTrueDots(NE.clusterChannel)/2;
            C2 = C2(1:NE.M.nTrueDots(NE.clusterChannel)/2, :);
        end
    end

    function NE_FindClusters101(varargin)
        % populates NE.C1 and NE.C2  if they don't exist, otherwise nothing
        dots = NE.N.dots{NE.clusterChannel}(:,1:3);
        
        C1 = dots(1,1:3);
        C2 = [];
        
        % C2 will be the next dot that is sufficiently far away from C1
        while(size(dots,1)>0)
            if eudist(C1.*NE.resolution, dots(1,1:3).*NE.resolution)>NE.d0nm
                C2 = dots(1,1:3);
                break;
            else
                dots = dots(2:end, :);
            end
        end
        
        NE.C1 = C1;
        NE.C2 = C2;
        
        %NE.M.nTrueDots = [1,0,1]*2;
    end

    function NE_FindClusters110(varargin)
        % populates NE.C1 and NE.C2  if they don't exist, otherwise nothing
        dots = NE.N.dots{NE.clusterChannel}(:,1:3);
        
        C1 = dots(1,1:3);
        C2 = [];
        
        % C2 will be the next dot that is sufficiently far away from C1
        while(size(dots,1)>0)
            if eudist(C1.*NE.resolution, dots(1,1:3).*NE.resolution)>NE.d0nm
                C2 = dots(1,1:3);
                break;
            else
                dots = dots(2:end, :);
            end
        end
        
        NE.C1 = C1;
        NE.C2 = C2;
        
        NE.M.nTrueDots = [1,1,0]*2;
    end

    function NE_FindClusters111(varargin)
        % populates NE.C1 and NE.C2  if they don't exist, otherwise nothing
        dots = NE.N.dots{NE.clusterChannel}(:,1:3);
        
        C1 = dots(1,1:3);
        C2 = [];
        
        % C2 will be the next dot that is sufficiently far away from C1
        while(size(dots,1)>0)
            if eudist(C1.*NE.resolution, dots(1,1:3).*NE.resolution)>NE.d0nm
                C2 = dots(1,1:3);
                break;
            else
                dots = dots(2:end, :);
            end
        end
        
        NE.C1 = C1;
        NE.C2 = C2;
        
        NE.M.nTrueDots = [1,1,1]*2;
    end


    function NE_AssociateToClusters(varargin)
        % Populate R1 and R2 based on NE.C1 and NE.C2
        NE.R1 = populateClusters(NE.C1, NE.N.dots, NE.d0nm, NE.M.nTrueDots/2, NE.resolution);
        NE.R2 = populateClusters(NE.C2, NE.N.dots, NE.d0nm, NE.M.nTrueDots/2, NE.resolution);
        assignin('base', 'NE', NE);
    end

    function NE_TrimClusters(varargin)
        % Remove all but the first dot in each cluster in channel 1 and 2
        if numel(NE.R1{1})>0
            NE.R1{1} = NE.R1{1}(1,:);
        end
        NE.R1{2} = [];
        if numel(NE.R1{3})>0
            NE.R1{3} = NE.R1{3}(1,:);
        end
        
        if numel(NE.R2{1})>0
            NE.R2{1} = NE.R2{1}(1,:);
        end
        NE.R2{2} = [];
        if numel(NE.R2{3})>0
            NE.R2{3} = NE.R2{3}(1,:);
        end
    end


    function NE_InitWindows(varargin)
        
        NE.zFirst = str2num(get(NE.zFirstEdit, 'string'));
        NE.zLast  = str2num(get(NE.zLastEdit, 'string'));
        
        NE.gCellLoaded = 0;
        
        NE.fig = figure('Position', [450, 200, 1200, 700]);
        
        x = sprintf('File: %d, Nuclei: %d R1:', NE.file, NE.nuclei);
        
        for kk = 1:numel(NE.M.channels)
            x = [x sprintf(' %d', size(NE.R1{kk}, 1))];
        end
        x = [x ' R2:'];
        for kk = 1:numel(NE.M.channels)
            x = [x sprintf(' %d', size(NE.R2{kk}, 1))];
        end
        
        set(NE.fig, 'Name', x);
        set(NE.fig, 'KeyPressFcn', @NE_keyPress);
        
        NE.gui_cLimA = uicontrol('Style', 'slider',...
            'Min',1,'Max',50,'Value',41,...
            'Position', [0 400 20 300],...
            'Callback', @gui_sliderClim);
        NE.gui_cLimB = uicontrol('Style', 'slider',...
            'Min',1,'Max',50,'Value',41,...
            'Position', [20 400 20 300],...
            'Callback', @gui_sliderClim);
        
        
        % Cluster/selection visualization
        % First cluster
        NE.fig_b1 = uicontrol('Style','pushbutton','String','C1',...
            'BackgroundColor', NE.clusterColors{1}, ...
            'Position',[0 350 40 30], ...
            'Callback', @gui_visC1);
        for kk = 1:numel(NE.M.channels)
            NE.fig_b1 = uicontrol( 'Style','pushbutton','String',NE.M.channels{kk},...
                'BackgroundColor', NE.clusterColors{1}, ...
                'Position',[0 350-30*kk 40 30], ...
                'Callback', @gui_visR1);
        end
        % Second cluster
        NE.fig_b1 = uicontrol('Style','pushbutton','String','C2',...
            'BackgroundColor', NE.clusterColors{2}, ...
            'Position',[45 350 40 30], ...
            'Callback', @gui_visC2);
        for kk = 1:numel(NE.M.channels)
            NE.fig_b1 = uicontrol( 'Style','pushbutton','String',NE.M.channels{kk},...
                'BackgroundColor', NE.clusterColors{2}, ...
                'Position',[45 350-30*kk 40 30], ...
                'Callback', @gui_visR2);
        end
        
        %% Views
        NE.fig_b2 = uicontrol('Style','pushbutton','String','XZ',...
            'Position',[30 30 30 30], ...
            'Callback', 'view([90,0]);');
        NE.fig_b1 = uicontrol('Style','pushbutton','String','XY',...
            'Position',[0 30 30 30], ...
            'Callback', 'view([0,90]);');
        NE.fig_b3 = uicontrol('Style','pushbutton','String','YZ',...
            'Position',[0 0 30 30], ...
            'Callback', 'view([0,00]);');
        NE.fig_b3 = uicontrol('Style','pushbutton','String','3D',...
            'Position',[30 0 30 30], ...
            'Callback', 'view(3);');
        
        %% Buttons for MIP images
        NE.gui_mipALL = uicontrol('Style','pushbutton','String','RGB',...
            'Position',[100 0 40 30], ...
            'Callback', @gui_ChangeMIP);
        for kk = 1:numel(NE.M.channels)
            uicontrol('Style','pushbutton','String',NE.M.channels{kk},...
                'Position',[100+40*kk 0 40 30], ...
                'Callback', @gui_ChangeMIP);
        end
        
        %% Buttons for dots
        uicontrol('Style','pushbutton','String','LBL',...
            'Position',[ 350 0 40 30], ...
            'Callback', @gui_switchLabels);
        for kk = 1:numel(NE.M.channels)
            NE.dbtn{kk} = uicontrol('Style','pushbutton','String',NE.M.channels{kk},...
                'Position',[350+kk*40 0 40 30], ...
                'Callback', @gui_ChangeDots);
        end
        
        % Display dots in NE.N.dots
        NE_update_dots
        
        % populates NE.imXY, NE.imXZ, NE.imYZ
        NE_update_graphics
        
        % controlled by NE.showClusterDots and NE.showClusterContours
        NE_show_clusters
        
        %% Adjust the viewport and add contours of the cells
        bbx = NE.N.bbx;
        axis([bbx(3)-1.5,bbx(4)+1.5,bbx(1)-1.5,bbx(2)+1.5]);
        grid on
        contour(NE.M.mask==NE.nuclei, [.5,.5], 'r')
        axis([bbx(3),bbx(4),bbx(1),bbx(2)]);
        view(3)
        %rotate3d('Enable', 'on', 'ButtonDownFilter', @r3dfilter, 'RotateStyle', 'box');
        
        x = colormap('bone');
        colormap(x(:, [1, 3, 2]))
        daspect([1,1,NE.resolution(1)/NE.resolution(3)])
        view([0,90])
        
        gui_ChangeMIP(NE.gui_mipALL);
        
    end

    function NE_keyPress(src, e)
        
        switch e.Key
            case 'a'
                for kk =1:numel(NE.dbtn)
                    gui_ChangeDots(NE.dbtn{kk});
                end
        end
    end



    function r = r3dfilter(obj, event_obj)
        obj
        if r == NE.fig_rdots1(1)
            r = 0;
        else
            r = 1;
        end
    end

    function NE_show_clusters(varargin)
        for kk = 1:numel(NE.M.channels)
            if numel(NE.R1{kk})>0
                NE.fig_rdots1(kk) = plot3(NE.R1{kk}(:,2), NE.R1{kk}(:,1), NE.R1{kk}(:,3), ...
                    'wo', 'MarkerFaceColor', NE.dotColors(kk), ...
                    'Visible', 'off', ...
                    'buttonDownFcn', @dotClickFcn);
            else
                NE.fig_rdots1(kk) = 0;
            end
        end
        
        for kk = 1:numel(NE.M.channels)
            if numel(NE.R2{kk})>0
                NE.fig_rdots2(kk) = plot3(NE.R2{kk}(:,2), NE.R2{kk}(:,1), NE.R2{kk}(:,3), ...
                    'wo', 'MarkerFaceColor', NE.dotColors(kk), ...
                    'Visible', 'off', ...
                    'buttonDownFcn', @dotClickFcn);
            else
                NE.fig_rdots2(kk) = 0;
            end
        end
        
        
        %cluster3e_show(dots0(:,[2,1,3]), C)
        [x,y,z]=sphere(10);
        r = 7.5;
        % First cluster, yellow
        if size(C1,1)>2
            for ss = 1:size(C1,1)
                NE.fig_c1objects(ss)=surf(r*x+C1(ss,2),r*y+C1(ss,1),r*z+C1(ss,3), 'EdgeColor', 'none', 'FaceColor', NE.clusterColors{1}, 'FaceAlpha', .1, ...
                    'Visible', 'off');
            end
            
        end
        % second cluster, margenta
        if size(C2,1)>2
            for ss = 1:size(C2,1)
                NE.fig_c2objects(ss)=surf(r*x+C2(ss,2),r*y+C2(ss,1),r*z+C2(ss,3), 'EdgeColor', 'none', 'FaceColor', NE.clusterColors{2}, 'FaceAlpha', .1, ...
                    'Visible', 'off');
            end
            
        end
    end


    function gui_visR1(hObject, varargin)
        for kk = 1:numel(NE.M.channels)
            if strcmp(get(hObject, 'String'), NE.M.channels{kk})
                if NE.fig_rdots1(kk)>0
                    if(strcmp(get(NE.fig_rdots1(kk), 'Visible'), 'on'))
                        set(NE.fig_rdots1(kk), 'Visible', 'off')
                    else
                        set(NE.fig_rdots1(kk), 'Visible', 'on')
                    end
                else
                    disp('No dot!')
                end
            end
        end
    end

    function gui_visR2(hObject, varargin)
        for kk = 1:numel(NE.M.channels)
            if strcmp(get(hObject, 'String'), NE.M.channels{kk})
                if NE.fig_rdots2(kk)>0
                    if(strcmp(get(NE.fig_rdots2(kk), 'Visible'), 'on'))
                        set(NE.fig_rdots2(kk), 'Visible', 'off')
                    else
                        set(NE.fig_rdots2(kk), 'Visible', 'on')
                    end
                else
                    disp('No dot!')
                end
            end
        end
    end



    function gui_visC1(varargin)
        for kk = 1:numel(NE.fig_c1objects)
            if(strcmp(get(NE.fig_c1objects(kk), 'Visible'), 'on'))
                set(NE.fig_c1objects(kk), 'Visible', 'off')
            else
                set(NE.fig_c1objects(kk), 'Visible', 'on')
            end
        end
    end

    function gui_visC2(varargin)
        for kk = 1:numel(NE.fig_c2objects)
            if(strcmp(get(NE.fig_c2objects(kk), 'Visible'), 'on'))
                set(NE.fig_c2objects(kk), 'Visible', 'off')
            else
                set(NE.fig_c2objects(kk), 'Visible', 'on')
            end
        end
    end


    function gui_ChangeMIP(hObject, callbackdata)
        %% Called when pressing a button to change graphics channel
        if strcmp(get(hObject, 'String'), 'RGB')
            disp('Only showing the first channels as Red, Green, Blue')
            %% Todo, use NE.cLimChannel to scale the channels
            if numel(NE.mipXY)==1
                NE.mipXY{2} = 0*NE.mipXY{1};
                NE.cLimChannel{2} = [0,2^16-1];
                
            end
            if numel(NE.mipXY)==2
                NE.mipXY{3} = 0*NE.mipXY{2};
                NE.cLimChannel{3} = [0,2^16-1];
            end
            
            x = cat(3,linStretch(NE.mipXY{1}, NE.cLimChannel{1}),...
                linStretch(NE.mipXY{2}, NE.cLimChannel{2}), ...
                linStretch(NE.mipXY{3}, NE.cLimChannel{3}));
            set(NE.fig_xy, 'CData', x);
            
            if numel(NE.mipXZ)==1
                NE.mipXZ{2} = 0*NE.mipXZ{1};
            end
            if numel(NE.mipXZ)==2
                NE.mipXZ{3} = 0*NE.mipXZ{2};
            end
            x = cat(3,linStretch(NE.mipXZ{1}, NE.cLimChannel{1}),...
                linStretch(NE.mipXZ{2}, NE.cLimChannel{2}), ...
                linStretch(NE.mipXZ{3}, NE.cLimChannel{3}));
            set(NE.fig_xz, 'CData', x);
            if numel(NE.mipYZ)==1
                NE.mipYZ{2} = 0*NE.mipYZ{1};
            end
            if numel(NE.mipYZ)==2
                NE.mipYZ{3} = 0*NE.mipYZ{2};
            end
            x = cat(3,linStretch(NE.mipYZ{1}, NE.cLimChannel{1}),...
                linStretch(NE.mipYZ{2}, NE.cLimChannel{2}), ...
                linStretch(NE.mipYZ{3}, NE.cLimChannel{3}));
            set(NE.fig_yz, 'CData', x);
        else
            NE.gChannel = get(hObject, 'String');
            for kk = 1:numel(NE.M.channels)
                if strcmp(get(hObject, 'String'), NE.M.channels{kk})
                    NE.gChannelNo = kk;
                end
            end
            NE.gChannel = NE.M.channels(NE.gChannelNo);
            
            set(NE.fig_xy, 'CData', NE.mipXY{NE.gChannelNo});
            set(NE.fig_xz, 'CData', NE.mipXZ{NE.gChannelNo});
            set(NE.fig_yz, 'CData', NE.mipYZ{NE.gChannelNo});
            
            gui_clim(NE.cLimChannel{NE.gChannelNo});
            %set(gca, 'clim', NE.cLimChannel{NE.gChannelNo})
        end
        
    end

    function gui_ChangeDots(hObject, callbackdata)
        %% Select dots to show
        
        % get the channel to display, since
        NE.dChannel = get(hObject, 'String');
        for kk = 1:numel(NE.M.channels)
            if strcmp(get(hObject, 'String'), NE.M.channels{kk})
                NE.dChannelNo = kk;
            end
        end
        
        if strcmp(get(NE.fig_dots{NE.dChannelNo}, 'Visible'), 'on')
            set(NE.fig_dots{NE.dChannelNo}, 'Visible', 'off');
            set(NE.fig_labels{NE.dChannelNo}, 'Visible', 'off');
        else
            set(NE.fig_dots{NE.dChannelNo}, 'Visible', 'on');
        end
    end

    function gui_switchLabels(hObject, callbackdata)
        %% Switch labels on/off
        if(strcmp(get(NE.fig_labels{NE.dChannelNo}, 'Visible'), 'on'))
            set(NE.fig_labels{NE.dChannelNo}, 'Visible', 'off')
        else
            set(NE.fig_labels{NE.dChannelNo}, 'Visible', 'on')
        end
    end

    function NE_C1plus(hObject, callbackdata)
        prompt = {'Enter channel number:','Enter dot number:'};
        dlg_title = 'Add to C1';
        num_lines = 1;
        def = {'1','1'};
        answer = inputdlg(prompt,dlg_title,num_lines,def);
        NE.C1 = [NE.C1 ; NE.N.dots{str2num(answer{1})}(str2num(answer{2}), 1:3)];
    end

    function NE_C2plus(hObject, callbackdata)
        prompt = {'Enter channel number:','Enter dot number:'};
        dlg_title = 'Add to C2';
        num_lines = 1;
        def = {'1','1'};
        answer = inputdlg(prompt,dlg_title,num_lines,def);
        NE.C2 = [NE.C2 ; NE.N.dots{str2num(answer{1})}(str2num(answer{2}), 1:3)];
    end

    function NE_R1plus(hObject, callbackdata)
        prompt = {'Enter channel number:','Enter dot number:'};
        dlg_title = 'Add to R1';
        num_lines = 1;
        def = {'1','1'};
        answer = inputdlg(prompt,dlg_title,num_lines,def);
        if numel(answer)==0
            NE_ShowR1
        else
            NE.R1{str2num(answer{1})} = [NE.R1{str2num(answer{1})} ; NE.N.dots{str2num(answer{1})}(str2num(answer{2}), 1:3)];
            NE.R1{str2num(answer{1})}
        end
    end

    function NE_R2plus(hObject, callbackdata)
        prompt = {'Enter channel number:','Enter dot number:'};
        dlg_title = 'Add to R2';
        num_lines = 1;
        def = {'1','1'};
        answer = inputdlg(prompt,dlg_title,num_lines,def);
        if numel(answer)==0
            NE_ShowR2
        else
            NE.R2{str2num(answer{1})} = [NE.R2{str2num(answer{1})} ; NE.N.dots{str2num(answer{1})}(str2num(answer{2}), 1:3)];
            NE.R2{str2num(answer{1})}
        end
    end

    function NE_R1minus(hObject, callbackdata)
        prompt = {'Enter channel number:','Enter dot number:'};
        dlg_title = 'Remove from R1';
        num_lines = 1;
        def = {'1','1'};
        answer = inputdlg(prompt,dlg_title,num_lines,def);
        if numel(answer)==0
            NE_ShowR1
        else
            if str2num(answer{2}) == 0
                NE.R1{str2num(answer{1})} = [];
            else
                x = NE.N.dots{str2num(answer{1})}(str2num(answer{2}), 1:3);
                ss = -1;
                for kk = 1:size(NE.R1{str2num(answer{1})})
                    if sum(x == NE.R1{str2num(answer{1})}(kk, 1:3))==3
                        ss = kk;
                    end
                end
                if ss == -1
                    disp('The dot was not found in R1')
                else
                    fprintf('Removing dot nr %d from R1\n', ss);
                    NE.R1{str2num(answer{1})} = [NE.R1{str2num(answer{1})}(1:ss-1, 1:3); ...
                        NE.R1{str2num(answer{1})}(ss+1:end, 1:3)];
                end
            end
            NE.R1{str2num(answer{1})}
        end
    end

    function NE_R2minus(hObject, callbackdata)
        prompt = {'Enter channel number:','Enter dot number:'};
        dlg_title = 'Remove from R2';
        num_lines = 1;
        def = {'1','1'};
        answer = inputdlg(prompt,dlg_title,num_lines,def);
        if numel(answer)==0
            NE_ShowR2
        else
            if str2num(answer{2}) == 0
                NE.R2{str2num(answer{1})} = [];
            else
                x = NE.N.dots{str2num(answer{1})}(str2num(answer{2}), 1:3);
                ss = -1;
                for kk = 1:size(NE.R2{str2num(answer{1})})
                    if sum(x == NE.R2{str2num(answer{1})}(kk, 1:3))==3
                        ss = kk;
                    end
                end
                if ss == -1
                    disp('The dot was not found in R2')
                else
                    fprintf('Removing dot nr %d from R2\n', ss);
                    NE.R2{str2num(answer{1})} = [NE.R2{str2num(answer{1})}(1:ss-1, 1:3); ...
                        NE.R2{str2num(answer{1})}(ss+1:end, 1:3)];
                end
            end
            NE.R2{str2num(answer{1})}
        end
    end

    function NE_update_dots()
        hold on
        
        for kk = 1:numel(NE.M.channels)
            NE.dots = NE.N.dots{kk}(:, 1:3); % Temporary
            NE.dots = NE.dots(1:min(size(NE.dots,1), NE.nDotsShow), 1:3);
            NE.fig_dots{kk} = plot3( NE.dots(:,2), ...
                NE.dots(:,1), ...
                NE.dots(:,3), NE.dotStyles{kk}, ...
                'MarkerSize', NE.dotSize(kk), ...
                'Visible', 'off', ...
                'ButtonDownFcn', @dotClickFcn);
            hold on
            labels = [];
            for ll =1:size(NE.dots,1)
                labels{ll}=num2str(ll);
            end
            
            if size(NE.dots, 1)>0
                NE.fig_labels{kk}=text(NE.dots(:,2)+2, NE.dots(:,1)+2, NE.dots(:,3)+2, labels, ...
                    'Color', NE.dotColors(kk), 'FontSize', 16, ...
                    'Visible', 'off');
            end
        end
        
    end

    function NE_ShowR1()
        disp('->NE.R1')
        for kk = 1:numel(NE.R1)
            fprintf('  Channel %d:\n', kk)
            disp(NE.R1{kk})
        end
    end

    function NE_ShowR2()
        disp('->NE.R2')
        for kk = 1:numel(NE.R2)
            fprintf('  Channel %d:\n', kk)
            disp(NE.R2{kk})
        end
    end

    function dotClickFcn(hObject, varargin)
        
        assignin('base', 'hObject', hObject)
        assignin('base', 'varargin', varargin)
        
        % Figure out what channel depending on which group of objects was
        % clicked
        
        NE.fig_dots(kk)
        for kk = 1:numel(NE.M.channels)
            if ismember(hObject, [NE.fig_dots{kk}, NE.fig_rdots1(kk), NE.fig_rdots2(kk)])
                x =kk;
            end
        end
        
        % Figure out dot number
        dots = NE.N.dots{x}; %(1:NE.nDotsShow, :);
        y = (dots(:,1)-varargin{1}.IntersectionPoint(2)).^2 + ...
            (dots(:,2)-varargin{1}.IntersectionPoint(1)).^2 + ...
            (dots(:,3)-varargin{1}.IntersectionPoint(3)).^2;
        y = find(y==min(y(:)));
        fprintf('You clicked: %d, %d\n', x, y)
        fprintf('To do: add dot options directly here\n');
        
        choice = listdlg('PromptString', sprintf('Dot #%d in channel %s?', y, NE.M.channels{x}), ...
            'SelectionMode', 'single', ...
            'ListString', {'Nothing', 'Add to R1', 'Add to R2', 'Remove from R1', 'Remove from R2'});
        
        % Handle response
        switch choice
            case 2
                NE.R1{x} = [NE.R1{x}; NE.N.dots{x}(y,1:3)];
            case 3
                NE.R2{x} = [NE.R2{x}; NE.N.dots{x}(y,1:3)];
            case 4
                z = (dots(y,1)-NE.R1{x}(:,1)).^2 + ...
                    (dots(y,2)-NE.R1{x}(:,2)).^2 + ...
                    (dots(y,3)-NE.R1{x}(:,3)).^2;
                y = find(z==0);
                NE.R1{x} = NE.R1{x}(setdiff(1:size(NE.R1{x},1), y), :);
            case 5
                z = (dots(y,1)-NE.R2{x}(:,1)).^2 + ...
                    (dots(y,2)-NE.R2{x}(:,2)).^2 + ...
                    (dots(y,3)-NE.R2{x}(:,3)).^2;
                y = find(z==0);
                NE.R2{x} = NE.R2{x}(setdiff(1:size(NE.R2{x},1), y), :);
        end
        
    end

    function NE_ExpTR1(hObject, callbackdata)
        exportClusterToTable(NE.R1, 1);
    end

    function NE_ExpTR2(hObject, callbackdata)
        exportClusterToTable(NE.R2, 2);
    end


    function exportClusterToTable(R, clusterNo)
        
        %% See if there is a file for correction of chromatic aberrations
        NE.ccFile = dir([NE.rfolder 'cc*.mat']);
        
        disp('Locating a cc_*.mat file for chromatic aberrations')
        if(numel(NE.ccFile)==0)
            warning('NO cc*.mat in %s -- will not correct for chromatic aberrations\n', rfolder);
            NE.ccFile = '';
        else
            NE.ccFile = [rfolder NE.ccFile(1).name];
        end
        
        
        x = [];
        dots = [];
        for kk = 1:numel(NE.M.channels)
            if numel(R{kk}>0)
                x = R{kk};
                % Fitting
                y = dotFitting(double(NE.iChannel{kk}), x, fittingSettings);
                y = d_stickyz(y, R{kk}, 1);
                % Correct for chromatic aberrations
                if exist(NE.ccFile, 'file')>0
                    z = cCorrI(y(:,1:3), NE.M.channels{kk}, NE.M.channels{2}, NE.ccFile);
                else
                    z = 0*x-1;
                end
                r = df_fwhm(double(NE.iChannel{kk}), y)*NE.resolution(1);
                dots = [dots; [repmat(NE.file, size(x,1), 1), repmat(NE.nuclei,size(x,1),1),  repmat(clusterNo, size(x,1), 1), ...
                    repmat(kk,size(x,1),1), z, y ,x], r, repmat(NE.N.dapisum, size(x,1), 1), repmat(NE.N.area, size(x,1), 1)];
            end
        end
        % Convert to a cell
        dots = num2cell(dots);
        for kk=1:size(dots,1)
            dots{kk,4} = NE.M.channels(dots{kk,4});
        end
        % Then to a table
        dots = cell2table(dots);
        % Then append variable names
        dots.Properties.VariableNames = {'File', 'Nuclei', 'Allele', 'Channel', 'CFx', 'CFy', 'CFz', 'F_x', 'F_y', 'F_z', 'Photons', 'FError', 'Sigma', 'Status', 'x', 'y', 'z', 'fwhm_nm', 'dapisum', 'dapiarea_px'}
        
        %% Write do disk
        exportFilename = sprintf('%sFile_%03d_Nuclei_%d_%d.csv', NE.rfolder, NE.file, NE.nuclei, clusterNo);
        writetable(dots, exportFilename);
        fprintf('Wrote data about %d dots to %s\n', size(dots,1), exportFilename);
    end


    function NE_ExpR1(hObject, callbackdata)
        for kk = 1:numel(NE.M.channels)
            if numel(NE.R1{kk}>0)
                x = datestr(now);
                exportFilename = sprintf('%sr_%d_%d_%s_A_%s.cvs', NE.wfolder, NE.file, NE.nuclei, NE.M.channels{kk}, x);
                fprintf('Exporting R1 to %s\n', exportFilename)
                dots = dotFitting(double(NE.iChannel{kk}), NE.R1{kk}, fittingSettings);
                dots = d_stickyz(dots, NE.R1{kk}, 1);
                csvwrite(exportFilename, NE.R1{kk})
                exportFilename = sprintf('%s%d_%d_%s_A_%s.cvs', NE.wfolder, NE.file, NE.nuclei, NE.M.channels{kk}, x);
                csvwrite([exportFilename], dots)
            else
                disp('No dots in channel')
            end
        end
        disp('Done')
    end
    function NE_ExpR2(hObject, callbackdata)
        for kk = 1:numel(NE.M.channels)
            if numel(NE.R2{kk}>0)
                x = datestr(now);
                exportFilename = sprintf('%sr_%d_%d_%s_B_%s.cvs', NE.wfolder, NE.file, NE.nuclei, NE.M.channels{kk}, x);
                fprintf('Exporting R2 to %s\n', exportFilename)
                dots = dotFitting(double(NE.iChannel{kk}), NE.R2{kk}, fittingSettings);
                dots = d_stickyz(dots, NE.R2{kk}, 1);
                csvwrite(exportFilename, NE.R2{kk})
                exportFilename = sprintf('%s%d_%d_%s_B_%s.cvs', NE.wfolder, NE.file, NE.nuclei, NE.M.channels{kk}, x);
                csvwrite([exportFilename], dots)
            else
                disp('No dots in channel')
            end
        end
        disp('Done')
    end

    function NE_LoadCR(hObject, callbackdata)
        x = sprintf('%s_%03d_%03d.NE', NE.wfolder, NE.file, NE.nuclei);
        if exist(x, 'file')
            y = load(x, '-mat');
            NE.C1 = y.C1;
            NE.C2 = y.C2;
            NE.R1 = y.R1;
            NE.R2 = y.R2;
        else
            disp('No saved state')
        end
    end

    function NE_SaveCR(hObject, callbackdata)
        x = sprintf('%s_%03d_%03d.NE', NE.wfolder, NE.file, NE.nuclei);
        save(x,  '-struct', 'NE', 'R1', 'R2', 'C1', 'C2', '-mat');
    end
    function gui_clim(x)
        NE.cLimChannel{NE.gChannelNo} = x
        set(NE.gui_cLimA, 'Value', x(1));
        set(NE.gui_cLimB, 'Value', x(2));
        set(gca, 'CLim', NE.cLimChannel{NE.gChannelNo});
    end

    function gui_sliderClim(hObject, callbackdata)
        NE.cLimChannel{NE.gChannelNo}=[get(NE.gui_cLimA, 'Value'), get(NE.gui_cLimB, 'Value')];
        set(gca, 'CLim', NE.cLimChannel{NE.gChannelNo});
    end

    function NE_update_graphics()
        bbx=NE.N.bbx;
        for kk = 1:numel(NE.M.channels)
            if ~NE.gFileLoaded
                fprintf('Loading channel %s ... ', NE.M.channels{kk});
                % Figure out the name of the dapi channel until it is
                % stored in the meta data
                x = strsplit(NE.M.dapifile, '/');
                x = x{end};
                x = x(1:end-8);
                NE.iChannel{kk} = df_readTif(strrep(strrep(NE.M.dapifile, x, NE.M.channels{kk}), 'erikw', getenv('USER')));
                if NE.LP
                    NE.iChannel{kk} = NE.iChannel{kk} - uint16(gsmooth(NE.iChannel{kk}, NE.LP_Sigma));
                end
                if NE.deconv == 1
                    NE.iChannel{kk} = uint16(deconvW3(double(NE.iChannel{kk}), NE.M.PSF, 0.005)/10);
                end
            end
            %NE.mipXY{kk} = max(NE.iChannel{kk}, [], 3);
            if ~NE.gCellLoaded
                disp(['Loading channel' num2str(kk)])
                NE.gMinMax{kk} = [min(min(min(NE.iChannel{kk}(bbx(1):bbx(2), bbx(3):bbx(4),:)))), ...
                    max(max(max(NE.iChannel{kk}(bbx(1):bbx(2), bbx(3):bbx(4),:))))];
                NE.mipXY{kk} =         max(NE.iChannel{kk}(bbx(1):bbx(2), bbx(3):bbx(4),NE.zFirst:NE.zLast), [], 3);
                NE.mipXZ{kk} = squeeze(max(NE.iChannel{kk}(bbx(1):bbx(2), bbx(3):bbx(4),:), [], 1));
                NE.mipYZ{kk} = squeeze(max(NE.iChannel{kk}(bbx(1):bbx(2), bbx(3):bbx(4),:), [], 2));
                %NE.cLimChannel{kk} = quantile16(NE.iChannel{kk}(bbx(1):bbx(2), bbx(3):bbx(4),:), [0.001, 0.999])
                if numel(NE.cLimChannel{kk})==0
                    NE.cLimChannel{kk} = quantile16(NE.iChannel{kk}(bbx(1):bbx(2), bbx(3):bbx(4),:), [0.00000000001, 1]); % min-max
                end
                isSaturated(NE.iChannel{kk}(bbx(1):bbx(2), bbx(3):bbx(4),:));
            end
            fprintf('done.\n')
        end
        NE.gFileLoaded = 1;
        NE.gCellLoaded = 1;
        NE
        if 0
            if numel(NE.M.channels)==3
                NE.mipXY{4}=cat(3, nrm(NE.mipXY{1}, NE.cLimChannel{1}), nrm(NE.mipXY{2}, NE.cLimChannel{2}), nrm(NE.mipXY{3}, NE.cLimChannel{3}));
                NE.mipXZ{4}=cat(3, nrm(NE.mipXZ{1}, NE.cLimChannel{1}), nrm(NE.mipXZ{2}, NE.cLimChannel{2}), nrm(NE.mipXZ{3}, NE.cLimChannel{3}));
                NE.mipYZ{4}=cat(3, nrm(NE.mipYZ{1}, NE.cLimChannel{1}), nrm(NE.mipYZ{2}, NE.cLimChannel{2}), nrm(NE.mipYZ{3}, NE.cLimChannel{3}));
            end
            
            if numel(NE.M.channels)==2
                NE.mipXY{4}=cat(3, nrm(NE.mipXY{1}, NE.cLimChannel{1}), nrm(NE.mipXY{2}, NE.cLimChannel{2}), zeros(size(NE.mipXY{2})));
                NE.mipXZ{4}=cat(3, nrm(NE.mipXZ{1}, NE.cLimChannel{1}), nrm(NE.mipXZ{2}, NE.cLimChannel{2}), zeros(size(NE.mipXZ{2})));
                NE.mipYZ{4}=cat(3, nrm(NE.mipYZ{1}, NE.cLimChannel{1}), nrm(NE.mipYZ{2}, NE.cLimChannel{2}), zeros(size(NE.mipYZ{2})));
            end
        end
        %NE.gIDLoaded = 1;
        hold on
        %NE.fig_xy = imagesc(NE.mipXY{NE.gChannelNo});
        NE.fig_xy = surface('XData',[bbx(3)-.5 bbx(4)+.5; bbx(3)-.5 bbx(4)+.5], ...
            'YData',[bbx(1)-.5 bbx(1)-.5; bbx(2)+.5 bbx(2)+.5],...
            'ZData',[1 1;1 1]-1,'CData',NE.mipXY{NE.gChannelNo},...
            'FaceColor','texturemap','EdgeColor','none');
        
        NE.fig_xz = surface('XData',[bbx(3)-.5 bbx(3)-.5; bbx(4)+.5 bbx(4)+.5], ...
            'YData',[bbx(2) bbx(2); bbx(2) bbx(2)],...
            'ZData',[.5 size(NE.iChannel{1},3)+.5; .5 size(NE.iChannel{1},3)+.5],'CData',NE.mipXZ{NE.gChannelNo},...
            'FaceColor','texturemap','EdgeColor','none');
        
        NE.fig_yz = surface('XData',[bbx(3) bbx(3); bbx(3) bbx(3)], ...
            'YData',[bbx(1)-.5 bbx(1)-.5; bbx(2)+.5 bbx(2)+.5],...
            'ZData',[.5 size(NE.iChannel{1},3)+.5; .5 size(NE.iChannel{1},3)+.5],'CData',NE.mipYZ{NE.gChannelNo},...
            'FaceColor','texturemap','EdgeColor','none');
        
        set(NE.gui_cLimA, 'Min', 0); %NE.gMinMax{NE.gChannelNo}(1));
        %set(NE.gui_cLimA, 'Max', NE.gMinMax{NE.gChannelNo}(2));
        set(NE.gui_cLimA, 'Max', 1.1*2^16);
        set(NE.gui_cLimB, 'Min', 0); %NE.gMinMax{NE.gChannelNo}(1));
        %set(NE.gui_cLimB, 'Max', NE.gMinMax{NE.gChannelNo}(2));
        set(NE.gui_cLimB, 'Max', 1.1*2^16);
        
        disp('mm')
        
        %set(gca, 'clim', NE.cLimChannel{NE.gChannelNo})
        gui_clim(NE.cLimChannel{NE.gChannelNo});
    end

    function isSaturated(V)
        t = sum(V(:)==2^16-1);
        if(t>0)
            fprintf('%d saturated pixels\n', t);
        end
    end

end
