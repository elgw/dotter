folder = uigetdir();
files = dir([folder '/*.NM']);
nNuclei = 0;
clear DOTS
clear DPNC
DPNC = [];
for ff = 1:numel(files)
    load([folder '/' files(ff).name], '-mat');
    if numel(N)>0
        if isfield(N{1}, 'userDots');
            
            for nn = 1:numel(N)
                if ~exist('DOTS', 'var')
                    DOTS = zeros(numel(M.channels),1);
                end
                for cc = 1:numel(M.channels)
                    DOTS(cc) = DOTS(cc) + size(N{nn}.userDots{cc},1);
                    DPNC(nNuclei+nn, cc) = size(N{nn}.userDots{cc},1);
                end                
                
            end
            nNuclei = nNuclei+numel(N);            
        else
            fprintf('No userDots for %s\n', files(ff).name);
        end
    else
        fprintf('No cells in %s\n', files(ff).name)
    end    
end


disp('DOTS')
DOTS
disp('nNuclei')
nNuclei
disp('DOTS/nNuclei')
DOTS/nNuclei
disp('Channels')
M.channels
disp('DOTS / nuclei and channel: DPNC');