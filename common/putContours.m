function I = putContours(mask)
% Create a binary mask outside of the masked regions
% in mask and mark with 1.

mask = mask>0;
mask2 = imdilate(mask, strel('disk', 1));
I = mask2 > mask;

end