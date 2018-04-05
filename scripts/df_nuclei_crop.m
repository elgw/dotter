function [C, X, Y] = df_nuclei_crop(N, I, varargin)
% Crop image to show nuclei
% c = df_nuclei_crop(N, I, 'pad', 4);
% default padding: 0

padding=0;
for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'pad')
        padding = varargin{kk+1};
    end
end

bbx = N.bbx;

[X,Y] = ndgrid(bbx(1)-padding:bbx(2)+padding, bbx(3)-padding:bbx(4)+padding);

for zz = 1:size(I,3)
    C(:,:,zz) = interpn(double(I(:,:,zz)), X, Y);
end

end
