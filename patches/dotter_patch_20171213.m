% Load a folder, 
% Load all NM files
% For each nuclei, export (x,y,z,intensity) to csv files
% To be used by silvano for topological data analysis

function dotter_patch_20171213()

folder = '/data/current_images/iEG/iEG364_20170524_004_calc';

if ~exist('folder', 'var')
    folder = uigetdir();
end

outFolder = [folder '/nuclei/'];
mkdir(outFolder);

files = dir([folder '/*.NM']);

threshold  = 12000;

for kk = 1:numel(files)
    disp(files(kk).name)
    exportNuclei([folder '/' files(kk).name], kk, outFolder, threshold);
end


end

function exportNuclei(file, fileNo, outFolder, threshold)

D = load(file, '-mat');
N = D.N;

M = D.M;

I = loadImagesFromM(M);

for kk = 1:numel(N);
    bbx = N{kk}.bbx;
    bbx(1) = max(1, bbx(1)-M.dilationRadius);
    bbx(3) = max(1, bbx(3)-M.dilationRadius);
    bbx(2) = min(1024, bbx(2)+M.dilationRadius);
    bbx(4) = min(1024, bbx(4)+M.dilationRadius);
    
    idata = I{1}(bbx(1):bbx(2), bbx(3):bbx(4), :);
    
    npixels = sum(idata(:)>threshold);
    T = zeros(npixels, 4);
    pos = 1;
    for xx = 1:size(idata,1)
        for yy = 1:size(idata,2)
            for zz = 1:size(idata,3)
                if idata(xx,yy,zz)>threshold
                    T(pos,:) = [xx, yy, zz, idata(xx,yy,zz)];
                    pos = pos+1;
                end
            end
        end
    end
    fname = sprintf('%s/%03d_%03d.csv', outFolder, fileNo, kk);
    
    writetable(array2table(T), fname)
end
    
end

function I = loadImagesFromM(M)
disp('Loading images');
    for kk = 1:numel(M.channels)        
        I{kk} = df_readTif(strrep(M.dapifile, 'dapi', M.channels{kk}));
    end
    I{end+1} = df_readTif(M.dapifile);
end
