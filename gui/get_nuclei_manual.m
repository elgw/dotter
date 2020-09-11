function [mask, S] = get_nuclei_manual(mask, I)
% function [mask, S] = get_nuclei_manual(mask, I)
% GUI for manual cell segmentation.
%
% Input:
% I: DAPI image
% mask: previous (incomplete) segmentation
%
% Output:
% mask: updated mask
% S:
%
% Shortcuts:
%  KEYBOARD
%    <space>    finalize current nuclei
%    s          find shape automatically, snaps to contours
%    L          show/hide labels
%    <enter>    done, return the nuclei
%    d/<bspace> delete current dots
%    h          show help
%
%  MOUSE
%    left       create dot/add dot to current nuclei
%    left-drag  move dot
%    right      delete dot OR nuclei
%
% Note:
%  - When cells are overlapping, the latest added will consume the ones
%  below

verbose = 0;

%snapType = 1; % Closest point
snapType = 2; % Closest Line

s.showLabels = 1;
s.radius = 30;    % For magic shape

if nargin == 0
    
    if 1
        testFolder = df_getConfig('DOTTER', 'testFolder', '');
        if numel(testFolder) == 0
            warning('no testFolder set');
            return
        end
        testImage = [testFolder '/dapi_001.tif'];
        I = df_readTif(testImage);
        I = max(I,[], 3);
    end
    
    if 0
        % Draw a lot of lines to test the speed
        I = zeros(1000,1000);
        J = zeros(100, 100); J(30:50, 30:50) = 1;
        J = repmat(J, 10,10);
        mask = bwlabeln(J);
    end
    
    if 0 % a square
        I = zeros(512,512);
        I(200:300,200:300) = 1;
    end
    
end



hasI = 1;
if numel(I) == 0
    hasI = 0;
end

if hasI
    I = double(I);
    if size(I,3)>1
        I = sum(I,3);
    end
end

cells = {};
Lines=[]; Labels = [];

% REMOVE
if exist('mask', 'var')
    [S, n] = bwlabeln(mask);
    %figure, imagesc(S);
    % Initialize cells
    for nn = 1:n
        %keyboard
        %[C] = contourc(double(S==kk), [.5,.5]);
        C = bwboundaries(S == nn, 8);
        C = C{1};
        % C = C(:,1:C(2,1));
        % plot(C(1,2:end), C(2,2:end));
        cells{nn}.xx = C(:,2);
        cells{nn}.yy = C(:,1);
        cells{nn}.sLabel = nn;
        %keyboard
    end
else
    S = zeros(size(I));
end

if exist('mask', 'var')
    mask0 = mask;
else
    mask0 = S;
end


if hasI
    f = figure('Position', [300,200,1024,1024], ...
        'NumberTitle','off', ...
        'Name', 'DAPI-segmenter, manual mode'); % Creates a new figure
else
    f = gcf;
end

uicontrol('Style', 'pushbutton', ...
    'String', 'Ok', ...
    'Units', 'Normalized', ...
    'Position', [.9, 0, .1, .05], ...
    'Callback', @done, ...
    'Parent', f);

uicontrol('Style', 'pushbutton', ...
    'String', 'Help', ...
    'Units', 'Normalized', ...
    'Position', [.8, 0, .1, .05], ...
    'Callback', @get_help, ...
    'Parent', f);

uicontrol('Style', 'pushbutton', ...
    'String', 'Settings', ...
    'Units', 'Normalized', ...
    'Position', [.7, 0, .1, .05], ...
    'Callback', @settings, ...
    'Parent', f);

uicontrol('Style', 'pushbutton', ...
    'String', 'Cancel', ...
    'Units', 'Normalized', ...
    'Position', [0, 0, .1, .05], ...
    'Callback', @cancel, ...
    'Parent', f);


set(f, 'Pointer', 'Cross'); % To show that some input is expected

if hasI
    img = imagesc(I);
    colormap gray, axis image, axis xy, hold on, axis off
else
    img = gca;
    hold on
end


%set(gca, 'clim', [minI, maxI]);

% Settings
markerSize = 9;
interpolationType = 'spline'; % cubic/spline/linear See interp1

% Internal initialisation
aH = gca;
h = 0;
Markers=[]; %stores pointers to all the markers
Line = [];
hasLine = 0;  % state variable, if there is a line or not
mode = 1; % Mark line
% mode = 2; % Slide
xstart = 0; newlast = 0;
xx = [];
yy = [];

