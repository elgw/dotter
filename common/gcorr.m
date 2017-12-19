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

G = G-mean(G(:));
G = G/(sum(G(:).^2).^(1/2));

%G(:)'*G(:)
%FGG = ifftn(fftn(G, size(I)));
if size(I,3)>1
    C = ifftn(fftn(I).*fftn(G, size(I)));
else    
    C = ifft2(fft2(I).*fft2(G, size(I,1), size(I,2)));
end
C = circshift(C, -[rxy, rxy, rz]);


if 0
    % Correct location of maxima
    t1 = zeros(100,100,100);
    t1(41,42,43) = 1;
    t1c = gcorr(t1, [1,1,1]);
    t1c(41,42,43)
    assert(t1c(41,42,43)==max(t1c(:)));
    
    % Invariant to constant addition
    t2 = t1+100;
    t2c = gcorr(t2, [1,1,1]);
    t2c(41,42,43)
    assert(abs(t1c(41,42,43)-t2c(41,42,43))<0.0001)
    
    % Linearity
    t3 = t1*100;
    t3c = gcorr(t3, [1,1,1]);
    t3c(41,42,43)  
    assert(abs(100*t1c(41,42,43)-t3c(41,42,43))<0.0001)
    
    % On slope? Or remove slopes first?
    
end
    