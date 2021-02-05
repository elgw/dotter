function fig = dotterSlide(I, P, S, s, varargin)
%% function [] = dotterSlide(I, P, S, s, varargin)
% I: image, 2D or 3D
% P: Coordinates of the dots, x,y,z
% S: sort points by this
% s: settings and meta information
% s.mask, a binary mask for the nuclei
%
% To do:
% change interface, to dotterSlide(I, P, 'property', 'value', ... )
% how to set the clim in an easier way?
%
% Example:
%  I = imread('a488_001.tif');
%  dotterSlide(I);
%  P = dotCandidates(I);
%  dotterSlide(I, P);
%
% Test with this:
% close all, P = 1024*rand(10000,4); P(:,4) = sort(P(:,4), 'descend'); dotterSlide(rand(1024,1024), P)
%
% Usage:
% n: toggle numbers for the dots
% m: select the number of dots to show
% s: switch between slice view, sum projection, max projection
% Click and drag Modes:
%   1) Change the number of dots to show
%   2) Change slice
% If meta data was supplied:
%  h: histogram of dots and threshold based on background distribution
%  j: dots per nucleus at current threshold
%  k: suggest a threshold based on preset number of dots per cell
%  t: set a threshold directly
% In RNA fish mode:
%  r: Export dots per nuclei and dots per region at current threshold
%

fileName = '??';

if ~exist('I', 'var')
    folder = df_getConfig('dotterSlide', 'folder', '~/');
    [file, path] = uigetfile({'*.tif'}, 'Select image to load', folder);
    if isnumeric(file)
        disp('Aborting')
        return
    end
    df_setConfig('dotterSlide', 'folder', path);
    I = [path file];
    fileName = I;
end

if ischar(I)
    I = df_readTif(I);
end

imageClass = class(I);
I = double(I);

if ~exist('P', 'var')
    P = [];
end

if ~exist('s', 'var')
    s.limitedCLIM = 1;
else
    if numel(s)==0
        s.limitedCLIM = 1;
    end
    if ~isfield(s, 'limitedCLIM')
        s.limitedCLIM = 0;
    end
end

if ~isfield(s, 'title')
    s.title = '';
end

s.wait = 0;
s.showNumbers = 1;
s.debug =0;

hasfwhm = 0;
dfwhm = [];

for kk = 1:numel(varargin)
    if strcmp(varargin{kk}, 'wait')
        s.wait = 1;
    end
    if strcmp(varargin{kk}, 'fwhm')
        dfwhm = varargin{kk+1};
        hasfwhm = 1;
    end
end

% Sort by S if it exists
if exist('S', 'var') && numel(S)>0
    if numel(S)>0
        [~, IDX]=sort(S, 'descend');
        P = P(IDX, :);
    end
