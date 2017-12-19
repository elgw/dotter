function [N, channels] = UDA_get_nuclei(folder)
%% function [N, channels] = UDA_get_nuclei(folder)
%  Reads all NM files in folder and returns the nuclei in an array

files = dir([folder '/*.NM']);
fprintf('Found %d files\n', numel(files));
N = []; % Store all nuclei
errlog = '';
proceed = 1;
for kk = 1:numel(files)
    errlog = [errlog sprintf('Opening %s\n', files(kk).name)];
    T = load([folder filesep() files(kk).name], '-MAT');
    if kk == 1
        if isfield(T.M, 'channels')
            channels = T.M.channels;
        else
            disp(T)
            assert(false , 'There is no M.channels in %s, this might indicate that the NM file is corrupt or that a very old version of DOTTER was used to create it.', files(kk).name)
        end
    else
        if ~isequal(channels, T.M.channels)
            errlog = [errlog sprintf(' - Different channels compared to the first field\n')];
            proceed = 0;
        end
    end
    if ~proceed
        errlog = [errlog '!!! Aborting\n'];
        msgbox(errlog);
        return
    end
    
    if numel(T.N)>0
        for kk = 1:numel(T.N)
            if isfield(T.N{kk}, 'userDots')
                N = [N T.N{kk}];
            else
                errlog = [errlog sprintf('- No userDots in nuceli %d\n', kk)];
            end
        end
        errlog = [errlog sprintf('- %d nuclei processed\n', kk)];
    else
        errlog = [errlog sprintf(' - Warning: no nuclei\n')];
    end
end

h = msgbox(errlog);
uiwait(h);

end