function [mask3, mask] = get_nuclei_dapi_3_ui(V,s)
%% function [N, mask] = get_nuclei_dapi_ui(V,s)
%
% Interactive segmentation of nuclei (DAPI or HOECHT) or cells (other
% channels)
% Works together with get_nuclei_dapi3.m
%

%% Parse inputs and define settings in s
if nargin<1 || nargin>2
    warning('Wrong number of inputs')
    return
end

if nargin==1
    warning('No default settings given');
    s=[];
end

if ~isfield(s, 'useWatershed')
    s.useWatershed = 0;
end

s.excludeOnEdge=1;
s.useHP = 1;
s.hpSigma = 1;
s.usePrefilter = 0;
s.localContrastProjection = [];

V = single(V);

s.firstZ = 1; % Range to use for automatic threshold selection
s.lastZ = size(V,3);
s.slice = round(size(V,3)/2);

gui.I = V(:,:,s.slice); % image to show

[nuclei, mask3, s]= get_nuclei_dapi_3(V, s);
if numel(mask3) == 0
    warning('dapi segmentation failed');
    mask = [];
    return
end

gui.nSelected = ones(numel(nuclei), 1);
gui.mask = mask3(:,:,s.slice);
gui.mask3 = mask3;
gui.N = nuclei;

s.contrast = [];
gui.contrastWindow = [];

%% Initiate window
gui.win = figure('Position', [300,200,1024,1024], 'Menubar', 'none', ...
    'NumberTitle','off', ...
    'Name', '3D DAPI-segmenter');
gui.win.Pointer = 'watch';
drawnow

%% Display current segmentation
figure(gui.win);
gui.dapiPlot = subplot('Position', [.15,.15,.8,.8]);
gui.im = imagesc(V(:,:,s.slice), 'ButtonDownFcn', @imClick);
colormap gray
hold on
axis image
axis ij

updateImage()

setZauto(); % updates s.firstZ and s.lastZ


addControls();

disp('GUI loop')
gui.win.Pointer = 'arrow';
uiwait(gcf);

% When the GUI is closed
if numel(gui.N)>0
    N = {gui.N{find(gui.nSelected>0)}};
else
    N = {};
end

% Exclude de-selected from the output mask
mask = gui.mask;
mask3 = gui.mask3;

excluded = sort(find(gui.nSelected==0));
for kk = 1:numel(excluded)
    mask(mask==excluded(kk))=0;
    mask(mask>excluded(kk)) = mask(mask>excluded(kk))-1;
    excluded(excluded>excluded(kk)) = excluded(excluded>excluded(kk))-1;
end

if isvalid(gui.win)
    close(gui.win);
