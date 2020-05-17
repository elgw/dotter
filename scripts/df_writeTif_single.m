function df_writeTif_single(stack, filename)
  %% function df_writeTif_single(stack, filename)
  % write data as 32 bit float to tif stack
  % i.e., what matlab calls 'single'


  if ~isa(stack, 'single')    
    error('Image has to be of type single');
  end

  if ~isa(filename, 'char')
    error('File name has to be a string')
  end

  t = Tiff(filename, 'w');

  tagstruct.ImageLength = size(stack, 1);
  tagstruct.ImageWidth = size(stack, 2);
  tagstruct.Photometric = Tiff.Photometric.MinIsBlack;

  tagstruct.BitsPerSample = 32;
  tagstruct.SampleFormat =  Tiff.SampleFormat.IEEEFP; 

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
