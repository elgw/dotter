function [V] = df_readTif(filename, varargin)
% function [V, info] = df_readTif(filename, varargin)
% Reads a volumetric tif image specified by filename
%
% erikw, 
%
% 20161218, using Tiff to read instead of imread. 5x faster.
% 20160425, created

warning('Depreciated, use df_readTif!')

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
    assert(numel(intersect(imBits, [8,16]))==1);
    
    if numel(tiffInfo) == 1
        V = imread(filename);
        return
    end
    
    if imBits == 16
        V = zeros(tiffInfo(1).Height, tiffInfo(1).Width, numel(tiffInfo), 'uint16');
    end
        
    if imBits == 8
        V = zeros(tiffInfo(1).Height, tiffInfo(1).Width, numel(tiffInfo), 'uint8');
    end
    
    
    for kk = 1:size(V,3)
        t.setDirectory(kk);
        V(:,:,kk) = t.read();
    end
    
    t.close();

    %{
info = imfinfo(filename);

%% Determine settings from metadata
s.channels = 1;
if isfield(info(1), 'ImageDescription')
    text = info(1).ImageDescription;
    scan = textscan(text, '%s%s', 'Delimiter', '=');
    for kk = 1:numel(scan{1})
        if strcmp(scan{1}{kk}, 'channels')
            s.channels = str2num(scan{2}{kk});
        end
    end
end


%% Parse input arguments, if any
for kk = 1:numel(varargin)
    if strcmp(varargin(kk), 'channels')
        s.channels = varargin{kk+1};
    end
end

%% Be verbosive
if s.channels>1
    fprintf('- Assuming %d channels, override by setting the ''channel'' value\n', s.channels);
    fprintf('- V is a 4D array, access channel cc by V(:,:,:,cc)\n');
end

%% Read the image
if numel(info)==1
    V = imread(filename);
else
    tiffInfo = imfinfo(filename);
    I = imread(filename, 1, 'info', tiffInfo);
        
    V = zeros(size(I,1), size(I,2), numel(info)/s.channels, s.channels, 'like', I);
    
    for cc = 1:s.channels
        for kk=1:numel(info)/s.channels
            V(:,:,kk, cc)=imread(filename, (kk-1)*s.channels+cc, 'info', tiffInfo);
        end
    end
    
end
%}
end