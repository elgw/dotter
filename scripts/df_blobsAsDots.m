function df_blobsAsDots(varargin)
% Read calc files and go through nuclei, replace dots by centre of mass
% of blobs

close all
clear all

s.plot = 0;
s.savePlots = 0;
s.setUserDots = 1;

%folder = '/data/current_images/20180405_whole_chromosome/iJC1099_20180322_calc/';

prefdir = df_getConfig('df_blobsAsDots', 'folder', tempdir());

D = uigetdir(prefdir, 'Select calc folder');
if isnumeric(D)
    error('No folder given');
    return;
else
    folder = [D filesep()];
    df_setConfig('df_blobsAsDots', 'folder', folder);
end

a = questdlg(sprintf('Use the blob detector to reset all userDots in %s ?', folder));
if ~strcmpi(a, 'Yes')
    disp('Aborting');
    return;
end

outImageFolder = tempdir();

files = dir([folder filesep() '*.NM']);

for kk = 1:numel(files)
    file = [folder filesep() files(kk).name];
    
    [M, N] = df_nm_load(file);
    
    nChannels = numel(M.channels);
    
    for cc = 1:nChannels
        I{cc} = gsmooth(df_meta_getImage(M, cc),1);
    end
    
    for nn = 1:numel(N)
        fprintf('File: %d nuclei: %d\n', kk, nn);
        
        [mask delta] = df_nuclei_crop(N{nn}, M.mask);
        %keyboard
        
        for cc = 1:nChannels
            
            C{cc} = df_nuclei_crop(N{nn}, I{cc});
            
            if s.plot
                clf
                subplot(1, 3, 1)
                %imagesc(mask.*mean(C{cc},3));
                imagesc(mask.*max(C{cc},[],3));
                title(M.channels{cc})
                axis image
                colormap gray
                subplot(1, 3, 2)
            end
            
            mask3 = repmat(mask == nn, [1,1,size(C{cc},3)]);
            pixels = C{cc}(mask3>0); pixels = pixels(:);
            low = mean(pixels);
            low = 15000;
            high = max(pixels);
            high = 20000;
            th = low+(high-low)*.7;
            th = mean(pixels)+3.5*std(pixels);
            
            th = df_blobTh(C{cc}, mask3, s);                        
            
            B = mask3.*(C{cc}>=th); % Binary
            S = C{cc}-th; S(S<0) = 0; % Shifted so that th is 0
            [L, n] = bwlabeln(B);
            stats = regionprops(L, S, 'WeightedCentroid');
            
            if(s.plot)
                subplot(1, 3, 2)
                imagesc(max(L, [], 3));
                axis image                
                title(sprintf('%d blobs', n));
            end
            
            D = [];
            for ww = 1:numel(stats)
                D = [D; stats(ww).WeightedCentroid];
            end
            
            if s.plot
                for dd = 1:size(D,1)
                    subplot(1, 3, 1)
                    hold on
                    plot(D(dd,1), D(dd,2), 'ro');
                    subplot(1, 3, 2)
                    hold on
                    plot(D(dd,1), D(dd,2), 'ro');
                end
            end
            
            if s.savePlots
                dprintpdf(sprintf('%s/%d_nuc_%d_%s.pdf', outImageFolder, kk, nn, M.channels{cc}), 'w', 35, 'h', 10);
            end
            %keyboard
            N{nn}.userDots{cc} = D(:,[2,1,3]) + repmat(delta, [size(D,1), 1]);
            N{nn}.userDotsExtra{cc} = [];
            N{nn}.userDotsLabels{cc} = ones(size(D,1),1);
            %pause
        end
        
    end
    
    if s.setUserDots
        df_nm_save(M, N, file);
    end
    
end

end