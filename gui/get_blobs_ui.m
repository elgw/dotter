function B = get_blobs_ui(V,s)
%% function = get_blobs_ui(V,s)
% 
% Look for blobs (large DNA fish signals or transciption centres)
% Initiated 2017-02-22
%
% To do: change nuclei->blob M, N, B (new)
% mask->blobMask
%

refine = 0;

if nargin<2
    s=[];
end

if ~isfield(s, 'useWatershed')
    s.useWatershed = 0;
end

s.excludeOnEdge=1;
s.useHP = 0;
s.hpSigma = 1;
s.mrfMean1 = 10;
s.mrfStd1 = 5;
s.mrfMean2 = 20;
s.mrfStd2 = 5;
s.mrfSigma = 5;
s.usePrefilter = 0;
s.projectionType = 'max'; % median, mean
s.localContrastProjection = [];

s.minArea = 20;
s.maxArea = 200;

gui.win = figure('Position', [300,200,1024,1024], 'Menubar', 'none', ...
    'NumberTitle','off', ...
    'Name', 'DAPI-segmenter');

%% Display current segmentation
gui.dapiPlot = subplot('Position', [.15,.15,.8,.8]);
gui.im = imagesc(imread([getenv('DOTTER_PATH') 'dotter/logo.jpg']), 'ButtonDownFcn', @imClick);
colormap gray
hold on
axis image

if nargin==0    
    V = df_readTif('/data/current_images/iXL/iXL95_20170213_002/a594_003.tif');    
end

V = double(V);
    
disp(size(V))
s.firstZ = 1;
s.lastZ = size(V,3);
gui.I = projectVolume(V);
[nuclei, mask, s]= get_blobs(gui.I, s);
gui.nSelected = ones(numel(nuclei), 1);
gui.mask = mask;
gui.N = nuclei;

s.contrast = [];
gui.contrastWindow = [];

cSlider = climSlider();
figure(gui.win)

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
axis xy

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
    

gui.projMethod = uicontrol('Style', 'popup', 'String', {'max', 'median', 'mean', 'local'}, ...   
'Parent', gui.Projection, ...
    'Units', 'Normalized', ...
    'Position', [0, 0, 1 1], ...
    'Callback', @projectionChanged);



gui.excludeOnEdge = uicontrol('Style', 'checkbox', 'String', 'Exclude On Edge', ...
    'Position', [5,650,100,20], ...
    'Value', s.excludeOnEdge);

% BLOB sizes
gui.blobSize = uipanel('Position', [0, .60, .12, .1], 'Title', 'Blob size');
uicontrol('Style', 'text', 'String', 'From', ...
    'Parent', gui.blobSize, ...
    'Units', 'Normalized', ...
    'Position', [0, 2/3, 0.5 1/3]);
uicontrol('Style', 'text', 'String', 'To', ...
    'Parent', gui.blobSize, ...
    'Units', 'Normalized', ...
    'Position', [.5, 2/3, 0.5 1/3]);
gui.minBlobSize = uicontrol('Style', 'edit', 'String', s.minArea, ...
    'Parent', gui.blobSize, ...
    'Units', 'Normalized', ...
    'Position', [0, 1/3, 0.5 1/3]);
gui.maxBlobSize = uicontrol('Style', 'edit', 'String', s.maxArea, ...
    'Parent', gui.blobSize, ...
    'Units', 'Normalized', ...
    'Position', [.5, 1/3, 0.5 1/3]);
    

gui.hp = uicontrol('Style', 'checkbox', 'String', 'HP filter', ...
    'Position', [5,350,100,20], ...
    'Value', s.useHP, 'Callback', @update);

gui.hpsigma = uicontrol('Style', 'edit', ...
    'String', s.hpSigma, ...
    'Position', [5, 300, 60, 20]);

gui.pf = uicontrol('Style', 'checkbox', 'String', 'Glow filter', ...
    'Position', [5,250,100,20], ...
    'Value', s.usePrefilter, ...
    'Callback', @glowSwitch);

gui.ws = uicontrol('Style', 'checkbox', 'String', 'Watershed', ...
    'Position', [5,200,100,20], ...
    'Value', s.useWatershed);

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

close(gui.win);

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

    function updateImage()
        gui.im.CData = gui.I;
        try
            cSlider.UserData.updateFcn('H', gui.I);
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
        gui.hPlot = subplot('Position', [.12, 0.02,.8,.10]);
        hold off
        gui.histogram = histogram(gui.I(:)/max(gui.I(:)), 'FaceColor', [.5,.5,.5], 'EdgeColor', 'none');
        ax = axis;
        hold on
        gui.levelslide = plot([s.level, s.level], ax(3:4), 'r');
        %set(get(gui.histogram, 'Parent'), 'Yscale', 'log'); No improvement
        
        subplot(gui.dapiPlot);
    end

    function glowSwitch(varargin)
        
        if get(gui.pf, 'Value') == 1
            gui.I = double(V);
            gui.I = sum(V,3);
            gui.I = gui.I-gsmooth(gui.I, 20, 'normalized');
            resetLevel();
            update
            updateHistogram
            
        else
            gui.I = double(V);
            gui.I = sum(V,3);
            resetLevel();
            update
            updateHistogram
            
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
        
        
        s.thresholding = 1;
                
        s.excludeOnEdge = get(gui.excludeOnEdge, 'Value');
                
        s.minarea = str2num(get(gui.minBlobSize, 'String'));
        s.maxarea = str2num(get(gui.maxBlobSize, 'String'));
        
        s.level = str2num(get(gui.level, 'String'));
        if numel(s.level) == 0
            s = rmfield(s, 'level');
        end
        s.useWatershed = get(gui.ws, 'Value');
        s.usePrefilter = get(gui.pf, 'Value');
        s.useHP = get(gui.hp, 'Value');
        s.hpSigma = str2num(get(gui.hpsigma, 'String'));
        
        [nuclei, mask, s]= get_blobs(gui.I, s);
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