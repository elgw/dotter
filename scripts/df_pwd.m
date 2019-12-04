function PD = df_pwd()
% function PD = df_pwd()
% get pairwise distances from nuclei in NM files using UserDots

N = df_getNucleiFromNM();
if numel(N) == 0
    return
end

PD = [];
ND = 0; % count the number of dots
for kk = 1:numel(N)
    D = [];
    %keyboard
    if isfield(N{kk}, 'userDots')
        for cc = 1:numel(N{kk}.userDots)
          dots = N{kk}.userDots{cc};
          if numel(dots)>0
            D = [D; dots(:,1:3)];
          end
        end
        ND = ND + size(D,1);                        
        PD = [PD, pdist(D, 'euclidean')];
    else
        warning(sprintf('No userDots in %s (%d)\n', N{kk}.file, N{kk}.nucleiNr));
    end
end

fprintf('%d nuclei, %d dots, %d pwd', numel(N), ND, numel(PD));

figure
ehistogram('data', PD, 'xlabel', 'Pairwise Distances', 'title', sprintf('%d nuclei, %d dots, %d pwd', numel(N), ND, numel(PD)));

end
