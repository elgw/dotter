function df_cc_apply_image_folder(folder, ccFile)

if folder(end) ~= '/'
    folder = [folder '/'];
end

files = dir([folder '*.tif']);
outDir = [folder 'cc/'];

if numel(files)>0
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end
else
    disp('No files');
    return;
end

cc = load(ccFile, '-mat');

w = waitbar(0, 'Processing ...');
for kk = 1:numel(files)    
    
    fprintf('(%d/%d) %s\n', kk, numel(files), files(kk).name);
	I = df_readTif([folder files(kk).name]);
    channel = im2chan_name(files(kk).name);
    cn = find(strcmp(cc.channels, channel));        
    if sum(strcmp(cc.channels, channel{1})) ~= 1
        msgbox(sprintf('Can''t correct channel %s, the cc files does not contain any information about it!', channel{1}));
        return
    end
    C = cc_apply_image('image', I, 'ccData', cc, 'from', channel{1}, 'to', 'dapi');
    df_writeTif(uint16(C), [outDir files(kk).name]);    
    waitbar(kk/numel(files), w);
end
close(w)

fprintf('done\n');
end