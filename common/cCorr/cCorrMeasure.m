function cCorrMeasure()
%%
% This interface exists as a convenience for calling df_cc.
% Here you specify what image folder and what field of view (FOV)
% that should be used to generate a correction file (.cc) that later on
% can be used to correct dots or images for shifts and chromatic
% aberrations.
%
% Parameters:
% N -- The number of dots to use from each channel.
% D -- the maximal distance, in pixels between dots from different channels
%      that potentially could be the same bead. Typically the default is
%      good enough. If that does not work at all, try to increase the
%      value.
% R -- the reference channel. All other channels will be corrected to match
%      this one. Preferably you should use the best possible channel as a
%      reference, i.e., the one with the brightest dots.
%
% Usage:
% 1. Set the parameters.
% 2. Fit the dots with the 'Fit Dots' button
% 3. Press 'Try/Export' to export the corrections and get some
%    statistics. If you are not happy, go back to 1.
%
% Warning:
% - Only load images with beads here since this function might
% overwrite/corrupt some of the data in the NM files for other images.

% To do:
% - Reset visibility of some buttons when changing field.
% - Ask for pixel size
%

%% All settings go into the struct s
s.folder = '';
s.refchannel = '';
s.maxDist = 10; % pixels
s.vChanNo = []; % current channel to view

s.field = 1;
s.fieldString = '001'; % updated by @gui_setField

s.fileNames = [];
s.th = []; % Threholds
s.N = []; % Number of dots to use from channel
s.mask = [];
s.F = [];
s.CX = [];
s.CY = [];
s.new = 1;

%% Create GUI components
GUI.fig = figure('Position', [0,200,400,600], 'Menubar', 'none', ...
    'NumberTitle','off', ...
    'Name', 'CC Analyzer', ...
    'Resize', 'Off');
%    'Color', [.8,1,.8], ...

uicontrol(GUI.fig, 'Style', 'text', ...
    'HorizontalAlignment', 'left', ...
    'String', 'From beads to calibration', ...
    'FontWeight', 'bold', ...
    'Units', 'Normalized', ...
    'Position',[0 .9 1 .1]);

uicontrol(GUI.fig, 'Style', 'text', ...
    'HorizontalAlignment', 'left', ...
    'String', 'Input:', ...
    'FontWeight', 'bold', ...
    'Position',[20 500 300 30]);

GUI.pickFolder = uicontrol(GUI.fig, 'Style', 'pushbutton', ...
    'String', 'Pick tif folder', ...
    'Position',[30 450 150 30], ...
    'Callback', @gui_selectFolder, ...
    'TooltipString', sprintf('Select a folder with tif-images of beads'));

GUI.folder = uicontrol(GUI.fig, 'Style', 'text', ...
    'HorizontalAlignment', 'left', ...
    'Position',[30 450 350 30], ...
    'Visible', 'off');

GUI.setField  = uicontrol(GUI.fig, 'Style', 'popupmenu', ...
    'String', ['fields ...'], ...
    'Position',[30 400 150 30], ...
    'Visible', 'off', ...    
    'Callback', @gui_setField, ...
    'TooltipString', sprintf('Set which field of view to use'));

GUI.channels  = uicontrol(GUI.fig, 'Style', 'popupmenu', ...
    'String', ['channels ...'], ...
    'Position',[30 370 150 30], ...
    'Visible', 'off');

GUI.viewChannel  = uicontrol(GUI.fig, 'Style', 'pushbutton', ...
    'String', 'View Channel', ...
    'Position',[200 370 150 30], ...
    'Visible', 'off', ...
    'Callback', @gui_viewChannel, ...
    'TooltipString', sprintf('Shows the channel selected above\nalong with detected dots.'));

GUI.showN = uicontrol(GUI.fig, 'Style', 'text', ...
    'String', 'N:', ...
    'Position',[30 320 30 30], ...
    'Visible', 'off', ...
    'TooltipString', sprintf('Number of dots to use\n more dots is slower but will take a longer time\nMinimum 10 are required'));

