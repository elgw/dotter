

folder = '/Users/erikw/data/121212_5/';
folder = '/Users/erikw/data/031112/031112_2/';



if 0
   pause
   
   up = 100; % unpadding value
   S = [0,0];
   up = 100; % unpadding value
   S = [0,0];
   
   imagesc(shift2d(double(midapi), [100,0]))
   % figure, imagesc(mitmr)
   [x,y] = meshgrid(-25:1:25, -25:1:25);
   c2 = 0*x;
   for kk = 1:size(x,1)
       progressbar(kk, size(x,1));
       for ll = 1:size(x,2)   
            c2(kk,ll) = corr2(unpadmatrix(shift2d(midapi, [x(kk,ll), y(kk,ll)]), up), unpadmatrix(mitmr, up));
       end
   end
    figure, imagesc(c2)
    
   [xp,yp]=find(c2==max(c2(:)));          
    figure, imagesc(cat(3,  normalisera(unpadmatrix(shift2d(midapi, [x(xp,yp), y(xp,yp)]), up)),  ...
        normalisera(unpadmatrix(mitmr, up)), ...
        0*unpadmatrix(mitmr, up)));
    axis image
    title('Corrected')
    figure, imagesc(cat(3,normalisera(unpadmatrix(shift2d(midapi, [0,0]), up)),  ...
        normalisera(unpadmatrix(mitmr, up)), ...
        0*unpadmatrix(mitmr, up)));
    axis image
    title('Original')
    
end