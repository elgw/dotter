function wrong = df_ls_dapi()
% See what files have the wrong DAPI file

wrong = 0;
files = dir('*.NM');
for kk = 1:numel(files)
    M = df_nm_load(files(kk).name);
    fprintf('%s: %s ', files(kk).name, M{1}.dapifile);
    
    
    if strcmp(files(kk).name(1:3), M{1}.dapifile(end-6:end-4)) == 1
        fprintf('\n');
    else
        wrong = wrong + 1;
        fprintf(' E\n');
    end
        
end


end