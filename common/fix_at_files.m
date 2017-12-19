files = dir('*.tif')
directory = pwd();
for kk = 1:numel(files)
    
    folders = strsplit(files(kk).name, '@');
    newdir = '';
    for ff = 1:numel(folders)-1
        mkdir(folders{ff})
        cd(folders{ff})
        newdir = [newdir folders{ff} '/'];       
    end
    cd(directory)    
    eval(sprintf('!mv %s %s%s\n', files(kk).name, newdir, folders{end}));            
end