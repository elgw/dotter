function df_plot(varargin)
%% Plot this vs that for NM files

% Ideas:
% - Extend the plot windows with an export option
% - Drawings and descriptions to explain the properties
% - Plugin sepecification, i.e., place files in specific folder, define
%   io, ...

f = [];
tab = [];

for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'tab')
        tab = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'closefun')
        closefun = varargin{kk+1};
    end
end

if numel(tab) == 0
    %% Create GUI components
    f = figure('Position', [0,200,400,600], 'Menubar', 'none', ...
        'NumberTitle','off', ...
        'Name', 'nd2 tif conversion');
    tabs = uitabgroup();
    tab = uitab(tabs, 'title', 'df_plot');
    closefun = @() close(f);
else
    f = tab.Parent;
end

% Set up variables
D.inputFiles = [];
D.readDir = df_getConfig('nd2tif_g', 'readDir', '~/Desktop/');
D.outputDir = df_getConfig('nd2tif_g', 'outputDir', '~/Desktop/');

dbg = 0;

if nargin == 99
    % for debuggin
    folder = '/data/current_images/iEG/test_calc/';
    folder = '/data/current_images/iJC/iJC829_20170918_001_calc/';
    close all
    dbg = 1 % assignin('base', 'A', A) and assignin('base', 'B', B) after plot
end

addpath([getenv('DOTTER_PATH') '/addons/structdlg/'])

%% Global data
N = [];
M = [];
d = [];
ccFile = '';

% Strings to appear both in list and as [x/y]labels

t = [];

% string:
%  what to show in gui
%  and what to show in plot axes
% selChan
%  0 - don't select channel
%  1 - select channels
%  2 - two set of channels
% features
%  a string specifying symbolically how many features that will be produced
% fun
%  the plugin/function to measure

% Plugins to write:
% Integral intensity
% Signal to noise ratio per nuclei
% Volume of cluster

% Number of features:
% N number of nuclei
% 2N number of clusters
% D number of dots

% Load measurement plugins
pluginPath = [getenv('DOTTER_PATH') 'plugins/measurements/'];
plugins = dir([pluginPath 'df_m_*.m']);
addpath(pluginPath)

if(numel(plugins)==0)
    warning('No plugins found!');
    return
end

for kk = 1:numel(plugins)
    fs = str2func(plugins(kk).name(1:end-2));
    t = fs('getSettings');
    if ~isfield(t,'s')
        t.s = [];
    end
    t.fun = fs;
    d.nucProps(kk) = t;
end


% Sort by string
strings = {d.nucProps.string};
[~, order] = sort(strings);
d.nucProps = d.nucProps(order);

for kk = 1:numel(d.nucProps)
    % Remove all non-normal characters
    d.nucProps(kk).xstring = regexprep(d.nucProps(kk).string,'[^a-zA-Z]','_');
end

t = [];
t.string = 'G1/below DAPI threshold';
t.fun = @nucfLow;
d.nucFilters(1) = t;
t.string = 'All';
t.fun = @nucfAll;
d.nucFilters(end+1) = t;
t.string = 'G2/above DAPI threshold';
t.fun = @nucfHigh;
d.nucFilters(end+1) = t;

%d.nucFilterFun = {@nucfLow, @nucfAll, @nucfHigh};

d.channels = {};

%d.nucPropA = {'Area [pixels]', 'Dapi sum [AU]', '# Dots per Nuclei', 'Distance between clusters'};
%d.nucPropAselChan = [0, 0, 1, 1];
%d.nucPropB = {'Area [pixels]', 'Dapi sum [AU]', '# Dots per Nuclei', 'None/Histogram'};
%d.nucPropBselChan = [0, 0, 1, 0];
%d.nucFun = {@nucpArea, @nucpDapi, @nucpNdots, []};

d.resolution = [1,1,1];

%% Gui components
%gui.win = figure('Position', [300,200,450,800], 'Menubar', 'none', ...
%    'NumberTitle','off', ...
%    'Name', 'DOTTER plot tool', ...
%    'Resize', 'On', ...
%    'WindowKeyPressFcn', @shortcuts);

gui.tabg = uitabgroup(tab,'Position',[0 0 1 1]); %, 'SelectionChangedFcn', @readsettings);
%gui.tabg = uitabgroup(gui.win,'Position',[0 0 1 1]); %, 'SelectionChangedFcn', @readsettings);

