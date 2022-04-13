function [xview, xview_rgb] = df_crossview(I, method)
% Return an image that containts the xy, xz and yz planes
% through the middle of the image
% imresize3 first if you want
% Ir = imresize3(size(I,1), size(I,2), size(I,3)*dx/dz)
% xv = df_crossview(I, 'max') % 'mid', 'max' or 'mean'
% xv = imresize(xv, 4, 'nearest')
%
if ~exist('method')
    method = 'mid';
end

switch method
    case 'mid'
        [xy, xz, yz] = mid_planes(I);
    case 'max'
        [xy, xz, yz] = max_planes(I);
    case 'mean'
        [xy, xz, yz] = mean_planes(I);
end
I = double(I);
pad = round(size(I, 1)/ 20);
xview = zeros(size(I,1) + size(I,3) + pad+1, ...
             size(I,2) + size(I,3) + pad+1);
% xy, upper left         
xview(1:size(xy,1), 1:size(xy,2)) = xy/max(xy(:));
% xz, right
xview(1:size(xz,1), ...
    size(xy,2)+pad+1 : size(xy,2)+pad+1 + size(xz,2)-1) = ...
    xz/max(xz(:));
% yz, bottom
xview(size(xy,1)+pad+1 : size(xy,1)+pad+1 + size(yz,1)-1, ...
    1 : size(yz,2)) = yz/max(yz(:));

[h, ~, ~] = rgb2hsv([0, 1, 1]);
H = h + zeros(size(xview));
V = xview;
S = .5+.5*V;
xview_rgb = hsv2rgb(H,S,V);

end

function [xy, xz, yz] = mid_planes(I)
midx = round(size(I, 1)/2);
midy = round(size(I, 2)/2);
midz = round(size(I, 3)/2);
xy = I(:,:, midz);
yz = I(midx, :,:);
yz = squeeze(yz)';
xz = I(:,midy,:);
xz = squeeze(xz);
end

function [xy, xz, yz] = mean_planes(I)
xy = mean(I, 3);
yz = mean(I, 1);
yz = squeeze(yz)';
xz = mean(I,2);
xz = squeeze(xz);
end

function [xy, xz, yz] = max_planes(I)
xy = max(I, [], 3);
yz = max(I, [], 1);
yz = squeeze(yz)';
xz = max(I,[], 2);
xz = squeeze(xz);
end

