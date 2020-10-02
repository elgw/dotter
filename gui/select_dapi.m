function [ldapi, rdapi] = select_dapi(D, outFolder)
% function [ldapi, rdapi] = select_dapi(D)
% Shows the histogram of D, assumed to be the sum of DAPI over a set of
% cells. Suggests how to set a lower value and an upper value to select G1
% cells by default and alows other choices.

% D = [1000+100*randn(150,1);  2000+125*randn(100,1)];
if exist('outFolder', 'var')
    if ~exist(outFolder, 'dir')
        mkdir(outFolder)
    end
end

maxDapi = max(D(:));
minDapi = min(D(:));
midDapi = graythresh(D/max(D(:)))*max(D(:));

assert(midDapi<maxDapi);
assert(midDapi>minDapi);

fig = figure('Position', [400,400,640,480], 'Menubar', 'none', ...
    'Color', [1,1,1], ...
    'NumberTitle','off', ...
    'Name', sprintf('DAPI Selector, %d cells', numel(D)));

subplot('Position', [.1, .2, .8, .7])

btn_g1 = uicontrol(fig,'Style','pushbutton',...
    'String','G1',...
    'Position',[10 10 60 30], ...
    'Callback', @select_g1); % Select the G1 phase
btn_g2 = uicontrol(fig,'Style','pushbutton',...
    'String','G2',...
    'Position',[80 10 60 30], ...
    'Callback', @select_g2); % Select the G1 phase
btn_all = uicontrol(fig,'Style','pushbutton',...
    'String','All',...
    'Position',[150 10 60 30], ...
    'Callback', @select_all); % Select the G1 phase
btn_manu = uicontrol(fig,'Style','pushbutton',...
    'String','Manual',...
    'Position',[220 10 60 30], ...
    'Callback', @manu); % Select the G1 phase
btn_done = uicontrol(fig,'Style','pushbutton',...
    'String','Done',...
    'Position',[290 10 60 30], ...
    'Callback', @done); % Select the G1 phase

histogram(D, 'BinMethod', 'sqrt')

ax = axis;
aH = gca;

ldapi = minDapi-1;
rdapi = midDapi+1;

hold on
plot(D(:), 0*D(:), 'ko')

left  = plot([ldapi, ldapi], [ax(3), ax(4)], 'LineWidth', 2, 'Color', [0.8500 0.3250 0.0980]);
right = plot([rdapi, rdapi], [ax(3), ax(4)], 'LineWidth', 2, 'Color', [0.9290 0.6940 0.1250]);
jLine = plot([ldapi, rdapi], [.99*ax(4)]*[1,1], 'LineWidth', 2, 'Color', [0, 0, 0]);



set(left,  'ButtonDownFcn', @startDragFcn)
set(right, 'ButtonDownFcn', @startDragFcn)
set(fig, 'WindowButtonUpFcn', @interEnd);

%set(f, 'WindowButtonUpFcn', @interEnd);
%set(f, 'WindowButtonDownFcn', @interStart);
set(fig, 'WindowKeyPressFcn', @keySwitch)

uiwait(fig);
close(fig);

    function startDragFcn(varargin)
        if strcmp(get(fig, 'WindowButtonDownFcn'), '')
            set(fig, 'WindowButtonMotionFcn', @draggingFcn)
        else
            set(fig, 'WindowButtonMotionFcn', '')
        end
    end



    function draggingFcn(varargin)
        pt = get(aH, 'CurrentPoint');
        if pt(1,1)>minDapi && pt(1,1)<maxDapi
            set(gco, 'Xdata', [pt(1,1) pt(1,1)])
            ldapi = get(left, 'Xdata');
            ldapi = ldapi(1);
            rdapi = get(right, 'Xdata');
            rdapi = rdapi(1);
            updateLines();
        end
    end

    function interEnd(varargin)
        set(fig, 'WindowButtonMotionFcn', '')
    end

    function done(varargin)        
        if exist('outFolder', 'var')
            dprintpdf([outFolder 'dapiSelection.pdf'], 'fig', fig, 'w', 15, 'h', 10)
        end
        uiresume(fig);
    end

    function keySwitch(varargin)
        key = varargin{2}.Key;
        if strcmp('key', 'return')
            done()
        end
    end

    function updateLines()
        set(left, 'XData', [ldapi, ldapi]);
        set(right, 'XData', [rdapi, rdapi]);
        set(jLine, 'Xdata', [ldapi, rdapi]);
    end

    function select_g1(varargin)
        ldapi = minDapi;
        rdapi = midDapi;
        updateLines()
    end

    function select_g2(varargin)
        ldapi = midDapi;
        rdapi = maxDapi;
        updateLines()
    end

    function select_all(varargin)
        ldapi = minDapi;
        rdapi = maxDapi;
        updateLines()
    end

    function manu(varargin)
        ldapi = str2double(inputdlg('Lower value for DAPI:'));
        rdapi = str2double(inputdlg('Upper value for DAPI:'));
        updateLines();
    end

end