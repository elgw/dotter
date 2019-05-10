function varargout = df_exportDots_ui(varargin)
% GUI for df_exportDots
%

tab = [];
files = []; % Files to extract dots from
csvFile = [];
ccFile = [];
s.extractUserDots = 1;
s.maxDots = 0;
s.calcFolderName = '';
s.calcSNR = 1;
s.calcFWHM = 0;


for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'tab')
        tab = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'closefun')
        closefun = varargin{kk+1};
    end
end

if numel(tab) == 0
    f = figure;
    tabs = uitabgroup();
    tab = uitab(tabs, 'title', 'Export Dots');
    closefun = @() close(f);
end

p_input = uipanel('Title', 'Input', ...
    'Units', 'Normalized', ...
    'Position', [0,.15, .3, .85], ...
    'Parent', tab);

p_settings = uipanel('Title', 'Settings', ...
    'Units', 'Normalized', ...
    'Position', [.3,.15, .7, .85], ...
    'Parent', tab);

b_selectNM = uicontrol('Style', 'pushbutton', ...
    'String', 'Select NM files', ...
    'Units', 'Normalized', ...
    'Position', [.1,.8,.8,.1], ...
    'Callback', @selectNM, ...
    'Parent', p_input);

b_selectCSV = uicontrol('Style', 'pushbutton', ...
    'String', 'Select CSV file', ...
    'Units', 'Normalized', ...
    'Position', [.1,.4,.8,.1], ...
    'Callback', @selectCSV, ...
    'Parent', p_input);

b_selectCC = uicontrol('Style', 'pushbutton', ...
    'String', 'Select CC file', ...
    'Units', 'Normalized', ...
    'Position', [.1,.6,.8,.1], ...
    'Callback', @selectCC, ...
    'Parent', p_input);

uicontrol('Style', 'Text', ...
    'String', 'Which nuclei?', ...
    'Units', 'Normalized', ...
    'Position', [.0,.7,.5,.1], ...
    'Parent', p_settings);

p_nuclei = uicontrol('Style', 'popup',...
    'String', {'All', 'G1', '>G1'},...
    'Units', 'Normalized', ...
    'Position', [.5,.7,.5,.1], ...
    'Parent', p_settings);

uicontrol('Style', 'Text', ...
    'String', 'Which dots?', ...
    'Units', 'Normalized', ...
    'Position', [.0,.6,.5,.1], ...
    'Parent', p_settings);

p_dots = uicontrol('Style', 'popup',...
    'String', {'userDots','all dots'},...
    'Units', 'Normalized', ...
    'Position', [.5,.6,.5,.1], ...
    'Parent', p_settings);

uicontrol('Style', 'Text', ...
    'String', 'Max dots per image', ...
    'Units', 'Normalized', ...
    'Position', [0,.5,.5,.1], ...
    'Parent', p_settings);

e_maxDots = uicontrol('Style', 'edit', ...
    'String', '1000', ...
    'Units', 'Normalized', ...
    'Position', [.5,.5,.5,.1], ...
    'Parent', p_settings);

uicontrol('Style', 'Text', ...
    'String', 'Fitting', ...
    'Units', 'Normalized', ...
    'Position', [0,.4,.5,.1], ...
    'Parent', p_settings);

p_fitting = uicontrol('Style', 'popup',...
    'String', {'none', 'centre of mass', 'ML+Gaussian'},...
    'Units', 'Normalized', ...
    'Position', [.5,.4,.5,.1], ...
    'Parent', p_settings);

c_snr = uicontrol('Style', 'checkbox', ...
    'String', 'Calc SNR', ...
    'Value', s.calcSNR, ...
    'Units', 'Normalized', ...
    'Position', [.1,.3,.5,.1], ...
    'Parent', p_settings);

c_fwhm = uicontrol('Style', 'checkbox', ...
    'String', 'Calc FWHM', ...
    'Value', s.calcFWHM, ...
    'Units', 'Normalized', ...
    'Position', [.1,.2,.5,.1], ...
    'Parent', p_settings);

