function plotBox(x,y,h, w, style)
%% function plotBox(x,y,h, w, style)
%
% Example:
%  plotBox(1,2,3, 4, 'r')
hold on
plot([x x+h], [y, y], style)
plot([x x+h], [y+w, y+w], style)
plot([x x], [y, y+w], style)
plot([x+h x+h], [y, y+w], style)