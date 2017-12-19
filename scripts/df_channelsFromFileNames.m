function [chan, dapichan] = df_channelsFromFileNames(folder)
%function [chan, dapichan] = df_channelsFromFileNames(folder or file)
% Identifies channel names from the names of the tif files in the folder
% or if a single file was given, return the channel name from that file
% name
%
% Expected file name format:
%   channelA_001.tif channelA_002.tif ...
%   channelB_001.tif channelB_002.tif ...
%   ...
%
% Only one channels is permitted to contain DAPI in the name
% the name of this channel will be returned in dapichan
%
% To get all channels in a cell, use:
% [channels, dapichan] = df_channelsFromFileNames(folders(1).name);
% channels{end+1} = dapichan;
%
%

if (exist(folder, 'file') == 2)
    % A single file was given
    chan = chanFromFile(folder);
    return;
    
end

chan = {};
dapichan = '';

if(folder(end) ~= filesep())
    folder = [folder filesep()];
end

files = dir([folder '*.tif']);

if numel(files)==0
    warning(['No tif files found in ' folder ' quiting'])
    return
end

%keyboard
for kk=1:numel(files)
    
    fName = files(kk).name;
    badName = 0;
    
    locations = find(fName == '_');
    
    if numel(locations) == 0
        disp('No _ in the file name');
        badName = 1;
    else
        if locations(end) == 1
            disp('Only _ is at the start of the file name');
            badName = 1;
        end
        
        if badName
            fprintf('Bad file name : %s\n', fName)
            warning('File names should be formatted CHANNEL_XYZ.tif');
            chan = {};
            dapichan = '';
            return
        end
        
        lastLoc = locations(end);
        channel = fName(1:lastLoc-1);
        
        if numel(strfind(upper(channel), 'DAPI'))==0
            chan{end+1} = channel;
        else
            dapichan=channel;
        end
    end
    chan = unique(chan);
end

if numel(dapichan) == 0
    warning('No DAPI channel detected');
end

end

function channel = chanFromFile(file)
badName = 0;
locations = find(file == '_');

if numel(locations) == 0
    disp('No _ in the file name');
    badName = 1;
else
    if locations(end) == 1
        disp('Only _ is at the start of the file name');
        badName = 1;
    end
    
    if badName
        fprintf('Bad file name : %s\n', fName)
        warning('File names should be formatted CHANNEL_XYZ.tif');
        channel = [];
        return
    end
    
    lastLoc = locations(end);
    channel = file(1:lastLoc-1);
end

end