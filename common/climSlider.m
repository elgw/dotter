function win = climSlider(varargin)
% function climSlider(varargin)
% clim sliders for current gca or the gca in first argument
%
% Example:
% fig1 = imagesc(rand(100,100));
% climSlider(fig1, [0,2^16-1])
% % or even
% im = imagesc(rand(100,100));
% climSlider(im)

% Settings
s.debug = 0;

% Global data
g = []; % global data
g.object = []; % image
g.H = []; % image CData to calculate histogram from
g.Hv = []; % value of histogram
g.Hd = []; % domain of histogram
g.clim = []; % current clim
g.clims = {}; % saved clims per channel 1, 2, ...
g.clim_min = 0; % lowest possible value for the sliders
g.clim_max = 1; % largest possible value for the sliders
g.range = []; % same as clim_min, clim_max?
g.histoLine = []; % line that represents the histogram
g.channel = 1;

if nargin == 0
    g.object = imagesc(rand(100,100));
end

g.clim_min = [];
g.clim_max = [];

if nargin>0
    if numel(varargin{1})==0
        g.object = gca;
    else
        g.object = varargin{1};
    end
    
    for kk = 1:numel(varargin)
        if strcmpi(varargin{kk}, 'min')
            g.clim_min = varargin{kk+1};
        end
        if strcmpi(varargin{kk}, 'max')
            g.clim_max = varargin{kk+1};
        end
    end
end

if isa(g.object, 'matlab.graphics.primitive.Image')
    % Got an image   
    g.oAxes = g.object.Parent;
    g.clim = g.object.Parent.CLim;
    g.figNum = g.object.Parent.Parent.Number;
    g.H = g.object.CData;
else
    disp('Object has to be matlab.graphics.primitive.Image')
    g.win = [];
    return
end


[g.Hv, g.Hd] = histoH(g.H);

g.range(1) = min(g.H(:));
g.range(2) = max(g.H(:));


%% Initilize GUI
g.win = figure('Position', [0,650,300,300], 'Menubar', 'none', ...
    'NumberTitle','off', ...
    'Name', sprintf('climSlider Fig. %d', g.figNum), ...
    'Resize', 'on');

g.win.UserData = struct('updateFcn', @updateWin);

g.range(2) = max(g.range(2), g.clim(2));
if (numel(g.clim_max)>0)
    g.range(2) = max(g.range(2), g.clim_max);
end
g.range(1) = min(g.range(1), g.clim(1));
if (numel(g.clim_min)>0)
    g.range(1) = min(g.range(1), g.clim_min);
end

g.sliderLower = uicontrol(g.win,'Style','slider',...
    'Max',g.range(2),'Min', g.range(1),'Value',g.clim(1),...
    'Units', 'Normalized', ...
    'Position',[0 .1 .8 .1], ...
    'Callback', @climChange);

g.valueLower = uicontrol(g.win, 'Style', 'edit', ...
    'String', num2str(g.clim(1)), ...
    'Units', 'Normalized', ...
    'Position',[.8 .1 .2 .1], ...
    'Callback', @climChange);

g.sliderUpper = uicontrol(g.win,'Style','slider',...
    'Max',g.range(2),'Min', g.range(1),'Value',g.clim(2),...
    'Units', 'Normalized', ...
    'Position',[0 0 .8 .1], ...
    'Callback', @climChange);

g.valueUpper = uicontrol(g.win, 'Style', 'edit', ...
    'String', num2str(g.clim(2)), ...
    'Units', 'Normalized', ...
    'Position',[.8 0 .2 .1], ...
    'Callback', @climChange);

g.hax = subplot('Position',[0.05 .35 .9 .60]);
g.transfer = plot([g.Hd(1), g.clim, g.Hd(end)], ...
    [min(g.Hv(:)), min(g.Hv(:)), max(g.Hv(:)), max(g.Hv(:))], 'r', 'lineWidth', 2);

hold on
g.histoLine = plot(g.Hd, g.Hv, 'k', 'lineWidth', 2);


if (numel(g.Hd) > 1) && (numel(g.Hv) > 1)
    axis([g.Hd(1), g.Hd(end), min(g.Hv), max(g.Hv)]);
else 
    warning('Can''t set the axis properly -- something strange with the image?')
end



g.hax.YTickLabel = {};

win = g.win;  % return

