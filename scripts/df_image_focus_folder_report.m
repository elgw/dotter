function df_image_focus_folder_report(folder, varargin)
% function df_image_focus_folder_report(folder, varargin)
% produce a pdf with focus curves for all 'dapi*.tif' images in a folder
% arguments:
% method: 'gm' -- gradient magnitude
% file_pattern: 'dapi*.tif'

% Defaults
method = 'gm';
pattern = 'dapi*.tif';
image = '';

% Argument parsing
for kk = 1:numel(varargin)
    if strcmp(varargin{kk}, 'method')
        method = varargin{kk+1};
    end
    if strcmp(varargin{kk}, 'image')
        image = varargin{kk+1};
    end
end

% Calculation
files = dir([folder filesep() pattern]);

figure();
hold on
xlabel('Z slice');
ylabel(method);

leg = {};
for kk = 1:numel(files)
    file=[folder filesep() files(kk).name];
    fprintf('%d/%d, %s\n', kk, numel(files), file);
    V = df_readTif(file);    
    assert(numel(V)>0)
    F = df_image_focus('image', V, 'method', method);
    plot(F)
    leg{kk} = num2str(kk);
end

legend(leg);

if numel(image)>0
    title(image, 'Interpreter', 'none');
    dprintpdf(image);
end

end