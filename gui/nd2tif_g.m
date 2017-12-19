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
    'Resize', 'Off');
    tabs = uitabgroup();
    tab = uitab(tabs, 'title', 'Bioformats to tif');
    closefun = @() close(f);
end

    
uicontrol('Style', 'pushbutton', ...
    'String', 'Select czi/ND2 file(s)', ...
    'Callback', @gui_selectFiles, ...%    'Enable', 'false', ...
    'Position',[30 500 150 30], ...
    'Parent', tab);

GUI.inFiles = uicontrol('Style', 'popupmenu', ...
    'String', ['none'], ...
    'Position',[30 450 300 30], ...
    'Parent', tab);

uicontrol('Style', 'pushbutton', ...
    'String', 'Select output dir', ...
    'TooltipString', 'A sub folder will be created for each nd2-file', ...
    'Callback', @gui_setOutputDir, ...%    'Enable', 'false', ...
    'Position',[30 400 150 30], ...
    'Parent', tab);

GUI.outputDir = uicontrol('Style', 'text', ...
    'String', D.outputDir, ...
    'Position',[30 350 340 30], ...
    'Parent', tab);

GUI.onlyFirst = uicontrol('Style', 'checkbox', ...
    'String', 'Only first field from each file', ...
    'Value', 0, ...
    'Position',[30 300 340 30], ...
    'Parent', tab);


GUI.convert = uicontrol('Style', 'pushbutton', ...
    'String', 'Convert', ...
    'Callback', @gui_convert, ...%    'Enable', 'false', ...
    'Position',[200 10 150 30], ...
    'Parent', tab);

uicontrol('Style', 'pushbutton', ...
    'String', 'Close', ...
    'Callback', @closeme, ...
    'Position',[30 10 150 30], ...
    'Parent', tab);

uicontrol('Style', 'pushbutton', ...
    'String', 'Help', ...
    'Callback', @gui_help, ...
    'Position',[30 50 150 30], ...
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
        onlyFirst = get(GUI.onlyFirst, 'Value');        
        for kk = 1:numel(D.inputFiles)
            fprintf('nd2tif(''%s'', ''%s'')\n', D.inputFiles{kk}, D.outputDir);
            if onlyFirst == 1
                nd2tif(D.inputFiles{kk}, D.outputDir, 'onlyFirst'); % , 'onlyFirst'
            else
                nd2tif(D.inputFiles{kk}, D.outputDir);
            end                
        end               
    end

end