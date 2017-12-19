% calculate more features for a dataset
% Creates M.dotTypes : information about available dot features
% also adds the dot features to M
% run dotterDotsSelect afterwards to select which dot type to use

folder = uigetdir();
files = dir([folder '/*.NM']);
sprintf('%s selected\n', folder);

nMAX = inputdlg('Set the max number of dots');

if numel(nMAX)==0
    nMAX = inf;
else    
    nMAX = str2num(nMAX{1});
    if numel(nMAX)~=1
        disp('Could not figure out the max number of dots, returning');
        return
    end
end

fprintf('Max number of dots: %d\n', nMAX);


for ff = 1:numel(files)
    NM = load([folder '/' files(ff).name], '-mat');
    M = NM.M;
    N = NM.N;
    
    for cc = 1:numel(M.channels)
        I = df_readTif(strrep(M.dapifile, 'dapi', M.channels{cc}));
        n = min(nMAX, size(M.dots{cc},1));
        fprintf('Using %d dots for channel %s\n', n, M.channels{cc});
        M.dots{cc} = M.dots{cc}(1:n,:);
        s = dotFitting();
        FIT = dotFitting(I, M.dots{cc},s);
        M.FIT{cc} = FIT;
        FWHM = df_fwhm(I, M.dots{cc});
        M.FWHM{cc} = FWHM;
        M.DOG{cc} = M.dots{cc}(:,4);
        M.PIXEL{cc} = M.dots{cc}(:,5);
    end
    
    type = 1;
    M.dotTypes{type}.field = 'PIXEL';
    M.dotTypes{type}.column = 1;
    M.dotTypes{type}.desc = 'Pixel Values';
    M.dotTypes{type}.ordering='descend';
    
    type = type+1;
    M.dotTypes{type}.field = 'DOG';
    M.dotTypes{type}.column = 1;
    M.dotTypes{type}.desc = 'DoG Filter Response';
    M.dotTypes{type}.ordering='descend';
    
    type = type+1;
    M.dotTypes{type}.field = 'FIT';
    M.dotTypes{type}.column = 4;
    M.dotTypes{type}.desc = 'Number of photons from Gaussian Fitting';
    M.dotTypes{type}.ordering='descend';
    
    type = type+1;
    M.dotTypes{type}.field = 'FIT';
    M.dotTypes{type}.column = 5;
    M.dotTypes{type}.desc = 'Fitting Error';
    M.dotTypes{type}.ordering='ascend';
    
    type = type+1;
    M.dotTypes{type}.field = 'FWHM';
    M.dotTypes{type}.column = 1;
    M.dotTypes{type}.desc = 'Full Width Half Max';
    M.dotTypes{type}.ordering='descend';
        
    save([folder '/' files(ff).name], 'N', 'M');
end

