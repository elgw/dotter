function x = normalisera(x, interval)
% maps [minx, maxx]->[0,1]
% or [interval(1), interval(1)] -> [0,1] and clips off everthing outside
x = double(x);
if exist('interval', 'var')
   x(x<interval(1))=interval(1);
   x(x>interval(2))=interval(2);
end


x = x-min(x(:));
if max(x(:))>0
    x = x./max(x(:));
end
end