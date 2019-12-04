function mergeTifFolders(ochannels, live)
%% function mergeTifFolders(ochannels, live)
% This function look for tif-files in subfolders of the current dir
% then copies them to the current folder.
%
% Example:
% mergeTifFolders([], 'true')
% a/dapi_001.tif -> dapi_001.tif
% a/a594_001.tif -> a594_001.tif
% b/dapi_001.tif -> dapi_002.tif
% b/a594_001.tif -> a594_001.tif
%
% mergeTifFolders({'dapi_', 'stain_'}, 'true')

if ~exist('live', 'var')
    disp('Dry run, change live to ''true'' to do any changes');
    live = false;
end

folders = dir();

channels = {};
if ~exist('ochannels', 'var')
    disp('No output channel names specified, using defaults');
    ochannels = {'dapi_', 'other_'};
end

cnumbers = [];

for kk = 3:numel(folders)
    if isdir(folders(kk).name)
        cd(folders(kk).name)
        
        if numel(channels)==0
            files = dir('*001.tif');
            for cc = 1:numel(files)
                channels{cc} = strrep(files(cc).name, '001.tif', '');
            end
            
            if numel(ochannels)~=numel(channels)
                disp('The number of output and input channels do not match, quiting')
                return
            end
            
            disp('Will do the following mapping:')
            for cc = 1:numel(channels)
                fprintf('%s -> %s\n', channels{cc}, ochannels{cc});
            end
        end
        
        if numel(cnumbers)==0
            cnumbers = ones(numel(channels), 1);
        end
              
        
        for cc = 1:numel(channels)
            files = dir([channels{cc} '*.tif']);
            [~, I] = sort({files(:).name});
            files = files(I);
            
            
            
            % Sort
            for ff = 1:numel(files)
                fin = files(ff).name;
                if numel(ochannels)>0
                    fout = strrep(fin, channels{cc}, ochannels{cc});
                end
                fout(end-6:end-4) = sprintf('%03d', cnumbers(cc));
                cmd = sprintf('!cp %s ../%s', fin, fout);
                if live
                    eval(cmd)
                end
                disp(cmd);
                cnumbers(cc) = cnumbers(cc)+1;
            end
        end
        
        cd ..
    end
end

