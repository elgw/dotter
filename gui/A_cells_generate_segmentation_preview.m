function A_cells_generate_segmentation_preview(folder)
%% function A_cells_generate_segmentation_preview(folder)
%
% For .NM file in <folder>, show dapi image
% and segmented nuclei. Write image to disk into <folder>
%
% 2017-01-26

if ~exist('folder', 'var')
    disp('No folder specified, using current folder');
    folder = pwd;
end

if folder(end)~='/'
    folder = [folder '/'];
end

fprintf('Generating segmentation previews\n');
fprintf('Looking for NM files in %s\n', folder);

files = dir([folder '*.NM']);

if numel(files) == 0
    warning('No NM files found!');
end

f = figure();
for kk = 1:numel(files)
    
    NE = load([folder files(kk).name], '-mat');
    NE.idapi = df_readTif(strrep(NE.M.dapifile, 'erikw', getenv('USER')));
    clf
    
    imagesc(sum(NE.idapi, 3));
    colormap gray
    hold on
    if ~isfield(NE.M, 'mask')
        warning('No mask available');
    else
        % note that for a 3D masks, the contours are drawn from the sum
        % projection
        if max(NE.M.mask(:)>0)
            contour(sum(NE.M.mask,3), [.5,.5], 'r');
        end
    end
    
    if isfield(NE, 'N')
        for tt = 1:numel(NE.N)
            if(isfield(NE.M, 'dapival'))
                x = NE.N{tt}.dapisum<NE.M.dapival;
            else
                x = 1;
            end
            plotbbx(NE.N{tt}, sprintf('%d', tt), x)
        end
    end
    
    axis image
    axis xy
    
    outImName = [folder filesep() files(kk).name(1:end-3) '_cells.png'];
    outFigName = [folder filesep() files(kk).name(1:end-3) '_cells.fig'];
    savefig(f, outFigName);
    imData = getframe();
    imwrite(imData.cdata, outImName);
end
close(f);
fprintf('Done!\n');

end

function plotbbx(N, label, color)
% Draw the bounding box for nuclei <N>

if color == 1
    x = 'g';
else
    x = 'b';
end

plot([N.bbx(3), N.bbx(3)], [N.bbx(1), N.bbx(2)], x);
plot([N.bbx(4), N.bbx(4)], [N.bbx(1), N.bbx(2)], x);
plot([N.bbx(3), N.bbx(4)], [N.bbx(1), N.bbx(1)], x);
plot([N.bbx(3), N.bbx(4)], [N.bbx(2), N.bbx(2)], x);
text(N.bbx(3), N.bbx(1), label, 'Color', [1,0,0], 'FontSize', 14);
end