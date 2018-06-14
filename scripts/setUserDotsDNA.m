function setUserDotsDNA(folder)
%% function setUserDotsDNA(folder)
%
% Purpose:
% --------
%  GUI for selection of
%  userDots : dots for further processing/analysis
%  userDotsLabels : 0, 1 or 2 depending on the homolog
%
% Input:
%  a _calc folder
%
% Output:
%  the .NM files in the _calc folder are updated, no new files are produced
%
% Keyboard shortcuts - Movement:
%  uparrow: previous channel
%  downarrow: next channel
%  rightarrow: next nuclei
%  leftarrow: previous nuclei
%
% Keyboard shortcuts - Dot and clustering:
%  c: clustering. Using k-means and randomized initialization,
%     try multiple times for different solutions
%  0: set all userDots to label 0 for the current nuclei
%  backspace: clear all userDots for the current nuclei
%  space: bring back all dots above the threshold for the current nuclei
%  v: 3-D plot of dots in current nuclei
%
% Mouse usage:
%  click and drag up and down to change slice (z)
%
% Hints:
% - Start by setting the thresholds right, that will save a lot of time
% - userDots are saved only when switching between fields, or when the
%   'quit and save' button is pressed.
% - To leave without saving, press <esc>
%

s.maxFiles = inf;

if nargin == 0
    folder = df_getConfig('DOTTER', 'testCalcFolder', '');
    if numel(folder) == 0
        warning('no testCalcFolder set');
        return
    end
    folder = '/data/current_images/iJC/iJC829_20170918_001_calc/';
    %folder = '/data/current_images/iXL/iXL213_20171005_00X_calc/';
    %folder = '/data/current_images/iEG/iEG410_170925_004_calc/';
    s.maxFiles = 2;
end

close all

gui = [];
s.updateAll = 1; % Indicate that all graphic components should be redrawn
s.updateMarkerTable = 1;

if ~strcmp(folder(end), '/')
    folder = [folder '/'];
end

s.folder = folder;
s.files = dir([folder '*.NM']);
if numel(s.files)==0
    fprintf('no .NM files to load in %s\n', folder);
    return
end

if numel(s.files)>s.maxFiles
    warning('Not loading all files');
    s.files = s.files(1:min(numel(s.files),s.maxFiles));
    whos s
end

% There are some bugs in previous versions of DOTTER that prevents this
% script from working as it should. Detect those scenarios

okFiles = df_validateNM(s.folder, s.files);

s.files = s.files(okFiles==1);

if numel(s.files) == 0
    warning('No valid files to load')
    return
end

% Set up global variables
win.w = 500;
win.h = 600;

ctrl = [];
ctrl.histogram = false;
N = []; % Nuclei
M = []; % Meta

% Dots for the current channel
anno = []; % annotations, nuclei number
DH = {}; % Handles to the plotted dots, 1=xtra dots, 2=label 0, 3=label 1, ...

D0n = []; % Dots for active nuclei
D1n = [];
C_MAX = {}; C_SUM = {}; C={};
ctr = []; % Points to the contour
xctr = []; % Points to dilated contour
img = []; % Points to the image of fig_image

s.dilationRadius = []; % pixels
s.activeColor = [0,0,1];
s.fieldNo = 1;
s.nFields = numel(s.files);

s.slice = 0;
s.sumProjection = 0;
s.maxProjection = 1;
s.dapiValue = 10^99;
%s.showDots = 'on';
s.nxshow = 3;

s.dots.maxDots = [];
s.dots.Z = [];
s.dots.fwhm = [];

s.captureRadius = 5;   % When clicking the images, how far away are dots captured

% Background dots
s.dotMarkers{1}.shape = 'x';
s.dotMarkers{1}.color = 'c';
s.dotMarkers{1}.size = 2;
s.dotMarkers{1}.name = 'background dots';
s.dotMarkers{1}.visible = 'on';

% Label 0
s.dotMarkers{2}.shape = 's';
s.dotMarkers{2}.color = 'c';
s.dotMarkers{2}.size = 10;
s.dotMarkers{2}.name = 'Label 0';
s.dotMarkers{2}.visible = 'on';

% Label 1
s.dotMarkers{3}.shape = 'o';
s.dotMarkers{3}.color = 'r';
s.dotMarkers{3}.size = 10;
s.dotMarkers{3}.name = 'Label 1';
s.dotMarkers{3}.visible = 'on';

% Label 2
s.dotMarkers{4}.shape = 'd';
s.dotMarkers{4}.color = 'b';
s.dotMarkers{4}.size = 10;
s.dotMarkers{4}.name = 'Label 2';
s.dotMarkers{4}.visible = 'on';

% Label 3
s.dotMarkers{5}.shape = 's';
s.dotMarkers{5}.color = 'g';
s.dotMarkers{5}.size = 10;
s.dotMarkers{5}.name = 'Label 3';
s.dotMarkers{5}.visible = 'on';

% Label 4
s.dotMarkers{6}.shape = 'p';
s.dotMarkers{6}.color = 'm';
s.dotMarkers{6}.size = 10;
s.dotMarkers{6}.name = 'Label 4';
s.dotMarkers{6}.visible = 'on';

% Label 5
s.dotMarkers{7}.shape = 'h';
s.dotMarkers{7}.color = 'r';
s.dotMarkers{7}.size = 10;
s.dotMarkers{7}.name = 'Label 5';
s.dotMarkers{7}.visible = 'on';

% Label 6
s.dotMarkers{8}.shape = '<';
s.dotMarkers{8}.color = 'b';
s.dotMarkers{8}.size = 10;
s.dotMarkers{8}.name = 'Label 6';
s.dotMarkers{8}.visible = 'on';

% Label 7
s.dotMarkers{9}.shape = '>';
s.dotMarkers{9}.color = 'r';
s.dotMarkers{9}.size = 10;
s.dotMarkers{9}.name = 'Label 7';
s.dotMarkers{9}.visible = 'on';

% Label 8
s.dotMarkers{10}.shape = 's';
s.dotMarkers{10}.color = 'r';
s.dotMarkers{10}.size = 10;
s.dotMarkers{10}.name = 'Label 8';
s.dotMarkers{10}.visible = 'on';


verbose = 1;
%
init_fig_menu();

% This resets some of the options above
gui_loadField(s.files(s.fieldNo).name);

% Set up the figure for the image data and annotations
fig_image = figure('KeyPressFcn', @gui_keyPress, ...
    'WindowButtonDownFcn', @fig_startMove, ...
    'WindowButtonUpFcn', @fig_endMove, ...
    'Name', 'setUserDotsDNA - viewer', ...
    'Position', [win.h, 0, 600, 600]);

gui.plotInfo = uicontrol('Style', 'Text', ...
    'Units', 'Normalized', ...
    'Position', [0,0,1, .05], ...
    'String', 'Info goes here', ...
    'Background', 'w', ...
    'HorizontalAlignment', 'left');

tightPos=get(gca,'TightInset');
noDeadSpacePos = [0 0 1 1] + 3*[tightPos(1:2) -(tightPos(1:2) + ...
    tightPos(3:4))];
set(gca,'Position',noDeadSpacePos);

a = findall(gcf);
b = findall(a,'ToolTipString','Link Plot');
set(b,'Visible','Off');

[icon,~] = imread(fullfile(matlabroot,...
    'toolbox','matlab','icons','plottype-gscatter.png'));
% Convert image from indexed to truecolor

[img,map] = imread(fullfile(matlabroot,...
    'toolbox','matlab','icons','plottype-scatter3.gif'));
% Convert image from indexed to truecolor
icon = ind2rgb(img, map);
p = uipushtool('TooltipString','3D view',...
    'ClickedCallback', @gui_visNuclei, ...
    'Separator', 'on');
% Set the button icon
p.CData = icon;

[icon] = imread(fullfile(matlabroot,...
    'toolbox','matlab','icons','tool_shape_ellipse.png'));
% Convert image from indexed to truecolor
p = uipushtool('TooltipString','Show/Hide dots',...
    'ClickedCallback', @gui_toggleDots, ...
    'Separator', 'on');
% Set the button icon

p.CData = double(icon)/2^16;

fig_image_xstart = []; % For moving in the stack

setUserDotsDNA_clustering('tab', tabCluster, 'channels', M.channels, 'fun', @gui_clustering);

fig_slider = [];
gui_update();

disp('Waiting for interactions (mainloop)');
figure(fig_menu)
fig_menu.DeleteFcn = @fig_menu_delete;

