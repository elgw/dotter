function df_fov_crop(folder, fov, outfolder)
% Interactively crop a fov in a given folder and save to a new folder

%
% folder = uigetdir('Select folder')
% fov = 1
% outfolder = uigetdir('Select and empty folder for the outputs')
% df_fov_crop(folder, fov, outfolder);

ending = '';

dfile = sprintf('%s/dapi_%03d', folder, fov);
if isfile([dfile '.tif'])
    ending = '.tif';
end
if isfile([dfile '.tiff'])
    ending = '.tiff';
end

if numel(ending) == 0
    error('Can''t find a dapi_%03.tif(f) in %s\n', fov, folder);
end

dfile = [dfile ending];
I = df_readTif(dfile);
I = max(I, [], 3);
imagesc(I), axis image, colormap gray

R = getrect();

a = R(2); b = R(2)+R(4);
c = R(1); d = R(1)+R(3);

I = I(a:b, c:d);
figure, imagesc(I), axis image, colormap gray

if numel(outfolder) == 0
    oname = inputdlg('Give a name for the cropped region:');
    outfolder = [folder filesep() oname{1}];
    mkdir(outfolder);
    mkdir(outfolder);
end

files = dir(sprintf('%s/*%03d%s', folder, fov, ending));

for kk = 1:numel(files)
    I = df_readTif([folder filesep() files(kk).name]);
    I = I(a:b, c:d, :);
    outname = [outfolder '/' files(kk).name];
    sprintf('Outname: %s\n', outname);
    df_writeTif(I, outname);
end

end