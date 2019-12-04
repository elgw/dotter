function h = plotBoundingBox(BB, color, varargin)
% function plotBoundingBox(BB, color)
% Plots a box, BB: (x,y, w, h)
% and returns the handle


x1 = BB(1); x2=BB(1)+BB(3);
y1 = BB(2); y2=BB(2)+BB(4);

for kk=1:numel(varargin)
    if strcmp(varargin{kk}, 'coordinates')
        x1 = BB(1); x2=BB(2);
        y1 = BB(3); y2=BB(4);
    end
end



if ~exist('color', 'var')
    color = 'r';
end

%plot([x1,x1], [y1, y2], color, 'LineWidth', 2)
%plot([x2,x2], [y1, y2], color, 'LineWidth', 2)
%plot([x1,x2], [y1, y1], color, 'LineWidth', 2)
%plot([x1,x2], [y2, y2], color, 'LineWidth', 2)
hold on
h = plot([x1,x1, x2, x2, x1], [y1, y2, y2, y1, y1], 'y', 'LineWidth', 2);

end