uiwait();
fig_menu_delete()

    function fig_menu_delete(varargin)
        % Cleanup function called when the menu window is closed
        
        if isvalid(fig_menu)
            fig_menu.DeleteFcn = []; % avoid recursive calls
            close(fig_menu)
        end
        
        if isvalid(fig_image)
            close(fig_image)
        end
        
        try
            close(fig_slider)
        catch
            disp('No fig_slider to close');
        end
        disp('Done');
    end

    function init_fig_menu()
        disp('Starting GUI ...');
        fig_menu = figure('Position', [0,0,win.w,win.h], 'Menubar', 'none', ...
            'NumberTitle','off', ...
            'Name', 'setUserDotsDNA', ...
            'KeyPressFcn', @gui_keyPress);
        %             'Resize', 'off',...
        
        tabg = uitabgroup(fig_menu,'Position',[0 0 1 1]); %, 'SelectionChangedFcn', @readsettings);
        tabSel = uitab(tabg, 'Title', 'Dots');
        tabView = uitab(tabg, 'Title', 'View');
        tabCluster = uitab(tabg, 'Title', 'Clustering');
        
        tabMore = uitab(tabg, 'Title', 'Markers');
        
        gui.infoPanel = uipanel('Position', [0, .7, 1, .3], 'Title', '', ...
            'Parent', tabSel);
        gui.toolsPanel =   uipanel('Position', [0, .15,  1, .35], 'Title', 'Tools', ...
            'Parent', tabSel);
        gui.Zpanel =   uipanel('Position', [0, .5,  1, .20], 'Title', 'Z limits', ...
            'Parent', tabSel);
        
        gui.viewPanel = uipanel('Position', [0, .2,  1, .65], 'Title', 'View', ...
            'Parent', tabView);
        gui.ctrlPanel =  uipanel('Position', [0, .0,  1, .1], 'Title', '', ...
            'Parent', tabView);
        
        ctrl.info = uicontrol('Style', 'edit', ...
            'String', 'ctrl.info', ...,
            'Units', 'Normalized', ...
            'Position', [0, 0, 1, 1], ...
            'HorizontalAlignment','left', ...
            'FontName', get(groot,'FixedWidthFontName'), ...
            'BackgroundColor', 'White', ...
            'Parent', gui.infoPanel, ...
            'Visible', 'on', ...
            'min',0,'max',10,...
            'enable','inactive');
        
        ctrl.table = uitable(...
            'Units', 'Normalized', ...
            'Position', [0,0,1,1], ...
            'Parent', gui.infoPanel, ...
            'Visible', 'off');
        
        ctrl.table.ColumnName = {'Channel', 'Dots/Nuclei', 'Threshold', 'MaxDots', 'minFWHM', 'maxFWHM', 'Dilation'};
        ctrl.table.ColumnEditable = [false,false,true, true, true, true, true];
        
        %'BackgroundColor', 'white', ...
        
        %% Thresholds
        
        ctrl.applyPan = uipanel(...
            'Title', 'Apply to', ...
            'Units', 'Normalized', ...
            'Position', [.0, .0, 1, .15], ...
            'Parent', tabSel);
        
        ctrl.threshold = uicontrol('Style', 'pushbutton', ...
            'String', 'This field', ...
            'Units', 'Normalized', ...
            'Position', [.5, .01, .5, .5], ...
            'Callback', @gui_detectDots, ... % @gui_setThresholds
            'Parent', ctrl.applyPan);
        
        ctrl.threshold = uicontrol('Style', 'pushbutton', ...
            'String', 'All fields', ...
            'Units', 'Normalized', ...
            'Position', [0, .01, .5, .5], ...
            'Callback', @gui_detectDotsAllFiles, ... % @gui_setThresholds
            'Enable', 'on', ...
            'Parent', ctrl.applyPan);
        
        uicontrol('Style', 'text', ...
            'String', 'Warning: this will reset all userDots', ...
            'Units', 'Normalized', ...
            'Position', [0, .51, 1, .4], ...
            'ForegroundColor', 'r', ...
            'Parent', ctrl.applyPan);
        
        uicontrol('Style', 'pushbutton', ...
            'String', 'plot thresholds', ...
            'Units', 'Normalized', ...
            'Position', [0,.6,.5,.2], ...
            'Callback', @plotTH,...
            'Parent', gui.toolsPanel);
        
        uicontrol('Style', 'pushbutton', ...
            'String', 'plot fwhm', ...
            'Units', 'Normalized', ...
            'Position', [0,.4,.5,.2], ...
            'Callback', @plotFWHM,...
            'Parent', gui.toolsPanel);
        
        if 0
        ctrl.threshold = uicontrol('Style', 'pushbutton', ...
            'String', 'reset thresholds', ...
            'Units', 'Normalized', ...
            'Position', [.5, .2, .5, .2], ...
            'Callback', @gui_resetThresholds,...
            'ForegroundColor', [1,0,0], ...
            'Parent', gui.toolsPanel);
        end
        
        uicontrol('Style', 'pushbutton', ...
            'String', 'Dots per nuclei', ...
            'Units', 'Normalized', ...
            'Position', [.0, .2, .5, .2], ...
            'Callback', @plotDotsPerNuclei,...
            'Parent', gui.toolsPanel);
        
        ctrl.threshold = uicontrol('Style', 'pushbutton', ...
            'String', 'visual thresholds', ...
            'Units', 'Normalized', ...
            'Position', [0, 0, .5, .2], ...
            'Callback', @gui_thresholdAid,...
            'Parent', gui.toolsPanel);
        %ctrl.threshold = uicontrol('Style', 'pushbutton', ...
        %    'String', 'ImageM', 'Position', [290,10,60,40], ...
        %    'Callback', @gui_thresholdImageM,...
        %    'Parent', gui.thPanel);
        
        
        
        %% Dot Z gui.Zpanel
        uicontrol('Style', 'text', ...
            'String', 'From', ...
            'Units', 'Normalized', ...
            'Position', [.5,.6,.25,.3], ...
            'Parent', gui.Zpanel);
        
        uicontrol('Style', 'text', ...
            'String', 'To', ...
            'Units', 'Normalized', ...
            'Position', [.75,.6,.25,.3], ...
            'Parent', gui.Zpanel);
        
        ctrl.viewDotZ = uicontrol('Style', 'pushbutton', ...
            'String', 'plot', ...
            'Units', 'Normalized', ...
            'Position', [0,.3,.25,.3], ...
            'Callback', @plotUDZ,...
            'Parent', gui.Zpanel);
        ctrl.dotZfrom = uicontrol('Style', 'edit', ...
            'String', '0', ...
            'Units', 'Normalized', ...
            'Position', [.5,.3,.25,.3], ...
            'Parent', gui.Zpanel);
        ctrl.dotZto = uicontrol('Style', 'edit', ...
            'String', 'N', ...
            'Units', 'Normalized', ...
            'Position', [.75,.3,.25,.3], ...
            'Parent', gui.Zpanel);
        
        % N extra
        uicontrol('Style', 'text', ...
            'String', '# Extra dots', 'Position', [10,260,150,40], ...
            'HorizontalAlignment','left',...
            'Parent', gui.viewPanel);
        ctrl.nExtra = uicontrol('Style', 'edit', ...
            'String', '>', 'Position', [190,260,80,40], ...
            'Parent', gui.viewPanel);
        uicontrol('Style', 'pushbutton', ...
            'String', 'apply', 'Position', [280,260,80,40], ...
            'Callback', @gui_change_nExtra, ...
            'Parent', gui.viewPanel);
        
        % Z Slice
        ctrl.viewSliceZ = uicontrol('Style', 'pushbutton', ...
            'String', 'view Z-slices', ...
            'Position', [10,210,150,40], ...
            'Callback', @plotSliceZ,...
            'Parent', gui.viewPanel);
        ctrl.sliceZfrom = uicontrol('Style', 'edit', ...
            'String', '0', ...
            'Position', [190,210,40,40], ...
            'Parent', gui.viewPanel);
        ctrl.sliceZto = uicontrol('Style', 'edit', ...
            'String', 'N', ...
            'Position', [230,210,40,40], ...
            'Parent', gui.viewPanel);
        ctrl.Zset = uicontrol('Style', 'pushbutton', ...
            'String', 'Set', ...
            'Position', [280,210,50,40], ...
            'Callback', @setSliceZ,...
            'Parent', gui.viewPanel);
        
        ctrl.slicePrevious = uicontrol('Style', 'pushbutton', ...
            'String', '<', 'Position', [190,160,40,40], ...
            'Callback', @gui_previousSlice,...
            'Parent', gui.viewPanel);
        ctrl.slice = uicontrol('Style', 'text', ...
            'String', 'Slice', 'Position', [10,160,150,40], ...
            'HorizontalAlignment','left',...
            'Parent', gui.viewPanel);
        ctrl.sliceNext = uicontrol('Style', 'pushbutton', ...
            'String', '>', 'Position', [230,160,40,40], ...
            'Callback', @gui_nextSlice,...
            'Parent', gui.viewPanel);
        ctrl.sumProjection = uicontrol('Style', 'checkbox', ...
            'String', 'SUM', 'value', s.sumProjection, 'Position', [280,160,100,40], ...
            'Callback', @gui_changeProjection,...
            'Parent', gui.viewPanel);
        ctrl.maxProjection = uicontrol('Style', 'checkbox', ...
            'String', 'MAX', 'value', s.maxProjection, 'Position', [330,160,100,40], ...
            'Callback', @gui_changeProjection,...
            'Parent', gui.viewPanel);
        
        % Nuclei
        ctrl.nucPrevious = uicontrol('Style', 'pushbutton', ...
            'String', '<', 'Position', [190,110,40,40], ...
            'Callback', @gui_previousNuclei,...
            'Parent', gui.viewPanel);
        ctrl.nuc = uicontrol('Style', 'text', ...
            'String', 'Nuclei', 'Position', [10,110,150,40], ...
            'HorizontalAlignment','left',...
            'Parent', gui.viewPanel);
        ctrl.nucJmp = uicontrol('Style', 'pushbutton', ...
            'String', '#', 'Position', [230,110,40,40], ...
            'Callback', @gui_nucJump,...
            'Parent', gui.viewPanel);
        ctrl.nucNext = uicontrol('Style', 'pushbutton', ...
            'String', '>', 'Position', [270,110,40,40], ...
            'Callback', @gui_nextNuclei,...
            'Parent', gui.viewPanel);
        
        %ctrl.setDapiValue = uicontrol('Style', 'pushbutton', ...
        %    'String', 'DAPI TH', 'Position', [300, 110. 80, 40], ...
        %    'Callback', @gui_setDapiValue, ...
        %    'Parent', gui.viewPanel);
        
        % Channel
        ctrl.channelPrevious = uicontrol('Style', 'pushbutton', ...
            'String', '<', 'Position', [190,60,40,40], ...
            'Callback', @gui_previousChannel,...
            'Parent', gui.viewPanel);
        ctrl.channel = uicontrol('Style', 'text', ...
            'String', 'Channel', 'Position', [10,60,150,40], ...
            'HorizontalAlignment','left',...
            'Parent', gui.viewPanel);
        ctrl.channelNext = uicontrol('Style', 'pushbutton', ...
            'String', '>', 'Position', [230,60,40,40], ...
            'Callback', @gui_nextChannel,...
            'Parent', gui.viewPanel);
        
        % Field
        ctrl.fieldPrevious = uicontrol('Style', 'pushbutton', ...
            'String', '<', 'Position', [190,10,40,40], ...
            'Callback', @gui_previousField,...
            'Parent', gui.viewPanel);
        ctrl.field = uicontrol('Style', 'text', ...
            'String', 'Field', 'Position', [10,10,150,40], ...
            'HorizontalAlignment','left',...
            'Parent', gui.viewPanel);
        ctrl.fieldJump = uicontrol('Style', 'pushbutton', ...
            'String', '#', 'Position', [230,10,40,40], ...
            'Callback', @gui_fieldJump,...
            'Parent', gui.viewPanel);
        ctrl.fieldNext = uicontrol('Style', 'pushbutton', ...
            'String', '>', 'Position', [270,10,40,40], ...
            'Callback', @gui_nextField,...
            'Parent', gui.viewPanel);
        
        
        % File operations
        %ctrl.save = uicontrol('Style', 'pushbutton', ...
        %    'String', 'Save', 'Position', [30,50,60,40], ...
        %    'Callback', @gui_save);
        
        ctrl.help = uicontrol('Style', 'pushbutton', ...
            'String', 'Help', ...
            'Units', 'Normalized', ...
            'Position', [.4, 0, .2, 1], ...
            'Callback', @gui_help,...
            'Parent', gui.ctrlPanel);
        
        ctrl.quit = uicontrol('Style', 'pushbutton', ...
            'String', 'Save and Quit', ...
            'Units', 'Normalized', ...
            'Position', [.7, 0,.3,1], ...
            'Callback', @gui_quit,...
            'Parent', gui.ctrlPanel);
        
        ctrl.quit = uicontrol('Style', 'pushbutton', ...
            'String', 'DBG', ...
            'Units', 'Normalized', ...
            'Position', [0,0,.2,1], ...
            'Callback', @gui_debug,...
            'Parent', gui.ctrlPanel);
        
        ctrl.markerTable = uitable(...
            'Units', 'Normalized', ...
            'Position', [0,.5,1,.5], ...
            'Parent', tabMore, ...
            'Visible', 'on');
        
        ctrl.markerPlot = subplot(...
            'Position', [0,0,.5,.5], ...
            'Parent', tabMore, ...
            'Visible', 'on');
        
        uicontrol('Style', 'pushbutton', ...
            'String', 'Try', ...
            'Units', 'Normalized', ...
            'Position', [.8,.1,.2,.1], ...
            'Callback', @markerDemo,...
            'Parent', tabMore);
        
        uicontrol('Style', 'pushbutton', ...
            'String', 'Accept', ...
            'Units', 'Normalized', ...
            'Position', [.8,.0,.2,.1], ...
            'Callback', @setMarkers,...
            'Parent', tabMore);
        
        updateMarkerTable();
        
        markerDemo();
        
    end

    function updateMarkerTable(varargin)
        % Update the table with markers and their visual properties
        
        ctrl.markerTable.ColumnName = {'Name', 'Style', 'Color', 'Size', 'Visible'};
        ctrl.markerTable.ColumnEditable = [false, true, true, true, true];
        ctrl.markerTable.Data = cell(numel(s.dotMarkers),5);
        for kk = 1:numel(s.dotMarkers)
            style = s.dotMarkers{kk};
            ctrl.markerTable.Data{kk,1} = style.name;
            ctrl.markerTable.Data{kk,2} = style.shape;
            ctrl.markerTable.Data{kk,3} = style.color;
            ctrl.markerTable.Data{kk,4} = style.size;
            ctrl.markerTable.Data{kk,5} = style.visible;
        end
        
    end

    function dotMarkers = parseMarkers(varargin)
        for kk = 1:numel(s.dotMarkers)
            style = s.dotMarkers{kk};
            dotMarkers{kk}.name = ctrl.markerTable.Data{kk,1};
            dotMarkers{kk}.shape = ctrl.markerTable.Data{kk,2};
            dotMarkers{kk}.color = ctrl.markerTable.Data{kk,3};
            dotMarkers{kk}.size = ctrl.markerTable.Data{kk,4};
            dotMarkers{kk}.visible = ctrl.markerTable.Data{kk,5};
        end
    end

    function setMarkers(varargin)
        try
            markerDemo()
        catch e
            msgbox('Not valid settings')
            return
        end
        dotMarkers = parseMarkers();
        s.dotMarkers = dotMarkers;
        s.updateDots = 1;
        gui_update();
    end

    function markerDemo(varargin)
        
        dotMarkers = parseMarkers();
        % Plot the markers
        a = subplot(ctrl.markerPlot);
        hold off
        d = {};
        for kk = 1:numel(dotMarkers)
            style = dotMarkers{kk};
            
            plot(0, kk, style.shape, 'Color', style.color, 'MarkerSize', style.size, 'Visible', style.visible);
            
            hold on
            d = [d {style.name}];
        end
        axis([-1,10,0,numel(dotMarkers)+1])
        axis ij
        legend(d)
        a.Color = 'k';
        %axis off
        
    end

    function gui_change_nExtra(varargin)
        if verbose
            disp('gui_change_nExtra');
        end
        s.nxshow = str2num(ctrl.nExtra.String);
        s.updateDots = 1;
        gui_update();
    end

    function plotTH(varargin)
        TH = df_dotThreshold('folder', s.folder);
        
        if exist('TH', 'var')
            
            a = questdlg('Do you want to use these thresholds?');
            if isequal(a, 'Yes')
                
                for kk = 1:numel(TH)
                    s.dots.th{kk} = TH(kk);
                    s.dots.th0{kk} = TH(kk)/2;
                end
                
                [M, N, s] = df_resetUserDots(M, N, s);
                s.updateDots = 1;
                gui_update()
            end
        end
        
        %for cc = 1:numel(M.channels)
        %    dotThreshold(M.dots{cc}(:,4), 'interactive', 'title', M.channels{cc});
        %end
    end

    function plotDotsPerNuclei(varargin)
        % Plot dots per nuclei and channel
        
        figure('Name', 'Dots Per Nuclei for current field')
        
        w = numel(M.channels); h = 1;
        addpath([getenv('DOTTER_PATH') , '/plugins/measurements/']);
        for cc = 1:numel(M.channels)
            handles(cc) = subplot(h, w, cc);
            dpa = df_m_nucpNdots([], N, cc);
            histogram(dpa);
            title(M.channels{cc})
        end
        linkaxes(handles, 'x')
    end

    function plotFWHM(varargin)
        % Plot FWHM for all dots
        
        if ~isfield(M, 'dotsMeta')
            msgbox('No meta information is available for the dots, please detect dots again with FWHM')
            return
        end
        
        fwhmCol = find(strcmpi(M.dotsMeta, 'fwhm'));
        valueCol = find(strcmpi(M.dotsMeta, 'fvalue'));
        handles = zeros(numel(M.channels), 2);
        if numel(fwhmCol) == 1
            
            figure
            
            w = numel(M.channels); h = 2;
            
            for cc = 1:numel(M.channels)
                handles(cc,1) = subplot(w, h, cc*2-1);
                % -2 means not calculated
                % -1 means could not be calculated
                
                F = M.dots{cc}(:,fwhmCol);
                V = M.dots{cc}(:, valueCol);
                F = F(F>0);
                V = V(F>0);
                
                histogram(F)
                
                xlabel('FWHM [pixels]')
                title(sprintf('%s %d dots', M.channels{cc}, numel(F)))
                
                handles(cc,2) = subplot(w, h, cc*2 );
                scatter(F, V)
                xlabel('FWHM')
                ylabel('Filtered value')
            end
            linkaxes(handles(:,1), 'x')
            linkaxes(handles(:,2), 'x')
        else
            msgbox('No FWHM available for this dataset')
        end
        
    end


    function gui_help(varargin)
        msgbox(help('setUserDotsDNA'));
    end

    function fig_startMove(varargin)
        % Change slide to view
        set(fig_image, 'WindowButtonMotionFcn', @fig_move);
        Q= get(fig_image, 'CurrentPoint');
        fig_image_xstart = Q(2);
    end

    function fig_endMove(varargin)
        set(fig_image, 'WindowButtonMotionFcn', '');
    end

    function fig_move(varargin)
        Q= get(fig_image, 'CurrentPoint');
        delta = (fig_image_xstart-Q(2));
        
        newValue = s.slice+round(delta/16);
        newValue = max(1, newValue);
        newValue = min(size(C{s.channel}, 3), newValue);
        s.slice = round(newValue);
        s.updateGraphics = 1;
        gui_update();
    end

    function nuclei_setLabelZero()
        % Set all UserDotsLabels to 0
        if s.nuclei>0
            L = N{s.nuclei}.userDotsLabels{s.channel};
            if numel(L)>0
                N{s.nuclei}.userDotsLabels{s.channel} = 0*L;
            end
        end
    end


    function gui_keyPress(varargin)
        
        key = varargin{2}.Key;
        if numel(varargin{2}.Modifier) == 1
            mod = varargin{2}.Modifier{1};
        else
            mod = '';
        end
        
        switch key
            case '1'
                gui.nclusters.String = '1';
            case '2'
                gui.nclusters.String = '2';
            case 'a'
                gui_previousSlice()
            case 'z'
                gui_nextSlice()
                
            case 'uparrow'
                gui_previousChannel()
            case 'downarrow'
                gui_nextChannel()
                
            case 'rightarrow'
                gui_nextNuclei()
                
            case 'leftarrow'
                gui_previousNuclei()
                
            case 'return'
                gui_nextField()
                
            case 'v'
                if s.nuclei>0
                    gui_visNuclei()
                end
            case 'escape'
                disp('Closing without saving')
                figure(fig_menu)
                uiresume();
            case 'backspace'
                nuclei_setLabelZero();
                
        end
        % disp('Updating GUI')
        gui_update();
        gui_showDots();
    end




    function gui_nextField(varargin)
        if s.fieldNo<s.nFields
            ctrl.info.Visible = 'on';
            ctrl.table.Visible = 'off';
            set(ctrl.info, 'String', sprintf('Saving %s ...', s.files(s.fieldNo).name), ...
                'ForegroundColor', s.activeColor);
            drawnow();
            gui_saveField();
            s.fieldNo = min(s.nFields, s.fieldNo+1);
            s.updateAll = 1;
            set(ctrl.info, 'String', sprintf('Loading %s ...', s.files(s.fieldNo).name));
            drawnow();
            gui_loadField(s.files(s.fieldNo).name);
            if ~isfield(N{1}, 'userDots')
                [M, N, s] = df_resetUserDots(M, N, s);
            end
            gui_update();
            ctrl.info.Visible = 'off';
            ctrl.table.Visible = 'on';
        end
    end

    function gui_nucJump(varargin)
        % Jump to another nuclei
        
        files = s.files;
        nmfiles = {};
        
        nucStrings{1} = 'None/All';
        for kk = 1:numel(N)
            gstr = 'G1';
            if(N{kk}.dapisum > M.dapiTh)
                gstr = '>G1';
            end
            nucStrings{kk+1} = sprintf('%d %s', kk, gstr);
        end
        
        [sel,~] = listdlg('PromptString','Select a nuclei:',...
            'SelectionMode','single',...
            'ListString',nucStrings);
        
        if numel(sel)>0
            s.nuclei = sel-1;
            gui_update();
        else
            disp('Not changing nuclei')
        end
    end

    function gui_fieldJump(varargin)
        % Jump directly to a field.
        
        files = s.files;
        nmfiles = {};
        for kk = 1:numel(files)
            nmfiles{kk} = files(kk).name;
            if numel(files)<20
            t = load(fullfile(s.folder, files(kk).name), '-mat');
            if numel(t.N) > 0
                if isfield(t.N{1}, 'userDots')
                    nmfiles{kk} = [nmfiles{kk} ' with userDots'];
                end
            end
            end
        end
        
        [sel,~] = listdlg('PromptString','Select a field:',...
            'SelectionMode','single',...
            'ListString',nmfiles);
        
        if numel(sel)>0
            gui_saveField();
            s.fieldNo = sel;
            s.updateAll = 1;
            set(ctrl.info, 'String', sprintf('Loading %s ...', s.files(s.fieldNo).name));
            gui_loadField(s.files(s.fieldNo).name);
            if ~isfield(N{1}, 'userDots')
                [M, N,s ] = df_resetUserDots(M, N, s);
            end
            gui_update();
        else
            disp('Not changing field')
        end
    end

    function gui_previousField(varargin)
        if s.fieldNo>1
            ctrl.info.Visible = 'on';
            ctrl.table.Visible = 'off';
            set(ctrl.info, 'String', sprintf('Saving %s ...', s.files(s.fieldNo).name), ...
                'ForegroundColor', s.activeColor);
            drawnow();
            gui_saveField();
            s.fieldNo = max(1, s.fieldNo-1);
            s.updateAll = 1;
            set(ctrl.info, 'String', sprintf('Loading %s ...', s.files(s.fieldNo).name));
            drawnow();
            gui_loadField(s.files(s.fieldNo).name);
            if ~isfield(N{1}, 'userDots')
                [M, N, s] = df_resetUserDots(M, N, s);
            end
            gui_update();
        end
        ctrl.info.Visible = 'off';
        ctrl.table.Visible = 'on';
    end

    function gui_saveField()
        disp('Updating meta data');
        M = setToM(M, s);
        disp('Saving user dots')
        nm_file = [s.folder s.files(s.fieldNo).name];
        Meta_old = df_nm_load(nm_file);
        
        if strcmp(Meta_old{1}.dapifile, M.dapifile) == 1                
            save(nm_file, 'M', 'N');
        else
            errordlg('You just found a super serious bug! Please report to erik!');
        end
    end

    function gui_loadField(filename)
        % Load an NM file into the GUI
        
        NM = load([s.folder filename], '-mat');
        N = NM.N; M = NM.M;
        
        if numel(N)==0
            msgbox('No Nuclei!')
        end
        
        doReset = 0;
        hasUserDots = 0;
        
        if numel(N)>0
            if isfield(N{1}, 'userDots')
                disp('User Dots already exists for this field')
                hasUserDots = 1;
            end
        end
        
        if hasUserDots
            s = parseFromM(M, s); % load settings from M to s
            
            % For backward compatibility
            if ~isfield(N{1}, 'userDotsLabels')
                disp('no userDotsLabels, creating');
                for kk = 1:numel(N)
                    for cc = 1:numel(M.channels)
                        N{kk}.userDotsLabels{cc} = ones(size(N{kk}.userDots{cc},1),1);
                    end
                end
            end
        end
        
        if ~hasUserDots
            doReset = 1;
            % if previous field had any settings
            if isfield(s.dots, 'th')
                answer = questdlg('Use settings from last field?');
                if strcmp(answer, 'Yes')
                    doReset = 0;
                end
            end
        end
        
        % keyboard
        if doReset
            % Reset
            if isfield(M, 'th')
                s.dots.th = M.th;
                s.dots.th0 = M.th0;
            else
                s.dots.th = cell(1, numel(M.channels));
                s.dots.th0 = cell(1, numel(M.channels));
            end
            for cc = 1:numel(M.channels)
                s.dots.fwhm{cc}(1) = .5;
                s.dots.fwhm{cc}(2) = 5;
            end
        end
        
        
        % Keep track if these was changed
        s.lastChannel = -1;
        s.lastNuclei = -1;
        
        %% Load image data
        disp('Loading images ...')
        for kk = 1:numel(M.channels)
            fileName = strrep(M.dapifile, 'dapi', M.channels{kk});
            fprintf(' %d/%d %s ... \n', kk, numel(M.channels), fileName);
            C{kk} = df_readTif(fileName);
        end
        
        gui.clusterChannels.String = M.channels;
        gui.clusterChannels.Value = 1:numel(M.channels);
        
        s.firstSliceZ = 1;
        s.lastSliceZ = size(C{1},3);
        s.dots.Z(1) = 1;
        s.dots.Z(2) = size(C{1},3);
        
        disp('Creating projections');
        generateProjections();
        
        if doReset
            [M, N, s] = df_resetUserDots(M, N, s);
        end
        
        % Revert some of the settings to default values
        s.slice = round(size(C{kk}, 3)/2);
        s.lastSlice = -1;
        s.updateContours = 1;
        s.nuclei = 0;
        s.channel = 1;
        s.sumProjection = 0;
        s.maxProjection = 1;
        
    end

    function generateProjections()
        disp('generateProjections')
        for kk = 1:numel(C)
            C_SUM{kk} = sum(double(C{kk}(:,:,s.firstSliceZ:s.lastSliceZ)), 3)/(s.lastSliceZ-s.firstSliceZ+1);
            C_MAX{kk} = max(C{kk}(:,:,s.firstSliceZ:s.lastSliceZ), [], 3);
        end
    end

    function gui_thresholdAid(varargin)
        dotterSlide(C{s.channel}, M.dots{s.channel}(1:10000,1:4), [],[], 'wait')
    end

    function gui_resetThresholds(varargin)
        s.dots.th = cell(1, numel(M.channels));
        s.dots.th0 = cell(1, numel(M.channels));
        [M, N, s] = df_resetUserDots(M, N, s);
        s.updateDots = 1;
        gui_update()
    end

    function gui_detectDotsParse(varargin)
        %% This function will reset the user dots based on the filter settings
        disp('gui_detectDots')
        
        % Set s.dots.Z(1) and s.dots.Z(2) used to discard dots based on their z
        % value
        
        % Get Z limits
        f1 = str2num(ctrl.dotZfrom.String);
        f2 = str2num(ctrl.dotZto.String);
        
        if(f1 < f2 && f1>0 && f2<=size(C{1},3));
            s.dots.Z(1) = f1;
            s.dots.Z(2) = f2;
        else
            ctrl.dotZfrom.String = num2str(s.dots.Z(1));
            ctrl.dotZto.String = num2str(s.dots.Z(2));
        end
        
        % Get fwhm limits and dilation
        for cc = 1:numel(M.channels)
            f1 = ctrl.table.Data{cc,5};
            f2 = ctrl.table.Data{cc,6};
            
            assert(isnumeric(f1));
            assert(isnumeric(f2));
            
            if numel(f1)>0 && numel(f2>0)
                if (f1 < f2 && f1 >= 0);
                    s.dots.fwhm{cc} = [f1, f2];
                else
                    ctrl.table.Data{cc,5} = s.dots.fwhm{cc}(1);
                    ctrl.table.Data{cc,6} = s.dots.fwhm{cc}(2);
                end
            end
            
            s.dilationRadius(cc) = ctrl.table.Data{cc,7};
            
        end
        
        %% Thresholds etc
        for kk = 1:numel(M.channels)
            th = ctrl.table.Data{kk,3};
            
            s.dots.th{kk} = th;
            s.dots.th0{kk} = th/2;
            
            s.dots.fwhm{kk} = [ctrl.table.Data{kk,5}, ctrl.table.Data{kk,6}];
            
            md = ctrl.table.Data{kk,4};
            s.dots.maxDots(kk) = md;
        end
        
        if verbose
            s.dots
        end
        
    end

    function gui_detectDotsAllFiles(varargin)
        
        a = questdlg('This will erase all userDots from all fields. Are you sure that you want to continue?', 'Warning!', 'Yes', 'No', 'No');
        
        if ~strcmpi(a, 'Yes')
            return
        end
        
        gui_detectDots('all files')
    end

    function gui_detectDots(varargin)
        
        % update s.dots
        gui_detectDotsParse();
        
        if strcmpi(varargin{1}, 'all files')
            ctrl.table.Visible = 'off';
            ctrl.info.String = '';
            ctrl.info.Visible = 'on';
            
            infoStr = sprintf('Applying to folder:\n %s\n', s.folder);
            
            for ff = 1:numel(s.files)
                fname = [s.folder s.files(ff).name];
                infoStr = [infoStr sprintf('File %d/%d: %s\n', ff, numel(s.files), s.files(ff).name)]
                ctrl.info.String = infoStr;
                
                drawnow();
                t = load(fname, '-mat');
                [M, N, s] = df_resetUserDots(t.M, t.N, s);
                M = setToM(M ,s);
                M.th = s.dots.th;
                M.th0 = s.dots.th0;
                save(fname, 'M', 'N', '-mat');
            end
            
            ctrl.table.Visible = 'on';
            ctrl.info.Visible = 'off';
            
            % Load current field again to get updated dots
            gui_loadField(s.files(s.fieldNo).name);
            
            s.updateAll = 1;
        else
            disp('Resetting dots in this field');
            [M, N, s] = df_resetUserDots(M,N,s);
            s.updateDots = 1;
        end
        
        s.updateGraphics = 1;
        gui_update();
    end

    function gui_Click(varargin)
        if s.nuclei == 0
            disp('Nothing to do with mouse when viewing all nuclei')
            return
        end
        % When the image is clicked
        disp('Image was clicked');
        
        gui_dotClick(varargin{1}, varargin{2})
    end

    function gui_dotClick(varargin)
        if s.nuclei == 0
            disp('Nothing to do with mouse when viewing all nuclei')
            return
        end
        
        % When an annotation is clicked, see which one.
        % Switch to when image is clicked, see what dot
        
        % When the image is clicked, see if a point was clicked.
        % Clicked points are changed in this way:
        % background dot ->
        % active dot, cluster A ->
        % active dot, cluster B ->
        % background dot
        
        % Get the coordinate of the clicked point
        xy = varargin{2}.IntersectionPoint;
        xy = xy([2,1]);
        
        % Which button was clicked?
        button2 = 0;
        
        showInfo = 0;
        if varargin{2}.Button >1
            showInfo = 1;
            button2 = 1;
        end
        
        if button2 == 1
            disp('No Match!')
            t = questdlg('Do you want to add a new dot here?');
            if strcmpi(t, 'Yes')
                addNewDot(xy);
                gui_showDots();
                return;
            end
        end
        
        % Extract D0 and D1 from N
        D0 = N{s.nuclei}.userDotsExtra{s.channel};
        if size(D0,1)>s.nxshow
            D0 = D0(1:s.nxshow,:);
        end
        
        D1 = N{s.nuclei}.userDots{s.channel};
        foundMatch = 0; % Used to abort
        
        %% Find closest dot
        
        if size(D0,1)==0
            d1 = Inf;
        else
            d1 = eudist(xy, D0(:,1:2));
        end
        
        d2 = eudist(xy, D1(:,1:2));
        if numel(d2)==0
            d2 = Inf;
        end
        
        if(min(d1)<min(d2))
            % Closest dot in D0
            if min(d1)<s.captureRadius
                kk = find(d1==min(d1));
                kk = kk(1);
                
                % userDotsExtra -> UserDots, Label 0
                % Add at the end of userDots and userDotsLabels
                N{s.nuclei}.userDotsLabels{s.channel} = [N{s.nuclei}.userDotsLabels{s.channel}; 0];
                
                % Add a zero at the end of D0 if it is to short (i.e.,
                % pixel value missing.
                D1 = [D1; [D0(kk,:) ones(1, size(D1,2)-size(D0,2))]];
                
                % Remove from D0
                D0 = N{s.nuclei}.userDotsExtra{s.channel};
                D0 = D0([1:kk-1 kk+1:end], :);
                
                % Write back
                N{s.nuclei}.userDots{s.channel} = D1;
                N{s.nuclei}.userDotsExtra{s.channel} = D0;
                
                fprintf('userDotsExtra kk: %d\n', kk)
                foundMatch = 1;
            end
        else
            if min(d2)<s.captureRadius
                kk = find(d2==min(d2));
                kk = kk(1);
                % homolog 1 -> homolog 2
                homolog = N{s.nuclei}.userDotsLabels{s.channel}(kk);
                if homolog == 0 || homolog == 1
                    N{s.nuclei}.userDotsLabels{s.channel}(kk) = homolog + 1;
                else % homolog 2 -> userDotsExtra
                    %keyboard
                    
                    % Grab D0 again, all of them
                    D0 = N{s.nuclei}.userDotsExtra{s.channel};
                    D0 = [D1(kk,:); D0];
                    D1 = D1([1:kk-1 kk+1:end], :);
                    labels = N{s.nuclei}.userDotsLabels{s.channel};
                    labels = labels([1:kk-1 kk+1:end], :);
                    N{s.nuclei}.userDots{s.channel} = D1;
                    N{s.nuclei}.userDotsExtra{s.channel} = D0;
                    N{s.nuclei}.userDotsLabels{s.channel} = labels;
                end
                fprintf('userDots kk: %d\n', kk)
                foundMatch = 1;
            end
        end
        
        if foundMatch == 1;
            gui_showDots();
        end
    end

    function addNewDot(xy)
        fprintf('Adding a new dot at %d %d\n', xy(1), xy(2));
        
        L = C{s.channel}(round(xy(1)), round(xy(2)), :);
        L = squeeze(L);
        z = find(L==max(L(:)));
        z = z(1);
        
        
        D = N{s.nuclei}.userDots{s.channel}; % Give the new dot the highest intensity value
        
        
        if numel(D)>0
            intensity = max(D(:,4))+1;
            N{s.nuclei}.userDots{s.channel} =  [xy(1), xy(2) z, intensity; D];
        else
            intensity = 10e6;
            N{s.nuclei}.userDots{s.channel} = [xy(1), xy(2) z, intensity];
        end
        
        L = N{s.nuclei}.userDotsLabels{s.channel};
        if numel(L)>0
            N{s.nuclei}.userDotsLabels{s.channel} = [0 ; L];
        else
            N{s.nuclei}.userDotsLabels{s.channel} = 0;
        end
        
        fprintf('Added a dot at location %d %d %d with intensity %d\n', xy(1), xy(2), z, intensity);
        
    end

    function gui_nextChannel(varargin)
        setChannel(s.channel+1);
    end

    function gui_previousChannel(varargin)
        setChannel(s.channel -1);
    end

    function setChannel(newChannel)
        s.channel = min(max(newChannel, 1), numel(M.channels));
        s.updateBBX = 1;
        gui_update();
    end

    function gui_nextNuclei(varargin)
        % change axis
        s.nuclei = min(s.nuclei+1, numel(N));
        gui_update();
    end

    function gui_previousNuclei(varargin)
        % change axis
        s.nuclei = max(s.nuclei-1, 0);
        gui_update();
    end

    function gui_nextSlice(varargin)
        s.slice = min(s.slice+1, size(C{s.channel}, 3));
        s.updateGraphics = 1;
        gui_update();
    end

    function gui_previousSlice(varargin)
        s.slice = max(s.slice-1, 1);
        s.updateGraphics = 1;
        gui_update();
    end

    function gui_showDots()
        % Redraw the dots.
        %
        % Either for one nuclei or for the whole field
        
        %% Delete all current dots
        figure(fig_image)
        for kk = 1:numel(DH)
            delete(DH{kk}) % extra dots
        end
        
        if numel(anno)>0
            delete(anno)
            anno = [];
        end
        
        if s.nuclei == 4
            %keyboard
        end
        
        if s.nuclei > 0 % A single nuclei will be drawn
            bbx = N{s.nuclei}.bbx;
            
            % Limit the number of extra dots shown
            d = N{s.nuclei}.userDotsExtra{s.channel};
            test1 = size(d,1);
            
            if size(d,1)>s.nxshow
                d = d(1:s.nxshow,:);
            end
            
            style = s.dotMarkers{1};
            if numel(d)>0
                DH{1} = plot(d(:,2), d(:,1), ...
                    style.shape, 'Color', style.color, 'MarkerSize', style.size, 'ButtonDownFcn', @gui_dotClick, ...
                    'Visible', style.visible);
            end
            
            % Color depending on userDotsLabels
            homolog = N{s.nuclei}.userDotsLabels{s.channel};
            
            for kk = 2:numel(s.dotMarkers)
                style = s.dotMarkers{kk};
                if numel(N{s.nuclei}.userDots{s.channel}) >0
                    HD = N{s.nuclei}.userDots{s.channel}(homolog==kk-2,:);
                    DH{kk} = plot(HD(:,2), HD(:,1), ...
                        style.shape, 'Color', style.color, 'MarkerSize', style.size, 'ButtonDownFcn', @gui_dotClick, ...
                        'Visible', style.visible);
                end
            end
            
            
            gui.plotInfo.String = sprintf('%s nuc: %d th: %.2f dots: %d (0: %d, 1: %d, 2: %d)\n', ...
                M.channels{s.channel}, s.nuclei, ...
                s.dots.th{s.channel}, ...
                size(N{s.nuclei}.userDots{s.channel},1), ...
                sum(homolog==0), ...
                sum(homolog==1), ...
                sum(homolog==2));
            
        else
            %% If all nuclei are shown at the same time
            
            % Extra dots
            d = zeros(0,3);
            for kk = 1:numel(N)
                dd = N{kk}.userDotsExtra{s.channel};
                nx = min(size(d,1), s.nxshow);
                if numel(dd)>0
                    d = [dd(1:nx, 1:3); d];
                end
            end
            style = s.dotMarkers{1};
            DH{1} = plot(d(:,2), d(:,1), ...
                style.shape, 'Color', style.color, 'MarkerSize', style.size, 'ButtonDownFcn', @gui_dotClick, ...
                'Visible', style.visible);
            
            for ll = 2:numel(s.dotMarkers)
                d = [];
                for kk = 1:numel(N)
                    homolog = N{kk}.userDotsLabels{s.channel};
                    d = [d; N{kk}.userDots{s.channel}(homolog==ll-2,:)];
                end
                style = s.dotMarkers{ll};
                DH{ll} = plot(d(:,2), d(:,1), ...
                    style.shape, 'Color', style.color, 'MarkerSize', style.size, 'ButtonDownFcn', @gui_dotClick, ...
                    'Visible', style.visible);
            end
            
            
            for kk = 1:numel(N)
                if N{kk}.dapisum < s.dapiValue
                    color = 'Green';
                else
                    color = 'Red';
                end
                anno(kk) = text(N{kk}.bbx(3), N{kk}.bbx(2), sprintf('%d', kk), 'Color', color, 'background', 'black');
            end
            
            gui.plotInfo.String = sprintf('th: %.2f', s.dots.th{s.channel});
            
            
        end
        
    end

    function gui_changeProjection(varargin)
        
        if strcmp(varargin{1}.String, 'MAX')
            set(ctrl.sumProjection, 'value', 0);
        end
        
        if strcmp(varargin{1}.String, 'SUM')
            set(ctrl.maxProjection, 'value', 0);
        end
        
        gui_update();
    end

    function gui_update(varargin)
        % Update the view of the image
        
        % s.updateBBX = 0;
        % s.updateDots = 0;
        % s.updateContours = 0;
        
        % Initialization, only run the first time
        if s.lastChannel == -1
            figure(fig_image)
            img = imagesc(C_SUM{s.channel}, 'ButtonDownFcn', @gui_Click);
            hold on
            axis image
            colormap gray
            s.updateAll = 1;
            try
                close(fig_slider)
            end
            fig_slider = climSlider(img);
            fig_slider.UserData.updateFcn('channel', s.channel);
            figure(fig_image);
        end
        
        if s.updateAll
            s.updateDots = 1;
            s.updateBBX = 1;
            s.updateGraphics = 1;
            s.updateContours = 1;
            s.updateAll = 0;
            s.updateCLIM = 1;
            s.updateMarkerTable = 1;
        end
        
        if s.updateMarkerTable
            updateMarkerTable();
        end
        
        if s.lastChannel ~= s.channel
            s.updateGraphics = 1;
            s.updateDots = 1;
        end
        
        if s.lastNuclei ~= s.nuclei
            s.updateBBX = 1;
            s.updateDots = 1;
        end
        
        if s.sumProjection ~= get(ctrl.sumProjection, 'Value')
            s.sumProjection = get(ctrl.sumProjection, 'Value');
            s.updateGraphics = 1;
        end
        
        if s.maxProjection ~= get(ctrl.maxProjection, 'Value')
            s.maxProjection = get(ctrl.maxProjection, 'Value');
            s.updateGraphics = 1;
        end
        
        if s.updateContours
            figure(fig_image)
            
            if numel(size(M.mask)) == 3
                mask = max(M.mask, [], 3);
            else
                mask = M.mask;
            end
            [~, ctr] = contour(mask, [.5,.5]);
            
            set(ctr, 'LineColor', 'b');
            s.updateContours = 0;
        end
        
        
        if s.updateBBX
            figure(fig_image)
            if s.nuclei >   0
                if s.nuclei == 3
                    %keyboard
                end
                bbx = N{s.nuclei}.bbx;
                
                bbx(1) = bbx(1)  - s.dilationRadius(s.channel);
                bbx(2) = bbx(2)  + s.dilationRadius(s.channel);
                bbx(3) = bbx(3)  - s.dilationRadius(s.channel);
                
                bbx(4) = bbx(4)  + max(s.dilationRadius);
                axis(bbx([3,4,1,2]))
                % Set the colour of the contour depending on DAPI
                try
                    if N{s.nuclei}.dapisum < s.dapiValue
                        set(ctr, 'LineColor', 'g')
                    else
                        set(ctr, 'LineColor', 'r')
                    end
                catch e
                    warning('')
                end
            else
                axis([0,size(C{1},1), 0, size(C{1},2)]);
                try
                    set(ctr, 'LineColor', 'w')
                catch e
                    warning('')
                end
            end
            s.updateBBX = 0;
            s.updateCLIM = 1;
        end
        
        if s.updateGraphics
            %disp('Applying updateGraphics')
            if s.sumProjection
                set(img, 'CData', C_SUM{s.channel})
            end
            if s.maxProjection
                set(img, 'CData', C_MAX{s.channel})
            end
            if s.maxProjection == 0 && s.sumProjection == 0
                set(img, 'CData', C{s.channel}(:,:,s.slice))
            end
            
            if isfield(M, 'xmask')
                disp('Updating xmask contours');
                %keyboard
                if ~isnumeric(xctr)
                    delete(xctr)
                    xctr = [];
                end
                figure(fig_image)
                [~, xctr] = contour(M.xmask{s.channel}, [.5,.5]);
                set(xctr, 'LineColor', 'w');
            end
            
            
            s.updateGraphics = 0;
            s.updateCLIM = 1;
            fig_slider.UserData.updateFcn('channel', s.channel);
        end
        
        if s.updateDots
            gui_showDots();
            s.updateDots = 0;
        end
        
        set(ctrl.nuc,     'String', sprintf('Nuclei  %d/%d', s.nuclei, numel(N)));
        set(ctrl.channel, 'String', sprintf('Channel %s %d/%d', M.channels{s.channel}, s.channel, numel(M.channels)));
        set(ctrl.slice,   'String', sprintf('Z-plane %d/%d', s.slice, size(C{1},3)));
        set(ctrl.field,   'String', sprintf('Field   %d/%d', s.fieldNo, s.nFields));
        
        infoString = sprintf('File: %s\n', s.files(s.fieldNo).name);
        infoString = [infoString sprintf('Channel   Threshold    Dots/Nuclei:\n')];
        
        ctrl.table.Data = cell(numel(M.channels), 6);
        for kk = 1:numel(M.channels);
            dotsPerNuclei = getDotsPerNuclei('Channel', kk);
            ctrl.table.Data{kk,1} = M.channels{kk};
            ctrl.table.Data{kk,2} = dotsPerNuclei;
            
            ctrl.table.Data{kk,3} = s.dots.th{kk};
            ctrl.table.Data{kk,4} = s.dots.maxDots(kk);
            
            ctrl.table.Data{kk,5} = s.dots.fwhm{kk}(1);
            ctrl.table.Data{kk,6} = s.dots.fwhm{kk}(2);
            ctrl.table.Data{kk,7} = s.dilationRadius(kk);
            
            infoString = [infoString, sprintf('%7s%12.2f   %5.1f\n', M.channels{kk}, s.dots.th{kk}, dotsPerNuclei)];
        end
        set(ctrl.info, 'String', infoString, 'ForegroundColor', [0,0,0]);
        
        s.lastNuclei = s.nuclei;
        s.lastChannel = s.channel;
        s.lastSlice = s.slice;
        
        if s.updateCLIM
            
            ax = get(fig_image, 'CurrentAxes');
            cdata = get(img, 'CData');
            ylim = round(ax.XLim);
            xlim = round(ax.YLim);
            xlim(1) = max(1, xlim(1));
            xlim(2) = min(xlim(2), size(cdata,1));
            ylim(1) = max(1, ylim(1));
            ylim(2) = min(ylim(2), size(cdata,2));
            
            cdata = cdata(xlim(1):xlim(2), ylim(1):ylim(2));
            newClim = [min(cdata(:)), max(cdata(:))];
            
            % Send cdata to climSlider and let it update the clims
            fig_slider.UserData.updateFcn('H', cdata);
        end
        
        ctrl.table.Visible = 'on';
        ctrl.info.Visible = 'off';
        
        ctrl.sliceZfrom.String = num2str(s.firstSliceZ);
        ctrl.sliceZto.String = num2str(s.lastSliceZ);
        
        ctrl.dotZfrom.String = num2str(s.dots.Z(1));
        ctrl.dotZto.String = num2str(s.dots.Z(2));
        
        ctrl.nExtra.String = num2str(s.nxshow);
        
        drawnow
    end

    function n = getDotsPerNuclei(varargin)
        channel = 0;
        %keyboard
        for kk = 1:numel(varargin)
            if strcmp(varargin{kk}, 'Channel')
                channel = varargin{kk+1};
            end
        end
        if channel==0
            n = nan;
            return
        end
        
        nDots = 0;
        for kk = 1:numel(N)
            nDots = nDots + size(N{kk}.userDots{channel}, 1);
        end
        if numel(N)>0
            n = nDots/numel(N);
        else
            n = nan;
        end
    end



%% Clustering functions
    function gui_clustering(clustering)
        % This is the callback from setUserDotsDNA_clustering
        % Should apply the clustering method of choice to
        % nuclei/field/fields
        
        disp(clustering)
        s.clustering = clustering;
        
        if strcmpi(s.clustering.applyTo, 'Nuclei');
            clustering_nuclei();
        end
        if strcmpi(s.clustering.applyTo, 'Field');
            clustering_field();
        end
        if strcmpi(s.clustering.applyTo, 'All');
            clustering_all();
        end
    end

    function clustering_nuclei(varargin)
        % Cluster only current nuclei
        if s.nuclei > 0
            fprintf('Clustering nuclei %d\n', s.nuclei);
            N{s.nuclei} = clustering_apply(N{s.nuclei}, s.clustering);
            s.updateDots = 1;
            gui_update()
        else
            disp('Not applicable')
        end
    end

    function clustering_field(varargin)
        % Cluster all nuclei in this field
        w = waitbar(0, 'Clustering');
        for nn = 1:numel(N)
            waitbar(nn/numel(N), w);
            N{nn} = clustering_apply(N{nn}, s.clustering);
        end
        close(w);
        s.updateDots = 1;
        gui_update()
    end

    function clustering_all(varargin)
        
        a = questdlg('This will erase all userDots from all fields. Are you sure that you want to continue?', 'Warning!', 'Yes', 'No', 'No');
        if ~strcmpi(a, 'Yes')
            return
        end
        
        p = waitbar(0, 'Clustering');
        for kk = 1:numel(s.files)
            waitbar(kk/numel(s.files), p);
            nmFile = [folder s.files(kk).name];
            t = load(nmFile, '-mat');
            M = t.M;
            N = t.N;
            for nn = 1:numel(N)
                N{nn} = clustering_apply(N{nn}, s.clustering); %gui_kmeansClustering()
            end
            save(nmFile, 'M', 'N');
        end
        close(p);
        
        % Load this field again with updated clustering
        gui_loadField(s.files(s.fieldNo).name);
        s.updateDots = 1;
        gui_update()
    end


%%
    function gui_visNuclei(varargin)
        
        if(s.nuclei < 1)
            warning('No specific nuclei selected\n');
            return
        end
        
        figure
        %keyboard
        hold on
        nuc = N{s.nuclei};
        hold on
        
        colors = {'b', 'g', 'r', 'c', 'm', 'k'};
        
        styles1 = {};
        styles2 = {};
        for kk = 1:numel(colors)
            styles1{kk} = ['o' colors{kk}];
            styles2{kk} = ['*' colors{kk}];
        end
        p = zeros(1,numel(M.channels));
        for cc = 1:numel(nuc.userDots)
            d = nuc.userDots{cc};
            l = nuc.userDotsLabels{cc};
            d1 = d(l==1, :);
            d2 = d(l==2, :);
            
            a = plot3(d1(:,1), d1(:,2), d1(:,3), styles1{cc});
            b = plot3(d2(:,1), d2(:,2), d2(:,3), styles2{cc});
            
            if numel(a)> 0
                p(cc) = a;
            else
                if numel(b)>0
                    p(cc) = b;
                else
                    p(cc) = 0;
                end
            end
            
        end
        legend(p(p>0), M.channels(p>0));
        
        title(sprintf('Nuclei %d', s.nuclei));
        view(3)
        axis equal
        grid on
    end

    function gui_restrictDots(nuc, chan)
        % Don't use more dots than specified by M.nTrueDots/2
        % per homolog
        % split user dots depending on label
        % pick strongest M.nTrueDots{cc}/2 from each
        % write back
        
        if ~exist('nuc', 'var')
            nuc = 1:numel(N);
        end
        
        if ~exist('chan', 'var')
            chan = 1:numel(M.channels);
        end
        
        for nn = nuc
            for cc = chan
                D = N{nn}.userDots{cc};
                L = N{nn}.userDotsLabels{cc};
                D1 = D(L==1, :);
                D2 = D(L==2, :);
                
                if size(D1,1)>0
                    [~, D1i] = sort(D1(:,4), 'descend');
                    D1u = D1(D1i(1: min(size(D1,1), M.nTrueDots(cc)/2)),:);
                    D1e = D1(D1i(size(D1u,1)+1:end), :);
                else
                    D1u = [];
                    D1e = [];
                end
                
                if size(D1,1)>0
                    [~, D2i] = sort(D2(:,4), 'descend');
                    D2u = D2(D2i(1: min(size(D2,1), M.nTrueDots(cc)/2)),:);
                    D2e = D2(D2i(size(D2u,1)+1:end), :);
                else
                    D2u = [];
                    D2e = [];
                end
                
                N{nn}.userDots{cc} = [D1u;D2u];
                N{nn}.userDotsExtra{cc} = [N{nn}.userDotsExtra{cc}; D1e; D2e];
                N{nn}.userDotsLabels{cc} = [ones(size(D1u,1),1) ;2*ones(size(D2u,1),1)];
                
                s.updateDots = 1;
                gui_update()
            end
        end
    end

    function gui_restoreNuclei(nuclei, chan)
        
        assert(numel(nuclei)==1);
        
        if ~exist('chan', 'var')
            chan = 1:numel(M.channels);
        end
        
        if nuclei > 0
            for cc = chan
                
                D = [N{nuclei}.userDots{cc} ; N{nuclei}.userDotsExtra{cc}];
                N{nuclei}.userDotsExtra{cc} = D(D(:,4)<s.dots.th{cc}, :);
                N{nuclei}.userDots{cc} = D(D(:,4) >= s.dots.th{cc}, :);
                N{nuclei}.userDotsLabels{cc} = zeros(size(N{nuclei}.userDots{cc},1),1);
            end
            s.updateDots = 1;
            gui_update()
        end
    end

    function gui_setLabelZero(nuclei, chan)
        % Set all userDots to label 0 in the current nuclei
        if nuclei > 0
            for cc = chan
                N{nuclei}.userDotsLabels{cc} = zeros(size(N{nuclei}.userDotsLabels{cc}));
            end
            s.updateDots = 1;
            gui_update()
        end
    end

    function gui_clearUserDots(nuclei, chan)
        
        assert(numel(nuclei)==1);
        
        if ~exist('chan', 'var')
            chan = 1:numel(M.channels);
        end
        
        if nuclei > 0
            for cc = chan
                N{nuclei}.userDotsExtra{cc} = [N{nuclei}.userDots{cc}; N{nuclei}.userDotsExtra{cc}];
                N{nuclei}.userDots{cc} = [];
                N{nuclei}.userDotsLabels{cc} = [];
            end
            s.updateDots = 1;
            gui_update()
        end
    end

    function gui_debug(varargin)
        Z = [];
        keyboard
    end

    function gui_quit(varargin)
        set(ctrl.info, 'String', sprintf('Saving %s ...', s.files(s.fieldNo).name), ...
            'ForegroundColor', s.activeColor);
        drawnow();
        gui_saveField();
        disp('quit')
        figure(fig_menu)
        uiresume();
    end

    function gui_toggleDots(varargin)
        % Toggle marker visibility on/off
        for kk = 1:numel(s.dotMarkers)
            if(strcmpi(s.dotMarkers{kk}.visible, 'off'))
                s.dotMarkers{kk}.visible = 'on';
            else
                s.dotMarkers{kk}.visible = 'off';
            end
        end
        
        s.updateDots = 1;
        s.updateMarkerTable = 1;
        gui_update();
    end

    function Z = plotSliceZ(varargin)
        % Plot slice nr vs contrast
        ctr = df_image_focus('image', C{1}, 'method', 'gm');
        
        figure
        plot(1:size(C{1},3), ctr)
        grid on
        xlabel('Z')
        ylabel('Focus')
    end

    function Z = plotUDZ(varargin)
        % plot slice nr vs nr of dots
        Z = [];
        for kk=1:numel(N)
            for cc = 1:numel(N{kk}.userDots)
                Z = [Z ; N{kk}.userDots{cc}(:,3)];
            end
        end
        figure,
        histogram(Z, 1:size(C{1},3)); %, 'Normalization', 'pdf');
        xlabel('Z')
        ylabel('UserDots')
        grid on
    end

    function setSliceZ(varargin)
        % Set s.dots.Z(1) and s.dots.Z(2) used to discard dots based on their z
        % value
        
        f1 = str2num(ctrl.sliceZfrom.String);
        f2 = str2num(ctrl.sliceZto.String);
        
        if(f1 < f2 && f1>0 && f2<=size(C{1},3));
            s.firstSliceZ = f1;
            s.lastSliceZ = f2;
        else
            ctrl.sliceZfrom.String = num2str(s.firstSliceZ);
            ctrl.sliceZto.String = num2str(s.lastSliceZ);
        end
        generateProjections();
        s.updateGraphics = 1;
        gui_update();
    end

