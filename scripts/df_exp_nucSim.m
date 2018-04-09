%% Look at a set of nuclei and figure out which are outliers based on the 
% dot profiles, consisting of the 20 strongest dots.

folder = '/data/current_images/iJC766_20170720_002_calc/';
folder = uigetdir('/data/current_images/');

[N, M] = df_getNucleiFromNM('folder', {folder}, 'noClusters');

nChan = numel(M{1}.channels);
nDots = 10;

for cc = 1:nChan
    P{cc} = [];
end

figure
for kk = 1:numel(N)
    for cc = 1:nChan
        subplot(1, nChan, cc)
        D = N{kk}.dots{cc};
        if(size(D,1)>nDots)
            D = D(1:nDots,:);
        end
        hold on
        plot(D(:,4));
        if(size(D,1)>=nDots)
            P{cc} = [P{cc}; D(:,4)'];
        end
    end
end
        
for cc = 1:nChan
        subplot(1, nChan, cc)
        title(M{1}.channels{cc})
        plot(mean(P{cc}), 'k-', 'LineWidth', 2);
end

%dprintpdf('/home/erikw/profiles_iEG458.pdf', 'w', 45, 'h', 10);
%dprintpdf('/home/erikw/profiles_iXL217.pdf', 'w', nChan*10, 'h', 10);
%dprintpdf('/home/erikw/profiles_iAM24.pdf', 'w', nChan*10, 'h', 10);
%dprintpdf('/home/erikw/profiles_iJC1041.pdf', 'w', nChan*10, 'h', 10);
%dprintpdf('/home/erikw/profiles_iJC1024.pdf', 'w', nChan*10, 'h', 10);










