function [V] = volumeSlideRGB(R, G, B)
% function [V] = volumeSlideRGB(R, G, B)

fprintf('Modes:\n 1) Click and drag to slide through the slices. \n 2) Select a line (left and right clicks) \n (enter) show a slice that goes through the line and extends in the z-direction\n');

if isstr(R)
    R = df_readTif(R);
end

if isstr(G)
    G = df_readTif(G);
end

if isstr(B)
    B = df_readTif(B);
end

if numel(R)>0
    msize = size(R);
end
if numel(G)>0
    msize = size(G);
end
if numel(B)>0
    msize = size(B);
end

if numel(R) == 0 
    R = zeros(msize);
end

if numel(G) == 0 
    G = zeros(msize);
end

if numel(B) == 0 
    B = zeros(msize);
end

maxrgb = double(max([R(:); G(:) ; B(:)]));

R = double(R); R = 5*R/maxrgb;
G = double(G); G = 2*G/maxrgb;
B = double(B); B = B/maxrgb;

R(R>1)=1;G(G>1)=1;B(B>1)=1;

nslices = size(R,3);
slice = round(nslices/2);
newslice = 0; xstart = 0;
mode = 1; % Scroll z
s.zstep = 125/200; % distance between z sampling 
s.zstep = 1;

fprintf('zstep: %f\n', s.zstep);

fig = gcf();
clf
border = .1;
plo = subplot('Position', [border,border,1-border,1-border]);
img = imagesc(cat(3, R(:,:,slice), G(:,:,slice), B(:,:,slice)));
ah = gca;
hold on
Line = plot(0,0, 'r', 'LineWidth', 3);

P = zeros(2,3);

s.limitedCLIM = 0;

colormap gray
axis image
axis off

set(fig, 'name', sprintf('Slice: %d', slice));
set(fig, 'WindowButtonDownFcn', @startMove);
set(fig, 'WindowButtonUpFcn', @endMove);
set(fig, 'WindowKeyPressFcn', @modeSwitch)

    function startMove(varargin)
        if mode == 1
            set(fig, 'WindowButtonMotionFcn', @move);
            Q= get(fig, 'CurrentPoint');
            xstart = Q(2);
            newslice = slice;
        end
        
        if mode == 2
            % Return the clicked point to workspace
            PT= get(ah, 'CurrentPoint');
            selection  = get(gcf,'SelectionType');
            if strcmp(selection, 'normal')
                P(1, :) = [PT(2,2), PT(1,1), slice];            
            else
                P(2, :) = [PT(2,2), PT(1,1), slice];            
            end
            set(fig, 'WindowButtonMotionFcn', @line);
            assignin('base', 'P', P);
            evalin('base', 'P');
                                    
            set(Line, 'Ydata', P(:,1));
            set(Line, 'Xdata', P(:,2));
                        
        end
    end

    function endMove(varargin)
        set(fig, 'WindowButtonMotionFcn', '');
        if mode == 1
            slice = newslice;
        end
    end

    function move(varargin)
        Q= get(fig, 'CurrentPoint');
        delta = xstart-Q(2);
        newslice = slice+round(delta/4);
        newslice = max(1, newslice);
        newslice = min(nslices, newslice);
        sliceRGB = cat(3, R(:,:,newslice), ... 
            G(:,:,newslice), ...
            B(:,:,newslice) );
        
        %whos sliceRGB;
        assignin('base', 'sliceRGB', sliceRGB);
        set(img, 'Cdata', sliceRGB);
        set(fig, 'name', sprintf('Slice: %d / %d', newslice, nslices));
    end

    function line(varargin)
        
    end

    function modeSwitch(varargin)        
        key = varargin{2}.Key;
      
        if strcmp(key, 'return')
            % Plot a cross section along the line-x-Z axis
            dx = P(2,1)-P(1,1);
            dy = P(2,2)-P(1,2);
            l = (dx^2+dy^2)^(1/2);
            theta = atan2(dx,dy);
            [T, Z] = meshgrid(1:round(l), 1:s.zstep:size(R,3));
            TX = P(1,1)+T*sin(theta); TY = P(1,2)+T*cos(theta);
            PZR = interpn(R, TX, TY, Z, 'linear');
            PZG = interpn(G, TX, TY, Z, 'linear');
            PZB = interpn(B, TX, TY, Z, 'linear');
            
            figure, imagesc(cat(3, PZR, PZG, PZB)); colormap gray, axis image
            
        end
        keynum = str2num(key)
        if numel(keynum)==1
            mode = keynum;
            set(fig, 'name', sprintf('Mode: %d slide: %d', mode, slice));
        end
    end

end

