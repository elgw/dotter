function win = thSlider(varargin)
% function thSlider(varargin)
% threshold slider for some parameter
%
% Example:
% data = rand(100,1);
% thSlider('Data', data, 'threshold', .5);
% thSlider.UserData.

th = [];
data = [];
cbFun = [];
for kk = 1:numel(varargin)
    if strcmp(varargin{kk}, 'Data')
        data = varargin{kk+1};
    end
    if strcmp(varargin{kk}, 'Threshold')
        th = varargin{kk+1};
    end
    if strcmp(varargin{kk}, 'Callback')
        cbFun = varargin{kk+1};
    end
end

assert(numel(data)>0);
if numel(th)==0
    th = mean(data);
end

[Hv, Hd] = histoH(data);

%    'Menubar', 'none', ...
win = figure('Position', [500,200,500,200], ...
    'NumberTitle','off', ...
    'Name', 'thSlider', ...
    'Resize', 'on');


win.UserData = struct('setTh', @setTh);

range = [];
range(1) = min(th, Hd(1));
range(2) = max(th, Hd(end));
thSlider = uicontrol(win,'Style','slider',...
    'Max',range(2),'Min', range(1),'Value',th,...
    'Units', 'Normalized', ...
    'Position',[0 0 1 .1], ...
    'Callback', @thChange);

hax = subplot('Position',[0.05 .3 .9 .65]);

thLine = plot([th, th], [min(Hv(:)), max(Hv(:))], 'r', 'lineWidth', 2);
c = uicontextmenu();
m1 = uimenu(c, 'Label', 'LogY', 'Callback', @logY);
m1 = uimenu(c, 'Label', 'LinY', 'Callback', @logY);
hax.UIContextMenu = c;

hold on
histo = plot(Hd, Hv, 'k', 'lineWidth', 2);

if(Hd(1)<Hd(end) && max(Hv)>min(Hv))    
    axis([Hd(1), Hd(end), min(Hv), max(Hv)])
end

hax.ButtonDownFcn = @setThHere;

hax.YTickLabel = {};

    function setThHere(varargin)
        disp('To Do');
    end

    function logY(varargin)
        switch varargin{2}.Source.Label
            case 'LogY'
                hax.YScale = 'log';
            case 'LinY'
                hax.YScale = 'linear'                
        end
    end

    function [Hv, Hd] = histoH(H)
        [Hv, Hd] = histcounts(H);
        Hd = linspace(mean(Hd(1:2)), mean(Hd(end-1:end)), numel(Hv));
    end

    function setTh(thres)
        % Get threshold externally
        %fprintf('thSlider got new th: %f\n', thres);
        th = thres;       
        th = max(th, range(1));
        th = min(th, range(2));
        thSlider.Value = th;
        updateWin();
    end

    function thChange(varargin)
        % Called when the sliders are released
        th = get(thSlider, 'value');
        updateWin()
        
        try
            if isa(cbFun, 'function_handle')
                cbFun(th)
            end
        catch
            warning('thSlider could not set the threshold')
        end
        
    end

    function updateWin(varargin)
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
                axis(hax, ax)
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
        
    end
end