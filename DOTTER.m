function DOTTER()
%% DOTTER - Dot localization and processing
%
%	Brings up the main menu for DOTTER.
%   Documentation is available via the GUI.
%

%   This GUI is stateless. I.e., working folder/file has to be specified
%    for each action.
%   It is not completely safe to run multiple copies simultaneously since
%   some temporary files as well as the configuration files are shared.

% should be set in startup.m
DOTTER_PATH = getenv('DOTTER_PATH');

if strcmp(DOTTER_PATH, '')
    warning('DOTTER is not properly configured.');
    disp('startup.m has to be run before DOTTER.m');
    disp('Please add the folder containing dotter to the paths')
    return
end

%% Turn on logging using MATLAB's diary()
logfile = [tempdir() 'dotter_log.txt'];
logfile_last = [tempdir() 'dotter_log_last.txt'];
try
    movefile(logfile, logfile_last);
catch
    % No old logfile
end

%logf = fopen(logfile, 'w');
%fprintf(logf, '');
%fclose(logf);

diary(logfile);
% will be turned off when the DOTTER window is closed

% Only one window allowed at the same time
h = findall(0,'tag','DOTTER');

if numel(h)>0
    disp('Already open')
    figure(h);
    return
end

helpFile = [getenv('DOTTER_PATH') 'HELP.html'];
chFile = [getenv('DOTTER_PATH') 'README.html'];
bugsFile = [getenv('DOTTER_PATH') 'BUGS.html'];

helpFile = ['file://' unRelFileName(helpFile)];
chFile = ['file://' unRelFileName(chFile)];
bugsFile = ['file://' unRelFileName(bugsFile)];

fprintf('DOTTER version %s\n<a href="%s">Changes</a>|<a href="%s">Bugs</a>|<a href="%s">Help</a>\n', ...
    df_version(), chFile, bugsFile, helpFile);
fprintf('<a href="https://bienkocrosettolabs.org/">BiCroLabs</a> 2015-2019\n');
disp(['Session started ' datestr(datetime('now'),'yyyy-mm-dd HH:MM:ss')])
disp(['MATLAB ' version()])


if exist('logo.jpg', 'file')
    I = imread('logo.jpg');
