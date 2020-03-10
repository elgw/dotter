function bg = df_bgEstimation(I)
% Background estimation of an image with nuclei on dark background
% Quick hack. Needs some attention. 
% This should try to appoximate a deconvolution.

assert(size(I,3) == 1); %only for 2D images in [0,1]
assert(max(I(:)) <= 1);
assert(min(I(:)) >= 0); %

p = graythresh(I);
bg0 = I;
Low = bg0; Low(bg0>p) = -1;
Low(Low==-1) = mean(mean(Low(Low >=0)));
bg = gsmooth(Low, 40, 'normalized');

end