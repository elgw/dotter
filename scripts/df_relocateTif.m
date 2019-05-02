function df_relocateTif(NMfolder, TIFfolder)
% Change the path of the dapi image of all NM files in a calc folder
% This function is called from DOTTER.m
%
% Proposed improvement: Two pass
% * Go through all files
% * Show everything that will be done
% * if ok, go

files = dir([NMfolder filesep() '*.NM']);

fprintf('Found %d files\n', numel(files));

for kk =1:numel(files)
    
    calc = load([NMfolder  files(kk).name], '-mat');  
    
    nFields = numel(fieldnames(calc));
    
    if(nFields ~= 2)
        warning('Wrong number of fields');
        fprintf('%s has %d fields, expected 2\n', files(kk).name, nFields);
    end
    
    M = calc.M;
    N = calc.N;
    
    % Dapi File name
    fn = M.dapifile;
    fn = strsplit(fn, filesep());
    fn = fn{end};
    
    % Fix possible wrong number of dapi file
    % so that XYZ.NM always points to dapi_XYZ.tif
    numStr = sprintf('%03d', kk);
    if strcmp(fn(6:8), numStr) ~= 1        
        errordlg(sprintf('Warning: %s was pointing to %s%s\n', files(kk).name, fn(6:8)));        
        fn(6:8) = numStr;
    end
    
    % folder name
    fo = NMfolder;        
    if fo(end) == filesep()
        fo = fo(1:end-1);
    end
    fo = strsplit(fo, filesep());
    
    cFolder = fo{end};
    pos = strfind(cFolder, '_calc');
    if numel(pos) == 0
        warndlg(sprintf('Can''t figure out what tif folder to use!'))
    end
        
    cFolder = cFolder(1:pos-1); % remove trailing '_calc'
        
    
    relocated_image = [TIFfolder filesep() cFolder filesep() fn];
        
    fprintf('%s\n -> %s\n', M.dapifile, relocated_image);    
    
    M.dapifile = relocated_image;
    save([NMfolder  files(kk).name], '-mat', 'M', 'N');
end

end

