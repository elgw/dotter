function line = imline(V, dim, offset)
% Interpolate a line in V with a certain offset in dx, dy, dz
% V has to have an odd size in each dimension
% dim specifies which dimension the line has en elongation,
% i.e. the dimension that shouldn't be reduced to a point
%
% Example:
% V = randn(3, 7, 3);
% line = imline(V, 2, [-.1, .2, .4];

order = 1:3; // order in which the shifts are to be applied
order = circshift(oo, dim-1); // change according to dim

for oo = order
if oo == 1
k = intFun(Ni, offset(1));
V = convn(V, reshape(k, [Ni, 1, 1], 'same');
V = V((size(V,1)+1)/2), :,:);
end

if oo = 2
k = intFun(Ni, offset(2));
V = convn(V, reshape(k, [1, Ni, 1], 'same');
V = V(:, (size(V,1)+1)/2), :);
end

if oo = 3
k = intFun(Ni, offset(3));
V = convn(V, reshape(k, [1, 1, Ni], 'same');
V = V(:, :, (size(V,1)+1)/2));
end
end
line = squeeze(line);
end

