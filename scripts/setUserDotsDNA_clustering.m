function setUserDotsDNA_clustering(varargin)
%
% Populate a tab with settings for clustering
%
% Loads plugins from the folder dotter/plugins/clustering
% Each of the plugins are queried for settings by calling it with
% 'getSettings' as single argument.
% 
%
% Arguments:
%  tab: the name of the tab to put the gui components in
%  channels: names of the channels to use
%  fun: function to call when the buttons under 'Apply to' are pressed
%
% fun:
%   The function 'fun' is called with the structure 
%   'clustering' as only input.
%   The fields are:
%   - channels_base, which channels should be used to define the cluster
%   shapes
%   - channels_apply, which channels to apply the clustering to
%   - channels_dots, an array stating the number of dots per channel
%   - applyTo: 'All', 'Field' or 'Nuclei'
%   - method: name of clustering method to use, i.e., name of a function
%   - param: Values of the variable settings
%
% Example:
% To create the gui components in a aready existing tab:
% setUserDotsDNA_clustering('tab', mytab, ...       
%              'channels', {'a594', 'cy5', 'tmr'}, ...
%               'fun', @clusterHere)
%
% Plugins to write:
%  - Set dots to constant value, 0, 1, ...
%  - Automatic number of clusters
%
% Currently only used by setUserDotsDNA

tab = []; % Tab to live in
gui = []; % Root for GUI components
s   = [];   % Internal settings

fun = []; % Callback function
clustering = []; % Settings to return to the callback function
clustering_defaults = []; % What is returned by 'getDefaults' by the choosen method

for aa = 1:numel(varargin)
    if strcmpi(varargin{aa}, 'tab')
        tab = varargin{aa+1};
    end
    if strcmpi(varargin{aa}, 'channels')
        s.channels = varargin{aa+1};
    end
    if strcmpi(varargin{aa}, 'fun')
        s.fun = varargin{aa+1};
    end
end

if numel(s) == 0
    warning('Debug mode')
    close all
    s.channels = {'a594', 'tmr', 'cy5'};
    s.fun = @test_Clustering;
    s.N = test_loadNuclei();
end

if numel(tab) == 0
    gui.f = figure;
    gui.tg = uitabgroup(gui.f);
    tab = uitab(gui.tg, 'Title', 'Clustering');
end

s.method_number = -1;

s.channels_dots = 101*ones(1, numel(s.channels));

%% Figure out available methods and read their defaults
s.methods = dir([getenv('DOTTER_PATH') 'plugins/clustering/' 'df_ud_clusters*.m']);
s.method_names = {};
for mm = 1:numel(s.methods)
    s.methods(mm).fun = str2func(s.methods(mm).name(1:end-2));
    s.ms = s.methods(mm).fun('getSettings');
    s.methods_names{mm} = s.ms.string;
end

assert(numel(s.methods)>0)

createGUIcomponents();

gui.method_list.String = s.methods_names;

gui_parse(); % load method etc
updateGUIcomponents();

