function [] = df_dotViewer()

s.debug = 0;
gui = [];
s.folder = '';
s.files = [];
s.nucleiStrings = [];
s.currentFile = -1;
s.D = []; % Loaded data
s.N = []; % Copy of current nuclei
s.fileNo = [];
s.nucleiNo = [];

s.dapiShape = [];
s.markerShapes = {'x', 'o', '<', 's', '>', 'p', '.'}; % labels
s.markerColors = {'k', 'r', 'b', 'g', 'c', 'm', 'y'}; % channels
s.markerSizes = [5, 10, 10, 10, 10, 10, 10];
s.markerVisible = ones(7,1);

if s.debug
    dbstop all
    s.folder = '/data/current_images/iEG/iEG408_170926_003_calc/';
    s.folder = '/data/current_images/iEG/iEG458_171304_004_calc/';
    close all
end

createGUI();

if numel(s.folder)>0
    loadFolder(s.folder);
    updateGUI();
end

    function loadFolder(folder)
        files = dir([folder '*.NM']);
        s.files = {};
        for kk = 1:numel(files)
            s.files{kk} = [folder filesep() files(kk).name];
        end
    end

    function loadFiles(varargin)
        s.files = uipickfiles('FilterSpec', s.folder, ...
            'Prompt', 'Select NM files(s)', 'REFilter', '.NM$');
        updateGUI();
    end

    function createGUI()
        gui.figure = figure('Name', 'df_dotViewer', 'NumberTitle', 'off', ...
            'WindowKeyPressFcn', @keyPressed);
        gui.tabs = uitabgroup('Position', [0, 0, .25, 1]);
        gui.tabNuclei = uitab(gui.tabs, 'title', 'Nuclei');
        gui.tabSettings = uitab(gui.tabs, 'title', 'Settings');
        %gui.tabInfo = uitab(gui.tabs, 'title', 'Nuc info');
        
        gui.loadFiles = uicontrol('Style', 'pushbutton', ...
            'String', 'Load Files', ...
            'Units', 'Normalized', ...
            'Position', [0, .91, 1, .08], ...
            'Parent', gui.tabNuclei, ...
            'Callback', @loadFiles);
        
        gui.nucList = uicontrol('Style', 'listbox', 'String', s.nucleiStrings, ...
            'Units', 'Normalized', ...
            'Position', [.0,0,1,.9], ...
            'Value', 1, ...
            'Max', 1, ...
            'Min', 1, ...
            'Parent', gui.tabNuclei, ...
            'Callback', @setNuclei);
        
        gui.markerTable = uitable(...
            'Units', 'Normalized', ...
            'Position', [0,.5,1,.5], ...
            'Parent', gui.tabSettings, ...
            'Visible', 'on');
        
        p = .1; % padding
        gui.plot = subplot('Position', [.4+p, 0+p, .6-2*p, 1-2*p], ...
            'Parent', gui.figure);
    end

    function keyPressed(varargin)
        
        nkey = str2num(varargin{2}.Key);
        if numel(nkey)>0
            if( (nkey)>0 && nkey<=numel(s.markerVisible) )
                s.markerVisible(nkey) = mod(s.markerVisible(nkey)+1, 2);
                plotNuclei();
                updateMarkerTable();
            end
        end
    end

    function setNuclei(varargin)
        
        item = varargin{1}.Value;
        s.fileNo = s.fileNum(item);
        s.nucleiNo = s.nucleiNum(item);
        
        if s.currentFile ~= s.fileNo
            fprintf('Loading %s\n', s.files{s.fileNo});
            s.D = load(s.files{s.fileNo}, '-mat');
            s.currentFile = s.fileNo;
        end
        
        if isfield(s.D.M, 'pixelSize')
            s.res = s.D.M.pixelSize;
        else
            warning('Using default pixel size');
            s.res = [130,130,300];
        end
        
        
        s.N = s.D.N{s.nucleiNo};
        
        updateMarkerTable();
        
        loadNuclei();
        plotNuclei();
    end

    function loadNuclei()
        % Load dots from all channels and clusters into s.D
        
        s.D.dots = cell(11,1);
        s.D.labels = cell(11,1);
        
        if ~isfield(s.N, 'userDots')
            warning('No userDots');            
            return;
        end
        
        channels = 1:numel(s.D.M.channels);
        s.channels = channels;
        dall = [];
        for kk = channels
            s.D.dots{kk} = [s.D.dots{kk} ; s.N.userDots{kk}];
            
            % Set resolution
            if numel(s.D.dots{kk})>0
                s.D.dots{kk}(:,1) = s.D.dots{kk}(:,1)*s.res(1)/1000;
                s.D.dots{kk}(:,2) = s.D.dots{kk}(:,2)*s.res(2)/1000;
                s.D.dots{kk}(:,3) = s.D.dots{kk}(:,3)*s.res(3)/1000;
                dall = [dall; s.D.dots{kk}(:,1:3)];
            end
            
            s.D.labels{kk} = [s.D.labels{kk} ; s.N.userDotsLabels{kk}];
            
        end
        
        m = mean(dall,1);
        if(numel(m) == 0)
            m = [0,0,0];
        end
        
        for kk = channels
            if numel(s.D.dots{kk})>0
                s.D.dots{kk}(:,1:3) = s.D.dots{kk}(:,1:3) - repmat(m, size(s.D.dots{kk},1), 1);
            end
        end
        
        %keyboard
        s.dapiShape = contourc(double(s.D.M.mask == s.nucleiNo), [.5, .5])';
        
        if numel(s.dapiShape)>2
            npoints = s.dapiShape(1,2);
            s.dapiShape = s.dapiShape(2:npoints, :);
            
            s.dapiShape = s.dapiShape*s.res(1)/1000;
            s.dapiShape = s.dapiShape(2:end, [2,1]);
            
            for kk = 1:2
                s.dapiShape(:,kk) = s.dapiShape(:,kk) - m(kk);
            end
            s.dapiShape = [s.dapiShape, zeros(size(s.dapiShape,1),1)];
        else
            s.dapiShape = [];
        end
    end

    function plotNuclei()
        % Load and show selected nuclei
        
        cla(gui.plot)
        
        if numel(s.D.dots) == 0
            disp('No dots to show');
            return
        end
        
        parseSettings();
        lStrings = {};
        for kk = s.channels
            for ll = 1:numel(s.labels)
                label = s.labels(ll);
                dots = s.D.dots{kk}(s.D.labels{kk}==label, :);
                
                if numel(dots)>0
                    if s.markerVisible(kk)
                        plot3(gui.plot, dots(:,2), dots(:,1), dots(:,3), ...
                            s.markerShapes{label+1}, ... % shape
                            'Color', s.markerColors{kk}, ...
                            'MarkerSize', s.markerSizes(label+1));
                        hold(gui.plot, 'on')
                        lStrings{end+1} = sprintf('%s %d', s.D.M.channels{kk}, label);
                    end
                end
            end
        end
        
        if numel(s.dapiShape)>0
            plot3(gui.plot, ...
                s.dapiShape(:,2), s.dapiShape(:,1), s.dapiShape(:,3), 'k');
        end
        
        if numel(lStrings)>0
            legend(gui.plot, lStrings);
        end
        
        view(gui.plot, 3)
        axis(gui.plot, 'equal')
        grid(gui.plot, 'on')
        xlabel(gui.plot, 'x [{\mu}m]')
        ylabel(gui.plot,'y [{\mu}m]')
        zlabel(gui.plot,'z [{\mu}m]')
    end

    function parseSettings()
        s.labels =  0:2; %unique(s.D.labels);
        s.channels = 1:numel(s.D.M.channels);
    end

    function updateGUI()
        updateNucleiStrings();
        gui.nucList.String = s.nucleiStrings;        
    end

    function updateNucleiStrings()        
        s.nucleiStrings = {};
        s.nucleiNum = [];
        s.fileNum = [];
        for kk = 1:numel(s.files)
            D = load(s.files{kk}, '-mat');
            for ll = 1:numel(D.N)
                s.nucleiStrings{end+1} = [s.files{kk} '  ' num2str(ll)];
                s.fileNum(end+1) = kk;
                s.nucleiNum(end+1) = ll;
            end
        end
    end

    function updateMarkerTable(varargin)
        % Update the table with markers and their visual properties
        
        gui.markerTable.ColumnName = {'Channel', 'On'};
        gui.markerTable.ColumnEditable = [false, false];
        gui.markerTable.Data = cell(numel(s.D.M.channels),2);
        for kk = 1:numel(s.D.M.channels)
            gui.markerTable.Data{kk,1} = s.D.M.channels{kk};
            gui.markerTable.Data{kk,2} = s.markerVisible(kk);
        end
    end

end