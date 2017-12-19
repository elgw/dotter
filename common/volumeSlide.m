function varargout = volumeSlide(V, varargin)
% function varargout = volumeSlide(V, varargin)
% Browse through along the z-direction of the volumetric image V
%
% Use:
%  No arguments: a file dialogue is opened
%

% Browse for a file if none provided
if ~exist('V', 'var')
    [file, path] = uigetfile({'*.tif'}, 'Select image to load');
    if isnumeric(file)
        disp('Aborting')
        return
    end
    fprintf('Reading %s\n',[path file]);
    V = df_readTif([path file]);
end

% Read from disk if a file name
if ischar(V)
    V = df_readTif(V);
end
V = double(V);



s.limitedCLIM = 0;
nslices = size(V,3);
slice = round(nslices/2);
newslice = 0; xstart = 0;
mode = 1; % Scroll z
s.zstep = 125/200; % distance between z sampling
s.zstep = 1;

for kk = 1:numel(varargin)-1
    if(strcmp(varargin{kk}, 'limitedCLIM'))
        s.limitedCLIM = varargin{kk+1};
    end
end

fprintf('X/Z resolution ratio: %f\n', s.zstep);

fig = figure('Tag', 'volumeSlide');
border = .1;
plo = subplot('Position', [border,border,1-border,1-border]);
img = imagesc(V(:,:,slice));
ah = gca;
hold on
Line = plot(0,0, 'r', 'LineWidth', 3);

P = zeros(2,3); % Position of line for mode 2

climVol = [min(V(:)), max(V(:))]; % Range of values in image

try
    if s.limitedCLIM == 1
        climVol = quantile16(V, [.1, 1-10^(-4)]); % 4 s
    else
        climVol = quantile16(V, [.1, 1]); % 4
    end
    set(gca, 'clim', climVol)
catch
    set(gca, 'Clim', [min(V(:)), max(V(:))]);
    disp('Set CLim between min and max')
end

sliderLower = uicontrol(fig,'Style','slider',...
    'Max',max(V(:))+1,'Min',min(V(:))-1,'Value',climVol(1),...
    'Position',[0 0 30 150],...
    'Callback', @cLimChange);
sliderUpper = uicontrol(fig,'Style','slider',...
    'Max',max(V(:))+1,'Min',min(V(:))-1,'Value',climVol(2),...
    'Position',[30 0 30 150],...
    'Callback', @cLimChange);


V = double(V);
%minVal = min(V(:));
%maxVal = max(V(:));
%set(gca, 'CLim', [minVal, maxVal]);

colormap gray
axis image
axis off

set(fig, 'name', sprintf('Slice: %d', slice));
set(fig, 'WindowButtonDownFcn', @startMove);
set(fig, 'WindowButtonUpFcn', @endMove);
set(fig, 'WindowKeyPressFcn', @modeSwitch)

if nargout == 1
    varargout{1}=V;
end

menu()

    function cLimChange(varargin)
        set(gca, 'clim', [get(sliderLower, 'Value'), get(sliderUpper, 'Value')]);
    end

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
        newslice = slice+round(delta/10);
        newslice = max(1, newslice);
        newslice = min(nslices, newslice);
        set(img, 'Cdata', V(:,:,newslice));
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
            [T, Z] = meshgrid(1:round(l), 1:s.zstep:size(V,3));
            TX = P(1,1)+T*sin(theta); TY = P(1,2)+T*cos(theta);
            if size(V,3) == 1
                PZ = interp2(V, TY, TX, 'linear');
                whos
                %assignin('base', 'PZ', PZ);
                figure, plot(PZ);
            end
            if size(V,3) == 3
                PZ = interpn(V, TX, TY, Z, 'linear');
                figure, plot(PZ');
                legend({'TMR','DAPI','TMR/DAPI'})
            end
            if size(V,3) >3
                PZ = interpn(V, TX, TY, Z, 'linear');
                figure, imagesc(PZ); colormap gray, axis image
                rl = round(l); % discrete length
                % unit length direction
                dire = [P(2,1), P(2,2)]-[P(1,1), P(1,2)];
                dire = dire/norm(dire);
                P2 = [[P(1,1), P(1,2)] ; [P(1,1), P(1,2)]+rl*dire];
                P
                P2
                line = interpn(V, ...
                    linspace(P2(1,1), P2(2,1), rl), ...
                    linspace(P2(1,2), P2(2,2), rl), ...
                    linspace(slice, slice, rl), ...
                    'cubic');
                getw(line, 1);
            end
            
        end
        keynum = str2num(key);
        if numel(keynum)==1
            mode = keynum;
            set(fig, 'name', sprintf('Mode: %d slide: %d', mode, slice));
        end
    end

    function menu()
        fprintf('-> Menu:\n');
        fprintf('Modes, select with keyboard:\n');
        fprintf(' 1) Click and drag to slide through the slices.\n')
        fprintf(' 2) Show tz-sections and fwhm for a line\n')
        fprintf('   Select a line (left and right clicks),  <enter> shows a tz-slice\n');
        fprintf('   that goes through the line and extends in the z-direction together with fwhm\n')
        fprintf('\n');
    end

end

