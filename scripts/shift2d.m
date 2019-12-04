function J = shift2d(I, D)

if size(I,3) == 1
[x1,x2] = ndgrid(1:size(I,2), 1:size(I,1));
J = interpn(I, x1-D(1), x2-D(2), 'linear', 0);
end

if size(I,3) > 1
[x1,x2] = ndgrid(1:size(I,2), 1:size(I,1));
J = 0*I;
for kk = 1:size(I,3)
    J(:,:,kk) = interpn(I(:,:,kk), x1-D(1), x2-D(2), 'linear', 0);
end
end


end