function [V] = df_readTif(filename, varargin)
% function [V, info] = df_readTif(filename, varargin)
% Reads a volumetric tif image specified by filename
% First tries to load filename.mat
%
% See also df_writeTif

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

% See nd2tif.m for how these mat files are created
matfilename = [filename '.mat'];
if isfile(matfilename)
    t = load(matfilename);
    V = t.V;
    return;
end

if isfile(filename)
    t = Tiff(filename, 'r');
    tiffInfo = imfinfo(filename);
else
    errorStr = sprintf('df_readTif: File %s does not exist', filename);
    errordlg(errorStr, 'File Error');
    error(errorStr);
end

if verbose
    tiffInfo
end

if 0
    fnames = fieldnames(tiffInfo);
    for kk = 1:numel(fnames)
        fname = fnames{kk};
        fdesc = getfield(tiffInfo(1), fname);
        if isstring(fdesc)
            fprintf('%s\t%s\n', fname, fdesc);
        else
            fprintf('%s\t%d\n', fname, fdesc);
        end
    end
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

% In order to pre-allocate the output array, figure out the format.

ifFloat = [];
if isfield(tiffInfo, 'SampleFormat')
    if strcmp(getfield(tiffInfo(1), 'SampleFormat'), 'IEEE floating point') == 1
        isFloat = 1
    else
        isFloat = 0
    end
else
    warning('SampleFormat not specified, assuming fix point');
    isFloat = 0;
end

if isFloat
    switch imBits
        case 32
            typeString = 'single';
        case 64
            typeString = 'double';
        otherwise
            error('Don''t know how to handle floats with %d bits per sample\n', imBits);
    end
else
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
end

V = zeros(tiffInfo(1).Height, tiffInfo(1).Width, numel(tiffInfo), typeString);


for kk = 1:size(V,3)
    t.setDirectory(kk);
    V(:,:,kk) = t.read();
end

t.close();

end