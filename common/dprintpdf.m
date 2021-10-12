function dprintpdf(filename, varargin)
%% function dprintpdf(fileName, varargin)
% Default Options:
% 'w', 10 : width of paper in cm
% 'h', 10 : height of paper in cm
%  A4 measures 21.0 × 29.7 cm
% 'fig', gcf
% 'driver', '-dpdf', specify multiple drivers as {'-dpng', '-depsc', ...}

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
        driver = {'-dpdf', '-depsc', '-dpng'};
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

% Print one file per driver
% file endings appended automatically -- which is dangerous
% if the filename variable contains a '.' files might be overwritten
% TODO: change this to [filename endigs{kk}] and append appropriate endings
% per file type
for kk = 1:numel(driver)
    ending = [];
    switch driver{kk}
        case '-dpng'
            ending = '.png';
        case '-dpdf'
            ending = '.pdf';
        case '-deps'
            ending = '.eps';
    end
    if(numel(ending) == 0)
        fprintf('Unknown driver: %s\n', driver{kk})
    else
        print(driver{kk}, sprintf('-f%d', fig.Number), [filename ending])
    end
end

end