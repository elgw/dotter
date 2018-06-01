function cCorrFolder_gui(varargin)
%% cCorrFolder_gui
%
% Correct images from shifts and chromatic aberrations measured from beads.
%
% 1. Select folder(s) that contains TIFF images.
% 2. Select the correction file to use
%
% For each input folder, the corrected images will be created in a new 
% subfolder called cc.
%
% As default, 'DAPI' is the reference channel, i.e., 'DAPI' is left
% unchanged while the other channels are deformed to map 'DAPI'.
% If 'DAPI' does not extist in the beads data, you will be queried to use
% another reference channel.
%
% Make sure not to correct the dots that you get from the images in the
% cc-folder since applying the correction twice will give you at least as 
% bad results as us you would get using no correction at all.

s.inFolder = df_getConfig('cCorrFolder_gui', 'inFolder', '~/Desktop/');
s.ccFile = df_getConfig('cCorrFolder_gui', 'ccFile', '~/Desktop/test.cc');

GUI.fig = figure('Position', [0,200,400,600], 'Menubar', 'none', ...
    'NumberTitle','off', ... % 'Color', [.8,1,.8], ...
    'Name', 'CC on folder');

% inFolder
uicontrol(GUI.fig, 'Style', 'text', ...
    'HorizontalAlignment', 'left', ...
    'String', 'Input folder:', ...
    'FontWeight', 'bold', ...
    'Position',[20 490 300 30]);

GUI.inFolderBTN = uicontrol(GUI.fig, 'Style', 'pushbutton', ...
    'String', '...', ...
    'Position', [10 450 35 30], ...
    'Callback', @gui_selectInFolder);

GUI.inFolder = uicontrol(GUI.fig, 'Style', 'text', ...
    'HorizontalAlignment', 'left', ...
    'Position',[50 450 400 30], ...
    'String', '...' );

% ccFile
uicontrol(GUI.fig, 'Style', 'text', ...
    'HorizontalAlignment', 'left', ...
    'String', 'CC file:', ...
    'FontWeight', 'bold', ...
    'Position',[20 400 300 30]);

GUI.ccFileBTN = uicontrol(GUI.fig, 'Style', 'pushbutton', ...
    'String', '...', ...
    'Callback', @gui_selectCCfile, ...
    'Position',[10 360 35 30]);

GUI.ccFile = uicontrol(GUI.fig, 'Style', 'text', ...
    'HorizontalAlignment', 'left', ...
    'Position',[50 360 400 30]);

% outFolder
uicontrol(GUI.fig, 'Style', 'text', ...
    'HorizontalAlignment', 'left', ...
    'String', 'Output folder:', ...
    'FontWeight', 'bold', ...
    'Position',[20 320 300 30]);

GUI.outFolderBtn = uicontrol(GUI.fig, 'Style', 'pushbutton', ...
    'String', '...', ...
    'Position',[10 280 35 30], ...
    'Visible', 'off', ...
    'Callback', @gui_selectOutFolder);

GUI.outFolder = uicontrol(GUI.fig, 'Style', 'text', ...
    'HorizontalAlignment', 'left', ...
    'Position',[50 280 400 30]);

% Controls
GUI.start = uicontrol(GUI.fig, 'Style', 'pushbutton', ...
    'String', 'Start', ...
    'Units', 'Normalized', ...
    'Position',[.7, 0, .3, .1], ...
    'Enable', 'off', ...
    'Callback', @gui_run);

GUI.cancel = uicontrol(GUI.fig, 'Style', 'pushbutton', ...
    'String', 'Cancel', ...
    'Units', 'Normalized', ...
    'Position',[0, 0, .3, .1], ...
    'Callback', @gui_quit);

GUI.help = uicontrol(GUI.fig, 'Style', 'pushbutton', ...
    'String', 'Help', ...
    'Units', 'Normalized', ...
    'Position',[0.4, 0, .3, .1], ...
    'Callback', @gui_help);


gui_refresh();
uiwait(GUI.fig);

try
    close(GUI.fig);
end

    function gui_help(varargin)
        hstring = help('cCorrFolder_gui');
        msgbox(hstring);
    end

    function gui_selectInFolder(varargin)
        disp('select folder')
        t = uipickfiles('FilterSpec', s.inFolder);
        if ~isnumeric(t)
            s.inFolder = t{1};
            s.outFolder = [s.inFolder '/cc'];
            df_setConfig('cCorrFolder_gui', 'inFolder', s.inFolder);
            gui_refresh();
        end
    end

    function gui_selectCCfile(varargin)
        disp('select ccFile');
        
        [folder, ~, ~] = fileparts(s.ccFile);
        t = uipickfiles('FilterSpec', [folder '/*.cc']);
        if ~isnumeric(t)
            s.ccFile = t{1};
            df_setConfig('cCorrFolder_gui', 'ccFile', s.ccFile);
            gui_refresh();
        end
    end

    function gui_quit(varargin)
        uiresume();
    end

    function gui_debug(varargin)
        keyboard
    end

    function gui_refresh()
        set(GUI.inFolder, 'String', s.inFolder);
        set(GUI.outFolder, 'String', [s.inFolder '/cc/']);
        set(GUI.ccFile, 'String', s.ccFile);
        
        if 1
            set(GUI.start, 'Enable', 'on');
        end
        
        if( exist(s.ccFile, 'file') )
            %set(GUI.ccFile, 'te');
        end
    end

    function gui_run(varargin)
        fprintf('cCorrFolder2(%s, %s)\n', s.inFolder, s.ccFile);
        df_cc_apply_image_folder(s.inFolder, s.ccFile);
        %cCorrFolder2(s.inFolder, s.ccFile);
    end

end