else
    disp('''logo.jpg'' could not be loaded from disk. Please verify the installation!')
    return
end

res = get(0, 'ScreenSize');
% xres = res(3);
yres = res(4);

pos = df_getConfig('DOTTER', 'winPos', []);
if numel(pos) == 0
    pos = [0,yres-100,469,75];
else
    pos(3) = 469;
    pos(4) = 75;
end

gui.win = figure('Position', pos, 'Menubar', 'none', ...
    'NumberTitle','off', ...
    'Name', sprintf('DOTTER v. %s ⸺ BiCroLabs 2015-2018', df_version()), ...
    'MenuBar', 'None', ...
    'Color', [1,1,1], ...
    'Resize', 'Off', ...
    'Tag', 'DOTTER', ...
    'WindowKeyPressFcn', @shortcuts, ...
    'DeleteFcn', @gui_delete);

gui.tabs = uitabgroup();
gui.tabs.Visible = 'off';

set(0, 'PointerLocation', [pos(1), pos(2)]);

% gui.win.WindowButtonDownFcn = @switchDisplay;

if nargout > 0
    h = gui.win();
end

subplot('Position', [0,0,1,1])
img = imshow(I);
stext = text(0,0, 'No info from git available', 'Interpreter', 'None');
stext.Visible = 'Off';

mDOTTER = uimenu(gui.win, 'Label', 'DOTTER');
mMAINT = uimenu(mDOTTER, 'Label', 'Maintenance');

uimenu(mMAINT, 'Label', 'Compile C functions', 'Callback', @compile);
uimenu(mMAINT, 'Label', 'Update', 'Callback', @update);
uimenu(mMAINT, 'Label', 'Check if there is a new version', 'Callback', @checkVersion);
uimenu(mMAINT, 'Label', 'Run self-tests', 'Callback', @tests);

uimenu(mDOTTER, 'Label', 'Open Run Log files', 'Callback', @openLogs);
uimenu(mDOTTER, 'Label', 'Help/What''s new?', 'Callback', @openChangelog);
uimenu(mDOTTER, 'Label', 'Quit', 'Callback', @quit,...
    'Separator', 'On', 'Accelerator', 'Q');

mND = uimenu(gui.win, 'Label', 'Images');
uimenu(mND, 'Label', 'nd2/czi -> tif', 'Callback', @convert_nd2, ...
    'Accelerator', 'T');
uimenu(mND, 'Label', 'Open and view a tif-image', 'Callback', @open_tif);
uimenu(mND, 'Label', 'Relocate TIF', 'Callback', @relocate);

mCC = uimenu(gui.win, 'Label', 'CC');
uimenu(mCC, 'Label',  'Measure chromatic aberrations', 'Callback', @CA_scripts);
uimenu(mCC, 'Label',  'View cc file', 'Callback', @CC_open);
uimenu(mCC, 'Label',  'Apply CC on images', 'Callback', @CA_folder);

mDots = uimenu(gui.win, 'Label', 'Dots');
uimenu(mDots, 'Label', 'Get threshold suggestion', 'Callback', @run_dotThreshold);
uimenu(mDots, 'Label', 'Manage colocalized dots', 'Callback', @run_manageOverlapping);

mCells = uimenu(gui.win, 'Label', 'Detect');
uimenu(mCells, 'Label', 'Find nuclei and dots (image -> calc)', 'Callback', @run_A_cells, ...
    'Accelerator','F');
%uimenu(mCells, 'Label', 'Get nuclei DAPI intensity and area from NE files', ...
%    'Callback', @dapiDistribution, ...
%    'Separator','on');
%uimenu(mCells, 'Label', 'Integral Intensity in nuclei -- all channels', 'Callback', @integralIntensity);
uimenu(mCells, 'Label', 'Add missing dapiTh and pixelSize for calc folder', 'Callback', @setDapiThFolder);


mDots = uimenu(gui.win, 'Label', 'Select');
uimenu(mDots, 'Label', 'View/Select DNA-FISH dots by threshold (->UD)', 'Callback', @run_setUserDots, ...
    'Accelerator','U');

%uimenu(mDots, 'Label', 'Pairwise Distances for UserDots', 'Callback', @run_pwd);
%uimenu(mDots, 'Label', 'N Clusters UserDots', 'Callback', @run_nkmeans);
%uimenu(mDots, 'Label', 'Get fwhm for strongest dot per nuclei', 'Callback', @run_getFWHMstrongest);


mDNA = uimenu(gui.win, 'Label', 'Measure');
uimenu(mDNA, 'Label', 'Basic plots', 'Callback', @run_plot);
%uimenu(mDNA, 'Label', 'DNA-FISH dots overlap', 'Callback', @run_DNA_ChannelOverlapAnalysis);
%uimenu(mDNA, 'Label', '3D visualization of a nuclei');
%uimenu(mDNA, 'Label', 'Dots Per Nuclei [UD]', 'Callback', @dotsPerNuclei);

%uimenu(mDNA, 'Label', 'Manually screen nuclei', 'Callback', @manuallyPerNuclei);


uimenu(mDNA, 'Label', 'Export dots', 'Callback', @run_exportDots, ...
    'Separator','on');
uimenu(mDNA, 'Label', 'Export 2D masks', 'Callback', @run_exportMasks, ...
    'Separator','on');

%mDNA_CSV = uimenu(mDNA, 'Label', 'Export');
%uimenu(mDNA_CSV, 'Label', 'Get basic properties of clusters/alleles', 'Callback', @userDotsAlleles);
%uimenu(mDNA_CSV, 'Label', 'Signal To Noise Ratio per cell [UD]', 'Callback', @userDotsSNR);

%mDNA_Special = uimenu(mDNA, 'Label', 'Specific');
%uimenu(mDNA_Special, 'Label', 'Q1 Promotor-Distance[UD]', 'Callback', @run_UDA_Q1);
%uimenu(mDNA_Special, 'Label', 'Extract alleles [UD]', 'Callback', @run_UDA_alleles);
%uimenu(mDNA_Special, 'Label', 'Find pairs and triplets', 'Callback', @pairsAndTriplets);

%mRNA = uimenu(gui.win, 'Label', 'RNA-FISH');
%uimenu(mRNA, 'Label', 'Analyse images (calc -> roq.pdf)', 'Callback', @run_B_analyze);
%uimenu(mRNA, 'Label', 'Get DAPI distribution from NE files', 'Callback', @dapiDistribution);
%uimenu(mRNA, 'Label', 'rnaSlide', 'Callback', @run_rnaSlide);

%mMISC = uimenu(gui.win, 'Label', 'Misc');

%uimenu(mMISC, 'Label', 'Fix Bad Masks', 'Callback', @fix_badMasks);

    function run_manageOverlapping(varargin)
        df_manageOverlapping()
    end

    function gui_delete(varargin)
        % disp('Closing DOTTER')
        pos = get(gui.win, 'Position');
        df_setConfig('DOTTER', 'winPos', pos);
        diary('off')
    end

    function open_tif(varargin)
        volumeSlide
    end

    function tests(varargin)
        set(gui.win, 'Pointer', 'watch');
        opts.outputDir = tempdir;
        opts.showCode = false;
        rfile = publish('df_unittest.m', opts);
        web(rfile, '-browser');
        %run(['df_unittest.m'])
        close all
        DOTTER
    end

    function run_pwd(varargin)
        D = df_pwd();
        assignin('base', 'D', D);
        disp('Data is also in the variable D')
    end

    function run_nkmeans(varargin)
        D = df_nkmeans();
        assignin('base', 'D', D);
        disp('Data is also in the variable D')
    end

    function run_exportDots(varargin)
        gui_tabs_enable();
        t = uitab(gui.tabs, 'Title', 'Export Dots');
        df_exportDots_ui('tab', t, 'closefun', @gui_tabs_update);
    end

    function relocate(varargin)
        h = msgbox('You will be asked for two folders, 1) the _calc folder that has been moved, 2) the sub folder of the folder containing the tif-images', ...
            'icon', 'help');
        uiwait(h)
        
        NMfolder = uigetdir('~/Desktop/', 'Pick a calc folder');
        if isnumeric(NMfolder)
            disp('Aborting');
        else
            
            TIFfolder = uigetdir([NMfolder '/..'], 'Say where the tif files are (sub folder)');
            
            if ~isnumeric(TIFfolder)
                df_relocateTif([NMfolder, '/'], [TIFfolder, '/'])
            else
                disp('Aborting')
            end
        end
        
    end

    function fix_badMasks(varargin)
        folder = uigetdir('~/Desktop/', 'Pick a calc folder');
        
        if ~isnumeric(folder)
            files = dir([folder '/*.NM']);
            fprintf('Found %d NM files\n', numel(files));
            fprintf('fixing ... ');
            for kk =1:numel(files)
                NM = load([folder '/' files(kk).name], '-mat');
                N = NM.N;
                M = NM.M;
                N = create_nuclei_from_mask(M.mask, 0*M.mask);
                save([folder '/' files(kk).name], '-mat', 'M', 'N');
            end
            disp('done!')
        else
            disp('Aborting')
        end
    end

    function run_DNA_ChannelOverlapAnalysis(varargin)
        disp('Starting DNA_ChannelOverlapAnalysis');
        m = msgbox(help('DNA_ChannelOverlapAnalysis'));
        uiwait(m);
        
        folder = uigetdir('~/Desktop/iXL34_35_36/', 'Pick a calc folder');
        if ~isnumeric(folder)
            DNA_ChannelOverlapAnalysis(folder)
        end
    end

    function run_dotThreshold(varargin)
        TH = df_dotThreshold()
        if exist('TH', 'var')
            fprintf('Suggested thresholds:\n');
            for kk = 1:numel(TH)
                fprintf('%f\n', TH(kk));
            end
        end
        
    end

    function run_setNUserDots(varargin)
        set(gui.win, 'Pointer', 'watch');
        disp('Starting df_setNUserDotsDNA');
        setNUserDots_folder = df_getConfig('DOTTER', 'setNUserDots_folder', '.');
        folder = uigetdir(setNUserDots_folder, 'Pick a calc folder');
        
        if ~isnumeric(folder)
            fprintf(['Picked folder: ' folder '\n']);
            df_setConfig('DOTTER', 'setNUserDots_folder', folder);
            
            files = dir([folder '/*.NM']);
            t = load([folder '/' files(1).name], '-mat');
            
            for cc = 1:numel(t.M.channels)
                prompt{cc} = t.M.channels{cc};
                defAns{cc} = '2';
            end
            dpna = inputdlg(prompt, 'Dots per nuclei', 1, defAns);
            dpn = [];
            for tt = 1:numel(dpna)
                dpn(tt) = str2num(dpna{tt});
            end
            
            
            df_setNUserDotsDNA('folder', folder, 'dpn', dpn)
        end
        
        try
            set(gui.win, 'Pointer', 'arrow');
        catch e
            % don't care
        end
    end

    function run_getFWHMstrongest(varargin)
        getFWHMstrongest_folder = df_getConfig('DOTTER', 'getFWHMstrongest_folder', '.');
        s.folder =  uigetdir(getFWHMstrongest_folder, 'Pick a calc folder');
        if ~isnumeric(s.folder)
            df_setConfig('DOTTER', 'getFWHMstrongest_folder', s.folder);
            F = df_getFWHMstrongest(s);
            assignin('base', 'F', F);
            disp('F, fwhm for strongest dots in each nuclei, accessible from command window')
        end
    end

    function run_setUserDots(varargin)
        set(gui.win, 'Pointer', 'watch');
        disp('Starting setUserDotsDNA');
        setUserDots_folder = df_getConfig('DOTTER', 'setUserDots_folder', '.');
        folder = uigetdir(setUserDots_folder, 'Pick a calc folder');
        if ~isnumeric(folder)
            df_setConfig('DOTTER', 'setUserDots_folder', folder);
            setUserDotsDNA(folder)
        end
        try
            set(gui.win, 'Pointer', 'arrow');
        catch e
            % don't care
        end
    end

    function quit(varargin)
        close(gui.win)
    end

    function checkVersion(varargin)
        try
            cdir = pwd;
            cd(DOTTER_PATH)
            !git cat-file -p origin/master:dotter/dotterCommitNumber > dotter/dotterRemote
            cd(cdir)
            F = fopen('dotterRemote');
            cnLatest = fread(F);
            fclose(F);
            
            if isequal(cn ,cnLatest)
                msgbox(sprintf('Up to date with the latest version 0.%s\n', cn(1:end-1)));
            else
                msgbox(sprintf('Can be updated. Latest version is 0.%s while you have 0.%s\n', cnLatest(1:end-1), cn(1:end-1)));
            end
        catch e
            warndlg('Could not determine the latest remote version')
            cd(cdir)
        end
    end

    function update(varargin)
        set(gui.win, 'Pointer', 'watch');
        d = pwd;
        cd(getenv('DOTTER_PATH'))
        !git pull
        cd(d)
        set(gui.win, 'Pointer', 'arrow');
    end

    function CA_scripts(varargin)
        disp('Starting cCorrMeasure');
        cCorrMeasure
    end

    function CA_folder(varargin)
        disp('starting cCorrFolder_gui')
        cCorrFolder_gui
    end

    function manuallyPerNuclei(varargin)
        m = msgbox(help('NEditor'));
        uiwait(m)
        NEditor
    end

    function dapiDistribution(varargin)
        set(gui.win, 'Pointer', 'watch');
        [D,A] = getDapiFromFolders();
        
        assignin('base', 'A', A);
        assignin('base', 'D', D);
        disp('RAW data is in the variable D, pixels per nuclei in A');
        if numel(D)>0
            figure
            subplot(1,3,1)
            histogram(D, 256);
            title('DAPI contents')
            subplot(1,3,2)
            histogram(A, 256)
            title('Area in mask [pixels]');
            subplot(1,3,3)
            scatter(D,A)
            xlabel('DAPI');
            ylabel('Area');
        else
            disp('No data to show')
        end
        set(gui.win, 'Pointer', 'arrow');
        
    end

    function pairsAndTriplets(varargin)
        msgbox('Edit and run D_find_triplets if three channels+DAPI');
        %D_find_triplets
    end

    function convert_nd2(varargin)
        gui_tabs_enable();
        t = uitab(gui.tabs, 'Title', 'Bioformats to tif');
        nd2tif_g('tab', t, 'closefun', @gui_tabs_update);
    end

    function openChangelog(varargin)
        clFile = [getenv('DOTTER_PATH') 'README.html'];
        % A trick to get the full file name, i.e., replace the tilde
        t = fopen(clFile);
        if t == -1
            warndlg('Can not find documentation');
            return
        end       
        clFile = fopen(t);
        fclose(t);
        web(['file://' clFile],  '-browser');        
    end

    function openHelp(varargin)
        disp('Trying to open the documentation')
        docFile = [getenv('DOTTER_PATH') 'dotter/documentation/dotter.pdf'];
        disp(docFile);
        openpdf(docFile);
    end

    function openLogs(varargin)
        disp('Opening the log files in the editor')
        web(['file://' logfile_last])
        web(['file://' logfile])
    end


    function run_UDA_alleles(varargin)
        % UDA: userDots analysis
        % alleles: extract alleles
        UDA_alleles_folder = df_getConfig('DOTTER', 'UDA_alleles_folder', '.');
        folder = uigetdir(UDA_alleles_folder, 'Pick a calc folder');
        if ~isnumeric(folder)
            df_setConfig('DOTTER', 'UDA_alleles_folder', folder);
            disp('calling UDA_alleles');
            UDA_alleles(folder)
        end
    end

    function setDapiThFolder(varargin)
        % Set dapi threshold for all NM files in calc-folder
        folder = df_getConfig('DOTTER', 'setDapiForFolder', '.');
        folder = uigetdir(folder, 'Pick a calc folder');
        if ~isnumeric(folder)
            df_setConfig('DOTTER', 'setDapiForFolder', folder);
            df_setDapiForFolder(folder)
        end
    end

    function run_UDA_Q1(varargin)
        % UDA: userDots analysis
        % Q1: One dot per channel and cluster
        % One channel is reference.
        % Get: Distance to reference channel
        
        UDA_Q1_folder = df_getConfig('DOTTER', 'UDA_Q1_folder', '.');
        folder = uigetdir(UDA_Q1_folder, 'Pick a calc folder');
        if ~isnumeric(folder)
            df_setConfig('DOTTER', 'UDA_Q1_folder', folder);
            UDA_Q1(UDA_Q1_folder)
        end
    end

    function dotsPerNuclei(varargin)
        disp('D_dots_per_nuclei')
        set(gui.win, 'Pointer', 'watch');
        setUserDots_folder = df_getConfig('DOTTER', 'dotsPerNuclei_folder', '.');
        folder = uigetdir(setUserDots_folder, 'Pick a calc folder');
        if ~isnumeric(folder)
            df_setConfig('DOTTER', 'dotsPerNuclei_folder', folder);
            disp(sprintf('running D_dots_per_nuclei(''%s'')', folder));
            D_dots_per_nuclei(folder)
        end
        set(gui.win, 'Pointer', 'arrow');
    end

    function reviewCalc(varargin)
        D_reviewCalc
    end

    function integralIntensity(varargin)
        disp('Running D_integralIntensity');
        set(gui.win, 'Pointer', 'watch');
        D_integralIntensity
        set(gui.win, 'Pointer', 'arrow');
    end

    function userDotsSNR(varargin)
        disp('Running D_userDotsSNR');
        m = msgbox(help('D_userDotsSNR'));
        uiwait(m);
        D_userDotsSNR
    end

    function userDotsAlleles(varargin)
        
        [N, M] = df_getNucleiFromNM();
        
        T = df_analyzeAlleles(M,N);
        fprintf('Measurements are now available in T\n');
        assignin('base', 'T', T);
        
        [fname, folder] = uiputfile('*.csv', 'Where to save the table');
        fname = [folder fname];
        fprintf('Saving the measurements to %s\n', fname);
        writetable(T, fname);
    end


    function run_rnaSlide(varargin)
        %msgbox('Select a NM-file corresponding to a DNA-FISH experiment to view dots, set thresholds and export data for a single file.')
        rnaSlide
    end

    function run_B_analyze(varargin)
        disp('Running B_analyze')
        B_analyze
    end

    function compile(varargin)
        disp('Compiling the mex functions. First checking that there is a compiler available.')
        disp('If this fails:')
        disp(' on MAC: install Xcode with Clang')
        disp(' on Linux: install gcc or clang')
        mex -setup c
        run('df_buildExternals');
    end

    function run_A_cells(varargin)
        disp('Running A_cells')
        set(gui.win, 'Pointer', 'watch');
        A_cells
        set(gui.win, 'Pointer', 'arrow');
    end

    function switchDisplay(varargin)
        % Swith between image and text in the window
        % when it is clicked
        if strcmp(stext.Visible, 'off')==0
            stext.Visible = 'Off';
            img.Visible = 'On';
        else
            img.Visible = 'Off';
            stext.Visible = 'On';
            
            % Get latest update message
            d = pwd;
            cd(getenv('DOTTER_PATH'))
            [~, cmdout] = system('git log -1 | cat');
            cd(d)
            stext.String = cmdout;
            
            stext.Units = 'normalized';
            stext.Position = [0,0.7,0];
            
        end
    end

    function run_plot(varargin)
        % Open the plotting gui
        gui_tabs_enable();
        t = uitab(gui.tabs, 'Title', 'Plot tool');
        df_plot('tab', t, 'closefun', @gui_tabs_update);
    end

    function shortcuts(varargin)
        % Key strokes go here
        if strcmpi(varargin{2}.Key, 'escape')
            disp('<esc>, closing');
            close(gui.win);
        end
    end

    function fName = unRelFileName(relName)
        try
            t = fopen(relName);
            fName = fopen(t);
            fclose(t);
        catch e
            fName = 'error';
        end
    end

    function CC_open(varargin)
        
        outFolder = df_getConfig('df_cc', 'ccfolder', '~');
        
        [b,a] = uigetfile([outFolder filesep() '*.cc'], 'Pick a cc file');
        
        if isnumeric(b)
            return
        end
        
        ccFile = [a b];
        df_setConfig('df_cc', 'ccfolder', a);
        opts.outputDir = tempdir;
        opts.codeToEvaluate = sprintf('df_cc_view(''%s'')', ccFile);
        opts.showCode = false;
        rfile = publish('df_cc_view.m', opts);
        web(rfile, '-browser');
        
    end

    function gui_tabs_update()
        if numel(gui.tabs.Children) == 0
            gui_tabs_disable();
        else
            gui_tabs_enable();
        end
    end

    function gui_tabs_enable()
        gui.tabs.Visible = 'on';
        gui.win.Resize = 'On';
        pos =  gui.win.Position;
        pos(3:4) = [700, 600];
        gui.win.Position = pos;
    end

    function gui_tabs_disable()
        gui.tabs.Visible = 'off';
        gui.win.Resize = 'Off';
        pos =  gui.win.Position;
        pos(3:4) = [469,75];
        gui.win.Position = pos;
    end

end

function run_exportMasks(varargin)
    df_exportMasks();
end