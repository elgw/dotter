function df_nm_integrity(varargin)
%% Check the integrity of an NM file
close all

file = '/home/erikw/projects/20180213_iFISH/data/1_or_2_clusters/iEG459_cc_006_calc/011.NM'
file = '/home/erikw/projects/20180213_iFISH/data/1_or_2_clusters/iEG458_007_OBS_no_CY5_calc///009.NM'
file = '/home/erikw/projects/20180213_iFISH/data/1_or_2_clusters/ieg458_nocc_calc///iEG458_004/006.NM'

if ~exist('file', 'var')
    [file, folder] = uigetfile('*.NM');
    file = [folder, file];
end

check(file);

end


function check(fileName)

[M, N] = df_nm_load(fileName);
M = M{1}
figure

M.dapifile
fileName

s = ceil(sqrt(numel(N)));

for kk = 1:numel(N)
    subplot(s,s, kk)
    imagesc(M.mask == kk);
    colormap gray
    axis image
    hold on
    dots = [];
    for cc = 1:numel(M.channels)
        %fprintf('Nuclei %d Channel: %s\n', kk, M.channels{cc});
        ndots = N{kk}.userDots{cc};
        
        dots = [dots; ndots];        
    end
    plot(dots(:,2), dots(:,1), 'o');
    plot(N{kk}.centroid(2), N{kk}.centroid(1), 'rx');
    title(sprintf('Nuclei %d', kk))
    
    
end




end
