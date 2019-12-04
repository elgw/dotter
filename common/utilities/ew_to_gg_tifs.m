%
% copies tif files that has the dotter convention i.e.,
% dapi_001.tif -> gg/dapi.channel1.series1.tif
% a647_001.tif -> gg/a647.channel2.series1.tif
% dapi_002.tif -> gg/dapi.channel1.series2.tif
% a647_002.tif -> gg/a647.channel2.series2.tif
% ...

%% identify channels
% To do, hard coded right now.

out_dir = 'gg/gg/';

%% create output folder
if ~exist(out_dir, 'dir')
    mkdir(out_dir)
end

%% copy

files = dir('*.tif');

for kk = 1:numel(files)
    name_ew = files(kk).name;
    
    name = name_ew(1:end-4);
    t = strsplit(name, '_');
    channel = t{1};
    if strcmp(channel, 'dapi')
        channel_number = 1;
    else
        channel_number = 2;
    end
    
    field = str2num(t{2});
    
    name_gg = sprintf('%s%s.channel%d.series%d.tif', out_dir, channel, channel_number, field);
    command = ['!cp ' name_ew ' ' name_gg];
    disp(command)
    
    %eval(command)
    
end







