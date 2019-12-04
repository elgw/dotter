function I = blitGauss(I, P, sigma, S)
%% function blitGauss(I, P, sigma)
% place Gaussian blobs in image I at points P using size sigma
%
% Example:
%  imagesc(blitGauss(zeros(100,100), [20,20; 25,25], 2))

if(numel(size(I))~=2)
    warning('Only for 2D images');
    return
end

if size(P,1) == 0
    return
end
if numel(sigma)==1
    sigma = ones(size(P,1),1)*sigma;
end

r = ceil(2*max(sigma(:))+2);

if ~exist('S', 'var')
    S = ones(size(P,1), 1);    
end

if (min(P(:,1))<1) || (min(P(:,2))<1) || (max(P(:,1))>size(I,1)) || (max(P(:,2))>size(I,2))
    disp('Warning: dots outside of the image are skipped');
end

P(P(:,1)<1, 1) = 1;
P(P(:,2)<1, 2) = 1;
P(P(:,1)>size(I,1),1) = size(I,1);
P(P(:,2)>size(I,2),2) = size(I,2);


I = padarray(I, [r,r]);
P = P + r;

[Cy, Cx] = meshgrid(-r:r, -r:r);

for kk = 1:size(P,1)    
    c = round(P(kk,:));
        
    Dx = Cx+(c(1)-P(kk,1));
    Dy = Cy+(c(2)-P(kk,2));
    
    I(c(1)-r:c(1)+r, c(2)-r:c(2)+r) = I(c(1)-r:c(1)+r, c(2)-r:c(2)+r) +...
        S(kk)*reshape(mvnpdf0([Dx(:), Dy(:)], [0,0], eye(2)*sigma(kk)), (2*r+1)*[1,1]);
    
end

I = I(r+1:end-r, r+1:end-r);
