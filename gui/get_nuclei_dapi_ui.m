function [mask, refine, P] = get_nuclei_dapi_ui(V,s)
%% function [N, mask, P] = get_nuclei_dapi_ui(V,s)
% Interactive segmentation of nuclei (DAPI or HOECHT) or cells (other
% channels)
% Works together with get_nuclei_dapi.m
%
% 2017-02-08, added local projection, inspired by smiFISH
% 2017-10-24, 
% - some factorization, moving bg estimation to df_bgEstimation
% - Also made the background estimation more subtle and useful!
% - This function would like some more factoriation and cleanup!
%
% Call with no parameters for testing

refine = 0;
addpath([getenv('DOTTER_PATH') '/addons/structdlg/']);

if  nargin>2
    warning('Wrong number of inputs')
    return
end

if nargin == 0
    disp('Test mode')
    testFolder = df_getConfig('DOTTER', 'testFolder', '');
    if numel(testFolder) == 0
        warning('no testFolder set');
        return
    end
    testImage = [testFolder '/dapi_001.tif'];
    V = df_readTif(testImage);
end

if nargin<2
    s=[];
    s.testMode = 1;
end


if ~isfield(s, 'useWatershed')
    s.useWatershed = 1;
end

s.excludeOnEdge=1;
s.useLP = 1;
s.useDS = 1;
s.DS_size = 7;
s.hpSigma = 4;
s.mrfMean1 = 10;
s.mrfStd1 = 5;
s.mrfMean2 = 20;
s.mrfStd2 = 5;
s.mrfSigma = 5;
s.usePrefilter = 0;
s.projectionType = 'max'; % median, mean
s.localContrastProjection = [];
% min and max area of nuclei, given in pixels

s.minarea = 500; 
s.maxarea = 60000;

if isfield(s, 'voxelSize')
    s.minarea = s.minarea*(130^2/s.voxelSize(1)^2);
    s.maxarea = s.maxarea*(130^2/s.voxelSize(1)^2);
end

gui.win = figure('Position', [300,200,1024,1024], 'Menubar', 'none', ...
    'NumberTitle','off', ...
    'Name', 'NUCLEI-segmenter');

%% Display current segmentation
gui.dapiPlot = subplot('Position', [.15,.15,.8,.8]);
gui.im = imagesc(imread([getenv('DOTTER_PATH') 'logo.jpg']), 'ButtonDownFcn', @imClick);

gui.c1 = uicontextmenu();
gui.im.UIContextMenu = gui.c1;
gui.m1 = uimenu(gui.c1, 'Label', 'Split', 'Callback', @splitNuclei);
gui.m1 = uimenu(gui.c1, 'Label', 'More Settings', 'Callback', @showSettings);

colormap gray
hold on
axis image
axis ij


V = single(V);

s.firstZ = 1;
s.lastZ = size(V,3);
gui.I = projectVolume(V, s);
[nuclei, mask, s]= get_nuclei_dapi(gui.I, s);
gui.nSelected = ones(numel(nuclei), 1);
gui.mask = mask;
gui.N = nuclei;
splitPosition = [];
s.contrast = [];
gui.contrastWindow = [];

updateImage()

if numel(gui.N)>0
    [~, gui.contour] = contour(gui.mask, [.5,.5], 'r', 'ButtonDownFcn', @imClick);
else
    gui.contour = [];
end

gui.box = [];

axis off
for tt = 1:numel(gui.N)
    gui.box{tt}= plotbbx(gui.N{tt}, sprintf('%d', tt), 1);
end

axis image


setZauto();

%% Add controls

gui.zSlicesPanel = uipanel('Position', [0, .90, .12, .1], 'Title', 'Z-slices');
gui.Projection = uipanel('Position', [0, .75, .12, .1], 'Title', 'Projection');

uicontrol('Parent', gui.zSlicesPanel, 'Style', 'pushbutton', ...
    'String', 'aid', ...
    'Units', 'Normalized', ...
    'Position',[0.01 0.01 .5 .3], ...
    'Callback', @showSliceContrast);

