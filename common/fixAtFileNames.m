% Fix filenames from the old directory of the server,
% i.e., batches of 
% !mv pub4@Magda_R@DNA_FISH@111212@Combinatorial_iPhase@a594_004.tif a594_004.tif

disp('Renaming abc@def@chan_XYZ.tif to chan_XYZ.tif')
disp('Press any key to continue')
pause

files = dir('*.tif');
for kk = 1:numel(files)    
    fname = files(kk).name;
    fname0 = fname;
    fname = strsplit(fname, '@');
    fname = fname{end};
    if ~strcmp(fname, fname0)
        eval(sprintf('!mv %s %s', fname0, fname));
    end
end

dapifiles = dir('dapi*.tif');
dnafiles =  dir('dna*.tif');


if numel(dnafiles)>0   
    if(numel(dapifiles)==0)
        disp('dna-files detected')
        disp('Renaming dna_XYZ.tif to dapi_XYZ.tif')
        for kk = 1:numel(files)
            fname0 = files(kk).name;
            fname = strrep(fname0, 'dna', 'dapi');
            eval(sprintf('!mv %s %s', fname0, fname));
        end
    else
        disp('Both dna and dapi files detected. Resolve this manually!')
    end
else
    disp('No dna-files to rename')
end
    