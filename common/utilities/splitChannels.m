% Split tif files with multiple channels into individual files
% Did this for iJC291 to iJC296_040416
% Those files were in lsm format so first they were converted with ImageJ

files = dir('Alexa*.tif');

channels = {'a647', 'dapi'};

for kk = 1:numel(files)
    file = files(kk).name;
    disp(['Reading ' file])
    V = df_readTif(file);
    
    a = V(:,:,:,1);
    b = V(:,:,:,2);
    
    file = file(1:end-4);
    
    aname = sprintf('%s_%03d.tif', channels{1}, kk);
    bname = sprintf('%s_%03d.tif', channels{2}, kk);
   
    disp(['Writing ' aname]);
    write_tif_volume(aname, a);
    
    disp(['Writing ' bname]);
    write_tif_volume(bname,b);
    
end

log = fopen('tif_conversion_log.txt', 'w');
for kk=1:numel(files)
    fprintf(log, '%s\n', files(kk).name);
    fprintf(log, '  %s_%03d.tif\n', channels{1}, kk);
    fprintf(log, '  %s_%03d.tif\n', channels{2}, kk);
end
fclose(log);    
