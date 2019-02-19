function C = gcorr(I, sigma)
%% function C = gcorr(I, sigma)
% Correlation to Gaussian kernel, as in DAOPHOT

rxy = round(4*sigma(1)+1);
rz  = round(4*sigma(1)+1);
if (size(I,3)) == 1
    rz = 0;
end

[X,Y,Z] = ndgrid(-rxy:rxy, -rxy:rxy, -rz:rz);
R = (X.^2+Y.^2+Z.^2).^(1/2);
G = mvnpdf([X(:), Y(:), Z(:)], [0,0,0], diag(sigma));
G = reshape(G, size(X));



try
    G = df_gaussianInt3([0,0,0], sigma, rxy);    
catch e
    disp('using mvnpdf, gaussianInt3 not available');
end

while(size(G,3)>size(I,3))
    G = G(:,:,2:end-1);    
end

G = G-mean(G(:));
G = G/(sum(G(:).^2).^(1/2)); % norm(G) == 1

%G(:)'*G(:)
%FGG = ifftn(fftn(G, size(I)));
if size(I,3)>1
    C = ifftn(fftn(I).*fftn(G, size(I)));
else    
    C = ifft2(fft2(I).*fft2(G, size(I,1), size(I,2)));
end
C = circshift(C, -[rxy, rxy, rz]);

end