end



%% Functions not sharing the global variables goes below

function M = setToM(M, s)
% See parseFromM()
M.th = s.dots.th;
M.th0 = s.dots.th0;
M.fwhm = s.dots.fwhm;
M.maxDots = s.dots.maxDots;
M.dilationRadius = s.dilationRadius;
end

function N = clustering_apply(N, s)
% Here is where the actual clustering is going on
% See setUserDotsDNA_clustering for how the settings are created
% For each nuclei, load all userDots and apply the clustering method
fun = str2func(s.method);

if numel(N)>0
    for kk = 1:numel(N)
        N(kk) = fun(N(kk), s);
    end
end
end

function s = parseFromM(M, s)
% Parse settings from M, this is called when a new NM files is loaded
% See setToM()
if isfield(M, 'dapiTh')
    s.dapiValue = M.dapiTh;
else
    warning('No DAPI threshold set for this field. Please set!');
end

if isfield(M, 'fwhm')
    if numel(M.fwhm)>0
        s.dots.fwhm = M.fwhm;
    else
        for cc = 1:numel(M.channels)
            s.dots.fwhm{cc} = [0, 100];
        end
    end
else
    for cc = 1:numel(M.channels)
        s.dots.fwhm{cc} = [0, 100];
    end
end

s.dots.fwhm


if isfield(M, 'maxDots')
    s.dots.maxDots = M.maxDots;
else
    s.dots.maxDots = 2*ones(1, numel(M.channels));
end

if isfield(M, 'dilationRadius')
    s.dilationRadius = M.dilationRadius;
else
    s.dilationRadius = 5*ones(1, numel(M.channels));
end

if isfield(M, 'th')
    s.dots.th = M.th;
    s.dots.th0 = M.th0;
else
    warning('No threshold available!');
    s.dots.th = mat2cell(zeros(1, numel(M.channels)), 1, ones(1,numel(M.channels)));
    s.dots.th0 = mat2cell(zeros(1, numel(M.channels)), 1, ones(1,numel(M.channels)));
end

end


