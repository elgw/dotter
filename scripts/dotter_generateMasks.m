function [masks, names, dEdge] = dotter_generateMasks(mask, d0)
%% function [masks, names, dEdge] = dotter_generateMasks(mask)
% Purpose: generate new masks from a nuclei mask, these are
% returned in names:
% {'nuclei', 'dilated nuclei', 'tesselation', 'outside_nuclei'}
% the 'dilated nuclei' needs to know how much the cells are to be dilated
% which is supplied in d0, given in pixels
% dEdge: closest distance to any nuclei edge

cellNo = unique(mask);
cellNo = setdiff(cellNo, 0);

D = zeros([size(mask,1), size(mask,2), numel(cellNo)]);
dmin = numel(D)*(1+D(:,:,1));
dminIn = 0*numel(D)*(1+D(:,:,1));
for kk = 1:numel(cellNo)
    t = bwdist(mask==cellNo(kk));
    tIn = bwdist(mask~=cellNo(kk));
    dmin = min(t,dmin);
    dminIn = max(tIn, dminIn);
    D(:,:,kk) = t;
end

dEdge = dmin-dminIn-+1*(dminIn>0);

minD = repmat(min(D,[],3), [1,1,size(D,3)]);
D2 = D==minD;

mask1 = mask;

mask3 = 0*mask1;
for kk = 1:size(D2,3)
    mask3 = max(mask3, D2(:,:,kk)*cellNo(kk));
end

mask2 = mask3.*(dmin<d0);

mask4 = mask1==0;

masks = {mask1, mask2, mask3, mask4};
names = {'nuclei', 'dilated nuclei', 'tesselation', 'outside_nuclei'};
end