gui.setZ = uicontrol('Style', 'pushbutton', 'String', 'use', ...
    'Parent', gui.zSlicesPanel, ...
    'Units', 'Normalized', ...
    'Position', [0.5, 0, 0.5 1/3], ...
    'Callback', @setZ);

uicontrol('Style', 'text', 'String', 'From', ...
    'Parent', gui.zSlicesPanel, ...
    'Units', 'Normalized', ...
    'Position', [0, 2/3, 0.5 1/3]);

uicontrol('Style', 'text', 'String', 'To', ...
    'Parent', gui.zSlicesPanel, ...
    'Units', 'Normalized', ...
    'Position', [.5, 2/3, 0.5 1/3]);


gui.firstZ = uicontrol('Style', 'edit', 'String', s.firstZ, ...
    'Parent', gui.zSlicesPanel, ...
    'Units', 'Normalized', ...
    'Position', [0, 1/3, 0.5 1/3]);

gui.lastZ = uicontrol('Style', 'edit', 'String', s.lastZ, ...
    'Parent', gui.zSlicesPanel, ...
    'Units', 'Normalized', ...
    'Position', [.5, 1/3, 0.5 1/3]);

gui.projMethod = uicontrol('Style', 'popup', 'String', {'max', 'median', 'mean'}, ...
    'Parent', gui.Projection, ...
    'Units', 'Normalized', ...
    'Position', [0, 0, 1 1], ...
    'Callback', @projectionChanged);

gui.excludeOnEdge = uicontrol('Style', 'checkbox', 'String', 'Exclude On Edge', ...
    'Position', [5,650,100,80], ...
    'Value', s.excludeOnEdge, ...
    'Callback', @update);

gui.ds = uicontrol('Style', 'checkbox', 'String', 'DOT supression', ...
    'Position', [5,400,100,20], ...
    'Value', s.useDS, 'Callback', @update_clear);

gui.hp = uicontrol('Style', 'checkbox', 'String', 'HP filter', ...
    'Position', [5,350,100,20], ...
    'Value', s.useLP, 'Callback', @update_clear);

gui.hpsigma = uicontrol('Style', 'edit', ...
    'String', s.hpSigma, ...
    'Position', [5, 300, 60, 20]);

gui.pf = uicontrol('Style', 'checkbox', 'String', 'Glow filter', ...
    'Position', [5,250,100,20], ...
    'Value', s.usePrefilter, ...
    'Callback', @glowSwitch);

gui.ws = uicontrol('Style', 'checkbox', 'String', 'Watershed', ...
    'Position', [5,200,100,20], ...
    'Value', s.useWatershed, ...
    'Callback', @wsSwitch);

uicontrol('Style', 'pushbutton', ...
    'String', 'Done', ...
    'Position',[5 5 60 20], ...
    'Callback', @done);

uicontrol('Style', 'pushbutton', ...
    'String', 'Manual', ...
    'Position',[5 30 60 20], ...
    'Callback', @manual);

uicontrol('Style', 'pushbutton', ...
    'String', 'Update', ...
    'Position',[5 60 60 20], ...
    'Callback', @update);

uicontrol('Style','text',...
    'String', 'Threshold',...
    'Position',[5 130 100 30]);

gui.level = uicontrol('Style', 'edit', ...
    'String', s.level, ...
    'Position', [5, 100, 60, 20]);

gui.cPlot = []; % Contrast plot

updateHistogram

set(gcf, 'WindowButtonDownFcn', @thresholdSlide);

disp('Waiting for input')
set(gcf, 'WindowKeyPressFcn', @shortcuts)

uiwait(gcf);

if numel(gui.N)>0
    N = {gui.N{find(gui.nSelected>0)}};
else
    N = {};
end

% Exclude de-selected from the output mask
mask = gui.mask;
excluded = sort(find(gui.nSelected==0));
for kk = 1:numel(excluded)
    mask(mask==excluded(kk))=0;
    mask(mask>excluded(kk)) = mask(mask>excluded(kk))-1;
    excluded(excluded>excluded(kk)) = excluded(excluded>excluded(kk))-1;
