function  [N, mask] = create_nuclei_from_mask(mask, I, s)
%   N = create_nuclei_from_mask(mask, I, s)
%   Initiates all nuclei based on a segmentation mask and the dapi image.
%
% Input:
% mask: binary mask
% I: 2D or 3D image of dapi
% s: settings (not used)
%
% Output:
% N{kk}.bbx
% N{kk}.centroid
% N{kk}.dapisum
% N{kk}.area
%
% TODO: 
% What to do if the mask is missing a label? Alternatives
% A/ Empty nuclei -- might screw up something later.
% B/ Changing the mask -- has to be propagated back!
% Idealy each nuclei should have a maskId which says what number in the
% mask that it belongs to.

N = [];
if max(mask(:)) == 1
    [S, nCells] = bwlabeln(mask, 8);
    mask = S;
else
    S = mask;
    nCells = max(S(:));
end

I = single(I);

if numel(size(mask)) == 2
    I = sum(I,3);
end

h = df_histo16(uint16(mask));
h = h(2:end); % exclude background counts
objects = find(h>0);

for kk=1:numel(objects)
    objNum = objects(kk);
    % fprintf('bbox for object %d with label %d\n', kk, objNum);
    % Bounding boxes are a few pixels larger than the masks
    seg = double(S == objNum);
    nuclei.bbx = bbox(seg);
    nuclei.bbx(1)=max(1, nuclei.bbx(1)-5);
    nuclei.bbx(2)=min(size(seg,1), nuclei.bbx(2)+5);
    nuclei.bbx(3)=max(1, nuclei.bbx(3)-5);
    nuclei.bbx(4)=min(size(seg,2), nuclei.bbx(4)+5);
    nuclei.centroid = [mean(nuclei.bbx(1:2)), mean(nuclei.bbx(3:4))];
    
    nuclei.dapisum = sum(sum(sum(seg.*I)));
    nuclei.area = sum(sum(sum(seg)));
    
    N{kk} = nuclei;
end


end

