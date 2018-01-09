function [] = df_dotViewer()

s.debug = 1;
gui = [];
s.folder = '';
s.files = [];
s.nucleiStrings = [];
s.currentFile = -1;
s.D = []; % Loaded data
s.N = []; % Copy of current nuclei

s.markerShapes = {'o', 'x', '<', 's', '>', 'p', '.'}; % channels
s.markerColors = {'k', 'r', 'b', 'g', 'c', 'm', 'y'}; % labels


if s.debug
    dbstop all
    s.folder = '/data/current_images/iEG/iEG408_170926_003_calc/';
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
        gui.figure = figure('Name', 'df_dotViewer', 'NumberTitle', 'off');
        
        gui.loadFiles = uicontrol('Style', 'pushbutton', ...
            'String', 'Load Files', ...
            'Units', 'Normalized', ...
            'Position', [0, .91, .25, .08], ...
            'Callback', @loadFiles);
        
        gui.nucList = uicontrol('Style', 'listbox', 'String', s.nucleiStrings, ...
            'Units', 'Normalized', ...
            'Position', [.0,0,.4,.9], ...
            'Value', 1, ...
            'Max', 1, ...
            'Min', 1, ...
            'Parent', gui.figure, ...
            'Callback', @setNuclei);
        p = .1; % padding
        gui.plot = subplot('Position', [.4+p, 0+p, .6-2*p, 1-2*p]);
    end

    function setNuclei(varargin)
        
       item = varargin{1}.Value;
       fileNo = s.fileNum(item);
       nucleiNo = s.nucleiNum(item);
       
       if s.currentFile ~= fileNo
           fprintf('Loading %s\n', s.files{fileNo});
           s.D = load(s.files{fileNo}, '-mat');
           s.currentFile = fileNo;
       end
       
       if isfield(s.D.M, 'pixelSize')
           s.res = s.D.M.pixelSize;
       else
           warning('Using default pixel size');
           s.res = [130,130,300];
       end
           
       
       s.N = s.D.N{nucleiNo};       
       
       plotNuclei();       
    end

    function plotNuclei()
        cla(gui.plot)
        
        
        s.D.dots = cell(11,1);
        s.D.labels = cell(11,1);
        
        parseSettings();        
        
        if ~isfield(s.N, 'userDots')
            warning('No userDots');
            keyboard
            return;
        end                
        
        for kk = s.channels                 
            s.D.dots{kk} = [s.D.dots{kk} ; s.N.userDots{kk}];
            s.D.labels{kk} = [s.D.labels{kk} ; s.N.userDotsLabels{kk}];
        end
                                
        if numel(s.D.dots) == 0
            disp('No dots to show');
            clf(gui.plot);
            return
        end
        
        for kk = 1:s.channels
            if numel(s.D.dots{kk})>0
                s.D.dots{kk}(:,1) = s.D.dots{kk}(:,1)*s.res(1)/1000;
                s.D.dots{kk}(:,2) = s.D.dots{kk}(:,2)*s.res(2)/1000;
                s.D.dots{kk}(:,3) = s.D.dots{kk}(:,3)*s.res(3)/1000;
            end
        end        
                
        parseSettings();       
        for kk = 1:s.channels
        for ll = 1:numel(s.labels)
            label = s.labels(ll);
            dots = s.D.dots{kk}(s.D.labels{kk}==label, :);
            if numel(dots)>0
                plot3(gui.plot, dots(:,2), dots(:,1), dots(:,3), s.markerShapes{kk}, 'Color', s.markerColors{ll}); 
                hold on
            end
        end
        end
        
        view(3)
        axis equal
        grid on
        xlabel('x [{\mu}m]')
        ylabel('y [{\mu}m]')
        zlabel('z [{\mu}m]')
        
        
    end

    function parseSettings()
        s.labels =  0:11; %unique(s.D.labels);
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

end