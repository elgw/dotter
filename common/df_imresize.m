function R = df_imresize(V, voxelSize, varargin)
% function df_imresize(V, voxelSize)
% Resize V so that the voxelsize is [1,1,1]
%
% Example:
% V = df_readTif('dapi_001.tif');
% % Has pixel size [130,130,300]
% R = df_imresize(V, [130,130,300]/130);
% Has pixel size [130,130,130]

method = 'linear';
extrapval = 'mean';

for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'method')
        method = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'extrapval')
        extrapval = varargin{kk+1};
    end
end

deltax = 1/voxelSize(1);
deltay = 1/voxelSize(2);
deltaz = 1/voxelSize(3);

[X,Y,Z] = ndgrid( 1:deltax:size(V,1), ...
    1:deltay:size(V,2), ...
    1:deltaz:size(V,3));


if ischar(extrapval)
    ev = mean(V(:));
else
    ev = extrapval;
end

if strcmp('method', 'nearest') == 1    
    R = interpn(V, X,Y,Z, 'nearest');    
else
    R = interpn(V, X,Y,Z, method, ev);
end

end