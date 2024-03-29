function [value] = df_getConfig(file, key, default)
% Load variable from a file. If no value is found, use the default
% if no default, error is cast
%
% Example:
% name = df_getConfig('myFunction', 'defaultName', 'John Doe')

if nargin ==1
    showAll(file)
    return
end

% Prefix key_ to numeric configuration names
if ~isvarname(key)
    key = ['key_' key];
end

filename = sprintf('~/.DOTTER/%s.mat', file);



if exist(filename, 'file')
    config = load(filename, '-MAT');
    config = config.config;
    if isfield(config, key)
        value = config.(key);
    end
else    
    warning('> %s does not exist.\n', filename);
end

if ~exist('value', 'var')
    if ~exist('default', 'var')
        error('No value found');
    end
    value = default;
end

    function showAll(file)
        filename = sprintf('~/.DOTTER/%s.mat', file);
        if exist(filename, 'file')
            config = load(filename, '-MAT');
            config = config.config;
            disp(config);
        else
            disp('Configuration file does not exist');
        end
    end

end