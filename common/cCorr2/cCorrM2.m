function [] = cCorrM2(folder)
% function [] = cCorrM2(folder)
% Sets up correction for chromatic aberrations which can be applied by the
% function cCorr2

if ~exist('folder', 'var')
    folder = uigetdir();
end

if ~strcmp(folder(end), '/')
    folder = [folder '/'];
end

files = dir([folder '*.tif']);

series = {};
channels = {};
for kk = 1:numel(files)
    series{kk} = files(kk).name(end-6:end-4);
    c = strsplit(files(kk).name, '_');
    channels{kk} = c{1};
end

series = unique(series);
channels = unique(channels);

fprintf('Found %d series and %d channels.', numel(series), numel(channels))

fprintf('Using series %s\n', series{1});

files = dir([folder '*' series{1} '.tif']);

%% Load data and get dots
for kk = 1:numel(files)
    files{kk}.V = df_readTif([folder files(kk).name]);
    files{kk}.D = dotCandidates(V);
    s = dotFitting();
    files{kk}.F = dotFitting(V, D(1:500,1:3), s);        
end

%% Select dots with a GUI

%% Save coefficients