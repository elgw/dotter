function [chan, dapichan, dapifiles] = df_channelsFromFileNames(folder, varargin)
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

prefix = ''; % Prefix to use
xprefix = 'dw_'; % Prefix to exclude

% Alternatively, use:
%prefix = 'dw_'; % Prefix to use
%xprefix = ''; % Prefix to exclude -- ignored if empty

for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'prefix')
        prefix = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'xprefix')
        xprefix = varargin{kk+1};
    end
end

% A single file was given
if exist(folder, 'file') == 2
    chan = chanFromFile(folder);
    return;
end

% A folder was given
chan = {};
dapichan = '';

if(folder(end) ~= filesep())
    folder = [folder filesep()];
end

files = dir([folder '*.*']);

pattern = ['^' prefix '(?<channel>\w+)\_(?<number>[0-9]+)\.(?<ending>[tT][iI][fF][fF]?)$'];
xpattern = ['^' xprefix];

use = zeros(numel(files), 1);
for kk = 1:numel(files)    
    file = files(kk).name;
    match =  regexp(file, pattern, 'match');
    if numel(xprefix) > 0
        xmatch =  regexp(file, xpattern, 'match');
    else
        xmatch = [];
    end
    if numel(match) == 1 && numel(xmatch) == 0
        use(kk) = 1;
    end
end
files = files(use == 1);

if numel(files) == 0
    fprintf('Used pattern: %s\n', pattern);
    warning(['No tif files found in ' folder ' quiting'])
    return
end

%keyboard
dapifiles = {};
for kk=1:numel(files)
    file = files(kk).name;
    reg = regexp(file, pattern, 'names');
    channel = reg.channel;
        
    if contains(upper(channel), 'DAPI')
        dapichan=[prefix channel];
        dapifiles{end+1} = [files(kk).name];
    else
        chan{end+1} = [prefix channel];
    end  
    
    chan = unique(chan);    
end

if numel(dapichan) == 0
    warning('No DAPI channel detected');
end

end