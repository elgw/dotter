function df_tilescan_merge(channels)
% Merge files like: 
% TileScan 1--Stage00--Z00--C00.tif
% Example use:
% df_tilescan_merge({'dapi', 'tritc'})
% C00 will be called dapi, C01 will be called tritc ...

if (nargin == 0)
    fprintf('Too few input arguments\n')
    help('df_tilescan_merge')
    return;
end

for stage = 0:10
    for cc = 0:10
        pattern = sprintf('TileScan 1--Stage%02d--Z*C%02d.tif', stage, cc);        
        files = dir(pattern);
        if numel(files) > 0
            fprintf('Stage%2d--Z**--C%02d.tif\n', stage, cc);
            merge_files(channels, files, stage, cc);
        end
    end
end

end

function merge_files(channels, files, stage, channel)
  
file = [files(1).folder filesep() files(1).name];
I = df_readTif(file);
V = zeros([size(I), numel(files)], class(I));

for kk = 1:numel(files)
    file = [files(kk).folder filesep() files(kk).name];
    I = df_readTif(file);
    V(:,:,kk) = I;
end

outdir = [files(1).folder filesep() 'merge/'];
if ~isdir(outdir)
    mkdir(outdir);
end

channelstr = sprintf('channel%02d', channel);

channelstr = channels{channel+1};

outfile = sprintf('%s%s_%03d.tif', outdir, channelstr, stage);
fprintf('-> %s\n', outfile);
if ~isfile(outfile)
    df_writeTif(V, outfile);
end

end