function [DPN] = df_dotsPerNucleiMM(varargin)
% function DPN = df_dotsPerNucleiMM(varargin)
% Counts the number of dots in all nuclei defined in the NM files in the
% selected folder.
%
% Method: Projects the image according to s.proj and then
%  caluclates mean, m, and standard deviation, s, for each nuclei
%  The nuclei is thresholded at m+2.5*s and the number of regions larger
%  than s.minPixels are counted.
%
% Settings:
%  minPixels Smallest number of pixels for a dot to be counted
%  proj      Projection type, one of 'maxz', 'meanz', 'none' (for 3d)
%  plot      View each nuclei as the script progresses (1 or 0)
%
% Example:
%  s = df_dotsPerNucleiMM('getDefaults');
%  s.plot = 1;
%  DPN = df_dotsPerNucleiMM('settings', s);
%  histogram(DPN);



% Defaults
s.minPixels = 2; % Discard objects smaller than this when counting dots
s.proj = 'maxz'; % Projection type: maxz, meanz, none
s.plot = 0;
%s.folder = '/data/current_images/iEG/iEG103_041215_001_calc';
%s.folder = '/data/current_images/iMB/iMB32_280416_001_calc';

DPN = [];

for kk = 1:numel(varargin)
     if strcmpi(varargin{kk}, 'getDefaults')
        n = s;
        return
    end
    if strcmpi(varargin{kk}, 'proj')
        s.proj = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'minPixels')
        s.minPixels = varargin{kk+1};
    end
     if strcmpi(varargin{kk}, 'settings')
        % Override all other settings
        s = varargin{kk+1};        
    end
end

disp('Settings:');
disp(s);

if 1
    
end

if ~isfield(s, 'folder')
    s.folder = uigetdir();
    fprintf('Picked: %s\n', s.folder);
end

if s.folder == 0
    disp('No folder selected')
    return
end

files = dir([s.folder '/*.NM']);

if numel(files) == 0
    disp(['No .NM files in ' s.folder])
    return
end
fprintf('Found %d files\n', numel(files));

ndots = 0;
nnuclei = 0;
for kk =1:numel(files)
    
    [meta] = load([s.folder '/' files(kk).name], '-mat');
    M = meta.M;
    N = meta.N;
    
 
    
    if (numel(M.channels)>1)
        warning(sprintf('Only looking for dots in %s\n', M.channels{1}));
    end
    
    
    vFiles = {strrep(M.dapifile, 'dapi', M.channels{1})};
    
    for cc = 1
        iChan = df_readTif(vFiles{cc});
       
        if strcmpi(s.proj, 'none')
            mask = repmat(M.mask, [1,1,size(iChan, 3)]);
        end
        if strcmpi(s.proj, 'maxz')
            mask = M.mask;
            iChan = max(iChan, [], 3);
        end
        if strcmpi(s.proj, 'meanz')
            mask = M.mask;
            iChan = mean(iChan, 3);
        end
        
        for nn = 1:numel(N)            
            % All pixels of the nuclei
            nuc = iChan(M.mask==nn);
            
            nucMasked = iChan;
            nucMasked(mask~=nn)=0;
            
            % These does not work well since the bg varies with z!
            nmean = mean(double(nuc(:)));
            if ~isnan(nmean)
                   nnuclei = nnuclei+1;
            nstd = std(double(nuc(:)));
            nth = nmean + 2.5*nstd;
            
            fprintf('mean: %f, std: %f, th: %f\n', nmean, nstd, nth);
                           
            
            [L,n] = bwlabeln(nucMasked>nth);
            
            h = df_histo16(uint16(L));
            nd = sum(h(2:end)>=s.minPixels);
            DPN = [DPN; nd];
            ndots = ndots + nd;
           
           
            if s.plot                
                figure(1)
                subplot(1,2,1)
                imagesc(L)
                axis image
                colormap jet
                subplot(1,2,2)
                imagesc(nucMasked)
                axis image
                colormap gray
                pause
            end
            
            else
                disp('NaN mean')
                disp('This probably means that there is a problem with the mask')
                disp('Aborting');
                return
            end
        end
    end
    
end

fprintf('Found %d dots in %f nuclei.\n', ndots, nnuclei);

end