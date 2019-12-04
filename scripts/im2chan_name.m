function chan = im2chan_name(fname)
%% function chan = im2chan_name(fname)
% Purpose: parse channel name from file name
% example:
% im2chan_name('/data/current_images/iMB37_290416_001/a488_001.tif')
% -> 'a488'

[~,name,~] = fileparts(fname);
name = strsplit(name, '_');
chan = name(1);
end