end

if isvalid(gui.win)
    close(gui.win);
end

if numel(gui.cPlot)>0
    if isvalid(gui.cPlot)
        close(gui.cPlot)
    end
end
    function showSliceContrast(varargin)
        % s.contrast, gui.contrastwindow
        
        if numel(s.contrast) == 0
            s.contrast = getSliceContrast(V);
        end
        
        if numel(gui.cPlot) == 0
            gui.cPlot = figure();
        end
        
        if isvalid(gui.cPlot)
            figure(gui.cPlot);
        else
            gui.cPlot = figure();
        end
        
        clf
        
        plot(s.contrast, 'k');
        xlabel('Z')
        ylabel('Gradient Magnitude')
        grid on
        hold on
        minc = min(s.contrast);
        maxc = max(s.contrast);
        yd = [minc, maxc];
        plot([s.firstZ, s.firstZ], yd, 'r');
        plot([s.lastZ, s.lastZ], yd, 'b');
        legend({'Focus', 'first slice', 'last slice'});
        
    end

    function updateImage()
        gui.im.CData = gui.I;
    end

    function shortcuts(varargin)
        key = varargin{2}.Key;
        if strcmp(key, 'return')
            done()
        end
        if strcmp(key, 'backspace')
            %    manual()
        end
        if strcmp(key, 'e')
            newS = StructDlg(s);
            if numel(newS)>0
                s = newS;
            else
            end
        end
        if strcmp(key, 's')
            %% Shortcut 's' : write image to disk
            cdata = [];
            folder = [];
            
            figure(gui.win)
            
            frame= getframe();
            [file, folder] = uiputfile('*.png');
            if ~isnumeric(file)
                filename = [folder, file];
                disp(['Writing to: ' filename])
                imwrite(frame.cdata, filename);
            end
            
        end
        
    end

    function updateHistogram
        gui.hPlot = subplot('Position', [.12, 0.02,.8,.10]);
        hold off
        gui.histogram = histogram(gui.I(:)/max(gui.I(:)), 'FaceColor', [.5,.5,.5], 'EdgeColor', 'none');
        ax = axis;
        hold on
        gui.levelslide = plot([s.level, s.level], ax(3:4), 'r');
        %set(get(gui.histogram, 'Parent'), 'Yscale', 'log'); No improvement        
        subplot(gui.dapiPlot);
    end

    function wsSwitch(varargin)
        update();
        updateImage();
    end

    function glowSwitch(varargin)        
        if get(gui.pf, 'Value') == 1            
            % Project again, not to apply this several times            
            gui.I = projectVolume(V, s);
            
            for kk = 1:3
            bg = df_bgEstimation(gui.I);
            if numel(bg) == 1
                gui.I = gui.I-bg+mean(bg(:));
            end
            end
           
            resetLevel();
            update();
            updateHistogram();
            updateImage();
        else
            gui.I = projectVolume(V, s);
            resetLevel();            
            update()
            updateHistogram()
            updateImage()
        end
    end

    function thresholdSlide(objectHandle , eventData )
        if gca == gui.hPlot
            coordinates = get(gui.hPlot,'CurrentPoint');
            level = coordinates(1);
            set(gui.levelslide, 'XData', [1,1]*level);
            s.level = level;
            set(gui.level, 'String', sprintf('%.3f', s.level));
            subplot(gui.dapiPlot);
            update
        end        
    end

    function resetLevel(varargin)
        set(gui.level, 'String', '-');
    end

    function imClick(varargin)                
        location = varargin{2}.IntersectionPoint;        
        if varargin{2}.Button == 1        
        for tt = 1:numel(gui.N)
            if inbbx(gui.N{tt}, location)
                delete(gui.box{tt}(1:5));
                if gui.nSelected(tt)
                    gui.box{tt}= plotbbx(gui.N{tt}, sprintf('%d', tt), 0);
                    gui.nSelected(tt) = 0;
                else
                    gui.box{tt}= plotbbx(gui.N{tt}, sprintf('%d', tt), 1);
                    gui.nSelected(tt) = 1;
                end
            end
        end
        end
        
        if varargin{2}.Button > 1             
                % consider disabling the context menu if no nuclei here
                % gui.im.UIContextMenu = gui.c1;                                
            splitPosition = location(1:2);
        end
    end

    function update_clear(varargin)
        if isfield(s, 'level')
            disp('clearing level')
            s = rmfield(s, 'level');
            set(gui.level, 'String', '-')
        end
        update(varargin)
    end

    function update(varargin)
        set(gui.win, 'Pointer', 'watch');
        drawnow
        
        s.thresholding = 1;
        s.mrfGC = 0;
        
        s.excludeOnEdge = get(gui.excludeOnEdge, 'Value');
                
        s.level = str2num(get(gui.level, 'String'));
        if numel(s.level) == 0
            s = rmfield(s, 'level');
        end
        s.useWatershed = get(gui.ws, 'Value');
        s.usePrefilter = get(gui.pf, 'Value');
        
        s.useLP = get(gui.hp, 'Value');
        s.useDS = get(gui.ds, 'Value');
        
        s.hpSigma = str2num(get(gui.hpsigma, 'String'));
                        
        
        
        [nuclei, mask, s]= get_nuclei_dapi(gui.I, s);
        set(gui.level, 'String', num2str(s.level));
        gui.nSelected = ones(numel(nuclei), 1);
        gui.mask = mask;
        gui.N = nuclei;
        delete(gui.contour);
        if numel(gui.N)>0
            [~, gui.contour] = contour(gui.mask, [.5,.5], 'r', 'PickableParts','none', 'hitTest', 'off');
        end
        
        for tt = 1:numel(gui.box)
            delete(gui.box{tt}(1:5));
        end
        gui.box(tt) = [];
        
        for tt = 1:numel(gui.N)
            gui.box{tt}= plotbbx(gui.N{tt}, sprintf('%d', tt), 1);
        end
        set(gui.win, 'Pointer', 'arrow');
        set(gui.levelslide, 'XData', s.level*[1,1]);
        
        disp('Done updating');
    end

    function done(varargin)
        % Parse settings
        P = gui.I;
        uiresume(gcbf);
    end

    function manual(varargin)
        refine = 1;
        done();
    end

    function within = inbbx(N, xy)
        % See if a point is within the bbx of N
        within = 0;
        if(N.bbx(1)<xy(2) && N.bbx(2)>xy(2) && ...
                N.bbx(3)<xy(1) && N.bbx(4)>xy(1) )
            within = 1;
        end
    end

    function h = plotbbx(N, label, color)
        if color == 1
            x = 'g';
        else
            x = 'b';
        end
        h(1) = plot([N.bbx(3), N.bbx(3)], [N.bbx(1), N.bbx(2)], x, 'HitTest', 'off', 'PickableParts','none');
        h(2) = plot([N.bbx(4), N.bbx(4)], [N.bbx(1), N.bbx(2)], x, 'HitTest', 'off', 'PickableParts','none');
        h(3) = plot([N.bbx(3), N.bbx(4)], [N.bbx(1), N.bbx(1)], x, 'HitTest', 'off', 'PickableParts','none');
        h(4) = plot([N.bbx(3), N.bbx(4)], [N.bbx(2), N.bbx(2)], x, 'HitTest', 'off', 'PickableParts','none');
        h(5) = text(N.bbx(3), N.bbx(1), label, 'Color', [1,0,0], 'FontSize', 14, 'HitTest', 'off',  'PickableParts','none');
    end

    function I = projectVolume(V, s)
        % Create a 2D projection of V
        if strcmp(s.projectionType, 'mean')
            I = sum(V(:,:,s.firstZ:s.lastZ),3);
        end
        
        if strcmp(s.projectionType, 'median')
            I = median(V(:,:,s.firstZ:s.lastZ),3);
        end
        
        if strcmp(s.projectionType, 'max')
            I = max(V(:,:,s.firstZ:s.lastZ),[], 3);
        end
        
        if strcmp(s.projectionType, 'local')
            gui.win.Pointer = 'watch';
            drawnow
            if numel(s.localContrastProjection) == 0
                s.localContrastProjection = localContrastProjection(V);
            end
            I = s.localContrastProjection;
            gui.win.Pointer = 'arrow';
        end        
        I = I- min(I(:));
        I = I/max(I(:));        
    end
    

    function setZauto()
        % Selects an interval of z-slices which covers the top 50%
        % in-contrast slices. Other approaches could also be considered
        % like setting at threshold at .5*(max-min)+min
        
        if numel(s.contrast) == 0
            
            s.contrast = df_image_focus('image', V);
                                    
            ma = max(s.contrast);
            if(size(V,3)>1)
                maLocation = find(s.contrast==ma);
                if min(maLocation) < 5 || max(maLocation)>(size(V,3)-4)
                    warning('Focus seems to be very close to the edge in this image')
                end
            end            
        end
        
        pslices = .15; % Proportion of slices to use
        t = sort(s.contrast);
        cMin = t(ceil((1-pslices)*numel(t)));                
        z = find(s.contrast>cMin);
        if numel(z)==0
            warning('No contrast could be determined');
            s.firstZ = 0;
            s.lastZ = size(V,3);
            return
        end
        if 0
            f=figure;
            plot(s.contrast)
            hold on
            plot(t)
            pause
            close(f)
        end
        s.firstZ = z(1);
        s.lastZ = z(end);        
    end

    function setZ(varargin)
        
        f1 = str2num(gui.firstZ.String);
        f2 = str2num(gui.lastZ.String);
        
        if(f1>0 && f2<=size(V,3) && f2>f1)
            s.firstZ = f1;
            s.lastZ = f2;
            
            gui.I = projectVolume(V, s);
            updateImage()
            if numel(gui.cPlot)>0
                if isvalid(gui.cPlot)
                    showSliceContrast
                end
            end
        else
            warning('Not a valid range')
            gui.firstZ.String = num2str(s.firstZ);
            gui.lastZ.String = num2str(s.lastZ);
        end
    end

    function projectionChanged(varargin)
        disp('projectionChanged')
        s.projectionType = gui.projMethod.String{gui.projMethod.Value};
        gui.I = projectVolume(V, s);
        updateHistogram();
        updateImage();
    end

    function I = localContrastProjection(V)
        % Something like what is used in tsanov2016smifish, also P. Malm,
        % etc
        
        % For each slice, determine the local contrast in each pixel
        dx = gpartial(V,1,1.5);
        dy = gpartial(V,2,1.5);
        gm = (dx.^2+dy.^2).^(1/2);
        
        % For each xy, use the median of the 5 pixels with highest contrast
        [~, idx] = sort(gm, 3);
        
        nxy = 5; % number of pixel per xy
        
        if 1
            II = zeros(size(V,1), size(V,2), nxy);
            % How to write this efficiently
            for kk = 1:size(II,1)
                for ll = 1:size(II,2)
                    for nn = 1:nxy
                        II(kk,ll, nn) = V(kk,ll,idx(kk,ll, nn));
                    end
                end
            end
            I = median(II,3);
        end
        
        % I = V(idx(:,:,3));
    end

    function splitNuclei(varargin)
       disp('To do ');        
       label = interpn(mask, splitPosition(2), splitPosition(1), 'nearest');
       msgbox(sprintf('Function: splitNuclei()\nTo split nuclei %d, ask for this feature to be implemented', label));
       % Heuristics to try: 
       % - for each large cluster of nuclei, find local
       %   threshold.
       % - Connect points on edge with high curvature (greedy, recursively)
       % - Snakes
       % - etc...       
    end

    function showSettings(varargin)
        t = StructDlg(s);
        if numel(t)>0
            s = t;
        end       
    end

end
