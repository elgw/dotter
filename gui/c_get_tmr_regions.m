function [M, N] = get_tmr_regions(M, N)

%% Purpose:
% Find out if there is only one marked region in tmr or actually two
% write these regions to M.mask_regions in a similar way as M.mask
% i.e., as a scalar field.

visualize = 0;

idapi = df_readTif(M.dapifile);

%% Load tmr
tmrfile = strrep(M.dapifile, 'dapi', 'tmr');
itmr = df_readTif(tmrfile);
mask_regions = 0*M.mask;

%% Low pass filter or threshold to find regions
itmrs = max(itmr, [], 3);
itmrs = itmrs - gsmooth(itmrs, 15);
itmrs = gsmooth(itmrs, 5);

%% Per nuclei, find one clump of marked chromosome or two homologs
for kk = 1:numel(N)
    bbx = N{kk}.bbx;
    tmrpatch = itmrs(bbx(1):bbx(2), bbx(3):bbx(4));
    maskpatch = M.mask(bbx(1):bbx(2), bbx(3):bbx(4));
    th = graythresh(tmrpatch(maskpatch>0));
    tmrpatch_th = double(tmrpatch)/2^16>th;
    
    %f = figure
    %hist(double(tmrpatch(maskpatch>0)), 256)
    %title(sprintf('%d', kk));
    %pause
    %close(f)
    % Clustering -- remove or join small regions.
    
    [L, n] = bwlabeln(tmrpatch_th);
    if (n==2)
       a1 = sum(L(:)==1);
       a2 = sum(L(:) == 2);
       if max(a1,a2)/min(a1,a2)>1.5
           n = 1;
       end
    end
    %figure, imshow2(tmrpatch_th), axis image, title(num2str(kk))
    N{kk}.ntmrregions = n;
    mask_regions(bbx(1):bbx(2), bbx(3):bbx(4)) = L;
end

M.mask_regions = mask_regions;

if visualize
    figure
    imagesc(max(idapi, [], 3))
    hold on
    colormap gray
    contour(double(M.mask>0), [.5, .5], 'g')
    contour(double(mask_regions>0), [.5, .5], 'r')
    for nn = 1:numel(N)
        dots1=N{nn}.dots{1};
        dots2=N{nn}.dots{2};
        %plot(dots1(1:16,2), dots1(1:16,1), 'o', 'markerfacecolor', 'none', 'markeredgecolor', 'w')
        %plot(dots2(1:16,2), dots2(1:16,1), 'o', 'markerfacecolor', 'none', 'markeredgecolor', 'b')
        text(N{nn}.bbx(3), N{nn}.bbx(1), num2str(nn), 'color', 'black', 'background', 'w')
    end

    
    figure
H = max(.4*(M.mask>0), .9*(mask_regions>0));
S = max(M.mask>0, mask_regions>0);
V = double(max(itmr, [], 3)); V= normalisera(V);
imagesc(hsv2rgb(double(H),double(S),double(V)));
hold on
contour(M.mask, 'g')
contour(mask_regions, 'r')
M.mask_regions = mask_regions;
for nn = 1:numel(N)
    dots1=N{nn}.dots{1};
    dots2=N{nn}.dots{2};
    %plot(dots1(1:16,2), dots1(1:16,1), 'o', 'markerfacecolor', 'none', 'markeredgecolor', 'w')
    %plot(dots2(1:16,2), dots2(1:16,1), 'o', 'markerfacecolor', 'none', 'markeredgecolor', 'b')
    text(N{nn}.bbx(3), N{nn}.bbx(1), num2str(nn), 'color', 'black', 'background', 'w')
end

if visualize
    pause
end

% This type of plot gives a clear indication on when the homologs are well
% separated. Shows the strongest dots of each channel
figure
subplot('position', [0,0,1,1])
R = max(idapi, [], 3); R = normalisera(R);
G = max(itmr, [], 3); G = normalisera(G);
B = 0*R;
imagesc(cat(3, R, G, B)), axis image;
hold on
for nn = 1:numel(N)
    dots1=N{nn}.dots{1};
    dots2=N{nn}.dots{2};
    plot(dots1(1:16,2), dots1(1:16,1), 'o', 'markerfacecolor', 'none', 'markeredgecolor', 'w')
    plot(dots2(1:16,2), dots2(1:16,1), 'o', 'markerfacecolor', 'none', 'markeredgecolor', 'b')
    
    
    text(N{nn}.bbx(3), N{nn}.bbx(1), num2str(nn), 'color', 'black', 'background', 'r')
    if N{nn}.ntmrregions == 2
         text(N{nn}.bbx(3), N{nn}.bbx(1), num2str(nn), 'color', 'black', 'background', 'g')
    end
end

end

end