GUI.setN  = uicontrol(GUI.fig, 'Style', 'edit', ...
    'String', 'View Channel', ...
    'Position',[70 320 150 30], ...
    'Visible', 'off');

GUI.showD = uicontrol(GUI.fig, 'Style', 'text', ...
    'String', 'D:', ...
    'Position',[30 280 30 30], ...
    'Visible', 'off', ...
    'TooltipString', sprintf('Clustering distance.\nDots further apart than D pixels \nare considered as different beads'));

GUI.setD  = uicontrol(GUI.fig, 'Style', 'edit', ...
    'String', '10', ...
    'Position',[70 280 150 30], ...
    'Visible', 'off');

GUI.showReferenceChannel = uicontrol(GUI.fig, 'Style', 'text', ...
    'String', 'R:', ...
    'Position',[30 240 30 30], ...
    'Visible', 'off' , ...
    'TooltipString', sprintf('Reference channel to morph the other channels to.\nThis channel will not be changed by the\nchromatic correction'));

GUI.referenceChannel  = uicontrol(GUI.fig, 'Style', 'popupmenu', ...
    'String', '', ...
    'Position',[70 240 150 30], ...
    'Visible', 'off' );

GUI.showDots  = uicontrol(GUI.fig, 'Style', 'pushbutton', ...
    'String', 'Show Dots', ...
    'Position',[30 200 150 30], ...
    'Visible', 'off', ...
    'Callback', @gui_showDots, ...
    'TooltipString', sprintf('Shows dots from all channels before correction\n'));

GUI.showSelection  = uicontrol(GUI.fig, 'Style', 'pushbutton', ...
    'String', 'Make Selection', ...
    'Position',[30 165 150 30], ...
    'Visible', 'off', ...
    'Callback', @gui_makeSelection, ...
    'Enable', 'Off', ...
    'TooltipString', sprintf('Not implemented'));

GUI.fitDots  = uicontrol(GUI.fig, 'Style', 'pushbutton', ...
    'String', 'Fit Dots', ...
    'Position',[30 130 150 30], ...
    'Visible', 'off', ...
    'Callback', @gui_fitDots, ...
    'TooltipString', sprintf('Localize dots with subpixel precision\n will take some time\nrequres that the c-functions are compiled'));

GUI.tryCC  = uicontrol(GUI.fig, 'Style', 'pushbutton', ...
    'String', 'Try/Export', ...
    'Position',[30 95 150 30], ...
    'Visible', 'off', ...
    'Callback', @gui_tryCC, ...
    'TooltipString', sprintf('See how errors are distributed after fitting and correction'), ...
    'Enable', 'Off');

GUI.export  = uicontrol(GUI.fig, 'Style', 'pushbutton', ...
    'String', 'Export', ...
    'Position',[190 95 150 30], ...
    'Visible', 'off', ...
    'Callback', @gui_export, ...
    'TooltipString', sprintf('Exports correction files to a folder\nthe final step of this tool'));

    function gui_showDots(varargin)
        s.N = str2num(GUI.setN.String);        
        cCorrMeasure_showDots(s);
    end

    function gui_makeSelection(varargin)
        mask = zeros(size(s.I{1}, 1), size(s.I{1}, 2));
        f2 = figure;
        markers = 'ox+*sdv^<>ph';
        N = str2num(get(GUI.setN, 'String'));
        for kk = 1:numel(s.chan)
            D = s.D{kk};
            D = D(D(:,4)>s.th(kk), :);
            plot(D(1:N,1), D(1:N,2), markers(kk));
            hold all
        end
        mask = get_nuclei_manual(mask, []);
        
    end

    function gui_showSelection(varargin)
        f2 = figure;
        markers = 'ox+*sdv^<>ph';
        for kk = 1:numel(s.chan)
            D = s.D{kk};
            D = D(D(:,4)>s.th(kk), :);
            plot3(D(:,1), D(:,2), D(:,3), markers(kk));
            hold all
        end
        legend(s.chan);
        set(GUI.fitDots, 'Visible', 'On');
        axis equal
    end

    function gui_viewChannel(varargin)
        s.vChanNo = get(GUI.channels, 'value');
        dotterSlide(s.I{s.vChanNo}, s.D{s.vChanNo});
    end