%%


    function [Hv, Hd] = histoH(H)
        [Hv, Hd] = histcounts(H);
        Hd = linspace(mean(Hd(1:2)), mean(Hd(end-1:end)), numel(Hv));
    end

    function climChange(varargin)
        % Callback for the sliders
        
        if strcmp(varargin{1}.Style, 'edit')
            disp('edit')
            climt = [0,0];
            climt(1) = str2double(g.valueLower.String);
            climt(2) = str2double(g.valueUpper.String);
            if isfinite(prod(climt))
                g.clim = climt;
            end
        else            
            % Called when the sliders are released
            g.clim(1) = get(g.sliderLower, 'value');
            g.clim(2) = get(g.sliderUpper, 'value');
            g.clim = sort(g.clim);
        end
        
        updateWin(); % this will update the gui components and set the clim
        
    end

    function updateWin(varargin)
        % Call externally by: w.UserData.updateFcn()
        % and internally when clim is changed
        
        if s.debug
            disp('updateWin')
            disp(g.clim);
        end
        
        newChannel = 0;
        newH = 0;
        
        for kk = 1:numel(varargin)-1
            if strcmp(varargin{kk}, 'H')                
                newH = 1;
            end
            if strcmp(varargin{kk}, 'channel')
                g.lastChannel = g.channel;
                g.channel = varargin{kk+1};
                newChannel = 1;
                newH = 1;
            end
        end
        
        if newChannel == 1;
            g.clims{g.lastChannel} = g.clim;
            if numel(g.clims) >= g.channel
                if g.clims{g.channel}
                    g.clim = g.clims{g.channel};
                end
            else
                g.clim = g.object.Parent.CLim;
            end
        end
        
        if newH == 1
            g.H = g.object.CData;
            updateHistogram(g.H);
        end
        
        updateTransfer();
        updateSliders();
        setClim()
    end

    function updateHistogram(H)
        % New image to calculate histogram from
        [g.Hv, g.Hd] = histoH(H);
        set(g.histoLine, 'XData', g.Hd, 'YData', g.Hv);
    end

    function updateSliders()
        if s.debug
            disp('updateSliders')
        end
        g.sliderLower.Value = g.clim(1);
        g.sliderUpper.Value = g.clim(2);
        
        
        
        ax = [min(min(g.Hd),g.clim(1)), max(max(g.Hd),g.clim(2)), ...
            min(g.Hv), max(g.Hv)];
        g.sliderLower.Min = min(ax(1), min(g.clim(1), g.sliderLower.Value));
        g.sliderLower.Max = max(ax(2), max(g.clim(2), g.sliderUpper.Value));
        
        % Set same range to the slider for the upper value
        g.sliderUpper.Min = g.sliderLower.Min;
        g.sliderUpper.Max = g.sliderLower.Max;
        
        
        if g.sliderUpper.Min < g.clim(2) && g.sliderUpper.Max > g.clim(2)
            g.sliderUpper.Value = g.clim(2);
        end
        
        if g.sliderUpper.Min > g.clim(2)
            g.sliderUpper.Value = g.sliderUpper.Min;
        end
        
        if g.sliderUpper.Max < g.clim(2)
            g.sliderUpper.Value = g.sliderUpper.Max;
        end
        
        if g.sliderLower.Min < g.clim(1) && g.sliderLower.Max > g.clim(1)
            g.sliderLower.Value = g.clim(1);
        end
        
        if g.sliderLower.Min > g.clim(1)
            g.sliderLower.Value = g.sliderLower.Min;
        end
        
        if g.sliderLower.Max < g.clim(1)
            g.sliderLower.Value = g.sliderLower.Max;
        end
        
        g.valueUpper.String = num2str(g.clim(2));
        g.valueLower.String = num2str(g.clim(1));
        
        % update the axes of the histogram plot
        g.clim = double(g.clim);
        ax = [min(min(g.Hd),g.clim(1)), ...
            max(max(g.Hd),g.clim(2)), min(g.Hv(:)), max(g.Hv(:))];
                
        if ax(3) == ax(4)
            ax(4) = ax(3) + 1;
            warning('Problem setting the axes')
        end
        axis(g.hax, ax)
    end

    function updateTransfer()
        if s.debug
            disp('updateTransfer')
        end        
        % Updates the transfer function (red curve) as well as the sliders
        g.transfer.XData = [min(g.Hd(1), g.clim(1)), ...
            g.clim(1),...
            g.clim(2),...
            max(g.Hd(end), g.clim(2))];
        g.transfer.YData = [min(g.Hv(:)),...
            min(g.Hv(:)),...
            max(g.Hv(:)),...
            max(g.Hv(:))];
    end

    function setClim()
        % Update the clim of the connected object
        set(g.oAxes, 'CLim', g.clim);
    end

end