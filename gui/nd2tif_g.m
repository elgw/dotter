function nd2tif_g(varargin)
%% GUI for conversion of microscopic images of various formats to .tif
% uses the BioFormats packags in the backend so more file formats than
% .nd2 and .czi might be supported.
%
% For each file, abc.nd2, a new folder called abc will be created in the
% output dir. The tif files will be stored there.
%
% DOTTER will only read .tif images.
%
% Please note that the images from the channel with nuclei staining must
% be named dapi_001.tif, dapi_002.tif, ...

%
% These files should change name in the future to reflect that more than
% nd2 files are supported.

% Set up variables
D.inputFiles = [];
D.readDir = df_getConfig('nd2tif_g', 'readDir', '~/Desktop/');
D.outputDir = df_getConfig('nd2tif_g', 'outputDir', '~/Desktop/');

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
        'Name', 'nd2 tif conversion', ...
        'Resize', 'On');
    tabs = uitabgroup();
    tab = uitab(tabs, 'title', 'Bioformats to tif');
    closefun = @() close(f);
end


filePanel = uipanel('Position', [0, .5, 1, .5], 'Title', 'Input/Output');
optionsPanel = uipanel('Position', [0, .1, 1, .45], 'Title', 'Options');

uicontrol('Style', 'pushbutton', ...
    'String', 'Select czi/ND2 file(s)', ...
    'Callback', @gui_selectFiles, ...%    'Enable', 'false', ...
    'Position',[30 200 150 30], ...
    'Parent', filePanel);

GUI.inFiles = uicontrol('Style', 'popupmenu', ...
    'String', ['none'], ...
    'Position',[30 150 300 30], ...
    'Parent', filePanel);

uicontrol('Style', 'pushbutton', ...
    'String', 'Select output dir', ...
    'TooltipString', 'A sub folder will be created for each nd2-file', ...
    'Callback', @gui_setOutputDir, ...%    'Enable', 'false', ...
    'Position',[30 100 150 30], ...
    'Parent', filePanel);

GUI.outputDir = uicontrol('Style', 'text', ...
    'String', D.outputDir, ...
    'Position',[30 50 340 30], ...
    'Parent', filePanel);

GUI.onlyFirst = uicontrol('Style', 'checkbox', ...
    'String', 'Only first field from each file', ...
    'Value', 0, ...
    'Position',[30 50 340 30], ...
    'Parent', optionsPanel);

uicontrol('Style', 'Text', 'String', 'Min focus-to-edge', ...
    'Position',[30 100 140 30], ...
    'Parent', optionsPanel);

GUI.focusDistance = uicontrol('Style', 'edit', 'String', '20', ...
    'Position',[30+100+50 100 100 30], ...
    'Parent', optionsPanel, ...
    'Enable', 'off');

GUI.focus = uicontrol('Style', 'popupmenu', ...
    'String', {'Don''t check focus', 'Warn about out of focus', 'Skip out of focus'}, ...
    'Position',[30 150 300 30], ...
    'Parent', optionsPanel, ...
    'Callback', @focusChange);

GUI.convert = uicontrol('Style', 'pushbutton', ...
    'String', 'Convert', ...
    'Callback', @gui_convert, ...%    'Enable', 'false', ...
    'Units', 'Normalized', ...
    'Position',[.65 0 .25 .1], ...
    'Parent', tab);

uicontrol('Style', 'pushbutton', ...
    'String', 'Close', ...
    'Callback', @closeme, ...
    'Units', 'Normalized', ...
    'Position',[.1 0 .25 .1], ...
    'Parent', tab);

uicontrol('Style', 'pushbutton', ...
    'String', 'Help', ...
    'Callback', @gui_help, ...
    'Units', 'Normalized', ...
    'Position',[.5-.25/2 0 .25 .1], ...
    'Parent', tab);


    function closeme(varargin)
        delete(tab);
        closefun()
    end

    function gui_help(varargin)
        msgbox(help('nd2tif_g'))
    end

    function gui_selectFiles(varargin)
        
        files = uipickfiles('Prompt', 'Select nd2 files', 'FilterSpec', D.readDir, 'REFilter', '\.nd2$|\.czi$');
        
        if iscell(files)
            D.inputFiles = files;
            t = files{1};
            last = find(t=='/');
            if numel(last)>0
                last = last(end);
            else
                last = numel(t);
            end
            D.readDir = t(1:last);
            %D.readDir = [D.readDir '/'];
            df_setConfig('nd2tif_g', 'readDir', D.readDir);
            refreshGUI
        end
        
    end

    function gui_setOutputDir(varargin)
        t = uigetdir(D.outputDir);
        if ischar(t)
            D.outputDir = [t '/'];
            refreshGUI();
            df_setConfig('nd2tif_g', 'outputDir', D.outputDir);
        end
    end

    function refreshGUI()
        set(GUI.outputDir, 'String', D.outputDir);
        set(GUI.inFiles, 'String', D.inputFiles);
    end

    function gui_convert(varargin)
        switch(GUI.focus.Value)
            case 1
                s.focus_check = 0;
            case 2
                s.focus_check = 1;
                s.focus_warn = 1;
                s.focus_skip = 0;
            case 3
                s.focus_check = 1;
                s.focus_warn = 0;
                s.focus_skip = 1;
        end
        s.focus_distance = str2num(GUI.focusDistance.String);        
        s.onlyFirst = get(GUI.onlyFirst, 'Value');
        s.logFileName = [tempdir() 'nd2tif_log.txt'];
        s.logFile = fopen(s.logFileName, 'w');
        
        for kk = 1:numel(D.inputFiles)            
            fprintf('nd2tif(''%s'', ''%s'')\n', D.inputFiles{kk}, D.outputDir);
            nd2tif(D.inputFiles{kk}, D.outputDir, s); % , 'onlyFirst'
        end
        
        fclose(s.logFile);
        web(s.logFileName, '-browser')
    end

    function focusChange(varargin)
        if(varargin{1}.Value == 1)
            GUI.focusDistance.Enable = 'off';
        else
            GUI.focusDistance.Enable = 'on';
        end
    end

end