uicontrol(GUI.fig, 'Style', 'pushbutton', ...
    'String', 'Debug', ...
    'Units', 'Normalized', ...
    'Position',[1/16 .01 1/4 .1], ...
    'Callback', @gui_debug);

uicontrol(GUI.fig, 'Style', 'pushbutton', ...
    'String', 'Help', ...
    'Units', 'Normalized', ...
'Position',[2/16+1/4 .01 1/4 .1], ...
    'Callback', @gui_help);

uicontrol(GUI.fig, 'Style', 'pushbutton', ...
    'String', 'Leave', ...
    'Units', 'Normalized', ...
'Position',[3/16+1/2 .01 1/4 .1], ...
    'Callback', @gui_quit);

    function gui_tryCC(varargin)
        %% Tries the CC correction based on the selected dots
        
        % Save .mat file with unfitted dots
        %ccFile = [tempdir() 'temp.cc'];
        
        
        N = str2num(get(GUI.setN, 'String'));
        assert(N>0);
        
        F = s.F;
        for kk = 1:numel(F)
            F{kk} = F{kk}(1:N,1:3);
        end
        
        if 0 % debug
            figure, plot3(F{1}(:,1), F{1}(:,2), F{1}(:,3), 'ro')
            hold on
            plot3(F{2}(:,1), F{2}(:,2), F{2}(:,3), 'ks')
        end
        
        if s.new == 1            
            t = df_cc('getDefaults');
            % save temp.mat
            df_cc('dots', F, 'channels', s.chan, 'settings', t);                                                                
        else
        
        folder = s.folder;
        chan = s.chan;
        refchan = s.chan(get(GUI.referenceChannel, 'Value'));
        fprintf('Reference channel: %s\n', refchan);
        
        save(ccFile, 'F', 'chan', 'N', 'folder', 'refchan');
        
        Q = [];
        D = str2num(get(GUI.setD, 'String'));
        
        s.refchan = s.chan{get(GUI.referenceChannel, 'Value')};
        
        E = [];
                        
        for kk = 1:numel(chan)            
            fprintf('Channel: %s\n', s.chan{kk});
            [Q{kk} Cx{kk} Cy{kk}, dz(kk), E{kk}] = cCorrI(F{kk}, chan{kk}, s.refchan, ccFile, D);
        end
        
        s.Cx = Cx;
        s.Cy = Cy;
        s.dz = dz;        
                
        figure;
        markers = 'ox+*sdv^<>ph';
        for kk = 1:numel(s.chan)
            D = Q{kk};
            plot(D(:,1), D(:,2), markers(kk));
            hold all
            title('Dots, CC applied')
        end
        legend(s.chan);
        axis equal
        grid on
        
        
        figure
        for kk = 1:numel(E)
            subplot(1,numel(E), kk)
            hist(E{kk})
            legend({sprintf('mean: %.3f', mean(E{kk}))})
            title(chan{kk})
            xlabel('{\Delta}xy [pixels]')
        end        
        end
        
        %set(GUI.export, 'enable', 'on');
        
    end

    function gui_selectFolder(varargin)
        %% Select folder with tif images
        folder = df_getConfig('cCorrMeasure', 'folder', '~/Desktop/');
        folder = uigetdir(folder, 'Select folder with tif images');
        if isnumeric(folder)
            disp('No folder selected, quiting')
            return
        end
        if(~strcmp(folder(end), '/'))
            folder = [folder '/'];
        end
        
        df_setConfig('cCorrMeasure', 'folder', folder);
        
        fprintf('Using folder: %s\n', folder);
        s.folder = folder;
        set(GUI.pickFolder, 'visible', 'off');
        set(GUI.folder, 'visible', 'on');
        set(GUI.setField, 'visible', 'on');
        %set(GUI.export, 'visible', 'on');        
        %set(GUI.export, 'enable', 'off');
        
        gui_detectChannels();
        
        gui_refresh();
    end

    function gui_detectChannels(varargin)
        %% Detect channels
        
        
        channels = dir([s.folder '*001.tif']);
        
        fprintf('Found %d channels\n', numel(channels));
        for kk = 1:numel(channels)
            s.chan{kk} = strrep(channels(kk).name, '_001.tif', '');
            fprintf('Channel %d : %s\n', kk, s.chan{kk});
        end
        
        nFields = numel(dir([s.folder '*' s.chan{kk} '*.tif']));
        
        fieldStrings = {};
        for kk = 1:nFields
            fieldStrings{kk} =  sprintf('Field %03d', kk);
        end
        
        GUI.setField.String = fieldStrings;
        GUI.setField.Visible = 'On';

        set(GUI.channels, 'Visible', 'On');
        set(GUI.viewChannel, 'Visible', 'On');
        gui_refresh();
        
        gui_loadImages()
        
        %set(GUI.showSelection, 'Visible', 'on');
        set(GUI.showDots, 'Visible', 'on');
        
        % Add reference channels to the list
        set(GUI.referenceChannel, 'String', s.chan);
        clr = GUI.referenceChannel.ForegroundColor;
        
        GUI.referenceChannel.ForegroundColor = 'red';
        for cc = 1:numel(s.chan)
            if(strcmpi(s.chan{cc}, 'dapi'))
                set(GUI.referenceChannel, 'String', s.chan{cc});
                % Revert to default if dapi found
                GUI.referenceChannel.ForegroundColor = clr; 
            end
        end
                
        set(GUI.referenceChannel, 'Visible', 'on');
        set(GUI.showReferenceChannel, 'Visible', 'on');
        
        gui_refresh();        
    end

    function gui_setField(varargin)
       gui_refresh();       
       %keyboard
       s.field = GUI.setField.Value;
       s.fieldString = sprintf('%03d', s.field);       
       gui_loadImages();
    end

    function gui_loadImages()
        % Load images for the current field into s.I
        % load dots from NM file if exist
        %
        % Called 
        % - when changing field
        % - from gui_detectChannels
        
        w = waitbar(0, 'Loading images and detecting dots');
        s.D = cell(1,numel(s.chan));
        
       
        
        for kk = 1:numel(s.chan)
            
            waitbar((2*kk-1)/(numel(s.chan)*2));
            imFile = [s.folder s.chan{kk}, '_' s.fieldString '.tif'];
            s.I{kk} = df_readTif(imFile);
            if kk == 1 % create a zero-mask, should not be used
                s.mask = zeros(size(s.I{kk},1), size(s.I{kk},2));
            end
            waitbar((2*kk)/(numel(s.chan)*2));
            
            N = {};
            M = {};
            
            % See if there is an NM file available with the dots?
            nmFile = im2nm_name(imFile);
            if exist(nmFile, 'file')
                NM = load(nmFile, '-mat');
                N = NM.N;
                M = NM.M;
                
                if(isfield(M, 'dots'))
                    if numel(M.dots)>=kk
                        if numel(M.dots{kk})>0
                            s.D{kk} = M.dots{kk};
                        end
                    end
                end
            end
            
            if numel(s.D{kk}) == 0
                %keyboard
                %s.D{kk} = dot_candidates(s.I{kk});%
                
                dotSettings = df_getDots('getDefaults', 'voxelSize', [130,130,300], 'lambda', df_getEmission(s.chan{kk}));
                s.D{kk} = df_getDots('Image', s.I{kk}, 'settings', dotSettings);
                
                M.dots{kk} = s.D{kk};
                [pathstr,~,~] = fileparts(nmFile);
                if ~exist(pathstr, 'dir')
                    mkdir(pathstr)
                end
                save(nmFile, 'N', 'M');
            end
            
            [th] = dotThreshold(s.D{kk}(:,4));
            s.th(kk) = 0*th;
            
            s.N(kk) = sum(s.D{kk}(:,4)>s.th(kk));
        end
        
        close(w)
        set(GUI.setN, 'String', num2str(min(min(s.N), 200)));
        
        set(GUI.setD, 'Visible', 'On');
        set(GUI.setN, 'Visible', 'On');
        set(GUI.showN, 'Visible', 'On');
        set(GUI.showD, 'Visible', 'On');
        set(GUI.fitDots, 'Visible', 'On');
        set(GUI.tryCC, 'Visible', 'On');
    end

    function gui_fitDots(varargin)
        %% Fit dots
        % Fit in all channels and only use the dots that are good in all channels.
        % Note: this assumes that the dots are somewhat not to far away and that
        % the fitting can start from the same location.
        % An alternative would be to find the closest strong dot in each of the
        % other channels.
                        
        dotFittingSettings = dotFitting(); % get default settings
        dotFittingSettings.useClustering = 0;
        dotFittingSettings.sigmafitXY = 1.4;
        dotFittingSettings.sigmafitZ = 1.6;
        dotFittingSettings.fitSigma = 0;
                        
        w = waitbar(0, 'Fitting Dots');
        N = str2num(get(GUI.setN, 'String'));
        for kk = 1:numel(s.chan)
            s.F{kk} = dotFitting(double(s.I{kk}), s.D{kk}(1:N, :), dotFittingSettings);
            waitbar(kk/numel(s.chan));
        end
        close(w)                
        GUI.tryCC.Enable = 'On';
    end

    function gui_export(varargin)
        
        %% Save a resource file for cCorr
        savedir = df_getConfig('cCorrMeasure', 'savedir', '~/Desktop/');
        savedir = uigetdir(savedir, 'Where to save the cc file?');
        savedir = [savedir '/'];
        if ~isnumeric(savedir)
            df_setConfig('cCorrMeasure', 'savedir', savedir);
            savename = sprintf('%scc_%s.mat', savedir, datestr(now, 'yyyymmdd'));
            savename2 = sprintf('%scc2_%s.mat', savedir, datestr(now, 'yyyymmdd'));
            fprintf('Saving to %s\n', savename);
            F = s.F;
            N = str2num(get(GUI.setN, 'String'));
            P = s.D;
            for kk = 1:numel(P)
                P{kk} = P{kk}(1:N,:);
            end
            
            folder = s.folder;
            chan = s.chan;
            refchan = s.chan(get(GUI.referenceChannel, 'Value'));
            save(savename, 'F', 'P', 'chan', 'N', 'folder', 'refchan');
            if numel(s.dz)>0
                disp('Writing coefficients')
                Cx = s.Cx;
                Cy = s.Cy;
                dz = s.dz;
                save(savename2, 'Cx', 'Cy', 'dz','chan');
            end
            
            disp('Done');
        end
    end

    function gui_refresh()
        
        set(GUI.folder, 'String', s.folder);
        if isfield(s, 'chan')
            set(GUI.channels, 'String', s.chan);
        end
    end

    function gui_quit(varargin)
        uiresume();
    end

    function gui_debug(varargin)
        keyboard
    end

    function gui_help(varargin)
       h = help('cCorrMeasure');
       m = msgbox(h);
       uiwait(m)
    end

gui_refresh();
uiwait(GUI.fig);

try
    close(GUI.fig);
end

end

