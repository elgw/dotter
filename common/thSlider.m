function app = thSlider(varargin)
% function thSlider(varargin)
% Parameters:
% 'Data' -- the data to show as a histogram
% 'Threshold' -- default threshold
% 'Callback' -- callback function, called when the threshold is changed
%
% Example:
% thSlider('Data', rand(100,1), 'threshold', .5, 'Callback', @disp);
%
% Updated 2020-11-05

% List of UI components
% https://se.mathworks.com/help/matlab/creating_guis/choose-components-for-your-app-designer-app.html
% uigridlayout
% https://se.mathworks.com/help/matlab/ref/uigridlayout.html
 


%% Global data
th = [];
data = [];
cbFun = [];

% Check input arguments
for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'Data')
        data = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'Threshold')
        th = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'Callback')
        cbFun = varargin{kk+1};
    end
end

% 
%save('datatemp.mat', 'data', 'th');
%load datatemp.mat

assert(numel(data)>0);
if numel(th)==0
    th = mean(data);
end

[Hv, Hd] = histoH(data);

%    'Menubar', 'none', ...
app = uifigure('Position', [500,200,500,300], ...
    'NumberTitle','off', ...
    'Name', 'thSlider', ...
    'Resize', 'on', ...
    'Toolbar', 'none', ...
    'MenuBar', 'none');

app.UserData = struct('setTh', @setTh);

range = [];
range(1) = min(th, Hd(1));
range(2) = max(th, Hd(end));

if(min(data(:)) < range(1))
    warning('The lowest value is not in range!');
end
if(max(data(:)) > range(2))
    warning('The largest value is not in range!');
end

g = uigridlayout(app); 
g.RowHeight = {'1x',40};
g.ColumnWidth = {'1x', 120};
%g.ColumnWidth = {350,'1x'};

% Histogram Axis
histAx = uiaxes(g);
thLine = plot(histAx, [th, th], [min(Hv(:)), max(Hv(:))], 'r', 'lineWidth', 2);
hold(histAx, 'on')
histo = plot(histAx, Hd, Hv, 'k', 'lineWidth', 2);
% axis(histAx, 'off')
% grid(histAx, 'on')

%c = uicontextmenu();
%m1 = uimenu(c, 'Label', 'LogY', 'Callback', @logY);
%m1 = uimenu(c, 'Label', 'LinY', 'Callback', @logY);
%histAx.UIContextMenu = c;

thSlider = uislider(g, ...
'Limits', range, ...        
    'ValueChangedFcn', @thChange);
thSlider.Layout.Row = 2;
thSlider.Layout.Column = 1;
thSlider.Value = th;

if(Hd(1)<Hd(end) && max(Hv)>min(Hv))
    axis(histAx, [Hd(1), Hd(end), min(Hv), max(Hv)*1.1])
end


info = uibutton(g); % No 'ButtonDownFcn', @uiSetTh
info.Layout.Column = 2;
info.Layout.Row = [1,2];
setInfoTxt();
info.ButtonPushedFcn = @uiSetTh;

%ax = uiaxes(g);
%ax.Layout.Row = [1 2];

%histAx.ButtonDownFcn = @setThHere;

histAx.YTickLabel = {};

    function setInfoTxt()        
        txt = sprintf('#=%.3d\nMin: %.3d\nMax: %.3d\nBelow: %d\nAbove: %d\nth: %.3f\n', ...
            numel(data), ...
            min(data(:)), max(data(:)), ...
            sum(data<th), sum(data>=th), ...            
            th);
        txt = sprintf('%s\nPress to \nset threshold\n', txt);
        info.Text = txt;       
    end

    function setThHere(varargin)
        disp('To Do');
    end

    function logY(varargin)
        switch varargin{2}.Source.Label
            case 'LogY'
                histAx.YScale = 'log';
            case 'LinY'
                histAx.YScale = 'linear';
        end
    end

    function [Hv, Hd] = histoH(H)
        [Hv, Hd] = histcounts(H);
        %keyboard
        Hd = linspace(mean(Hd(1:2)), mean(Hd(end-1:end)), numel(Hv));
        % Extend limits
        Hd = [Hd(1) - (Hd(2)-Hd(1)) Hd Hd(end)+Hd(end)-Hd(end-1)];
        Hv = [0 Hv 0];
    end

    function uiSetTh(varargin)
        
        thres = inputdlg('Give a threshold');
        if numel(thres)  == 1
        thres = thres{1};
        thres = str2num(thres);        
        setTh(thres);
        end
         
    end

    function setTh(thres)
        % Get threshold externally
        %fprintf('thSlider got new th: %f\n', thres);
        th = thres;
        th = max(th, range(1));
        th = min(th, range(2));
        thSlider.Value = th;
        updateapp();
    end

    function thChange(varargin)
        % Called when the sliders are released
        th = get(thSlider, 'value');
        updateapp()        
        try
            if isa(cbFun, 'function_handle')
                cbFun(th)
            end
        catch
            warning('thSlider could not set the threshold')
        end
        
    end

    function updateapp(varargin)
        % Call externally by: w.UserData.updateFcn()
        
        for kk = 1:numel(varargin)
            if strcmp(varargin{kk}, 'H') == 1
                % New image to calculate histogram from
                H = varargin{kk+1};
                [Hv, Hd] = histoH(H);
                % Since the image changed, the clim probably did as well
                clim = get(object, 'CLim');
                fprintf('thSlider got new H [%f, %f]\n', min(H(:)), max(H(:)));
                % update the axes of the histogram plot
                ax = [min(Hd), max(Hd), min(Hv), max(Hv)];
                axis(histAx, ax)
                set(histo, 'XData', Hd, 'YData', Hv);
                
                sliderLower.Min = ax(1);
                sliderLower.Max = ax(2);
                sliderLower.Value = max(ax(1), min(clim(1), ax(2)));
                sliderUpper.Min = ax(1);
                sliderUpper.Max = ax(2);
                sliderUpper.Value = max(ax(1), min(clim(2), ax(2)));
            end
        end
        
        thLine.XData = [th th];
        thLine.YData = [min(Hv(:)), max(Hv(:))];
        setInfoTxt();
    end
end