function settings = df_guisettings(varargin)
% GUI for edit settings in s
% name: name of window
% settings is an array of structs with
% name, type and value
% help should be a function handle to some help function
%
% Example:
% s(1).name = 'Name'; s(1).type = 'String'; s(1).value = 'John'
% s(2).name = 'Age'; s(2).type = 'int';
% s(3).name = 'Record'; s(3).type = 'file';
% df_guisettings('name', 'Demo', 'settings', s)

if nargin < 2
    error('Too few input arguments');
end

s = [];

name = 'No name provided';
helpfun = [];
for kk = 1:2:nargin
    if strcmpi(varargin{kk}, 'name')
        name = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'settings')
        s = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'help')
        helpfun = varargin{kk+1};
    end
end

if 0
    for kk = 1:numel(s)
        fprintf('%s \t %s\n', s(kk).name, s(kk).type);
    end
end

height = 45*(numel(s)+1)+10;
height = min(height, 900);

app = uifigure('Position', [500,200,300, height], ...
    'NumberTitle','off', ...
    'Name', name, ...
    'Resize', 'on', ...
    'Toolbar', 'none', ...
    'MenuBar', 'none');

lastdir = pwd();

g = uigridlayout(app); 
g.Scrollable = true;

rows = {};

for kk = 1:numel(s)
    rows{end+1} = 35;
end
rows{end+1} = 35;

g.RowHeight = rows;
g.ColumnWidth = {100, '1x', 50};
gui = cell(numel(g.RowHeight), numel(g.ColumnWidth));

for kk = 1:numel(s)
    l = uilabel(g, 'Text', s(kk).name);    
    v = s(kk).value;
    
    if strcmpi(s(kk).type, 'numeric')
        v = num2str(v);
    end
    
    if strcmpi(s(kk).type, 'logical')
        if s(kk).value == 0
            v = 'false';
        else
            v = 'true';
        end
    end
    
    e = [];
    if strcmpi(s(kk).type, 'dir')
        e = uibutton(g, 'Text', 'dir', 'ButtonPushedFcn', @getDir);
    end
    if strcmpi(s(kk).type, 'file')
        e = uibutton(g, 'Text', 'file', 'ButtonPushedFcn', @getFile);
    end
    v = '';
    if isfield(s(kk), 'value')
        if numel(s(kk).value) > 0
            v = s(kk).value;
        end
        if ~ischar(v)
            v = num2str(v);
        end
    end
    t = uieditfield(g, 'Value', v);
    t.Editable = 'on';
    t.Enable = 'on';
    % uitextarea
    l.Layout.Column = 1;
    l.Layout.Row = kk;
    gui{kk, 1} = l;
    
    t.Layout.Column = 2;
    t.Layout.Row = kk;
    gui{kk, 2} = t;
    
    if numel(e) == 1
        e.Layout.Column = 3;
        e.Layout.Row = kk;
        gui{kk, 3} = e;
    end
end

b = uibutton(g, 'Text', 'ok', 'ButtonPushedFcn', @leave);
b.Layout.Column = 2; 
b.Layout.Row = numel(s)+1;

b = uibutton(g, 'Text', 'Cancel', 'ButtonPushedFcn', @leave);
b.Layout.Column = 1; 
b.Layout.Row = numel(s)+1;

if isa(helpfun, 'function_handle')
b = uibutton(g, 'Text', 'Help', 'ButtonPushedFcn', helpfun);
b.Layout.Column = 3; 
b.Layout.Row = numel(s)+1;
end

settings = [];
uiwait(app);
if isvalid(app)
    close(app); 
end

function getFile(btn, event)
        % Get a directory
        d = uigetfile(lastdir);
        if ~isnumeric(d)
            lastdir = d;
            % Find correponding setting
            row = [];
            for kk = 1:size(gui,1)
                if isequal(btn, gui{kk, 3})
                    row = kk;
                end
            end            
            gui{row,2}.Value = d; 
        end            
end

    function getDir(btn, event)
        % Get a directory
        d = uigetdir(lastdir);
        if ~isnumeric(d)
            lastdir = d;
            % Find correponding setting
            row = [];
            for kk = 1:size(gui,1)
                if isequal(btn, gui{kk, 3})
                    row = kk;
                end
            end            
            gui{row,2}.Value = d;
        end            
    end

    function leave(btn, event)

if strcmpi(btn.Text, 'ok')
    settings = uiparse(s);    
else
    settings = [];
end
    uiresume(app);    
    end

    function s2 = uiparse(s)                
        for kk = 1:size(gui,1)-1          
            name = gui{kk,1}.Text;
            if isequal(s(kk).type, 'numeric')
                s2.(name) = str2num(gui{kk,2}.Value);
            else
                s2.(name) = gui{kk,2}.Value;       
            end
        end
    end

end
