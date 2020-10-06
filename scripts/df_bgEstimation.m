function bg = df_bgEstimation(I)
% Background estimation of an image with nuclei on dark background
% Quick hack. Needs some attention. 
% This should try to appoximate a deconvolution.
bg = [];

if ~size(I,3) == 1
    warning('df_bgEstimation is only for 2D images in [0,1]');
    return;
end

if max(I(:)) > 1 || min(I(:)) < 0
    warning('df_bgEstimation is only for images in the range [0,1]');
    return
end

p = graythresh(I);
bg0 = I;
Low = bg0; Low(bg0>p) = -1;
Low(Low==-1) = mean(mean(Low(Low >=0)));
bg = gsmooth(Low, 40, 'normalized');

end