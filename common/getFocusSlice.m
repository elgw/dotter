function sliceNo = getFocusSlice(V)
% Return the z-index of the most foucussed slice

E = zeros(size(V,3),1);
for kk=1:size(V,3)
    E(kk)= sum(sum((unpadmatrix(diff(diff(V(:,:,kk),1), 2),2)).^2)); 
end
sliceNo = find(E==max(E));