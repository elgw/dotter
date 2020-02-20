function ST=gst3(V, sigma_g, sigma_t)
% function ST=gst3(V, sigma_g, sigma_t)
% Gradient structure tensor
% sigma_g gradient sigma
% sigma_t tensor sigma

% Partial derivatives
d1=gpartial(V,1,sigma_g);
d2=gpartial(V,2,sigma_g);
d3=gpartial(V,3,sigma_g);

% Structure tensor
ST=zeros([size(d1), 6]);
ST(:,:,:,1)=d1.*d1;
ST(:,:,:,2)=d1.*d2;
ST(:,:,:,3)=d1.*d3;
ST(:,:,:,4)=d2.*d2;
ST(:,:,:,5)=d2.*d3;
ST(:,:,:,6)=d3.*d3;

% Smooth the components
for k=1:6
  ST(:,:,:,k)=gsmooth(ST(:,:,:,k), sigma_t);
end

end