f = uipickfiles();

I1 = df_readTif(f{1});
I2 = df_readTif(f{2});

I1 = double(I1);
I1 = max(I1,[], 3);
I1 = I1/max(I1(:));

I2 = double(I2);
I2 = max(I2,[], 3);
I2 = I2/max(I2(:));

I = cat(3, I1, I2, 0*I1);

figure
imshow(I/max(I(:)))


title(f{1}, 'interpreter', 'none')