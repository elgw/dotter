function M = createDistanceMasks(M)
% Append distanceMask to each M, defined as the distance transform
% of the binary mask M.mask

for kk = 1:numel(M)
    if ~isfield(M{kk}, 'distanceMask')
        mask = M{kk}.mask;
        mask = mask>0;
        mask = ~mask;
        M{kk}.distanceMask = bwdist(mask);
    end
end

end