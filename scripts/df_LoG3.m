function LoG = df_LoG3(S)
% Generate a 3D LoG filter with sigma values from S

if numel(S) == 1
    S = [S, S, S];
end

sigma = S(1);
cutoff = ceil(4*sigma);
Gx = fspecial('gaussian', [1, 2*cutoff+1], sigma);
d2Gx = Gx .* ((-cutoff:cutoff).^2 - sigma^2) / sigma^4;
Gx = reshape(Gx, [numel(Gx), 1, 1]);
d2Gx = reshape(d2Gx, [numel(d2Gx), 1, 1]);
sigma = S(2);
cutoff = ceil(4*sigma);
Gy = fspecial('gaussian', [1, 2*cutoff+1], sigma);
d2Gy = Gy .* ((-cutoff:cutoff).^2 - sigma^2) / sigma^4;
Gy = reshape(Gy, [1, numel(Gy), 1]);
d2Gy = reshape(d2Gy, [1, numel(d2Gy), 1]);
sigma = S(3);
cutoff = ceil(4*sigma);
Gz = fspecial('gaussian', [1, 2*cutoff+1], sigma);
d2Gz = Gz .* ((-cutoff:cutoff).^2 - sigma^2) / sigma^4;
Gz = reshape(Gz, [1, 1, numel(Gz)]);
d2Gz = reshape(d2Gz, [1, 1, numel(d2Gz)]);

dxx = convn(d2Gx, Gy, 'full');
dxx = convn(dxx, Gz, 'full');

dyy = convn(Gx, d2Gy, 'full');
dyy = convn(dyy, Gz, 'full');

dzz = convn(Gx, Gy, 'full');
dzz = convn(dzz, d2Gz, 'full');

LoG = dxx + dyy + dzz;

end