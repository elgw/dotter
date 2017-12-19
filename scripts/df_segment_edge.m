close all

I = df_readTif('/data/current_images/iAM/iAM24_20171108_myc_Both/dapi_001.tif');

I = double(I);
%volumeSlide(I)
%pause
J = sum(I(:,:,10:25),3);

figure, imagesc(J), colormap gray, axis image

figure, imagesc(E)
E = gsmooth(double(edge(J, 'canny', [], 6)), 1);

figure,
imshow(cat(3, ones(size(J)), zeros(size(J)), zeros(size(J))));
hold on
h = imagesc(J);
h.AlphaData = (1-.5*E/max(E(:)));
colormap gray
