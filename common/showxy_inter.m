function showxy_inter(I)
%{ 
    A simple interactive script to create open contours over an image.
    Left click on the image: adds a new point
    Left click and drag on a marker: moves it around
    Right click on marker: deletes it

    The coordinates of the line are copied to the workspace as xx and yy

    Wanted:
        More intuitive connection of new markers

    erikw, 20121108
%}


f = gcf; % Creates a new figure if none available
set(f, 'Pointer', 'Cross');

if ~exist('I', 'var')
    I = imread('cameraman.tif');
end

img = imagesc(I);
colormap gray, axis image, hold on, axis off

% Settings
makerSize = 9;

% Internal
aH = gca;
h = 0;
Markers=[]; %stores pointers to all the markers
Line = [];
noLine = 1;  % state variable, if there is a line or not
set(f, 'WindowButtonUpFcn', @stopDragFcn);
set(f, 'WindowButtonDownFcn', @windowClick);

    function startDragFcn(varargin)
        set(f, 'WindowButtonMotionFcn', @draggingFcn)        
    end
    
    function draggingFcn(varargin)        
        pt = get(aH, 'CurrentPoint');
        set(gco, 'Xdata', pt(1,1))
        set(gco, 'Ydata', pt(1,2))                        
        updateLine
    end

    function stopDragFcn(varargin)  
        % Stop following the mouse
        set(f, 'WindowButtonMotionFcn', '')                
        
        % Export the line, but give it unit speed first
        xdata = get(Line, 'Xdata');
        ydata = get(Line, 'Ydata');
        if numel(xdata)>2
            [xout, yout]=unitspeed2(xdata, ydata, 500);
            assignin('base', 'xx', xout)
            assignin('base', 'yy', yout)
        end
    end

    function windowClick(varargin)        
        
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
        
        % If the image surface was clicked, add a new point
        if gco == img 
            pt = get(aH, 'CurrentPoint');
            % Create and show a marker
            h = plot(pt(1,1), pt(1,2), 'yo', 'MarkerSize', makerSize);        
            set(h, 'ButtonDownFcn', @startDragFcn)
                
        % Find out where it should be added in the list
        % First, extract the closest and second closest point
        cmarkerDist =10^12;
        if (numel(Markers)>0)
            for kk=1:numel(Markers)
                mx = get(Markers(kk), 'Xdata');
                my = get(Markers(kk), 'Ydata');
                d = ((mx(1)-pt(1,1))^2+(my(1)-pt(1,2))^2)^(1/2);
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
                    d = ((mx(1)-pt(1,1))^2+(my(1)-pt(1,2))^2)^(1/2);
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
            disp('!')
            Markers = [Markers h];        
        end        
        updateLine;        
     else
         % If something else than the image was clicked
        % Nothing, but the clicked point will be moved 
     end
    end

    function updateLine(varargin)
        % There are possibly two lines to update, the one that starts at np
        % and the one that ends at np

        if numel(Markers)==0
            noLine = 1;
            delete(Line)
            Line = [];
        end
        
        if numel(Markers)==1
            x=get(Markers(1), 'Xdata');
            y=get(Markers(1), 'Ydata');        
            if noLine
                noLine = 0;
                Line = plot(x,y, 'r');                 
                uistack(Line, 'down');                 
            else
                set(Line, 'Xdata', x)
                set(Line, 'Ydata', y)                    
            end
        end
        
        if(numel(Markers)>2) % Cubic (well at lest for more points)
            for kk=1:numel(Markers)
                x(kk)=get(Markers(kk), 'Xdata');
                y(kk)=get(Markers(kk), 'Ydata');
            end
                
            xp=[x x(1)]; yp=[y y(1)];
            xx = interp1(1:numel(xp), xp, linspace(1,numel(xp), 500), 'pchip');
            yy = interp1(1:numel(yp), yp, linspace(1,numel(yp), 500), 'pchip');
            set(Line, 'Xdata', xx)
            set(Line, 'Ydata', yy)                    
        end           
    end
end
