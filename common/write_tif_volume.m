function write_tif_volume(stack, filename)
%% function write_tif_volume(stack, filename)

assert(isa(stack, 'uint16'))
assert(isa(filename, 'char'))

t = Tiff(filename, 'w');

	tagstruct.ImageLength = size(stack, 1);
	tagstruct.ImageWidth = size(stack, 2);
	tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
	tagstruct.BitsPerSample = 16;
	tagstruct.SampleFormat =  1; % uint
	tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    %tagstruct.Compression = Tiff.Compression.LZW;
    tagstruct.Compression = Tiff.Compression.None;

	for k = 1:size(stack, 3)
		t.setTag(tagstruct)
		t.write(stack(:, :, k));
		t.writeDirectory();
	end

	t.close();
end


function [status] = write_tif_volume_old(V, filename)
% function [status] = write_tif_volume(V, filename)

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
