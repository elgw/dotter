function dprintpdf(filename, varargin)
%% function dprintpdf(fileName, varargin)
% Default Options:
% 'w', 10 : width of paper in cm
% 'h', 10 : height of paper in cm
%  A4 measures 21.0 × 29.7 cm
% 'fig', gcf

w = 10; % target paper size
h = 10;

fig = gcf;

for kk = 1:numel(varargin)
    if strcmp(varargin{kk}, 'w')
        w = varargin{kk+1};
    end
    if strcmp(varargin{kk}, 'h')
        h = varargin{kk+1};
    end
    if strcmp(varargin{kk}, 'fig')
        fig = varargin{kk+1};
    end
end

set(fig,'Units','centimeters',...
    'PaperUnits', 'centimeters', ...
    'PaperSize',[w h], ...
    'PaperPosition', [0,0,w,h], ...
    'PaperPositionMode', 'Manual')

drawnow
pause(0.1)

print('-dpdf', sprintf('-f%d', fig.Number), filename)

