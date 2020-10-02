function nmfile = df_nm_get_name_from_image(imagefile)
%% function nmfile = df_nm_get_name_from_image(imagefile)
% Return the name of the associated NM file from an image name
% The folder and the extension is discardrd

[~, fname, ~] = fileparts(imagefile);
fname = strsplit(fname, '_');
num = str2num(fname{end});

if numel(num) == 0
    error('Can''t convert %s to a number', num);
end

nmfile = [fname{end}, '.NM'];

end