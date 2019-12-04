function nmName = im2nm_name(imName)
%% Purpose: map an image name to the corresponding NM file
%
% Example:
% imName = '/data/current_images/iMB_001/dapi_001.tif'
% im2nm_name(imName)
% -> /data/current_images/iMB_001_calc/001.NM

[pathstr,name,ext] = fileparts(imName);
assert(strcmp(ext, '.tif'))

N = name(end-2:end);
N = str2num(N);

assert(isnumeric(N));

nmName = sprintf('%s_calc/%03d.NM', pathstr, N);

end