gui.tabExp =   uitab(gui.tabg, 'Title', 'NM files');
%gui.tabDot =   uitab(gui.tabg, 'Title', 'Per Dot');
%gui.tabAl  =   uitab(gui.tabg, 'Title', 'Per Cluster');
gui.tabNuc =   uitab(gui.tabg, 'Title', 'Properties');
%gui.tabField = uitab(gui.tabg, 'Title', 'Per Field');

% NM Files
gui.dataPanel  = uipanel(gui.tabExp, 'Position', [0, .1, 1, .9], 'Title', 'Data Info');
gui.DataInfo = uicontrol(gui.dataPanel, 'Style','text',...
    'String', ['No NM files loaded'],...
    'Units', 'Normalized', ...
    'Position', [0, 0, 1, 1], ...
    'HorizontalAlignment','left', ...
    'FontName', get(0,'FixedWidthFontName'));

gui.loadData = uicontrol(gui.tabExp, ...
    'Style', 'Pushbutton', ...
    'Units', 'Normalized', ...
    'Position', [.5, 0, .5, .1], ...
    'String', '2. Load NM files', ...
    'Callback', @loadNMfiles);

gui.cc = uicontrol(gui.tabExp, ...
    'Style', 'Pushbutton', ...
    'Units', 'Normalized', ...
    'Position', [.0, 0, .5, .1], ...
    'String', '1. Load Correction', ...
    'Enable', 'on', ...
    'Callback', @loadCCfile);


% Per nuclei - gui.tabNuc


%uicontrol('Style', 'Text', ...
%    'String', 'vs', ...
%    'Units', 'Normalized', ...
%    'Position', [.01, .62, .9, .1], ...
%        'Parent', gui.tabNuc);

gui.nucA = uicontrol('Style', 'listbox', 'String', {d.nucProps(:).string}, ...
    'Units', 'Normalized', ...
    'Position', [.01,.67,.49,.3], ...
    'Value', 2, ...
    'Min', 1, ...
    'Parent', gui.tabNuc, ...
    'Callback', @nucChangeSelection);

cA = uicontextmenu('Parent', tab.Parent.Parent);
gui.nucA.UIContextMenu = cA;
uimenu(cA,'Label','Info','Callback', @getInfoA);
uimenu(cA,'Label','Settings','Callback', @settingsA);
uimenu(cA,'Label','Edit','Callback', @getInfoA);

gui.nucChanA = uicontrol('Style', 'listbox', 'String', d.channels, ...
    'Units', 'Normalized', ...
    'Position', [.51,.67,.24,.3], ...
    'Value', 1, ...
    'Max', 100, ...
    'Min', 1, ...
    'Parent', gui.tabNuc);

gui.nucChanA2 = uicontrol('Style', 'listbox', 'String', d.channels, ...
    'Units', 'Normalized', ...
    'Position', [.76,.67,.24,.3], ...
    'Value', 1, ...
    'Max', 100, ...
    'Min', 1, ...
    'Parent', gui.tabNuc);


gui.nucB = uicontrol('Style', 'listbox', 'String', {d.nucProps(:).string}, ...
    'Units', 'Normalized', ...
    'Position', [.01,.35,.49,.3], ...
    'Value', 1, ...
    'Min', 1, ...
    'Parent', gui.tabNuc, ...
    'Callback', @nucChangeSelection);

cB = uicontextmenu('parent', tab.Parent.Parent);
gui.nucB.UIContextMenu = cB;
uimenu(cB,'Label','Info','Callback', @getInfoB);
uimenu(cB,'Label','Settings','Callback', @settingsB);

gui.nucChanB = uicontrol('Style', 'listbox', 'String', d.channels, ...
    'Units', 'Normalized', ...
    'Position', [.51,.35,.24,.3], ...
    'Value', 1, ...
    'Max', 100, ...
    'Min', 1, ...
    'Parent', gui.tabNuc);
gui.nucChanB2 = uicontrol('Style', 'listbox', 'String', d.channels, ...
    'Units', 'Normalized', ...
    'Position', [.76,.35,.24,.3], ...
    'Value', 1, ...
    'Max', 100, ...
    'Min', 1, ...
    'Parent', gui.tabNuc);