set(f, 'WindowButtonUpFcn', @interEnd);
set(f, 'WindowButtonDownFcn', @interStart);
set(f, 'WindowKeyPressFcn', @modeSwitch)

updateLines;
uiwait(f);
close(f);

    function modeSwitch(varargin)
        key = varargin{2}.Key;
        %keyboard
        
        if strcmpi(key, 'H');
            hTxt = help('get_nuclei_manual');
            msgbox(hTxt);
        end
        
        if strcmpi(key, 'L')
            s.showLabels = mod(s.showLabels+1,2);
            updateLabels();
        end
        
        if strcmpi(key, 'V')
            verbose = mod(verbose+1,2);
            fprintf('Verbose = %d\n', verbose);
        end
        
        if mode == 1
            if strcmp(key, 's')
                shapeMagic();
            end
        end
        
        if strcmp(key, '1')
            set(f, 'name', sprintf('mark mode (1) %d last: %d', mode, last));
            mode = 1;
        end
        
        if strcmp(key, '2')
            set(f, 'name', sprintf('slide mode (2) %d last: %d', mode, last));
            mode = 2;
        end
        
        if strcmp(key, 'space')
            finalizeShape();
        end
        
        if strcmpi(key, 'D')
            clearCurrentMarkers();
        end
        if strcmpi(key, 'backspace')
            clearCurrentMarkers();
        end
        
        if strcmp(key, 'return')
            done();
        end
    end

    function finalizeShape()
        if numel(xx)>2
            
            % Create a new cell
            nCells = numel(cells)+1;
            cells{nCells}.xx = xx;
            cells{nCells}.yy = yy;
            cells{nCells}.active = 0;
            cells{nCells}.sLabel = -1;
            
            xx = []; yy = [];
            hasLine = 0;
            %cells
            
            for kk=1:numel(Markers)
                delete(Markers(kk))
            end
            Markers = [];
            delete(Line);
            Line = [];
            updateLines
        else
            warning('No contours available to create a new nuclei');
        end
    end


    function startDragFcn(varargin)
        set(f, 'WindowButtonMotionFcn', @draggingFcn)
    end

    function draggingFcn(varargin)
        pt = get(aH, 'CurrentPoint');
        set(gco, 'Xdata', pt(1,1))
        set(gco, 'Ydata', pt(1,2))
        updateLine
    end

    function interEnd(varargin)
        % This is what happens when the mouse click ends
        
        % Stop following the mouse
        set(f, 'WindowButtonMotionFcn', '')
        
        if mode == 1
            
        end
        if mode == 2
            updateLines
        end
    end

    function interStart(varargin)
        if mode == 1
            
            %% delete markers if they where clicked with the right button
            if numel(Markers)>0
                markerNo = find(gco==Markers);
                if numel(markerNo)>0
                    if strcmp(get(gcbf, 'SelectionType'), 'alt')
                        delete(gco)
                        Markers = Markers([1:(markerNo-1) (markerNo+1):end]);
                        updateLine
                    end
                end
            end
            
            
            % If the image surface was clicked with the right button
            % delete the closest nuclei
            if gco == img
                if strcmp(get(gcbf, 'SelectionType'), 'alt')
                    
                    disp('Delete a nuclei?');
                    if numel(Markers)==0
                        disp('No markers, try to delete something')
                        pt = get(aH, 'CurrentPoint'); x = pt(1,1); y = pt(1,2);
                        dmin = inf;
                        dCell = -1;
                        for kk = 1:numel(cells)
                            d = norm([x-mean(cells{kk}.xx), y-mean(cells{kk}.yy)]);
                            if d<dmin
                                dmin = d;
                                dCell = kk;
                            end
                        end
                        if verbose
                            fprintf('dCell: %d, distance %f\n', dCell, dmin);
                        end
                        if dCell > 0 && dmin < 100
                            disp('Deleting');
                            % keyboard
                            
                            delete(Lines(dCell))
                            delete(Labels(dCell))
                            cells = {cells{1:dCell-1} cells{dCell+1:end}};
                            Lines = [Lines(1:dCell-1) Lines(dCell+1:end)];
                            Labels = [Labels(1:dCell-1) Labels(dCell+1:end)];
                            
                            S(S==dCell) = 0;
                            
                            updateLabels
                            updateLines
                        end
                    end
                end
            end
            
            % If the image surface was clicked, add a new point
            if (gco == img) & (strcmp(get(gcbf, 'SelectionType'), 'normal') == 1)
                if verbose
                    disp('Creating a new dot')
                end
                %if strcmp(get(gcbf, 'SelectionType'), 'normal')
                % i) create and show a new marker
                pt = get(aH, 'CurrentPoint'); x = pt(1,1); y = pt(1,2);
                h = createMarker(pt(1,1), pt(1,2));
                
                
                
                % ii) Figure out where it belongs among the existing points
                
                %  1  Closest points -- Not always intuitive
                %  2  Closest (straight) line
                %  -  Where it causes the least change in the total line length
                %  -  Closest actual line
                
                if snapType == 1 % Closest points
                    % First, extract the closest and second closest point
                    cmarkerDist =10^12;
                    if (numel(Markers)>0)
                        for kk=1:numel(Markers)
                            mx = get(Markers(kk), 'Xdata');
                            my = get(Markers(kk), 'Ydata');
                            d = ((mx(1)-x)^2+(my(1)-y)^2)^(1/2);
                            if d<cmarkerDist
                                cmarkerDist=d;
                                cmarker = kk;
                            end
                        end
                        
                        if (numel(Markers)>1)
                            dmarkerDist =10^12;
                            for kk=[1:(cmarker-1) (cmarker+1):numel(Markers)];
                                mx = get(Markers(kk), 'Xdata');
                                my = get(Markers(kk), 'Ydata');
                                d = ((mx(1)-x)^2+(my(1)-y)^2)^(1/2);
                                if d<dmarkerDist
                                    dmarkerDist=d;
                                    dmarker = kk;
                                end
                            end
                        end
                        
                        % cmarker is the closest marker, dmarker the second closest
                        if exist('dmarker', 'var')
                            % There are two closest markers, but if one of them is the end
                            % point, we'd like the new marker to stick to that one only
                            
                            if cmarker == 1 && (cmarkerDist < 2*dmarkerDist)
                                Markers = [h Markers];
                            elseif cmarker == numel(Markers) && (cmarkerDist < 2*dmarkerDist)
                                Markers = [Markers h];
                            else
                                pos = min(cmarker, dmarker);
                                Markers = [Markers(1:pos) h Markers((pos+1):numel(Markers))];
                            end
                            
                        else % If
                            if cmarker == 1;
                                Markers = [h Markers];
                            else
                                Markers = [Markers h];
                            end
                        end
                    else
                        Markers = [Markers h];
                    end
                    updateLine;
                end
                
                if snapType == 2; % Distance to closest line used, the most intuitive that I know of
                    
                    nMarkers = numel(Markers);
                    
                    if nMarkers == 0
                        Markers = h;
                        updateLine
                    end
                    
                    if nMarkers == 1
                        Markers = [Markers h];
                        updateLine()
                    end
                    
                    if nMarkers > 1
                        
                        minLineDist = 10^99; % Shortest distance to any line
                        p1Dist = 10^9; % Distance to first point
                        pendDist = 10^9; % Distance to last point
                        
                        for kk=1:nMarkers % Loop over all line segments
                            if kk ==nMarkers
                                px = get(Markers(kk), 'Xdata'); py = get(Markers(kk), 'Ydata');
                                qx = get(Markers(1), 'Xdata'); qy = get(Markers(1), 'Ydata');
                            else
                                px = get(Markers(kk), 'Xdata'); py = get(Markers(kk), 'Ydata');
                                qx = get(Markers(kk+1), 'Xdata'); qy = get(Markers(kk+1), 'Ydata');
                            end
                            t = [qx-px, qy-py];
                            lineLength = norm(t);
                            t = t/lineLength; % Line tangent
                            n = [t(2), -t(1)]; % Line normal
                            lx = x - px;
                            ly = y - py;
                            tc = t(1)*lx + t(2)*ly; % Tangential coordinate
                            nc = n(1)*lx + n(2)*ly; % Normal coordinate
                            % Distance to first point
                            if kk==1 && tc < 0
                                p1Dist = (nc^2+tc^2)/4;
                            end
                            % Distance to last point
                            if kk==(nMarkers-1) && (tc-lineLength)>0;
                                pendDist = (nc^2+(lineLength-tc)^2)/4;
                            end
                            % Distance to line
                            if tc > lineLength
                                tc = tc-lineLength;
                            elseif tc < 0
                                tc = -tc;
                            else
                                tc = 0;
                            end
                            lineDist(kk) = tc.^2+nc.^2; % Square of distance to line
                            if lineDist(kk) < minLineDist
                                minLineDist = lineDist(kk);
                                pointPosition = kk;
                            end
                        end
                        if verbose
                            fprintf('lineDist: %d\n', lineDist);
                        end
                        
                        if minLineDist < min(p1Dist, pendDist)
                            Markers = [Markers(1:pointPosition) h Markers((pointPosition+1):end)];
                        else
                            if p1Dist < pendDist
                                Markers = [h Markers];
                            else
                                Markers = [Markers h];
                            end
                        end
                    end
                    
                    updateLine;
                end
                %end
            end
        end
        if mode == 2
            set(f, 'WindowButtonMotionFcn', @move);
            Q= get(f, 'CurrentPoint');
            xstart = Q(2);
            newlast = last;
            % Clear all cells
            for kk=1:numel(Lines)
                delete(Lines(kk))
                delete(Labels(kk))
            end
            %Lines = [];
        end
    end

    function move(varargin)
        % When dragging
        
        Q= get(f, 'CurrentPoint');
        delta = xstart-Q(2);
        newlast = last+round(delta/4);
        newlast = max(shownslices+1, newlast);
        newlast = min(size(V,1), newlast);
        %set(img, 'Cdata', squeeze(sumv(newlast,:,:)-sumv(newlast-shownslices,:,:)));
        set(img, 'Cdata', integralImage3(V,uint16(newlast-shownslices), uint16(newlast)));
        set(f, 'name', sprintf('Slice: %d -- %d (%d)', newlast-shownslices,newlast, size(V,1)));
        %set(gca, 'clim', (shownslices)*[100, 120]);
        
    end

    function updateLine(varargin)
        % Draws the line or nothing according to the markers
        
        % If no markers, delete the line
        if numel(Markers)<2
            hasLine = 0;
            delete(Line)
            Line = [];
        end
        
        % If one marker, create a line (point) if none available
        if numel(Markers)==1
            x=get(Markers(1), 'Xdata');
            y=get(Markers(1), 'Ydata');
            if hasLine == 0;
                hasLine = 1;
                Line = plot(x,y, 'r');
                set(Line, 'HitTest', 'off');
                uistack(Line, 'down');
            else
                set(Line, 'Xdata', x)
                set(Line, 'Ydata', y)
            end
        end
        
        % If multiple markers, just update the line
        if(numel(Markers)>2)
            for kk=1:numel(Markers)
                x(kk)=get(Markers(kk), 'Xdata');
                y(kk)=get(Markers(kk), 'Ydata');
            end
            
            
            %xx = interp1(1:numel(xp), xp, linspace(1,numel(xp), 3*nLinePoints), interpolationType);
            % xx = xx(nLinePoints:(2*nLinePoints+10));
            
            if 0
                % MATLAB does not have closed splines
                xp = [x x x]; yp = [y y y];
                nLinePoints = 10*numel(x);
                xx = interp1(1:numel(xp), xp, linspace(numel(x)+1, 2*numel(x)+1, nLinePoints), interpolationType);            
                yy = interp1(1:numel(xp), yp, linspace(numel(x)+1, 2*numel(x)+1, nLinePoints), interpolationType);                
            else             
                [~, xx] = df_circspline(1:numel(x), x, 15);
                [~, yy] = df_circspline(1:numel(y), y, 15);                        
            end
            
            
            %keyboard
            
            set(Line, 'Xdata', xx)
            set(Line, 'Ydata', yy)
        end
    end

    function updateLabels(varargin)
        % Update the labels in the plot to reflect the order of the labels
        % in the Labels
        
        for kk = 1:numel(Labels)
            set(Labels(kk), 'String', num2str(kk));
            if s.showLabels
                set(Labels(kk), 'Visible', 'On');
            else
                set(Labels(kk), 'Visible', 'Off');
            end
        end
    end

    function updateLines(varargin)
        ll=numel(Lines);
        for kk=(numel(Lines)+1):numel(cells)
            % Show only if they are in the region defined by first,last
            if numel(cells{kk})>0
                if numel(cells{kk}.xx)>2
                    ll=ll+1;
                    Lines(ll) = plot(cells{kk}.xx, cells{kk}.yy,'r', 'LineWidth', 2);
                    Labels(ll) = text(cells{kk}.xx(1), cells{kk}.yy(1), num2str(kk), ...
                        'HorizontalAlignment','center',...
                        'BackgroundColor',[.7 .9 .7], ...
                        'FontSize', 12);
                    
                    set(Lines(ll), 'HitTest', 'off');
                    set(get(Lines(ll), 'Children'), 'HitTest', 'Off')
                    set(Lines(ll), 'PickableParts', 'none');
                    set(get(Lines(ll), 'Children'), 'PickableParts', 'Off')
                    
                    set(Labels(ll), 'HitTest', 'off');
                    set(get(Labels(ll), 'Children'), 'HitTest', 'Off')
                    set(Labels(ll), 'PickableParts', 'none');
                    set(get(Labels(ll), 'Children'), 'PickableParts', 'Off')
                end
                
            end
        end
    end

    function h = createMarker(x,y)
        % create a maker and return the handle
        h = plot(x, y, 'yo', 'MarkerSize', markerSize);
        set(h, 'ButtonDownFcn', @startDragFcn);
    end

    function shapeMagic()
        % Try to shrink the contour
        
        if numel(Markers) == 0
            warning('No markers to use')
            return
        end
        
        if numel(Markers) == 1
            disp('Only one marker')
            x0=get(Markers(1), 'Xdata');
            y0=get(Markers(1), 'Ydata');
            
            nPoints = 5;
            
            for kk = 1:nPoints
                x(kk) = x0+sin(2*pi*kk/nPoints)*s.radius;
                y(kk) = y0+cos(2*pi*kk/nPoints)*s.radius;
            end
            delete(Markers(1));
            Markers = [];
            for kk = 1:numel(x)
                h = createMarker(x(kk), y(kk));
                Markers = [Markers, h];
            end
        end
        
        for kk=1:numel(Markers)
            x(kk)=get(Markers(kk), 'Xdata');
            y(kk)=get(Markers(kk), 'Ydata');
        end
        
        % For each marker,
        % 1. get Normal
        % 2. Interpolate the image along the normal
        % 3. Move the point to the max along the nomal line
        
        x0 = mean(x(:));
        y0 = mean(y(:));
        
        
        if verbose
            figure(2)
            clf
        end
        
        for kk = 1:numel(x)
            dx = x0- x(kk);
            dy = y0 -y(kk);
            x1 = x0 - 2*dx;
            y1 = y0 - 2*dy;
            L = interpn(I, linspace(y0,y1, 51), linspace(x0,x1,51));
            
            if verbose
                subplot(numel(x),1,kk);
                plot(L)
                figure(1)
                plot(x0, y0, 'gx');
                plot([x0,x1], [y0,y1], 'r');
                figure(2)
            end
            
            dL = - gpartial(L(:),1,1);
            dL(1:6) = 0; dL(end-5:end) = 0;
            lmax = find(dL == max(dL));
            lmax=lmax(1);
            
            if verbose
                hold on
                plot([lmax,lmax], [min(L), max(L)])
            end
            
            x(kk) = x(kk) - (lmax-26)/26*dx;
            y(kk) = y(kk) - (lmax-26)/26*dy;
        end
        
        for kk=1:numel(Markers)
            set(Markers(kk), 'Xdata', x(kk));
            set(Markers(kk), 'Ydata', y(kk));
        end
        
        if verbose
            figure(1)
        end
        
        updateLine();
    end

    function clearCurrentMarkers()
        % Remove current markers/restart
        for kk = 1:numel(Markers)
            delete(Markers(kk));
        end
        Markers = [];
        updateLine();
    end

    function cancel(varargin)
        mask = mask0;
        uiresume(f);
    end

    function done(varargin)
        % When done. This will create the 2D pixel map, mask,
        % and then end the GUI
        
        % Reset the mask
        mask = 0*S;
        
        label = 1;
        for kk = 1:numel(cells)
            if numel(cells{kk}.xx)>0
                %keyboard
                
                if cells{kk}.sLabel > 0
                    % Use mask if exist since mask->contour->poly2mask
                    % is not perfectly invertible.
                    mask(S==cells{kk}.sLabel) = kk;
                    label = label + 1;
                else
                    T = poly2mask(round(cells{kk}.xx), round(cells{kk}.yy), size(mask,1), size(mask,2));
                    [~, N] = bwlabeln(T, 8);
                    mask(T==1) = kk;
                    if(N~=1)
                        warning('Wrong number of regions for cell %d. Will be excluded', kk);
                    else
                        label = label+1;
                    end
                end
                
            end
        end
        [mask] = bwlabeln(mask);
        uiresume(f);
    end

    function get_help(varargin)        
        hm = help('get_nuclei_manual');
        msgbox(hm);
    end

    function settings(varargin)
        t = StructDlg(s);
        if numel(t)>0
            disp('Updating settings')
            s = t;
        else
            disp('Not changing settings')
        end
        
    end

end