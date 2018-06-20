function dprintpdf(filename, varargin)
%% function dprintpdf(fileName, varargin)
% Default Options:
% 'w', 10 : width of paper in cm
% 'h', 10 : height of paper in cm
%  A4 measures 21.0 × 29.7 cm
% 'fig', gcf
% 'driver', '-dpdf', specify multiple drivers as {'-dpng', '-depsc', ...}


if contains(filename, '.')
   warning('Filename contains ''.'', replacing with ''_'' ');
   filename = strrep(filename, '.', '_');
end

w = 10; % target paper size
h = 10;

fig = gcf;
driver = {'-dpdf'};


for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'w')
        w = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'h')
        h = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'fig')
        fig = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'driver')
        driver = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'publish')
        driver = {'-dpdf', '-depsc'};
    end
end



        


set(fig,'Units','centimeters',...
    'PaperUnits', 'centimeters', ...
    'PaperSize',[w h], ...
    'PaperPosition', [0,0,w,h], ...
    'PaperPositionMode', 'Manual')

drawnow
pause(0.1)

if ~iscell(driver)
    driver = {driver};
end

% Print one file per driver, file endings appended automatically
for kk = 1:numel(driver)    
    print(driver{kk}, sprintf('-f%d', fig.Number), filename)
end

end