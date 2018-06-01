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


refChannel = setRefChannel(cc, 'dapi');

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
    C = cc_apply_image('image', I, 'ccData', cc, 'from', channel{1}, 'to', refChannel);
    df_writeTif(uint16(C), [outDir files(kk).name]);    
    waitbar(kk/numel(files), w);
end
close(w)

fprintf('done\n');
end


function refChannel = setRefChannel(cc, defChan)
% Set the default reference channel to use
% second argument is the default. Shows a dialog if it does not exist.
refChannel = '';

hasRefChannel = find(strcmpi(cc.channels, defChan));
if numel(hasRefChannel) == 0
    
    PromptString{1} = 'The default reference channel';
    PromptString{2} = sprintf('%s does not exist', defChan);
    PromptString{3} = 'please use another one';
    PromptString{4} = '';
    
    refChanNo = listdlg('ListString', cc.channels, ...
        'SelectionMode', 'single', ...
        'PromptString', PromptString);
    
    
    if numel(refChanNo) == 1
        refChannel = cc.channels{refChanNo};
    else
        error('No reference channel picked');
    end
    

else
    refChannel = defChan;
end

return;
end