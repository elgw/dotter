function B_analyze()
%{

A GUI to extract data from NM files of RNA experiments.

%}


%% Set up variables
D.folders = {}; % Folders to load (set in GUI)
D.ldapi = NaN; % Left/Low DAPI value
D.rdapi = NaN; % Right/High DAPI value
D.nCells = 0; % Number of loaded cells
D.wFolder = ''; % folder to write output to (set in GUI)
D.NMfiles = []; % -> number of fields
D.DAPIsums = []; % sum of dapi intensities -> #Cells
% 1: auto, per field, 2: auto, one for all, 3: manual, one for all
D.rnaThresholdType = 1;
D.dapiDilation = [];
D.useDebug = 0;
D.rnaSavename = '';

% Temporary variables for debugging etc
N = []; M = [];
x = []; y = []; t = [];


%% Create GUI components
GUI.fig = figure('Position', [0,200,400,600], 'Menubar', 'none', ...
    'Color', [.8,1,.8], ...
    'NumberTitle','off', ...
    'Name', 'DOTTER Analyzer', ...
    'Resize', 'off');

GUI.tabg    = uitabgroup(GUI.fig,'Position',[.0 .0 1 .95]);

GUI.tab1    = uitab(GUI.tabg,'Title','Load');
GUI.tab2    = uitab(GUI.tabg,'Title','CELLS');
GUI.tabFWHM = uitab(GUI.tabg,'Title','FWHM');
GUI.tab3    = uitab(GUI.tabg,'Title','RNA FISH');
GUI.tab4    = uitab(GUI.tabg,'Title','DNA FISH');

uicontrol(GUI.tab1, 'Style', 'text', ...
     'HorizontalAlignment', 'left', ...
    'String', 'Input:', ...
    'FontWeight', 'bold', ...
    'Position',[20 500 300 30]);

GUI.inFolders = uicontrol(GUI.tab1, 'Style', 'popupmenu', ...
    'String', ['none'], ...
    'Position',[30 450 300 30]);

uicontrol(GUI.tab1, 'Style', 'pushbutton', ...
    'String', 'Pick _calc folders', ...
    'Position',[30 410 150 30], ...
    'Callback', @gui_selectFolders);

uicontrol(GUI.tab1, 'Style', 'text', ...
    'HorizontalAlignment', 'left', ...
    'String', 'Output folder:', ...
    'FontWeight', 'bold', ...
    'Position',[20 300 300 30]);

GUI.wfolder = uicontrol(GUI.tab1, 'Style', 'text', ...
    'String', '-', ...
    'HorizontalAlignment', 'left', ...
    'Position',[30 230 300 60]);

uicontrol(GUI.tab1, 'Style', 'pushbutton', ...
    'String', 'Change', ...
    'Callback', @gui_changeWfolder, ...
    'Position',[30 190 150 30]);

uicontrol(GUI.tab1, 'Style', 'pushbutton', ...
    'String', 'Debug', ...
    'Callback', @debug, ...
    'Position',[200 10 150 30]);

GUI.ldapi = uicontrol(GUI.tab2, 'Style', 'text', ...
    'String', 'Lower DAPI:', ...
    'Position',[30 400 250 30]);
GUI.rdapi = uicontrol(GUI.tab2, 'Style', 'text', ...
    'String', 'Upper DAPI:', ...
    'Position',[30 360 250 30]);
GUI.nDAPI = uicontrol(GUI.tab2, 'Style', 'text', ...
    'String', '#cells selected:', ...
    'Position',[30 320 250 30]);
uicontrol(GUI.tab2, 'Style', 'pushbutton', ...
    'String', 'Set DAPI bounds', ...
    'Callback', @gui_setDAPI, ...
    'Position',[30 450 150 30]);

% GUI.tabFWHM
uicontrol(GUI.tabFWHM, 'Style', 'Text', 'String', 'To be implemented', ...
    'HorizontalAlignment', 'left', ...
    'Position', [30, 390. 150, 60]);

uicontrol(GUI.tab3, 'Style', 'Text', 'String', 'Threshold:', ...
    'HorizontalAlignment', 'left', ...
    'Position',[30 390 90 30]);

GUI.rnaThreshold = uicontrol(GUI.tab3, 'Style', 'popupmenu', ...
    'Position',[130 390 150 30], ...
    'String', {'Auto: per field', 'Auto: for all', 'Manual: for all', 'Manual: interactive'}, ...
    'Callback', @gui_refresh);

