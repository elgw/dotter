function df_setDapiForFolder(folder)
% Set upper DAPI threshold for folder

[D,~] = getDapiFromFolders([], {folder});
if numel(D) == 0
    disp('Got no DAPI values, any NM files in the folder?')
    return
else
    th = df_dapiThDialog(D);
    if numel(th)>0
        fprintf('>>> Setting M.dapiTh for all NM files ... \n');
        nmFiles = dir([folder filesep() '*.NM']);
        for kk = 1:numel(nmFiles)
            fprintf('.');
            fname = [folder filesep() nmFiles(kk).name];
            t = load(fname, '-mat');
            t.M.dapiTh = th;
            M = t.M; N = t.N;
            
            if ~isfield(M, 'pixelSize')
                if ~exist('vsize', 'var')
                answer = {};
                while(numel(answer) == 0)
                    vsize = [130, 130, 300];
                    prompt = {sprintf('Set the voxel size for proper dot detection.\nCheck the nd2 file if you are unsure!\n\nXY:'),'Z:'};
                    dlg_title = 'Input voxel size';
                    num_lines = 1;
                    defaultans = {num2str(vsize(1)),num2str(vsize(3))};
                    answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
                end
                
                vsize(1) = str2num(answer{1});
                vsize(2) = vsize(1);
                vsize(3) = str2num(answer{2});
                end
                M.pixelSize = vsize;
            end
            
            
            
            save(fname, 'M', 'N');
        end
        fprintf('    done\n');
    else
        warning('M.dapiTh not set!');
    end
end
end