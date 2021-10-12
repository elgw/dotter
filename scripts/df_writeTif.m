function df_writeTif(stack, filename, metaData)
%% function df_writeTif(stack, filename)
% Writes a uint16 volumetric image to disk

if ~isa(stack, 'uint16')    
    error('Image has to be of type uint16');
end

if ~isa(filename, 'char')
    error('File name has to be a string')
end

if 2*numel(stack) >= 2^32
    disp('Writing as BigTIFF')
    t = Tiff(filename, 'w8');
else
    t = Tiff(filename, 'w');
end

	tagstruct.ImageLength = size(stack, 1);
	tagstruct.ImageWidth = size(stack, 2);
	tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
    
	tagstruct.BitsPerSample = 16;
	tagstruct.SampleFormat =  1; % uint
    
	tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    %tagstruct.Compression = Tiff.Compression.LZW;
    tagstruct.Compression = Tiff.Compression.None;

    if exist('metaData', 'var')
        % TODO put more meta data
    end
    
	for k = 1:size(stack, 3)
		t.setTag(tagstruct)
		t.write(stack(:, :, k));
		t.writeDirectory();
	end

	t.close();
end


function [status] = df_writeTif_old(V, filename)
% function [status] = df_writeTif(V, filename)

t = Tiff(filename,'w');

tagstruct.ImageLength = size(V,1);
tagstruct.ImageWidth = size(V,2);
tagstruct.SamplesPerPixel = size(V,3);

tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
if isa(V, 'uint16')
    tagstruct.BitsPerSample = 16;
else
    disp('Volume type not supported');
end

tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagstruct.Software = 'MATLAB';
t.setTag(tagstruct);

t.write(V);
t.close();
end
