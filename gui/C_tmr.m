%% Initialization
wfolder = '/Users/erikw/data/310715_calc/';
files = dir([wfolder '*NM']);



for kk = 1:numel(files) %% Per file
    progressbar(kk, numel(files))
    F = [];
    load([wfolder files(kk).name], '-mat')    
    [M, N] = c_get_tmr_regions(M, N);
    save([wfolder files(kk).name], 'N', 'M');
end
