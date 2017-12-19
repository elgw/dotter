function w = getw(line, debug, lzero)
interpolation = 'pchip';
%% function w = getw(line, interpolation, lzero)
% Calculate the widht for the peak in line 
% Normalized the line by [lzero, lmax] -> [0,1]
interpolation = 'spline';

if ~exist('lzero', 'var')
    lzero = sort(line);
    lzero = mean(lzero(1:round(end/5)));
end


dbstop if error
if debug
    figure(171)
    clf
 subplot(2,1,1)
    plot(line)
    hold on

end
    
[~, lmax] = fminsearch(@(x) interp1(-line, x, interpolation), (numel(line)+1)/2);
lmax = -lmax;

% If all same value, abort
if(lmax==lzero)
    w = -1;
    return
end

% Normalization in [0,1]
line = (line-lzero)/(lmax-lzero);
if debug
     subplot(2,1,2)
     di = linspace(1, numel(line), 1000);
     linei = interp1(line, di, interpolation);
    plot(di, linei)
    hold on
    plot(1:numel(line), line, 'ko');
end

mid = find(line==max(line));
mid = mid(1);

% find where line = 1/2, from left to mid
left = line(1:mid)-.5;
left = find(left(end:-1:1)<0);
if numel(left)>0    
    left = left(1);
    left = mid-left+1;
    try
        left0  = fzero(@(x) interp1(line-.5, x, interpolation), [left, mid]);
    catch e
        w = -1;
        return
    end
else
    w = -1;
    return;
end
% find where line = 1/2, from right to end
right = line(mid:end)-.5;
right = find(right<0);
if numel(right)>0
    right = right(1);
    right = mid+right-1;
    right0 = fzero(@(x) interp1(line-.5, x, interpolation), [mid, right]);
else 
    w = -1;
    return;
end

w = right0-left0;

if debug
    plot([left0, left0], [0,1])
    plot([right0, right0], [0,1])
    title(sprintf('fwhm: %f (%f nm)', w, w*131.08));   
end

dbclear if error
end