gui.nucFilters = uicontrol('Style', 'listbox', 'String', {d.nucFilters(:).string}, ...
    'Units', 'Normalized', ...
    'Position', [.01,.15,.99,.15], ...
    'Value', 1, ...
    'Min', 1, ...
    'Parent', gui.tabNuc);

gui.plotNuc = uicontrol('Style', 'Pushbutton', ...
    'String', 'Plot', ...
    'Units', 'Normalized', ...
    'Position', [.8,0,.2,.1], ...
    'Parent', gui.tabNuc, ...
    'Callback', @nucPlot);

gui.ExportNuc = uicontrol('Style', 'Pushbutton', ...
    'String', 'Export', ...
    'Units', 'Normalized', ...
    'Position', [.6,0,.2,.1], ...
    'Parent', gui.tabNuc, ...
    'Callback', @nucPlot);

if(exist('folder', 'var'))
    loadFolder(folder);
end

updateGUI();
nucChangeSelection();

%% Nuclei filters
    function ok = nucfAll(~,~)
        ok = 1;
    end

    function ok = nucfLow(M,N)
        m = N.metaNo;
        if(N.dapisum < M{m}.dapiTh)
            ok = 1;
        else
            ok = 0;
        end
    end

%% GUI functions


    function loadFolder(folder)
        [N, M] = df_getNucleiFromNM('folder', folder);
        if isfield(M{1}, 'pixelSize')
            d.resolution = M{1}.pixelSize;
        end
        updateGUI();
    end

    function loadCCfile(varargin)
        gui.DataInfo.String = 'waiting for CC file';
        ccFolder = df_getConfig('df_cc', 'ccfolder', '~/');
        [b, a] = uigetfile([ccFolder '*.cc'], 'Select cc file');
        if ~isnumeric(a)
            ccFile = [a b];
            applyCC();
            gui.cc.Enable = 'off';
            gui.cc.String = 'Corrections Loaded';
        else
            warning('No CC file given')
        end
        updateGUI();
    end

    function loadNMfiles(varargin)
        gui.DataInfo.String = 'waiting for NM files';
        gui.cc.Enable = 'off';
        
        % Note: if ccFile = '', nothing happens
        [N, M] = df_getNucleiFromNM('ccFile', ccFile);
        
        if numel(N) >0
            if isfield(M{1}, 'pixelSize')
                d.resolution = M{1}.pixelSize;
            else
                warning('No pixel size in meta data')
            end
            
            updateGUI();
            
        end
    end

    function updateGUI(varargin)
        if numel(N) == 0 % No nuclei available
            gui.DataInfo.String = 'No data loaded';
            gui.DataInfo.ForegroundColor = [1, 0, 0];
        else
            d.nNuclei = numel(N);
            d.nFields = numel(M);
            
            d.channels = M{1}.channels;
            
            sstring = sprintf('Channels:\n');
            for kk = 1:numel(M{1}.channels)
                sstring = [sstring sprintf(' %d: %s\n', kk, M{1}.channels{kk})];
            end
            
            
            if ~isfield(M{1}, 'dapiTh');
                dstring = sprintf('! dapi threshold not available\n');
            else
                dstring = '';
            end
            
            if isfield(M{1}, 'pixelSize');
                rstring = sprintf('Resolution: %d x %d x %d nm\n', M{1}.pixelSize(1), M{1}.pixelSize(2), M{1}.pixelSize(3));
            else
                rstring = sprintf('! pixel size not available\n');
            end
            
            uDotsMissing = 0;
            for kk = 1:numel(N)
                if ~isfield(N{kk}, 'userDots');
                    uDotsMissing = uDotsMissing + 1;
                end
            end
            
            if uDotsMissing > 0
                ustring = sprintf('\n! userDots missing in %d nuclei\n', uDotsMissing);
            else
                ustring = '';
            end
            
            istring = sprintf('\nFields: %d\nNuclei: %d\n%s\n%s%s%s', d.nFields, d.nNuclei, sstring, rstring, dstring, ustring);
            
            if numel(ccFile)>0
                istring = [istring, sprintf('\nCorrection file:\n%s\n', ccFile)];
            else
                istring = [istring, sprintf('\nNo corrections loaded')];
            end
            
            gui.DataInfo.String = istring;
            
            gui.DataInfo.ForegroundColor = [0, 0, 0];
        end
        if numel(M)>0
            d.channels = M{1}.channels;
        else
            d.channels = {};
        end
        gui.nucChanA.String = d.channels;
        gui.nucChanA.Value = 1:numel(d.channels);
        gui.nucChanB.String = d.channels;
        gui.nucChanB.Value = 1:numel(d.channels);
        gui.nucChanA2.String = d.channels;
        gui.nucChanA2.Value = 1:numel(d.channels);
        gui.nucChanB2.String = d.channels;
        gui.nucChanB2.Value = 1:numel(d.channels);
    end

    function nucPlot(varargin)
        
        s.export = 0;
        s.plot = 1;
        
        if strcmpi(varargin{1}.String, 'Export')
            s.export = 1;
            s.plot = 0;
        end
        
        m1 = gui.nucA.Value;
        m2 = gui.nucB.Value;
        
        funA = d.nucProps(m1).fun;
        settingsA = d.nucProps(m1).s;
        funB = d.nucProps(m2).fun;
        settingsB = d.nucProps(m1).s;
        
        chanA = gui.nucChanA.Value;
        chanA2 = gui.nucChanA2.Value;
        
        chanB = gui.nucChanB.Value;
        chanB2 = gui.nucChanB2.Value;
        
        funF = d.nucFilters(gui.nucFilters.Value).fun;
        
        Nselect = {};
        for kk = 1:numel(N)
            if funF(M,N{kk})
                Nselect{end+1} = N{kk};
            end
        end
        
        disp(datestr(now))
        
        if strcmpi(d.nucProps(m1).features, '0') && strcmpi(d.nucProps(m2).features, '0')
            disp('Noting to plot')
            return
        else
            if ~(strcmpi(d.nucProps(m1).features, '0') || strcmpi(d.nucProps(m2).features, '0'))
                if ~strcmpi(d.nucProps(m1).features, d.nucProps(m2).features)
                    fprintf('Can''t plot %s vs %s features\n', d.nucProps(m1).features, d.nucProps(m2).features);
                    return
                end
            end
        end
        
        fprintf('Plotting %s _vs_ %s\n', d.nucProps(m1).string, d.nucProps(m2).string);
        
        if strcmpi(d.nucProps(m1).features, d.nucProps(m2).features)
            
            A = funA(M, Nselect, chanA, chanA2, settingsA);
            B = funB(M, Nselect, chanB, chanB2, settingsB);
            
            if s.plot
                figure,
                
                plot(A,B, 'o')
                grid on
                xlabel(d.nucProps(m1).string);
                ylabel(d.nucProps(m2).string);
                nucFilterString = d.nucFilters(gui.nucFilters.Value).string;
                legend({sprintf('%d nuclei\n%s', numel(Nselect), nucFilterString)});
            end
            if s.export
                %keyboard
                T = array2table([A, B]);
                T.Properties.VariableNames = {d.nucProps(m1).xstring, d.nucProps(m2).xstring};
                [folder, name] = uiputfile('.csv');
                if ~isnumeric(name)
                    fname = [name folder];
                    fprintf('Writing to %s\n', fname);
                    writetable(T, fname);
                end
            end
            
            if dbg
                assignin('base', 'A', A);
                assignin('base', 'B', B);
            end
            return
        end
        
        if strcmpi(d.nucProps(m1).features, '0') || strcmpi(d.nucProps(m2).features, '0')
            if strcmp(d.nucProps(m1).features, 'alone')
                funA(M, Nselect, chanA, chanA2, settingsA);                
                return
            end
            if strcmp(d.nucProps(m2).features, 'alone')
                funB(M, Nselect, chanB, chanB2, settingsB);
                return
            end
            
            
            if strcmpi(d.nucProps(m2).features, '0')
                A = funA(M, Nselect, chanA, chanA2, settingsA);
                xlabelString = d.nucProps(m1).string;
                prop = m1;
            else
                A = funB(M, Nselect, chanB, chanB2, settingsB);
                xlabelString = d.nucProps(m2).string;
                prop = m2;
            end
            
            showBasicStatistics(A);
            Aplus = A(A>0);
            fprintf('And for the values >0\n')
            showBasicStatistics(Aplus);
            clear Aplus;
            
            ylabelString = '';
            nucFilterString = d.nucFilters(gui.nucFilters.Value).string;
            
            if s.plot
                
                df_histogramPlot('Data', A, ...
                    'xlabel', xlabelString, ...
                    'ylabel', ylabelString, ...
                    'title', '', ...
                    'legend', {sprintf('%d(%d) objects\n%s', sum(~isnan(A)), numel(A), nucFilterString)});
            end
            
            if s.export
                %keyboard
                T = array2table(A);
                T.Properties.VariableNames = {d.nucProps(prop).xstring};
                [folder, name] = uiputfile('.csv');
                if ~isnumeric(name)
                    fname = [name folder];
                    fprintf('Writing to %s\n', fname);
                    writetable(T, fname);
                end
            end
            
            if dbg
                assignin('base', 'A', A);
            end
            return
        end
        
    end

    function ok = nucfHigh(M,N)
        m = N.metaNo;
        if(N.dapisum < M{m}.dapiTh)
            ok = 0;
        else
            ok = 1;
        end
    end

    function nucChangeSelection(varargin)
        % Called when the nuclei property lists are changed
        
        selA = gui.nucA.Value;
        selB = gui.nucB.Value;
        
        %% Some properties can only be used alone, disable the other feature list
        %  if one of them was selected
        if strcmpi(d.nucProps(selA).features, 'alone')
            gui.nucB.Enable = 'off';            
        else
            gui.nucB.Enable = 'on';            
        end
        
        if strcmpi(d.nucProps(selB).features, 'alone')
            gui.nucA.Enable = 'off';            
        else
            gui.nucA.Enable = 'on';            
        end
        
        switch d.nucProps(selA).selChan
            case 2
                gui.nucChanA.Enable = 'On';
                gui.nucChanA2.Enable = 'On';
            case 1
                gui.nucChanA.Enable = 'On';
                gui.nucChanA2.Enable = 'Off';
            case 0
                gui.nucChanA.Enable = 'Off';
                gui.nucChanA2.Enable = 'Off';
        end
        switch d.nucProps(selB).selChan
            case 2
                gui.nucChanB.Enable = 'On';
                gui.nucChanB2.Enable = 'On';
            case 1
                gui.nucChanB.Enable = 'On';
                gui.nucChanB2.Enable = 'Off';
            case 0
                gui.nucChanB.Enable = 'Off';
                gui.nucChanB2.Enable = 'Off';
        end
    end

    function shortcuts(varargin)
        % Key strokes go here
        if strcmpi(varargin{2}.Key, 'd')
            disp('<d>, debug');
            keyboard
        end
        if strcmpi(varargin{2}.Key, 'escape')
            disp('<esc>, closing');
            close(gui.win);
        end
    end

    function test(varargin)
        disp('!')
        varargin{1}
        varargin{2}
    end

    function getInfoA(varargin)
        fName = func2str(d.nucProps(gui.nucA.Value).fun);
        fHelp = help(func2str(d.nucProps(gui.nucA.Value).fun));
        
        if strcmpi(varargin{1}.Label, 'Info')
            msgbox(sprintf('Function: %s\n\n%s', fName, fHelp));
        end
        if strcmpi(varargin{1}.Label, 'Edit')
            edit(fName)
        end
    end

    function getInfoB(varargin)
        fName = func2str(d.nucProps(gui.nucB.Value).fun);
        fHelp = help(func2str(d.nucProps(gui.nucB.Value).fun));
        msgbox(sprintf('Function: %s\n\n%s', fName, fHelp));
    end

    function settingsA(varargin)
        method = gui.nucA.Value;
        setSettings(method);
    end

    function settingsB(varargin)
        method = gui.nucB.Value;
        setSettings(method);
    end

    function setSettings(method)
        oldS = d.nucProps(method).s;
        if numel(oldS)>0
            newS = StructDlg(oldS);
            if numel(newS)>0
                d.nucProps(method).s = newS;
            else
                disp('No setting changed');
            end
        else
            msgbox('No settings');
        end
    end

    function showBasicStatistics(A)
        fprintf('%d values\n', numel(A));
        fprintf('%d values are NaN\n', sum(isnan(A)));
        fprintf('Mean: %d, std: %d\n', mean(A(~isnan(A))), std(A(~isnan(A))));
        fprintf('Min: %d, Max: %d\n', min(A(~isnan(A))), max(A(~isnan(A))));
    end

    function applyCC()
        
    end

end
