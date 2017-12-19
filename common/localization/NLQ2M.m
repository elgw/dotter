function L=NLQ2M(patch, sigma, x)
NSIGNALS = (numel(x)-1)/3;
%x: x, y, Nphotons, 

%[X,Y] = meshgrid(1:size(patch,1), 1:size(patch,2));
%s = round(B*mvnpdf([Y(:), X(:)], [mux, muy], sigma*eye(2)));
s = 0*patch;
%x
for kk=1:NSIGNALS
    mupos = (kk-1)*NSIGNALS+1;
    s = s+ (x(2*NSIGNALS+kk)*df_gaussianInt2([x(mupos), x(mupos+1)], [sigma, sigma], (size(patch,1)-1)/2));
end
s = s + x(end);

res = patch(:)-s(:);
L = sum(res.^2);

%[L,x']

if 0
figure(11),
subplot(1,3,1)
imagesc(s), axis image
subplot(1,3,2)
imagesc(patch), axis image
subplot(1,3,3)
imagesc(reshape(res, size(patch))), axis image
title(sprintf('L: %f', L))
pause
end

end