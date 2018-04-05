function df_blobsAsDots(varargin)
% Read calc files and go through nuclei, replace dots by centre of mass 
% of blobs
close all
clear all

s.savePlots = 1;

folder = '/data/current_images/20180405_whole_chromosome/iJC1099_20180322_calc/';

files = dir([folder filesep() '*.NM']);

for kk = 1:numel(files)
    file = [folder filesep() files(kk).name];
    
    D = load(file, '-mat');
    M = D.M;
    N = D.N;
    nChannels = numel(M.channels);
    
    for cc = 1:nChannels
        I{cc} = gsmooth(df_meta_getImage(M, cc),1);
    end
    
    for nn = 1:numel(N)
        nn
        mask = df_nuclei_crop(N{nn}, M.mask);
        for cc = 1:nChannels
            clf
            C{cc} = df_nuclei_crop(N{nn}, I{cc});
            subplot(1, 3, 1)
            %imagesc(mask.*mean(C{cc},3));
            imagesc(mask.*max(C{cc},[],3));
            title(M.channels{cc})
            axis image
            colormap gray
            subplot(1, 3, 2)
            
            mask3 = repmat(mask, [1,1,size(C{cc},3)]);
            pixels = C{cc}(mask3>0); pixels = pixels(:);
            low = mean(pixels)
            low = 15000;            
            high = max(pixels)
            high = 20000;
            th = low+(high-low)*.7;
            th = mean(pixels)+3.5*std(pixels)
            
            th = df_blobTh(C{cc}, mask3)
            subplot(1, 3, 2)
            
            B = mask3.*(C{cc}>=th); % Binary
            S = C{cc}-th; S(S<0) = 0; % Shifted so that th is 0
            [L, n] = bwlabeln(B);            
            
            imagesc(max(L, [], 3));            
            axis image
            stats = regionprops(L, S, 'WeightedCentroid');
            title(sprintf('%d blobs', n));
            
            for ww = 1:numel(stats)
                st = stats(ww).WeightedCentroid;
                subplot(1, 3, 1)
                hold on
                plot(st(1), st(2), 'ro');
                subplot(1, 3, 2)
                hold on
                plot(st(1), st(2), 'ro');
            end
            if s.savePlots
                dprintpdf(sprintf('~/temp/nuc_%d_%s.pdf', nn, M.channels{cc}), 'w', 35, 'h', 10);
            end
                
            %pause
        end        
        
    end
    
end

end