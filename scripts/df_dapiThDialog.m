function th = df_dapiThDialog(D, th)
% function th = df_dapiThDialog(D)
% Pick an upper threshold for DAPI
%

if ~exist('D', 'var')
    close all
    D = 10^9*rand(100,1);
end

if ~exist('th', 'var')
    th = median(D);
end

gui.isok = 0; % set to 1 if 'Ok' was pressed at exit
gui.f = figure('Name', 'Set upper threshold for DAPI', 'NumberTitle', 'off');
gui.a = axes('Units', 'Normalized', ...
    'Position', [0.1,0.25,.8,.7]);
gui.h = histogram('Parent', gui.a, D, round(numel(D)/2));
hold on
ax = axis();
gui.thLine = plot([th, th], [ax(3), ax(4)], 'LineWidth', 2);

set(gui.f, 'WindowButtonDownFcn', @interStart);

gui.thValue = uicontrol('Style', 'text', ...
    'String', '', ...
    'Units', 'Normalized', ...
    'Position', [0.1,0,.8,.2], ...
    'Callback', @ok, ...
    'Parent', gui.f, ...
    'HorizontalAlignment','left', ...
    'FontName', get(0,'FixedWidthFontName'));

gui.ok = uicontrol('Style', 'pushbutton', ...
    'String', 'Ok', ...
    'Units', 'Normalized', ...
    'Position', [0.85,0.05,.1,.1], ...
    'Callback', @ok, ...
    'Parent', gui.f);

setTh(th);

uiwait(gui.f);

if gui.isok == 0
    th = [];
end

if isvalid(gui.f)
    close(gui.f);
end

function ok(varargin)
    gui.isok = 1;
    uiresume();
end

    function interStart(varargin)
        gco
        if gco == gui.h | gco == gui.a
            x = get(gui.a, 'CurrentPoint'); x = x(1);        
            setTh(x);          
        end
        if gco == gui.thLine
            set(gui.f, 'WindowButtonMotionFcn', @lineDrag);  
            set(gui.f, 'WindowButtonUpFcn', @stopDrag);
        end
    end

    function stopDrag(varargin)
            set(gui.f, 'WindowButtonMotionFcn', []);  
    end

    function lineDrag(varargin)
           x = get(gui.a, 'CurrentPoint'); x = x(1);
           setTh(x);
    end

    function setTh(x)
        gui.thLine.XData = ones(1,2)*x;
        th = x;
        gui.thValue.String = sprintf('Nuclei: %d\nTh: %.2e\nAbove: %d\nBelow: %d', numel(D), th, sum(D>th), sum(D<th));     
    end


end