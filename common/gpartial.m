function partial = gpartial(V, d, sigma)
% function partial=gpartial(V, d, sigma)
% Calculate the partial derivative of V along dimension d using a filter of
% size sigma
% Example. Get the gradient magnitude of V:
% sigma = 1;
% dx = gpartial(V, 1, sigma);
% dy = gpartial(V, 2, sigma),
% dz = gpartial(V, 3, sigma);
% gm = (dx.^2+dy.^2+dz+^2).^(1/2);

w=round(8*sigma+2); % Width in pixels
if mod(w,2)==0 % Always use a filter with odd number of elements 
    w=w+1;
end
w=2*w+1;
if sigma == 1
    w=11;
end

if sigma == 0
    dg = [0 -1 1];
    g = [0 .5 .5];
else    
    g =fspecial('gaussian', [w,1], sigma);
    x=(-(w-1)/2:(w-1)/2)';
    k0=1/sqrt(2*pi*sigma^2); k1=1/(2*sigma^2);
    dg=-2*k0*k1.*x.*exp(-k1*x.^2);
    % dg2=1/sigma^2*(-(w-1)/2:(w-1)/2)'.*g;
end


nel=numel(g); % Number of elements in g

partial=V;
if(numel(size(V))==3) % If 3D volume
    if sum(d==1)
        partial=convn(partial, reshape(dg, [nel,1,1]), 'same');
    else 
        partial=convn(partial, reshape(g, [nel,1,1]), 'same');
    end
    
    if sum(d==2)
        partial=convn(partial, reshape(dg, [1,nel,1]), 'same');
    else 
        partial=convn(partial, reshape(g, [1,nel,1]), 'same');
    end
    
    if sum(d==3)
        partial=convn(partial, reshape(dg, [1,1,nel]), 'same');
    else 
        partial=convn(partial, reshape(g, [1,1,nel]), 'same');
    end            
end


if(numel(size(V))==2) % If 2D image
    if sum(d==1)
        partial=convn(partial, reshape(dg, [nel,1]), 'same');
    else 
        partial=convn(partial, reshape(g, [nel,1]), 'same');
    end
    if sum(d==2)
        partial=convn(partial, reshape(dg, [1, nel]), 'same');
    else 
        partial=convn(partial, reshape(g, [1,nel]), 'same');
    end   
end  


if 1==0
    % Test 3D Functionality
    t=zeros(11,11, 11);
    figure, t(6,6,6)=1;
    
    tx=gpartial(t,1,1);
    figure, imagesc(tx(:,:,6))
    
    ty=gpartial(t,2,1);
    figure, imagesc(ty(:,:,6))
    
    txy=gpartial(t,[1,2],1);
    figure, imagesc(txy(:,:,6))
    
    tyx=gpartial(t,[2,1],1);
    figure, imagesc(tyx(:,:,6))
    
    
    txyz=gpartial(t,[1,2],2);
    figure, imagesc(txyz(:,:,6))
        
    txx=gsecond(t, 1, 1);
    figure, imagesc(txx(:,:,7))
     
   % Test functionality in 2D
   t=zeros(21,21);
   t(11,11)=1;
   sigma=3;
   d1=gpartial(t, 1, sigma);
   figure,   imagesc(d1)
   d2=gpartial(t, 2, sigma);
   figure, imagesc(d2)
   figure
   colormap(hot)
   for theta=linspace(0,8*pi, 200)
   imagesc(cos(theta)*d1+sin(theta)*d2)
   drawnow
   pause(0.1)
   end
         
end
    