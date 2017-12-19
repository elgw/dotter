function L=NLQ2(patch, sigma, x)
%x: x, y, Nphotons, 
mux = x(1);
muy = x(2);
Nphotons = x(3);
BG = x(4);

%[X,Y] = meshgrid(1:size(patch,1), 1:size(patch,2));
%s = round(B*mvnpdf([Y(:), X(:)], [mux, muy], sigma*eye(2)));
s = (Nphotons*df_gaussianInt2([mux, muy], sigma, (size(patch,1)-1)/2));

res = patch(:)-s(:)-BG;
L = sum(res.^2);
end