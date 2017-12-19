function [x2,y2] = unitspeed2(x,y, varargin)
% Re-interpolate the signal (x,y) so that the spacing is equal
% unitspeed(x,y,N) interpolate using N points

if ~exist('x','var')
    demo
    return
end

if numel(varargin)==1
    nOutPoints = varargin{1};
else
    nOutPoints = numel(x);
end
  
    npoints = 2*numel(x); % Number of intermediate points
    xx = spline(1:numel(x),x, linspace(1,numel(x),npoints));
    yy = spline(1:numel(y),y, linspace(1,numel(y),npoints));
    %figure, plot(xx,yy, 'x')
    % Get the speed
    l = ((xx(2:end)-xx(1:end-1)).^2+(yy(2:end)-yy(1:end-1)).^2).^(1/2);
    l = [0, l];
    cl = cumsum(l);
    %figure, plot(cumsum(l))
    L = cl(end); % Total length
    % Invert the speed
    icl = spline(cl, 0:numel(cl)-1, linspace(0,max(cl),nOutPoints));   % change to linear 
    %figure, subplot(1,2,1), plot(cl), subplot(1,2,2), plot(icl)
    % Re-interpolate with unit speed
    x2 = spline(0:numel(xx)-1, xx, icl/max(icl)*(numel(xx)-1));
    y2 = spline(0:numel(yy)-1, yy, icl/max(icl)*(numel(yy)-1));    
    %figure, plot(x2, y2, 'x')
end

function demo
x= rand(5,1);
y =rand(5,1);    

figure,
subplot(1,2,1)
xx = spline(1:numel(x),x, linspace(1,numel(x),50));
yy = spline(1:numel(y),y, linspace(1,numel(y),50));
plot(xx,yy, 'k');
hold on
plot(xx,yy, 'rx');
plot(x,y,'o', 'MarkerSize', 15)
axis([0,1,0,1])
title('Input signal')
subplot(1,2,2)
[x2,y2]=unitspeed2(xx,yy, 50);
plot(x2,y2, 'k')
hold on
plot(x2,y2,'rx')
title('Unit speed output')
axis([0,1,0,1])

end

