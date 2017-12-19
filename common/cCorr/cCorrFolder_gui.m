function cCorrFolder_gui(varargin)

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
    'Position',[200 100 150 30], ...
    'Enable', 'off', ...
    'Callback', @gui_run);

GUI.pickOutFolder = uicontrol(GUI.fig, 'Style', 'pushbutton', ...
    'String', 'Cancel', ...
    'Position',[30 100 150 30], ...
    'Callback', @gui_quit);

GUI.pickOutFolder = uicontrol(GUI.fig, 'Style', 'pushbutton', ...
    'String', 'debug', ...
    'Position',[0 0 50 30], ...
    'Callback', @gui_debug);


gui_refresh();
uiwait(GUI.fig);

try
    close(GUI.fig);
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