end

    function addControls()
        
        % Image has Position [.15,.15,.8,.8]
        %keyboard
        gui.sPanel = uipanel(...
            'Title', 'Settings', ...
            'Units', 'Normalized', ...
            'Position',[0.01 0.15 .15-0.02 .85]);
        
        gui.thPanel = uipanel('Parent', gui.sPanel,...
            'Units', 'Normalized', ...
            'Position', [0, .75, 1, .10],...
            'Title', 'Threshold');
        
        gui.level = uicontrol(...
            'Parent', gui.thPanel, ...
            'Style', 'edit', ...
            'String', s.level, ...
            'Units', 'Normalized', ...
            'Position', [0, 1/3, .5, 1/3]);
        
        gui.level = uicontrol(...
            'Parent', gui.thPanel, ...
            'Style', 'pushbutton', ...
            'String', 'set', ...
            'Units', 'Normalized', ...
            'Position', [.5, 1/3, .5, 1/3], ...
            'Callback', @update);
        
        
        gui.zSlicesPanel = uipanel('Parent', gui.sPanel,...
            'Units', 'Normalized', ...
            'Position', [0, .10, 1, .18],...
            'Title', 'Z-slices');
        
        uicontrol('Parent', gui.zSlicesPanel, 'Style', 'pushbutton', ...
            'String', 'aid', ...
            'Units', 'Normalized', ...
            'Position',[0.01 0.01 .5 .3], ...
            'Callback', @showSliceContrast);
        
        gui.setZ = uicontrol('Style', 'pushbutton', 'String', 'use', ...
            'Parent', gui.zSlicesPanel, ...
            'Units', 'Normalized', ...
            'Position', [0.5, 0.01, 0.5 .3], ...
            'Callback', @setZ);
        
        
        gui.slice = uicontrol('Style', 'text', ...
            'String', 'Z', ...
            'Units', 'Normalized', ...
            'Position', [0.96, .95, 0.04, .05], ...
            'Callback', @updateSlice);
        
        gui.slice = uicontrol('Style', 'slider', ...
            'Min',1,'Max',size(V,3),'Value',s.slice,...
            'Units', 'Normalized', ...
            'Position', [0.96, 0, 0.04, .95], ...
            'Callback', @updateSlice);
        
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
        
        gui.pf = uicontrol('Style', 'checkbox', ...
            'String', 'Glow filter', ...
            'Parent', gui.sPanel, ...
            'Units', 'Normalized', ...
            'Position', [0, .45, 1, .05], ...
            'Value', s.usePrefilter, ...
            'Callback', @glowSwitch);
        
        gui.excludeOnEdge = uicontrol('Style', 'checkbox', ...
            'String', 'Exclude On Edge', ...
            'Parent', gui.sPanel, ...
            'Units', 'Normalized', ...
            'Position', [0, .40, 1, .05], ...
            'Value', s.excludeOnEdge);
        
        
        gui.ws = uicontrol('Style', 'checkbox', 'String', 'Watershed', ...
            'Parent', gui.sPanel, ...
            'Units', 'Normalized', ...
            'Position', [0, .5, 1, .05], ...
            'Value', s.useWatershed);
        
        uicontrol('Style', 'text', ...
            'String', 'sigma', ...
            'Parent', gui.sPanel, ...
            'Units', 'Normalized', ...
            'Position', [0, .55, .5, .05]);
        
        gui.hpsigma = uicontrol('Style', 'edit', ...
            'String', s.hpSigma, ...
            'Parent', gui.sPanel, ...
            'Units', 'Normalized', ...
            'Position', [.5, .55, .5, .05]);
        
        gui.hp = uicontrol('Style', 'checkbox', 'String', 'HP filter', ...
            'Parent', gui.sPanel, ...
            'Units', 'Normalized', ...
            'Position', [0, .6 1, .05], ...
            'Value', s.useHP, 'Callback', @update);                
        
         uicontrol('Style', 'pushbutton', ...
            'String', 'Done', ...
            'Units', 'Normalized', ...
            'Position', [0.01, 0.01 .09, .03], ...
            'Callback', @done, ...
            'Background', [0,1,0]);                
        
        uicontrol('Style', 'pushbutton', ...
            'Parent', gui.sPanel, ...
            'Units', 'Normalized', ...
            'Position', [0, 0, 1, .05], ...
            'String', 'Update segmentation', ...
            'Position',[5 60 60 20], ...
            'Callback', @update);
        
        updateHistogram()
        
        set(gcf, 'WindowButtonDownFcn', @thresholdSlide);
        set(gcf, 'WindowKeyPressFcn', @shortcuts)
    end

    function showSliceContrast(varargin)
        % s.contrast, gui.contrastwindow
        
        if numel(s.contrast) == 0
            s.contrast = getSliceContrast(V);
        end
        
        figure,
        plot(s.contrast)
        xlabel('Z')
        ylabel('Gradient Magnitude')
        
    end

    function updateSlice(varargin)
        % When the gui.slice is changed, to set the Z position
        s.slice = round(gui.slice.Value);
        %fprintf('Set slice to %d\n', s.slice);
        gui.I = V(:,:,s.slice);
        gui.mask = gui.mask3(:,:,s.slice);
        updateImage();
    end

    function updateImage()
        % Whenever the image contrast is updated or the slice to view is
        % changed
        
        gui.im.CData = gui.I;
        
        
        if numel(gui.N)>0
            if isfield(gui, 'contour')
                delete(gui.contour);
            end
            [~, gui.contour] = contour(gui.mask, [.5,.5], 'r', 'ButtonDownFcn', @imClick);
        else
            gui.contour = [];
        end
        
        if isfield(gui, 'box')
            for kk = 1:numel(gui.box)
                delete(gui.box{kk});
            end
        end
        
        gui.box = [];
        
        axis off
        for tt = 1:numel(gui.N)
            gui.box{tt}= plotbbx(gui.N{tt}, sprintf('%d', tt), 1);
        end
        
    end

    function shortcuts(varargin)
        key = varargin{2}.Key;
        if strcmp(key, 'return')
            done()
        end
        if strcmp(key, 'backspace')
            %    manual()
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
        % Image has Position [.15,.15,.8,.8]
        gui.hPlot = subplot('Position', [.17, 0.02,.8-0.02,.14-0.02]);
        
        hold off
        gui.histogram = histogram(V(:)/max(V(:)), 'FaceColor', [.5,.5,.5], 'EdgeColor', 'none');
        ax = axis;
        hold on
        gui.levelslide = plot([s.level, s.level], ax(3:4), 'r');
        %set(get(gui.histogram, 'Parent'), 'Yscale', 'log'); No improvement
        
        subplot(gui.dapiPlot);
    end

    function glowSwitch(varargin)
        warning('Not implemented for 3D')
        % should switch a parameter that goes into
        % get_nuclei_dapi_3
        % then update should be called
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

    function update(varargin)
        set(gui.win, 'Pointer', 'watch');
        drawnow
                
        s.excludeOnEdge = get(gui.excludeOnEdge, 'Value');
                
        s.level = str2num(get(gui.level, 'String'));
        if numel(s.level) == 0
            s = rmfield(s, 'level');
        end
        
        s.useWatershed = get(gui.ws, 'Value');
        s.usePrefilter = get(gui.pf, 'Value');
        s.useHP = get(gui.hp, 'Value');
        s.hpSigma = str2num(get(gui.hpsigma, 'String'));
        
        [nuclei, mask3, s]= get_nuclei_dapi_3(V, s);
        gui.mask3 = mask3;
        gui.mask = mask3(:,:,s.slice);
        
        set(gui.level, 'String', num2str(s.level));
        gui.nSelected = ones(numel(nuclei), 1);
        gui.N = nuclei;
        
        %% Update the graphics
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
        uiresume(gcbf);
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

    function I = projectVolume(V)
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
        gui.I = I;
    end

    function C = getSliceContrast(V)
        dx = gpartial(V,1,1);
        dy = gpartial(V,2,1);
        gm = (dx.^2+dy.^2).^(1/2);
        C = squeeze(sum(sum(gm,1),2));
    end

    function setZauto()
        % updated firstZ and lastZ to only include the most in contrast
        % slices
        if numel(s.contrast) == 0
            s.contrast = getSliceContrast(V);
        end
        t = sort(s.contrast);
        cMin = t(ceil(0.25*numel(t)));
        z = find(t>cMin);
        s.firstZ = z(1);
        s.lastZ = z(end);
    end

    function setZ(varargin)
        s.firstZ = str2num(gui.firstZ.String)
        s.lastZ = str2num(gui.lastZ.String)
        gui.I = projectVolume(V);
        updateImage()
    end

    function projectionChanged(varargin)
        disp('projectionChanged')
        s.projectionType = gui.projMethod.String{gui.projMethod.Value};
        gui.I = projectVolume(V);
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

end