function D = df_mask_ldist(M)
% function D = df_mask_ldist(M)
% Create a 2D distance mask for the nuclei in M
% M==0 is interpreted as background
% M > 0 is interpreted as nuclei
% Everything outside of nuclei is set to -1

nuc = unique(M(:));
nuc = setdiff(nuc, 0); % remove 0 from nuc
D = zeros(size(M));
for nn = 1:numel(nuc)
    B = M==nuc(nn);
    Dn = bwdist(~B);
    D = D + Dn;
end
D(M==0) = -1;
D = double(D);
end