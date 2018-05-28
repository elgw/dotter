function df_folder_sumproj(folder)

if ~exist('folder', 'var')
    folder = pwd;
end

files = dir('*.tif');

fprintf('This will flatten %d files in folder:\n', numel(files));
fprintf('%s\n', folder);
fprintf('Warning: this can not be undone\n');
fprintf('Press enter to continue or Ctrl+C to abort\n');    

pause

for kk = 1:numel(files)
    filename = files(kk).name;
    
    fprintf('%03d/%03d %s\n', kk, numel(files), filename);
    
    I = df_readTif(filename);
    
    type = class(I);
    I = double(I);
    I = mean(I,3);
    
    if isequal(type, 'uint8')
        I = uint8(I);
    end
    
    if isequal(type, 'uint16')
        I = uint16(I);
    end

    imwrite(I, filename);
end

fprintf('done.\n');

end
