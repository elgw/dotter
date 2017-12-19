function xaxis(range)
% function xaxis(range)
% change the x-axis of a plot

a = axis();
a(1:2) = range;
axis(a);

end