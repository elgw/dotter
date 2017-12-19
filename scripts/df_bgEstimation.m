function bg = df_bgEstimation(I)
% Background estimation of an image with nuclei on dark background
%
% Todo: Convert into an iterative procedure where a smooth function
% is fitted to the background.

            
assert(size(I,3) == 1); %only for 2D images in [0,1]
assert(max(I(:)) <= 1);
assert(min(I(:)) >= 0); %

 
p = graythresh(I);

bg0 = I;

Low = bg0; Low(bg0>p) = -1;
Low(Low==-1) = mean(mean(Low(Low >=0)));


%mask = 1+0*bg0; mask(bg0>p) = 1;
bg = gsmooth(Low, 40, 'normalized');%./gsmooth(mask, 40, 'normalized');

%            bg = gsmooth(gui.I, 200, 'normalized');

end