GUI.rnaThresholdManual = uicontrol(GUI.tab3, 'Style', 'edit', ...
    'Position',[130 350 150 30], ...
    'Enable', 'Off', ...
    'String', 'Manual threshold');

uicontrol(GUI.tab3, 'Style', 'Text', 'String', '[AU]', ...
    'HorizontalAlignment', 'left', ...
    'Position',[290 350 90 30]);

uicontrol(GUI.tab3, 'Style', 'Text', 'String', 'DAPI dilation:', ...
    'HorizontalAlignment', 'left', ...
    'Position',[30 300 90 30]);

GUI.dapiDilation = uicontrol(GUI.tab3, 'Style', 'edit', ...
    'Position',[130 300 150 30], ...
    'Enable', 'On', ...
    'String', '30');

uicontrol(GUI.tab3, 'Style', 'Text', 'String', '[pixels]', ...
    'HorizontalAlignment', 'left', ...
    'Position',[290 300 90 30]);

GUI.plotThresholds = uicontrol(GUI.tab3, 'Style', 'checkbox', ...
    'String', 'Plot dot distribution and threshold', ...
    'Position',[30 260 300 30]);

uicontrol(GUI.tab3, 'Style', 'pushbutton', ...
    'String', 'dots per cell', ...
    'Callback', @rna_dotsPerCell, ...
    'Position',[30 210 150 30]);

GIU.dotsPerCellView = uicontrol(GUI.tab3, 'Style', 'pushbutton', ...
    'String', 'Show results', ...
    'Callback', @rna_dotsPerCell_view, ...
    'enable', 'off', ...
    'Position',[200 210 150 30]);

uicontrol(GUI.tab3, 'Style', 'pushbutton', ...
    'String', 'Signal to Noise', ...
    'Callback', @rna_SNR, ...
    'Position',[30 170 150 30]);

GUI.useDebug = uicontrol(GUI.tab3, 'Style', 'checkbox', ...
    'Position',[10 10 150 30], ...
    'Value', 0);

uicontrol(GUI.tab3, 'Style', 'pushbutton', ...
    'String', 'Generate report', ...
    'Callback', @RNA_REPORT, ...
    'Position',[200 10 150 30], ...
    'Visible', 'off');

