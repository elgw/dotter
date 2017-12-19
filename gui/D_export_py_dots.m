%% Purpose: export dots as csv to be read by Pyhton
% cplot3.py

% csv format, files: 001_001_001.csv
% or file_nuclei_channel.csv


wfolder = '/Users/erikw/data/310715_calc/';
outFolder = [wfolder 'csv_dots/'];

files = dir([wfolder '*.NM']);


try
    mkdir(outFolder)
end


for kk = 1:numel(files) %% Per file    
    load([wfolder files(kk).name], '-mat') 
    M.nTrueDots = [3,4,5];
    
    for nn = 1:numel(N)
        for cc = 1:numel(M.nTrueDots)
            
            dots = N{nn}.dots{cc};
            fileName = sprintf('%s%03d_%03d_%03d.csv', outFolder, kk, nn, cc);                        
            csvwrite(fileName, dots);
            
        end
    end
end
            
    
