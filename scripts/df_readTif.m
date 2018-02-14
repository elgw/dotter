function [V] = df_readTif(filename, varargin)
% function [V, info] = df_readTif(filename, varargin)
% Reads a volumetric tif image specified by filename
%

% Possible improvement, for non-local files, copy to temp location before
% reading because the Tif reader makes multiple disk accesses.
%
% 20161218, using Tiff to read instead of imread. 5x faster.
% 20160425, created

verbose = 0;
for kk = 1:numel(varargin)
    if strcmp(varargin{kk}, 'verbose')
        verbose =1;
    end
end

t = Tiff(filename, 'r');
tiffInfo = imfinfo(filename);

if verbose
    tiffInfo
end

imBits = tiffInfo(1).BitsPerSample;
if ~(numel(intersect(imBits, [8,16,32]))==1)
    warning('%d BitsPerSample\n', imBits);
end
    

if numel(tiffInfo) == 1
    % use imread to read 2D images
    V = imread(filename);
    return
end

switch imBits
    case 8
        typeString = 'uint8';
    case 16
        typeString = 'uint16';
    case 32
        typeString = 'uint32';
    otherwise
        error('Don''t know how to handle %d bit files\n', imBits);        
end

V = zeros(tiffInfo(1).Height, tiffInfo(1).Width, numel(tiffInfo), typeString);

for kk = 1:size(V,3)
    t.setDirectory(kk);
    V(:,:,kk) = t.read();
end

t.close();

end