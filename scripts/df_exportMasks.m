function df_exportMasks()

s.outputDir = df_getConfig('exportMasks', 'outputDir', '~/Desktop/');
s.pre = 'dapi_';
s.post = '_cmle';
s.inputFolders = {};


f = figure('Position', [0,200,400,600], 'Menubar', 'none', ...
    'NumberTitle','off', ...
    'Name', 'Export 2D masks', ...
    'Resize', 'On');

tabs = uitabgroup();
tab = uitab(tabs, 'title', 'Export 2D masks');
closefun = @() close(f);


filePanel = uipanel('Position', [0, .5, 1, .5], 'Title', 'Input/Output');
optionsPanel = uipanel('Position', [0, .1, 1, .45], 'Title', 'Options');

uicontrol('Style', 'pushbutton', ...
    'String', 'Select calc folders', ...
    'Callback', @gui_selectFolders, ...%    'Enable', 'false', ...
    'Position',[30 200 150 30], ...
    'Parent', filePanel);

GUI.inFolders = uicontrol('Style', 'popupmenu', ...
    'String', ['none'], ...
    'Position',[30 150 300 30], ...
    'Parent', filePanel);

uicontrol('Style', 'pushbutton', ...
    'String', 'Select output dir', ...
    'TooltipString', 'A sub folder will be created for each nd2-file', ...
    'Callback', @gui_setOutputDir, ...%    'Enable', 'false', ...
    'Position',[30 100 150 30], ...
    'Parent', filePanel);

uicontrol('Style', 'Text', 'String', 'Prefix', ...
    'Units', 'Normalized', ...
    'Position',[.0, .7, .5, .2], ...
    'Parent', optionsPanel);

GUI.pre = uicontrol('Style', 'Edit', 'String', s.pre, ...
    'Units', 'Normalized', ...
    'Position',[.5, .7, .5, .2], ...
    'Parent', optionsPanel);

uicontrol('Style', 'Text', 'String', 'Post', ...
    'Units', 'Normalized', ...
    'Position',[.0, .4, .5, .2], ...
    'Parent', optionsPanel)

GUI.post = uicontrol('Style', 'Edit', 'String', s.post, ...
    'Units', 'Normalized', ...
    'Position',[.5, .4, .5, .2], ...
    'Parent', optionsPanel, ...
    'Callback', @refreshGUI);

uicontrol('Style', 'Text', 'String', 'Example', ...
    'Units', 'Normalized', ...
    'Position',[.0, .1, .5, .2], ...
    'Parent', optionsPanel)

GUI.exampleName = uicontrol('Style', 'Text', 'String', '', ...
    'Units', 'Normalized', ...
    'Position',[.5, .1, .5, .2], ...
    'Parent', optionsPanel);

uicontrol('Style', 'pushbutton', ...
    'String', 'Export', ...
    'Callback', @gui_export, ...%    'Enable', 'false', ...
    'Units', 'Normalized', ...
    'Position',[.5, 0, .5, .07]);

refreshGUI();

    function gui_selectFolders(varargin)
        
        readDir = df_getConfig('exportMasks', 'readDir', '~/Desktop');
        files = uipickfiles('Prompt', 'Select calc_folders', 'FilterSpec', readDir);
        
        if iscell(files)
            s.inputFolders = {};
            for kk = 1:numel(files)
                if(isfolder(files{kk}))
                    fprintf('Folder: %s\n', files{kk});
                    s.inputFolders{end+1} = files{kk};
                end
            end
            
            if numel(s.inputFolders) > 0
                readDir = s.inputFolders{1};
            end
            
            df_setConfig('exportMasks', 'readDir', readDir);
            refreshGUI
        end
        
    end

    function gui_setOutputDir(varargin)
        t = uigetdir(s.outputDir);
        if ischar(t)
            s.outputDir = [t '/'];
            refreshGUI();
            df_setConfig('exportMasks', 'outputDir', s.outputDir);
        end
    end

    function refreshGUI(varargin)
        %s.inputFolders
        %s.outputDir
        s.pre = GUI.pre.String;
        s.post = GUI.post.String;
        GUI.exampleName.String = sprintf('%s001%s.tif', s.pre, s.post);
        if numel(s.inputFolders) == 0
            GUI.inFolders.String = {''};
        else
            GUI.inFolders.String = s.inputFolders;
        end
    end



    function gui_export(varargin)
        refreshGUI()
        
        if numel(s.inputFolders) == 0
            errordlg('No calc folders selected');
            return
        end
        
        fprintf('Looking into %d folders\n', numel(s.inputFolders));
        for ff = 1:numel(s.inputFolders)
            inFolder = [s.inputFolders{ff}];            
            fold = strsplit(inFolder, filesep());            
            fold = fold{end};
                        
            outFolder = [s.outputDir filesep() fold filesep()];
            
            
            files = dir([inFolder filesep() '*.NM']);
            if numel(files) == 0
                warning('%s has no NM files\n', inFolder);
            else
                if ~isfolder(outFolder)
                    mkdir(outFolder)
                end    
            end
            for kk = 1:numel(files)
                file= [inFolder filesep() files(kk).name];
                fprintf('%s -> %s, (%sxyz%s.tif)\n', file, outFolder, s.pre, s.post);
                nm2mask(file, outFolder, s.pre, s.post);
            end            
        end
    end
end


function nm2mask(nm_path, outdir, pre, post)
%% Export 2D mask from a DOTTER-generated NM file.
%
% Args:
%   nm_path (string): path to existing NM file.
%   outdir  (string): optional path to output directory, defaults to input
%                     directory otherwise.
%

if ~isfolder(outdir)
    mkdir(outdir);
end

if ~isfile(nm_path)
    disp('Cannot find specified file.');
    return
end

[dirpath, filename, ~] = fileparts(nm_path);

if nargin == 1
    outdir = dirpath;
end

load(nm_path, 'M', '-mat');

filename = strcat(outdir, filesep(), pre, filename, post, '.tif');

if ismember('mask', fieldnames(M))
    fprintf('Exported "mask" field from "%s"\n', nm_path);
    imwrite(uint8(M.mask), sprintf(filename), 'tiff');
    return
end

if ismember('xmask', fieldnames(M))
    fprintf('Exported "xmask" field from "%s"\n', nm_path);
    imwrite(uint8(M.xmask{1}), filename, 'tiff');
    return
end

fprintf('ERROR: no field exported from "%s"\n', nm_path);
return

end