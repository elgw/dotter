function batchTifRead(files, fun)
%% function batchTifRead(files, fun)
% Example:
% batchTifRead('*', @(x) fprintf('%d\n', sum(x(:)==255)));
%

files = dir(files);

for kk = 1:numel(files)
    if numel(files(kk).name)>3
        
        if strcmp(files(kk).name(end-2:end), 'tif')==1
            V = df_readTif(files(kk).name);
            fprintf('%s ', files(kk).name);
            fun(V)
        end
    end
end