else
    if numel(P)>0
        if size(P,2)>3
            [~, idx] = sort(P(:,4), 'descend');
            if ~(sum(idx' == 1:size(P,1)) == size(P,1))
                warning('Sorting P by column 4')
                P = P(idx,:);
            end
        else
            assert(size(P,2) ==3);
            warning('No 4th column, appending')            
            P = [P, (size(P,1):-1:1)'];
            assert(size(P,2)==4);
        end
        
    end
end


% If there are no points, add one just to make things run
if ~exist('P', 'var')
    P = zeros(0,4);
end
% If the list of points is empty, set it to dummy
if numel(P)==0
    P = zeros(0,4);
end

sumI = sum(I,3)/size(I,3);
maxI = max(I,[], 3);

fig = figure('DeleteFcn', @cleanup);
clf();
border = .1;
%plo = subplot('Position', [border,border,1-border,1-border]);
subplot('position', [0 0 1 1]);

mode = 1;
if ~isfield(s, 'sumView')
    s.sumView = 2; % Set default to (2) = max projects
end
slide = round((size(I,3)+1)/2);
tSlide = slide;
s.updateImageData = 1;

%% Build GUI components
gui.img_sub = subplot('Position', [.1, 0, .9, 1]);
gui.img = imagesc(I(:,:,slide));
ah = gca;
hold on

gui.panel = uipanel('Units', 'Normalized', ...
    'Position', [0, .0, .1, 1], ...
    'Title', 'Controls');

gui.projPanel = uipanel('Units', 'Normalized', ...
    'Position',[0 .65 1 .3],...
    'Title', 'Projection', ...
    'Parent', gui.panel);

bg = uibuttongroup('Visible','off',...
    'Parent', gui.projPanel, ...
    'Position',[0,0,1,1],...
    'SelectionChangedFcn',@setProjection);

% Create three radio buttons in the button group.
r1 = uicontrol(bg,'Style',...
    'radiobutton',...
    'String','Slice',...
    'Units', 'Normalized', ...
    'Position',[0, .6, 1, .2],...
    'HandleVisibility','off');

r2 = uicontrol(bg,'Style','radiobutton',...
    'String','Sum',...
    'Units', 'Normalized', ...
    'Position',[0, .3, 1, .2],...
    'HandleVisibility','off');

r3 = uicontrol(bg,'Style','radiobutton',...
    'String','Max',...
    'Units', 'Normalized', ...
    'Position',[0, .0, 1, .2],...
    'HandleVisibility','off');

% Make the uibuttongroup visible after creating child objects.
bg.Visible = 'on';
switch s.sumView
    case 0
        bg.SelectedObject = r1;
    case 1
        bg.SelectedObject = r2;
    case 2
        bg.SelectedObject = r3;
end

gui.btn_showLabels = uicontrol('Style', 'togglebutton', ...
    'Parent', gui.panel, ...
    'Units', 'Normalized', ...
    'Position', [0, .5, 1, .1], ...
    'String', 'Numbers', ...
    'Callback', @setNumbers, ...
    'Value', s.showNumbers);

gui.btn_info = uicontrol('Style', 'pushbutton', ...
    'Parent', gui.panel, ...
    'Units', 'Normalized', ...
    'Position', [0, .2, 1, .1], ...
    'String', 'Histograms', ...
    'Callback', @showHistogram);

gui.btn_info = uicontrol('Style', 'pushbutton', ...
    'Parent', gui.panel, ...
    'Units', 'Normalized', ...
    'Position', [0, .1, 1, .1], ...
    'String', 'Info', ...
    'Callback', @showInfo);

gui.btn_help = uicontrol('Style', 'pushbutton', ...
    'Parent', gui.panel, ...
    'Units', 'Normalized', ...
    'Position', [0, 0, 1, .1], ...
    'String', 'Help', ...
    'Callback', @showHelp);

if exist('s', 'var')
    if isfield(s, 'mask')
        if size(s.mask, 3)==1
            [con, conh] = contour(double(s.mask>0), 1);
        else
            [con, conh] = contour(double(s.mask(:,:,slide)>0), 1);
        end
        set(conh, 'LineColor', 'red')
        
    end
    if isfield(s, 'mask2')
        [con2, conh2] = contour(double(s.mask2>0), 1);
        set(conh2, 'LineColor', 'blue')
    end
end

if s.limitedCLIM == 1
    climVol = quantile16(I, [.1, 1-10^(-4)]); % 4 s
    climProj = quantile16(sumI, [.1, 1-10^(-4)]);
    climMax = quantile16(maxI, [.1, 1-10^(-4)]);
else
    climVol = quantile16(I, [0, 1]); % 4 s
    climProj = quantile16(sumI, [0, 1]);
    climMax = quantile16(maxI, [0, 1]);
end

climVol(1) = max(climVol(1), min(I(:))-1);
climVol(2) = min(climVol(2), max(I(:))+1);

if(climVol(1) == climVol(2))
    climVol(2) = 1+climVol(1);
end
set(gca, 'CLim', climVol);

marker = 'ro'; % Primary marker
marker2 = 'r.'; % Marker for original location etc...
labelColor = 'red';
focusColor = [0,1,0];

markerSize1 = 10;
markerSize2 = 18;


% Set number of points to show depending on the threshold.
% Variables: th, nps, nPointsShow
% Is really both nps and nPointShow needed?

nPoints = size(P,1);
if nPoints>0 && size(P,2)>3
    th = dotThreshold(P(:,4));
    nPointsShow = sum(P(:,4)>th);
else
    th = NaN;
    nPointsShow = 0;
end
%nPointsShow = min(size(P,1),50);
nps = nPointsShow;



if size(P,1)>0
    Zround = round(P(:,3));
else
    Zround = [];
end

%DOTS = plot(P(1:nPointsShow,2), P(1:nPointsShow,1), marker, 'ButtonDownFcn', @markerInfo);
DOTS = plot(gui.img.Parent, P(1:nPointsShow,2), P(1:nPointsShow,1), marker, 'MarkerSize', markerSize1);


P1 = P(Zround(1:nPointsShow)==slide, 1:2); % In current plane
DOTSG = plot(gui.img.Parent, P1(:,2), P1(:,1), 'o', 'Color', focusColor, 'MarkerSize', markerSize2);

if size(P,2)==6
    differentialMode =1;
else
    differentialMode = 0;
end

if differentialMode
    DOTS2 = plot(gui.img.Parent, P(1:nPointsShow,5), P(1:nPointsShow,4), marker2, 'ButtonDownFcn', @markerInfo);
    for kk = 1:size(P,1)
        if kk>nPointsShow
            LINES12(kk) = plot(gui.img.Parent, [P(kk,2), P(kk,5)], [P(kk,1), P(kk,4)], 'r', 'visible', 'off');
        else
            LINES12(kk) = plot(gui.img.Parent, [P(kk,2), P(kk,5)], [P(kk,1), P(kk,4)], 'r');
        end
    end
end

TEXTS = [];
for kk=1:min(500, size(P,1))
    TEXTS(kk)=text(gui.img.Parent, round(P(kk,2))+2, round(P(kk,1))+2, num2str(kk), 'HitTest', 'off', 'color', labelColor, 'visible', 'off', 'FontSize', 14);
end

for kk=1:min(nPointsShow, numel(TEXTS))
    set(TEXTS(kk), 'visible', 'on');
end

colormap gray
axis image
axis off
mode =1;
xstart=0;

set(fig, 'name', sprintf('%s nPoints: %d / %d', s.title, nps, nPoints));

%set(fig, 'name', sprintf('Slice: %d', slice));
set(fig, 'WindowButtonDownFcn', @startMove);
set(fig, 'WindowButtonUpFcn', @endMove);
set(fig, 'WindowKeyPressFcn', @modeSwitch)
%addlistener(fig,'WindowKeyPress',@modeSwitch);

if s.debug
    disp('settings:')
    disp(s)
end

if hasfwhm
    fwhmSlide = thSlider('Object', gui.img, 'Data', dfwhm, 'Callback', @setFwhm);
end

clim = climSlider(gui.img, 'Min', min(I(:)), 'Max', max(I(:)) );
if size(P,1)>0 && size(P,2)>3
    thSlide = thSlider('Object', gui.img, 'Data', P(:,4), 'Callback', @setTh);
end

updateGUI();

if s.wait
    uiwait
end

    function cLimChange(varargin)
        set(gca, 'clim', [get(sliderLower, 'Value'), get(sliderUpper, 'Value')]);
    end

    function startMove(varargin)
        if mode == 1
            % Change number of dots
            set(fig, 'WindowButtonMotionFcn', @move);
            Q= get(fig, 'CurrentPoint');
            xstart = Q(2);
        end
        if mode == 2
            % Change slide to view
            set(fig, 'WindowButtonMotionFcn', @move);
            Q= get(fig, 'CurrentPoint');
            xstart = Q(2);
        end
    end

    function endMove(varargin)
        if mode == 1
            set(fig, 'WindowButtonMotionFcn', '');
            nPointsShow = nps;
        end
        if mode == 2
            set(fig, 'WindowButtonMotionFcn', '');
            slide = tSlide;
            s.updateImageData = 1;
        end
    end

    function updateGUI()
        
        
        switch(s.sumView)
            case 0
                gui.text.String = 'Projection: None';
            case 1
                gui.text.String = 'Projection: Sum';
            case 2
                gui.text.String = 'Projection: Max';
        end
        
        
        
        % Select dots
        set(DOTS, 'Ydata', P(1:nps,1));
        set(DOTS, 'Xdata', P(1:nps,2));
        
        % Markers for dots in plane
        delete(DOTSG);
        P1 = P(Zround(1:nps)==tSlide, 1:2);
        DOTSG = plot(gui.img.Parent, P1(:,2), P1(:,1), 'o', 'Color', focusColor, 'MarkerSize', markerSize2);
        
        
        if differentialMode
            set(DOTS2, 'Ydata', P(1:nps,4));
            set(DOTS2, 'Xdata', P(1:nps,5));
            for kk=1:min(numel(LINES12), nps)
                set(LINES12(kk), 'visible', 'on');
            end
            for kk=min(nps+1, numel(LINES12)):numel(LINES12)
                set(LINES12(kk), 'visible', 'off');
            end
        end
        
        
        % Update numbers besides the dots
        if s.showNumbers
            for kk=1:min(numel(TEXTS), nps)
                set(TEXTS(kk), 'visible', 'on');
            end
            for kk=min(nps+1, numel(TEXTS)):numel(TEXTS)
                if kk>0
                    set(TEXTS(kk), 'visible', 'off');
                end
            end
        end
        
        if s.updateImageData
            if s.sumView == 0
                set(gui.img, 'CData', I(:,:,tSlide));
                %delete(con)
                if isfield(s, 'mask')
                    delete(conh)
                    %[con, conh] = contour(double(s.mask(:,:,slide)>0), 1);
                    [con, conh] = contour(double(s.mask>0), 1);
                    set(conh, 'LineColor', 'red')
                end
            end
            if s.sumView == 1
                set(gui.img, 'CData', sumI);
            end
            if s.sumView == 2
                set(gui.img, 'CData', maxI);
            end
            s.updateImageData=0;
        end
        
        %keyboard
        % Set the new title
        if size(P,1)>1
            set(fig, 'name', sprintf('%s %d/%d #P: %d/%d, th: %f', s.title, tSlide, size(I,3), nps, nPoints, th));
        else
            set(fig, 'name', sprintf('%s %d/%d #P: %d/%d', s.title, tSlide, size(I,3), nps, nPoints));
        end
        
        try
            thSlide.UserData.setTh(th);
        catch
            %disp('No thSlide attached')
        end
    end

    function move(varargin)
        Q= get(fig, 'CurrentPoint');
        delta = (xstart-Q(2));
        
        if mode == 1
            newValue = nPointsShow+round(delta/4);
            newValue = max(0, newValue);
            newValue = min(nPoints, newValue);
            nps = round(newValue);
            
            switch nps
                case size(P,4)
                    th = min(P(:,4))*0.9;
                case 0
                    th = max(P(:,4))*1.1;
                otherwise
                    th = P(nps,4);
            end                            
        end
        
        if mode == 2
            newValue = slide+round(delta/4);
            newValue = max(1, newValue);
            newValue = min(size(I,3), newValue);
            tSlide = round(newValue);
            s.updateImageData = 1;
        end
        
        updateGUI();
    end

    function markerInfo(varargin)
        %va{2}
    end

    function modeSwitch(varargin)
        key = varargin{2}.Key;
        
        
        if strcmp(key, '1')
            mode = 1;
        end
        
        if strcmp(key, '2')
            mode = 2;
        end
        
        if strcmp(key, 'uparrow')
            slide = min(slide+1, size(I,3));
            tSlide = slide;
            s.updateImageData = 1;
            updateGUI;
        end
        
        if strcmp(key, 'downarrow')
            slide = max(1, slide-1);
            tSlide = slide;
            s.updateImageData = 1;
            updateGUI;
        end
        
        if strcmp(key, 'return')
            close(fig);
        end
        
        if strcmp(key, 'n')
            setNumbers();
        end
        
        if strcmp(key, 'h')
            figure,
            h = histogram(P(:,4), 1024);
            hold on
            title(sprintf('Dots: %s', s.title));
            
            d = P(:,4);
            assignin('base', 'd', d);
            
            [th] = dotThreshold(d);
            
            ax = axis;
            %x = linspace(ax(1), ax(2), 2048);
            %ye =  exppdf_dr(x-subs, lambda);
            %ye = ye/max(ye)*max(h.Values);
            %plot(x+subs,ye, 'g')
            plot([th,th], ax(3:4))
            fprintf('Suggested threshold: %f\n', th);
            
            
            Pt = P(P(:,4)>th, :);
            if( isfield(s, 'mask'))
                N = interpn(s.mask, Pt(:,1), Pt(:,2), 'nearest');
                H = zeros(max(s.mask(:)),1);
                
                for kk = 1:numel(N)
                    if N(kk)>0
                        H(N(kk))=H(N(kk))+1;
                    end
                end
                
                disp('Appending dots per nuclei to log.txt')
                logf = fopen('log.txt', 'a');
                fprintf(logf, '%s\n', s.NMfile);
                for kk = 1:numel(H)
                    fprintf(logf, '%03d, %03d, %03d\n', ...
                        str2num(s.NMfile(end-5:end-3)), kk, H(kk));
                end
                fclose(logf);
            else
                disp('No mask available')
            end
            
            
        end
        
        if strcmp(key, 'j')
            
            disp('Showing dots per nuclei at current threshold')
            disp('Using dots per nuclei stored in the NM file')
            
            DPN = [];
            Meta = load(s.NMfile, '-mat');
            %keyboard
            for kk = 1:numel(Meta.N)
                if(Meta.N{kk}.area>10)
                    kk
                    PN = sum(Meta.N{kk}.dots{s.channelNo}(:,4)>=P(nps,4)); % Dots in this nucleus
                    DPN = [DPN, PN];
                end
            end
            
            figure
            histogram(DPN, 0:max(DPN));
            hold on
            
            title(sprintf('dots per nuclei th: %f', s.title, P(nps,4)));
            legend({sprintf('mean: %f', mean(DPN))})
            ylabel('#')
            xlabel('Dots per nucleus')
            fprintf('Total %d dots in %d nuclei (average: %f)\n', sum(DPN), numel(Meta.N), sum(DPN)/numel(Meta.N));
            
        end
        
        if strcmp(key, 'k')
            
            figure,
            Meta = load(s.NMfile, '-mat');
            th = findThresholdForBestDistribution(Meta, s.channelNo);
            DPN = [];
            Meta = load(s.NMfile, '-mat');
            
            for kk = 1:numel(Meta.N)
                PN = sum(Meta.N{kk}.dots{s.channelNo}(:,4)>=th); % Dots in this nucleus
                DPN = [DPN, PN];
            end
            FISH = [];
            OTHER = [];
            dots = [];
            for kk = 1:numel(Meta.N)
                dots = Meta.N{kk}.dots{s.channelNo}(:,4);
                FISH = [FISH ; dots(dots>=th)]; % Dots in this nucleus
                OTHER =[OTHER; dots(dots<th)];
            end
            sn = (mean(FISH)-mean(OTHER))/std(OTHER);
            histogram(DPN, 0:20);
            title(sprintf('%s, th: %f, SN: %f', s.title, th, sn));
            ylabel('#')
            xlabel('Dots per nucleus')
            
        end
        
        if strcmp(key, 'm')
            temp = inputdlg('Number of signals:', '', 1, {'50'});
            nnps = str2num(temp{1});
            nPointsShow = nps;
            updateGUI();
        end
        
        if strcmp(key, 's')
            setProjection();
        end
        
        if strcmp(key, 'z')
            z=get(zoom, 'Enable');
            strcmp(z, 'on')
            if strcmp(z, 'on')
                zoom off;
                figure(fig)
                disp('zoom off')
            else
                zoom;
                figure(fig)
                disp('zoom on')
            end
        end
        
        if strcmp(key, 't')
            th = inputdlg('Set a threshold');
            th = str2num(th{1});
            nps = sum(P(:,4)>=th);
            nPointsShow = nps;
            updateGUI();
            
        end
        
        if strcmp(key, 'r')
            
            % Settings
            fitDots = 0;
            calcFWHM = 0;
            
            fitDotsQ = questdlg('should the dots be localized with sub pixel precision?', ...
                'Fitting options', 'Yes', 'No', 'No');
            
            switch fitDotsQ
                case 'Yes'
                    fitDots = 1;
                case 'No'
                    fitDots = 0;
            end
            
            
            calcFWHMQ = questdlg('Calculate fwhm?', ...
                'Fitting options', 'Yes', 'No', 'No');
            
            switch calcFWHMQ
                case 'Yes'
                    calcFWHM = 1;
                case 'No'
                    calcFWHM = 0;
            end
            
            
            
            outFolder = s.NMfile;
            ofr = strsplit(outFolder, '/');
            outFolder = outFolder(1:end-numel(ofr{end}));
            
            logName = [outFolder  ofr{end}(1:end-3) '_rna.txt'];
            f = fopen(logName, 'w');
            fprintff(f, 'Writing log to %s\n', logName);
            
            fprintff(f, 'Image: %s\n', s.cFile);
            fprintff(f, 'Image size: %d x %d x %d\n', size(I,1), size(I,2), size(I,3));
            
            res = [131.08, 131.08, 200];
            fprintff(f, 'Exporting RNA fish data\n')
            d0 = inputdlg('Set the radius around the cells [nm]');
            d0 = str2num(d0{1});
            fprintff(f, 'Dilation radius set to %f [nm]\n', d0);
            cellNo = unique(s.mask);
            cellNo = setdiff(cellNo, 0);
            fprintff(f,'# cells: %d\n', numel(cellNo));
            threshold = P(nps,4);
            fprintff(f,'Threshold: %f\n', threshold);
            d = P(1:nps, :);
            d= double(d);
            fprintff(f,'# dots: %d\n', size(d,1));
            fprintff(f,'Resolution: %f x %f x %f\n', res);
            
            %             D = zeros([size(s.mask,1), size(s.mask,2), numel(cellNo)]);
            %             dmin = numel(D)*(1+D(:,:,1));
            %             dminIn = 0*numel(D)*(1+D(:,:,1));
            %             for kk = 1:numel(cellNo)
            %                 t = bwdist(s.mask==cellNo(kk));
            %                 tIn = bwdist(s.mask~=cellNo(kk));
            %                 dmin = min(t,dmin);
            %                 dminIn = max(tIn, dminIn);
            %                 D(:,:,kk) = t;
            %             end
            %
            %             DedgeI = dmin-dminIn-+1*(dminIn>0);
            %
            %             minD = repmat(min(D,[],3), [1,1,size(D,3)]);
            %             D2 = D==minD;
            %
            %             mask1 = s.mask;
            %
            %             mask3 = 0*mask1;
            %             for kk = 1:size(D2,3)
            %                 mask3 = mask3+D2(:,:,kk)*cellNo(kk);
            %             end
            %
            %             mask2 = mask3.*(dmin<d0/res(1));
            %
            %             mask4 = mask1==0;
            %
            %masks = {mask1, mask2, mask3, mask4};
            %names = {'nuclei', 'dilated nuclei', 'tesselation', 'outside_nuclei'};
            
            [masks, names, DedgeI] = dotter_generateMasks(s.mask, d0/res(1));
            
            figure
            for kk = 1:numel(masks)
                subplot(2,2,kk)
                imagesc(masks{kk}), axis image
                title(names{kk})
                set(gca, 'Clim', [0, max(cellNo)]);
            end
            colormap([[0, 0,0]; jet])
            
            
            figure,
            imagesc(DedgeI)
            title('Distance to periphery')
            axis image
            Dedge = interpn(DedgeI, d(:,1), d(:,2), 'linear')*res(1);
            DedgeP = interpn(DedgeI, P(:,1), P(:,2), 'linear')*res(1);
            d = [d double(Dedge)];
            
            disp('Calculating SN')
            Pin = P(DedgeP<0, :); % Dots in nuclei
            Pout = P(DedgeP>=0, :); % Dots outside nuclei
            
            SNin = (mean(Pin(Pin(:,4)>=threshold,4))-mean(Pin(Pin(:,4)<threshold,4)))/std(Pin(Pin(:,4)<threshold,4));
            fprintf(' Inside nuclei: %f\n', SNin);
            
            SNout = (mean(Pout(Pout(:,4)>=threshold,4))-mean(Pout(Pout(:,4)<threshold,4))) /std(Pout(Pout(:,4)<threshold,4));
            fprintf(' Outside nuclei: %f\n', SNout);
            
            fprintff(f, 'Calculating FWHM\n');
            if calcFWHM
                fw = df_fwhm(I, d(:,1:3))*res(1);
            else
                fw = -1*ones(size(d,1),1);
            end
            d = [d fw];
            
            fprintff(f, 'Fitting dots\n');
            s_fit.useClustering = 1;
            s_fit.sigmafitXY = 1.5;
            s_fit.sigmafitZ = 3;
            s_fit.fitSigma = 1;
            s_fit.verbose = 0;
            s_fit.clusterMinDist = 5;
            if fitDots
                fitted = dotFitting(I, d(:,1:3), s_fit);
            else
                fitted = zeros(size(d,1), 4);
            end
            d = [d fitted(:,4)];
            
            for kk = 1:numel(masks)
                fprintff(f,'Per %s\n', names{kk});
                m = interpn(masks{kk}, d(:,1), d(:,2), 'nearest');
                fprintff(f,'  Mean # dots: %f\n', sum(m>0)/numel(cellNo));
                fprintff(f,'  Mean DoG: %f\n', sum(d(m>0, 4))/sum(m>0));
                fprintff(f,'  Mean intensity: %f\n', sum(d(m>0, 5))/sum(m>0));
                fw = d(m>0, 7);
                fw = fw(fw>0);
                fprintff(f,'  Mean fwhm: %f [nm]\n', mean(fw));
                ph = d(m>0, 8);
                ph = ph(ph>0);
                fprintff(f,'  Mean nPhotons: %f \n', mean(ph));
                fprintff(f,'  Mean edge distance: %f [nm]\n', sum(d(m>0, 6))/sum(m>0));
                exDots = [d(m>0,:) m(m>0)];
                
                exDots = [exDots , max(s.mask(:))*ones(size(exDots,1), 1)];
                if size(exDots,1)>0
                    exDots = array2table(exDots, 'VariableNames', {'x', 'y', 'z', 'DoG', 'Intensity', 'Dedge_nm','FWHM_nm', 'nPhotons','Nuclei', 'nNuclei'});
                    tFileName = [outFolder  ofr{end}(1:end-3) '_rna_' names{kk} '.csv'];
                    fprintff(f, '  Exporting dots to %s\n', tFileName);
                    writetable(exDots, tFileName);
                else
                    fprintff(f, 'No dots to export\n');
                end
            end
            fprintff(f, 'closing log\n');
            fclose(f);
            
        end
    end

    function setTh(thres)
        th = thres;
        fprintf('Got new threshold, %f\n', th);
        
        nps = sum(P(:,4)>=th);
        nPointsShow = nps;
        updateGUI();
    end

    function setFwhm(thres)
        fwhmth = thres;
        fprintf('Got fwhm threshold, %f\n', th);
        
        nps = sum(P(:,4)>=th);
        nPointsShow = nps;
        updateGUI();
    end

    function cleanup(varargin)
        try
            close(clim)
        end
        try
            close(thSlide)
        end
    end

    function setNumbers(varargin)
        if numel(varargin) > 0
            s.showNumbers = varargin{1}.Value;
        else
            s.showNumbers = mod(s.showNumbers+1,2);
            gui.btn_showLabels.Value = s.showNumbers;
        end
        
        % Plot a cross section along the line-x-Z axis
        if s.showNumbers==0
            if s.debug
                fprintf('Numbers off\n');
            end
            for kk=1:numel(TEXTS)
                set(TEXTS(kk), 'visible', 'off');
            end
        else
            if s.debug
                fprintf('Numbers off\n');
            end
        end
        updateGUI();
    end

    function showHelp(varargin)
        msgbox(help('dotterSlide'));
    end

    function setProjection(varargin)
        if numel(varargin)>0
            display(['Previous: ' varargin{2}.OldValue.String]);
            display(['Current: ' varargin{2}.NewValue.String]);
            switch (varargin{2}.NewValue.String)
                case 'Slice'
                    s.sumView = 0;
                case 'Sum'
                    s.sumView = 1;
                case 'Max'
                    s.sumView = 2;
            end
        else
            s.sumView = mod(s.sumView+1,3);
            switch s.sumView
                case 0
                    bg.SelectedObject = r1;
                case 1
                    bg.SelectedObject = r2;
                case 2
                    bg.SelectedObject = r3;
            end
        end
        
        
        if s.sumView==0
            disp('slice mode')
            set(gca, 'clim', climVol)
        end
        if s.sumView==1
            disp('z-projection mode')
            set(gca, 'clim', climProj)
        end
        if s.sumView==2
            disp('z-max-projection mode')
            set(gca, 'clim', climMax)
        end
        
        s.updateImageData = 1;
        updateGUI();
        
    end

    function showInfo(varargin)
        msg = sprintf('Info:\n\n');
        msg = [msg, ...
            sprintf('File name: %s\n', fileName)];
        msg = [msg, ...
            sprintf('Image size: %dx%dx%d\n', size(I,1), size(I,2), size(I,3))];
        msg = [msg, ...
            sprintf('Image type: %s\n', imageClass)];
        msg = [msg, ...
            sprintf('Number of dots: %d\n', size(P,1))];
        msg = [msg, ...
            sprintf('\n')];
        msgbox(msg);
    end

    function showHistogram(varargin)
        figure
        subplot(1,2,1)
        histogram(I(:));
        grid on
        xlabel('Voxel Intensity')
        ylabel('#')
        title('Image')
        subplot(1,2,2)        
        histogram(P(:,4));
        grid on
        title('Dots')
        xlabel('Dot values (4th column)')
        ylabel('#');
    end

end

