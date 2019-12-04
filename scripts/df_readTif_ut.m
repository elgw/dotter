function df_readTif_ut()
disp('-> Write and read tif file');
I = zeros(1024, 1024+1, 41, 'uint16');
I(1:end) = mod(1:numel(I), (2^16-1)-3);
I(4,5,6) = 2^16;

filename = [tempdir() 'test.tif'];
tic
df_writeTif(I, filename);
fprintf('Took %.2f s to write a normal sized tif file\n', toc);
tic
I2 = df_readTif(filename);
fprintf('Took %.2f s to load the tif file\n', toc);
assert(sum(I(:) == I2(:)) == numel(I));
assert(sum(size(I)==size(I2)) == 3);

end