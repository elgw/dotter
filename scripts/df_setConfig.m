function df_setConfig(file, key, value)
% Write a setting to disk.
% see also df_getConfig

folder = '~/.DOTTER/';
if ~(exist(folder, 'dir')==7)
    mkdir(folder)
end

filename = sprintf('%s%s.mat', folder, file);

if exist(filename, 'file')
    config = load(filename, '-MAT');    
    config = config.config;
else
    config = [];    
end

% Prefix key_ to numeric configuration names
if ~isvarname(key)
    key = ['key_' key];
end

config.(key) = value;
save(filename, 'config');

end