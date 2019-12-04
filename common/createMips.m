function createMips(folder)
%% Converts all tif-files in the folder to mip images

if folder(end)~= '/'
    folder = [folder '/'];
end

files = dir([folder '*.tif']);

for kk=1:numel(files)
    V = df_readTif([folder files(kk).name]);
    imwrite(max(V,[],3), [folder 'm_' files(kk).name]);
end
