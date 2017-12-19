function relocateTIF(NMfolder, TIFfolder)

files = dir([NMfolder '*.NM']);

fprintf('Found %d files\n', numel(files));

for kk =1:numel(files)
    
    load([NMfolder  files(kk).name], '-mat');  
    
    % file name
    fn = M.dapifile;
    fn = strsplit(fn, '/');
    fn = fn{end};
    
    % folder name
    fo = NMfolder;        
    if fo(end) == '/'
        fo = fo(1:end-1);
    end
    fo = strsplit(fo, '/');
    cFolder = fo{end};
    cFolder = cFolder(1:end-5);
    
    % New name
    nn = [TIFfolder '/' cFolder '/' fn];
        
    fprintf('%s\n -> %s\n', M.dapifile, nn);    
    
    M.dapifile = nn;
    save([NMfolder  files(kk).name], '-mat', 'M', 'N');
end

end