%% Functions goes below

    function updateGUIcomponents()
        
    end

    function createGUIcomponents()
        
        gui.methodsPanel = uipanel('Position', [0, .85, 1, .14], 'Title', 'Method', ...
            'Parent', tab);
        gui.clusterPanel = uipanel('Position', [0, .2,  1, .65], 'Title', 'Settings', ...
            'Parent', tab);
        gui.applyPanel = uipanel('Position', [0, 0,  1, .2], 'Title', 'Apply To', ...
            'Parent', tab);
        
        gui.method_list = uicontrol('Style', 'popup', ...
            'String', {'Not loaded', '...'}, ...
            'Units', 'Normalized', ...
            'Position', [0,0,.49,1], ...
            'Callback', @selectMethod, ...
            'Parent', gui.methodsPanel);
        
        gui.method_help = uicontrol('Style', 'pushbutton', ...
            'String', 'Help', ...
            'Units', 'Normalized', ...
            'Position', [.5, 0, .25, 1], ...
            'Callback', @method_help, ...
            'Parent', gui.methodsPanel);
        
        gui.method_edit = uicontrol('Style', 'pushbutton', ...
            'String', 'Edit', ...
            'Units', 'Normalized', ...
            'Position', [.75, 0, .25, 1], ...
            'Callback', @method_edit, ...
            'Parent', gui.methodsPanel);
        
        gui.clusterChannelPanel = uipanel( ...
            'Units', 'Normalized', ...
            'Position', [0,.0,.6,1], ...
            'Parent', gui.clusterPanel);
        uicontrol('Style', 'Text', ...
            'String', 'Base channel', ...
            'Units', 'Normalized', ...
            'Position', [0,.9, .4,.1], ...
            'Parent', gui.clusterChannelPanel);
        
        uicontrol('Style', 'Text', ...
            'String', 'Apply to', ...
            'Units', 'Normalized', ...
            'Position', [.4,.9, .4,.1], ...
            'Parent', gui.clusterChannelPanel);
        
        gui.channels_base = uicontrol('Style', 'listbox', ...
            'String', s.channels, ...
            'Units', 'Normalized', ...
            'Position', [0, 0, .4,.9], ...
            'Parent', gui.clusterChannelPanel, ...
            'Max', 100);
        
        gui.channels_apply = uicontrol('Style', 'listbox', ...
            'String', s.channels, ...
            'Value', 1:numel(s.channels), ...
            'Units', 'Normalized', ...
            'Position', [.4, 0, .4,.9], ...
            'Parent', gui.clusterChannelPanel, ...
            'Max', 100);
        gui.channels_dots = uicontrol('Style', 'listbox', ...
            'String', cellfun(@num2str, num2cell(s.channels_dots), 'UniformOutput', false), ...
            'Value', 1, ...
            'Units', 'Normalized', ...
            'Position', [.8, 0, .2,.9], ...
            'Parent', gui.clusterChannelPanel, ...
            'Max', 1, ...
            'Callback', @setDotsPerChannel);
        
        gui.clusterSettingsPanel = uipanel( ...
            'Units', 'Normalized', ...
            'Position', [.6,.0,.4,1], ...
            'Parent', gui.clusterPanel);
        
        for pp = 1:4
            gui.param(pp).desc = uicontrol('Style', 'Text', ...
                'String', sprintf('Parameter %d', pp), ...
                'Units', 'Normalized', ...
                'Position', [0,.90-.2*pp, .5,.2], ...
                'Parent', gui.clusterSettingsPanel);
            gui.param(pp).edit = uicontrol('Style', 'Edit', ...
                'String', num2str(0), ...
                'Units', 'Normalized', ...
                'Position', [.5,.95-.2*pp, .5,.2], ...
                'Parent', gui.clusterSettingsPanel);
        end
        
        uicontrol('Style', 'pushbutton', ...
            'String', 'Field', ...
            'Units', 'Normalized', ...
            'Position', [.33,0,.33,1], ...
            'Callback', @apply,...
            'Parent', gui.applyPanel);
        
        uicontrol('Style', 'pushbutton', ...
            'String', 'Nuclei', ...
            'Units', 'Normalized', ...
            'Position', [.66,0,.33,1], ...
            'Callback', @apply,...
            'Parent', gui.applyPanel);
        
        uicontrol('Style', 'pushbutton', ...
            'String', 'All Fields', ...
            'Units', 'Normalized', ...
            'Position', [0,0,.33,1], ...
            'Callback', @apply,...
            'ForegroundColor', 'r', ...
            'Parent', gui.applyPanel);
    end

    function setDotsPerChannel(varargin)
        % When the list of number of dots per channels is clicked
       cNum = varargin{1}.Value;
        v = inputdlg(sprintf('Number of dots per cluster for channel %s? ', s.channels{cNum}));        
        if numel(v) == 1            
            s.channels_dots(cNum) = str2num(v{1});            
            gui.channels_dots.String = cellfun(@num2str, num2cell(s.channels_dots), 'UniformOutput', false);            
        end
    end

    function method_help(varargin)        
        % Display help for the choosen function
        h = help(s.methods(s.method_number).name);
        msgbox(h);
    end

    function method_edit(varargin)
        % Edit the choosen function
        edit(s.methods(s.method_number).name);
    end

    function selectMethod(varargin)        
        gui_parse();
        updateGUIcomponents();
    end

    function gui_parse(varargin)
        
        %% Update GUI if method was changed
        if (gui.method_list.Value ~= s.method_number)
            s.method_number = gui.method_list.Value;
            clustering.method = s.methods(s.method_number).name(1:end-2);
            
            clustering_defaults = s.methods(s.method_number).fun('getSettings');
            for pp = 1:numel(gui.param)
                gui.param(pp).edit.Visible = 'off';
                gui.param(pp).desc.Visible = 'off';
            end
            
            for pp = 1:numel(clustering_defaults.param)
                gui.param(pp).desc.String = clustering_defaults.param(pp).String;
                gui.param(pp).edit.String  = num2str(clustering_defaults.param(pp).Value);
                gui.param(pp).edit.Visible = 'on';
                gui.param(pp).desc.Visible = 'on';
            end
            
            if(clustering_defaults.channels_base == 1)
                gui.channels_base.Enable = 'On';
            else
                gui.channels_base.Value = 1:numel(s.channels);
                gui.channels_base.Enable = 'Off';
                
            end
            if(clustering_defaults.channels_apply == 1)
                gui.channels_apply.Enable = 'On';
            else
                gui.channels_base.Value = 1:numel(s.channels);
                gui.channels_apply.Enable = 'Off';
            end
            
        end
        
        
        %% Read parameters from GUI
        for pp = 1:numel(clustering_defaults.param)
            clustering.param(pp).Value = gui.param(pp).edit.String;
        end
        
        % Also which channels to use
        clustering.channels_base  = gui.channels_base.Value;
        clustering.channels_apply = gui.channels_apply.Value;
        clustering.channels_dots = s.channels_dots;
        
        
    end

    function apply(varargin)
        gui_parse();
                                
        % Figure out what to apply to
        if strcmpi(varargin{1}.String, 'Nuclei')
            clustering.applyTo = 'Nuclei';
        end
        if strcmpi(varargin{1}.String, 'Field')
            clustering.applyTo = 'Field';
        end
        if strcmpi(varargin{1}.String, 'All Fields')
            clustering.applyTo = 'All';
        end
        
        s.fun(clustering);
    end


    function N = test_loadNuclei()
        N = [];
        for cc = 1:3
            N.userDots{cc} = 50*rand(11,3);
            N.userDots{cc}(:,3) = 1;
            N.userDotsLabels{cc} = zeros(11,1);
        end
    end


    function test_Clustering(x)
        disp(x);
        
        cfun = str2func(x.method);
        N = s.N;
        N = cfun(N, x);
        %disp(NC);
        
        figure(2)
        clf
        hold on
        nLabels = 0;
        for cc = 1:numel(N.userDots)
            nLabels = max(nLabels, max(N.userDotsLabels{cc}));
        end
        nLabels = nLabels + 1;
        
        colors = [0 0 0
            1 0 0
            0 1 1
            1 0 1
            0 0 1];
        
        markerStyles = 'oxs.';
        lstrings = {};
        for cc = 1:numel(markerStyles)
            for ll = 0:2
                plot(0,0, markerStyles(cc), 'Visible', 'off', 'Color', colors(ll+1,:));
                lstrings{end+1} = sprintf('Channel %d, Label %d', cc, ll);
            end
        end
        legend(lstrings);
        
        for cc = 1:numel(N.userDots)
            D = N.userDots{cc};
            L = N.userDotsLabels{cc};
            for kk = 1:size(D,1)
                plot(D(kk,2), D(kk,1),  markerStyles(cc), ...
                    'Color', colors(L(kk)+1,:));
            end
        end
        
        s.N = N;
    end


end