centroids = uicontrol('Style', 'checkbox', ...
    'String', 'Clusters to centroids (per channel)', ...
    'Value', 0, ...
    'Units', 'Normalized', ...
    'Position', [.1,.1,.8,.1], ...
    'Parent', p_settings);


b_close = uicontrol('Style', 'pushbutton', ...
    'String', 'Close', ...
    'Units', 'Normalized', ...
    'Position', [0,.0,1/3,.1], ...
    'Callback', @closeme, ...
    'Parent', tab);

b_help = uicontrol('Style', 'pushbutton', ...
    'String', 'Help', ...
    'Units', 'Normalized', ...
    'Position', [1/3,.0,1/3,.1], ...
    'Callback', @open_help, ...
    'Parent', tab);

b_exportCSV = uicontrol('Style', 'pushbutton', ...
    'String', 'Export to CSV file', ...
    'Units', 'Normalized', ...
    'Position', [2/3,.0,1/3,.1], ...
    'Callback', @exportCSV, ...
    'Parent', tab);

if 0
    T = df_exportDots('UserDots');
    if numel(T)>0
        assignin('base', 'T', T);
        disp('Data is also in the variable T')
    end
end

    function closeme(varargin)
        delete(tab);
        closefun()
    end

    function selectNM(varargin)
        folder = df_getConfig('df_exportDots', 'folder', pwd);
        files = uipickfiles('FilterSpec', folder, 'Prompt', 'Select NM files', 'REFilter', '.NM$');
        if isnumeric(files)
            disp('No NM files selected')
            return
        else
            % Extract iEG504 or iJC801_180920 etc from calc file name            
            [a,b] = regexpi(files{1}, 'i[a-zA-Z][a-zA-Z][0-9][0-9][0-9].*_calc');
            if numel(a)>0
                a = a(1); b=b(1);
                s.calcFolderName = files{1}(a:b-5);
            end
        end
        % Set the default folder to look in next time
        df_setConfig('df_exportDots', 'folder', fileparts(files{1}))
    end

    function parseGUI()
        % Read the settings specified in the GUI
        
        s.nucleiSelection = p_nuclei.Value;
        % All, G1, G2
        
        if p_dots.Value == 1
            s.extractUserDots = 1;
        else
            s.extractUserDots = 0;
        end
        
        s.calcFWHM = c_fwhm.Value;
        s.calcSNR = c_snr.Value;
        s.centroids = centroids.Value;
        s.maxDots = str2num(e_maxDots.String);
        s.fitting = p_fitting.String{p_fitting.Value};
        disp(s)
        
    end

    function selectCSV(varargin)
        parseGUI()
        
        if s.extractUserDots
            sugFile = [s.calcFolderName '_userDots.csv'];
        else
            sugFile = [s.calcFolderName '_allDots.csv'];
        end
        
        [A, B] = uiputfile(sugFile);
        if isnumeric(A)
            disp('Aborting')
            return
        end
        csvFile = [B, A];
    end

    function exportCSV(varargin)
        parseGUI()
        
        if numel(files) == 0
            warndlg('No NM files given')
            return
        end
        if numel(csvFile) == 0
            warndlg('Don''t know where to save the csv data');
            return
        end
        
        whos
        disp(s)
        
        df_exportDots('files', files, ...
            'ccFile', ccFile', ...
            'fwhm', s.calcFWHM, ...
            'maxDots', s.maxDots, ...
            'outFile', csvFile, ....
            'exportUserDots', s.extractUserDots, ...
            'nucleiSelection', s.nucleiSelection, ...
            'fitting', s.fitting, ...
            'centroids', s.centroids);
    end

    function selectCC(varargin)
        ccFolder = df_getConfig('df_cc', 'ccfolder', '~/');
        [b, a] = uigetfile([ccFolder '*.cc'], 'Select cc file');
        if ~isnumeric(a)
            ccFile = [a b];
        else
            warning('No CC file given')
            ccFile = '';
        end
    end

end

function open_help(varargin)
doc('df_exportDots')
end