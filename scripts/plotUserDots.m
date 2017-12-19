function varargout = plotUserDots(nmFile)
% Plot userDots for a given .NM-file
%
% Example:
%  plotUserDots('015.mat');

if nargin == 0
    warning('No nm file specified.');
    help('plotUserDots');
    return
end

fprintf('nm-file: %s\n', nmFile);

t = load(nmFile, '-mat');
N = t.N; M = t.M;


f = figure;
contour(M.mask, [.5, .5], 'Color', 'black');
hold on

styles = {'bo', 'rd', 'gx'};
sizes = [10, 8, 10];

setLegend(styles, M.channels);

for cc = 1:numel(M.channels)
    for nn = 1:numel(N)
        dots = N{nn}.userDots{cc};
        if numel(dots)>0
            plot(dots(:,2), dots(:,1), styles{cc}, 'MarkerSize', sizes(cc));
        end
    end
end

axis([0, size(M.mask,1), 0, size(M.mask,2)]);
axis equal
axis image
grid on
title(sprintf('%s %d nuclei', nmFile, numel(N)) );

% Have the grid to have equal spacing in x and y
set(gca, 'XTick', 0:100:1000);
set(gca, 'YTick', 0:100:1000);

dotPos = find(nmFile == '.'); dotPos = dotPos(end);

outFileName = ['userDots_' nmFile(1:dotPos-1) '.pdf'];
fprintf('Saving plot to %s\n', outFileName);

w = 10; h = 10;
set(f,'Units','centimeters',...
    'PaperUnits', 'centimeters', ...
    'PaperSize',[w h], ...
    'PaperPosition', [0,0,w,h], ...
    'PaperPositionMode', 'Manual')

print('-dpdf', outFileName);

% Optional, return a handle to the figure
if nargout == 1
    varargout{1} = f;
end

end

function setLegend(styles, strings)
% Set the legend before plotting

h = zeros(numel(styles), 1);
for kk = 1:numel(styles)
    %h(kk) = plot(0,0,styles{kk}, 'visible', 'off');
    h(kk) = plot(NaN, NaN, styles{kk});
end
legend(h, strings);
end