function dirs = rdir(folder)
%% function files = rdir(pattern)
% Finds all subfolders
% Example:
% dirs = rdir(pwd())

files = dir(folder);
dirs = {folder};

for kk = 3:numel(files)
    fo = [files(kk).folder, filesep(), files(kk).name, filesep()];
    if isfolder(fo)        
        rd = rdir(fo);                
        if numel(rd)>0            
            for dd = 1:numel(rd)
                dirs{end+1} = rd{dd};
            end
        end        
    end
end


end
