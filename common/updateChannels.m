function updateChannels(folder, channels)
%% function updateChannels(folder, channels)
%
%
% Change M.channels for all NM files in a folder to channels
% 
% Example:
%  cd iEW_001_calc/
%  updateChannels('./', {'a594', 'cy5'});
%  will update files in the current folder to have a594 and cy5 (+dapi)
%  NOTE: dapi should not be part of this list

if ~exist('folder', 'var')
    disp('No folder supplied, pick one')
    folder = uigetdir();
    folder = [folder '/'];
end

if ~exist('channels', 'var')
    channels = {};
    cont = 1;
    while cont
        channel = inputdlg();
        
        if numel(channel)>0 && numel(channel{1})>0
            channels{numel(channels)+1} = channel{1};
        else
            cont = 0;
        end
    end
end

files = dir([folder '*.NM']);
fprintf('Folder: %s\n', folder);
fprintf('%d NM files\n', numel(files));
fprintf('New channels\n');
disp(channels);

assert(numel(channels)>0);


for kk=1:numel(files)
    fname = [folder files(kk).name];
    disp(fname);    
    t = load(fname, '-mat');
    
    disp('Old channels:')
    disp(t.M.channels);
    
    t.M.channels = channels;    
    save(fname, '-struct', 't');
end

      