uicontrol(GUI.tab4, 'Style', 'pushbutton', ...
    'String', 'Generate report', ...
    'Callback', @DNA_REPORT, ...
    'Position',[200 10 150 30]);


    function gui_changeWfolder(varargin)
        D.wFolder = uigetdir();
        D.wFolder = [D.wFolder '/'];
        gui_refresh();
    end

    function gui_selectFolders(varargin)
        % Select what _calc folders to look in
        % changes D.folders, D.nNM, D.NMfiles
        
        D.folders = [];
        D.NMfiles = {};
        D.DAPIsums = [];
        D.nNM = 0;
        D.nCells = 0;
        
        gui_refresh();
        
        folder = df_getConfig('B_analyze', 'basedir', '~/Desktop/');
        fi = uipickfiles('Prompt', 'Select _calc folders', 'filterSpec', folder);
        wait_h = waitbar(0, 'Loading');
        folder = fi{1};
        lastSep = find(folder == filesep); lastSep=lastSep(end);
        if numel(lastSep)>0
            lastSep = lastSep(end);
            folder = folder(1:lastSep);
        end
        df_setConfig('B_analyze', 'basedir', folder);
        
        files = [];
        for kk =1:numel(fi)
            D.folders(kk).name = fi{kk};
        end
        
        for ff = 1:numel(D.folders)
            
            folder = D.folders(ff).name;
            nmfiles = dir([folder '/*.NM']);
            
            D.nNM = D.nNM + numel(nmfiles);
                        
            for nn = 1:numel(nmfiles)
                
                nmFile = nmfiles(nn).name;
                D.NMfiles{end+1} = [folder filesep nmFile];
                load([folder filesep nmFile], '-mat');
                for cc = 1:numel(N)
                    D.DAPIsums = [D.DAPIsums N{cc}.dapisum];
                end
            end
            waitbar(ff/numel(D.folders), wait_h);
        end
        
        D.wFolder = [D.folders(end).name filesep 'report' filesep];
        
        gui_refresh();
        close(wait_h);
    end

    function gui_setDAPI(varargin)
        [D.ldapi D.rdapi] = select_dapi(D.DAPIsums, D.wFolder);
        gui_refresh();
    end

    function gui_refresh(varargin)
        set(GUI.tab2, 'title', sprintf('CELLS (%d)', numel(D.DAPIsums)));
        set(GUI.wfolder, 'String', sprintf('%s', D.wFolder));
        set(GUI.ldapi, 'String', sprintf('Lower DAPI: %.0d', D.ldapi));
        set(GUI.rdapi, 'String', sprintf('Upper DAPI: %.0d', D.rdapi));
        set(GUI.nDAPI, 'String', sprintf('%d/%d cells selected', sum(D.DAPIsums>D.ldapi & D.DAPIsums<D.rdapi), numel(D.DAPIsums)));
        if numel(D.folders)>0
            set(GUI.inFolders, 'String', {D.folders.name})
        else
            set(GUI.inFolders, 'String', 'none')
        end
        D.rnaThresholdType = get(GUI.rnaThreshold, 'Value');
        if D.rnaThresholdType == 3
            set(GUI.rnaThresholdManual, 'Enable', 'On');
        else
            set(GUI.rnaThresholdManual, 'Enable', 'Off');
        end
        
        D.useDebug = get(GUI.useDebug, 'Value');
    end

    function rna_dotsPerCell(varargin)
        
        if D.useDebug
            keyboard
        end
        
        t = str2num(get(GUI.dapiDilation, 'String'));
        if isnumeric(t)
            D.dapiDilation = t;
        else
            fprintf('Invalid DAPI dilation value\n');
            return
        end
        
        %% If a global automatic threshold is needed, calculate it here
        TH = [];
        nmFile = D.NMfiles{1};
        load(nmFile, '-mat');
        Dots = cell(1,numel(M.channels));
        thlog_fd = fopen([D.wFolder 'thresholds.txt'], 'w');
        
        if (D.rnaThresholdType == 2)
            fprintff(thlog_fd, 'Finding automatic thresholds for each of the channels\n')
            for nn = 1:numel(D.NMfiles)
                nmFile = D.NMfiles{nn};
                load(nmFile, '-mat');
                for mm = 1:numel(M.channels);
                    Dots{mm} = [Dots{mm} M.dots{mm}];
                end
            end
            fprintff(thlog_fd, 'Using supplied thresholds\n');
            for mm = 1:numel(M.channels)
                [th, subs, lambda] = dotThreshold(Dots{mm}(:,4));
                TH(mm) = th;
                fprintff(thlog_fd, 'Threshold for channel %s: %f\n', M.channels{mm}, TH(mm));
            end            
            clear Dots
        end
        
        if (D.rnaThresholdType == 3)
            TH = str2num(get(GUI.rnaThresholdManual, 'String'));
            if numel(TH) ~= numel(M.channels)
                fprintff(thlog_fd, 'Wrong number of thresholds, please supply one per channel separated by commas')
                return
            else
                for mm = 1:numel(TH)
                    fprintff(thlog_fd, 'Threshold for channel %s: %f\n', M.channels{mm}, TH(mm))
                end
            end        
        end
        
        %% Extract all the data
        DH = [];
        Hall = cell(numel(M.channels), 3); % All histograms
        Tall = cell(numel(M.channels), 3); % All tables
        % for each NM file
        if ~exist(D.wFolder, 'dir')
            mkdir(D.wFolder)
        end
        
        log_fd = fopen([D.wFolder 'fileNames.txt'], 'w');
        for nn = 1:numel(D.NMfiles)
            
            nmFile = D.NMfiles{nn};
            fprintff(log_fd, 'Loading file %d: %s\n', nn, nmFile);
            if D.rnaThresholdType == 1
                fprintf(thlog_fd, 'File %d: %s\n', nn, nmFile);
            end
            load(nmFile, '-mat');
            
            % Subselect nuclei that match the DAPI limits
            mask_selection = M.mask;
            
            for dd = 1:numel(N)
                if N{dd}.dapisum < D.ldapi || N{dd}.dapisum > D.rdapi
                    mask_selection(mask_selection == dd) = 0;
                end
            end
            
            [masks, maskNames, dEdge] = dotter_generateMasks(mask_selection, D.dapiDilation);
            
            masks = masks(1:end-1);
            maskNames = maskNames(1:end-1);
            
            for cc = 1:numel(M.channels)
                
                channel = M.channels{cc};
                fprintf('Using channel #%d : %s\n', cc, channel);
                
                if ~isfield(M, 'dots')
                    disp('No dots to load!')
                    % See code in rnaSlide to put them there, or run it for this data
                    % set
                    % Probably you want to run A_dots again
                end
                
                P = M.dots{cc};
                dog = P(:,4);
                if numel(TH) == 0
                    if D.rnaThresholdType == 4
                        %% Ask for a manual threshold
                        
                        th = dotThreshold(M.dots{cc}(:,4));
                        fig = dotterSlide(df_readTif(strrep(M.dapifile, 'dapi', M.channels{cc})), M.dots{cc});
                        uiwait(fig)
                        th = str2double( ...
                            inputdlg('Enter threshold', 'Title', 1, {num2str(th)}));                        
                        
                    else                        
                        [th] = dotThreshold(dog);
                    end
                    fprintff(thlog_fd, ' Found threshold: %f for %s\n', th, channel);
                else
                    th = TH(cc);
                end                
                
                if(get(GUI.plotThresholds, 'Value'))
                    fig_th = figure;
                    histogram(P(:,4));
                    ax  = get(fig_th, 'CurrentAxes');
                    set(ax, 'YScale', 'log')
                    hold on
                    ax = axis;
                    plot([th, th], ax(3:4))
                    nmFileShort = D.NMfiles{nn};
                    nmFileShort= nmFileShort(end-5:end-3);
                    dprintpdf(sprintf('%sth_%s_%s.pdf', D.wFolder, nmFileShort, channel), 'fig', fig_th, 'w', 20, 'h', 10);
                    close(fig_th);
                end
                
                Pth = P(P(:,4)>=th, :);
                
                % For each mask ...                                
                for ma = 1:numel(masks)
                    fprintf(' Mask: %s\n', maskNames{ma});
                    m = interpn(masks{ma}, Pth(:,1), Pth(:,2), 'nearest');
                    Pma = Pth(m>0, :); % The dots falling into some region of the mask
                    fprintf(' Number of dots: %d\n',sum(m>0));
                    nCells = max(masks{ma}(:));
                    fprintf(' Number of regions: %d\n', nCells);
                    fprintf(' Dots per region: %d\n',sum(m>0)/nCells);
                                        
                    
                    % Create a table for export [ Pma m nmFile]
                    Tall{cc,ma} = [Tall{cc,ma} ; ...
                                    [Pma, m(m>0), repmat(nn, size(Pma,1), 1)]];
                    
                                                
                    % accumulate histograms per cc and ma
                    H = zeros(10000,1);
                    for hh = 1:nCells
                        index = sum(m==hh);
                        if (index+1)>numel(H) % dynamically grow H
                            H(index+1) = 1;
                        else
                            H(index+1) = H(index+1)+1;
                        end
                    end
                    if numel(Hall{cc,ma}) == 0
                        Hall{cc, ma} =  H;    
                    else
                        Hall{cc, ma} = Hall{cc, ma} + H;
                    end
                end                
            end                        
        end              
        fclose(log_fd);
        fclose(thlog_fd);
        
        D.rnaSavename = [D.wFolder 'B_analyze_rna.mat'];
        fprintf('Saving to %s\n', D.rnaSavename);
        channelNames = M.channels;
        save(D.rnaSavename, 'Hall', 'Tall', 'D', 'maskNames', 'channelNames')
        set(GIU.dotsPerCellView, 'enable', 'on');
        fprintf('done\n')
        
        % Export data
        % for cc and ma
        
    end

    function rna_dotsPerCell_view(varargin)
        fprintf('calling B_cells_view_rna(%s)\n', D.rnaSavename)
        B_cells_view_rna(D.rnaSavename);
        
    end

    function debug(varargin)
        keyboard
    end

    function rna_SNR(varargin)
        SNR = []; % One measurement per field.
        
        
        %% for each NM file
        for nn = 1:numel(D.NMfiles)
            
            nmFile = D.NMfiles{nn};
            load(nmFile, '-mat');
            
            if ~isfield(M, 'dots')
                disp('No dots to load!')
                % See code in rnaSlide to put them there, or run it for this data
                % set
            end
            
            if ~exist('channel', 'var')
                if numel(M.channels)>1
                    channelNo = listdlg('PromptString', 'Select a channel', 'ListString', M.channels);
                else
                    channelNo = 1;
                end
                channel = M.channels{channelNo};
                fprintf('Using channel #%d : %s\n', channelNo, channel);
            end
            
            P = M.dots{channelNo};
            d = P(:,4);
            th = dotThreshold(d);
            DH = d(d>=th);
            DL = d(d<=th);
            SNR = [SNR (mean(DH)-mean(DL))/std(DL)];
        end
        
        fprintf('Mean snr: %f\n', mean(SNR));
        figure, histogram(SNR)
        title('SNR per field')
        
        
    end

gui_refresh();
uiwait(GUI.fig);

try
    close(GUI.fig);
end

end

