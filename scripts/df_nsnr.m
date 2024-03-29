function nsnr = df_nsnr(M, N, image, dots, channelNumber)
% NSNR caluclated as value of image at dot / median value of image over
% nuclei
% Using the max projection.
% Using the dilated mask (if available).
% Requested by SU

if size(dots,1) < 1
    fprintf('df_nsnr: No dots\n');
    nsnr = [];
    return;
end

nsnr = zeros(size(dots,1),1);

% 1/ Calculate median value per nuclei

if isfield(M, 'xmask')
    mask = M.xmask{channelNumber}; % Use the dilated mask
else
    if isfield(M, 'mask')
        mask = M.mask;
    else
        error('No mask found in meta data. Corrupt NM file?')
    end
end
imax = max(image, [], 3); % Max projection
BG = zeros([max(mask(:)), 1]);
for kk = 1:numel(BG)
    pixels = imax(mask == kk);
    BG(kk) = median(pixels(:));
end
    
% 2/ For each dot, divide image intensity by the correponding nuclei
% value from 1.

nuclei = interpn(mask, dots(:,1), dots(:,2), 'nearest');
value = interpn(image, dots(:,1), dots(:,2), dots(:,3));
for kk = 1:size(nsnr,1)
    if nuclei(kk) > 0
        nsnr(kk) = value(kk)/BG(nuclei(kk));
    else
        nsnr(kk) = -1;
    end
end


end