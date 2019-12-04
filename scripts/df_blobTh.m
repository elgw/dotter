function th = df_blobTh(I, mask, s)
% Suggests a threshold for segmenting blobs in nuclei.
% I: 3D cropped image of a nuclei
% mask: 2D mask
% See df_blobsAsDots.m


assert(isequal(size(I), size(mask)));

s.nLevels = 150; % Number of thresholds to try
%s.plot = 1;

pixels = I(mask>0);
ths = linspace(mean(pixels), max(pixels), s.nLevels);
g = goodness(I, mask, ths);

best = find(g==max(g));
th = ths(best(1));


if s.plot
    subplot(1,3,3)
    cla
    plot(ths,g)
    axis([ths(1), ths(end), -1000, 1000])
    xlabel('Threshold')
    ylabel('Goodness');
    a = axis;
    hold on
    plot([th,th], [a(3), a(4)], 'r');
end

end

function G = goodness(I, mask, ths)
G = zeros(size(ths));

for kk = 1:numel(ths)
    
    g = 1;
    th = ths(kk); % Threshold to evaluate
    B = mask.*(I>=th); % Binary
    S = I-th; S(S<0) = 0; % Shifted so that th is 0
    [L, n] = bwlabeln(B);
    
    stats = regionprops(L, S, 'Area');
    for ss = 1:numel(stats)
        g = g+1-(stats(ss).Area-1000)^2/2000/n;
    end
    G(kk) = g; %/(n-2)^2;
end

end