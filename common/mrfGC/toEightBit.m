% Choose window size
disp('Choosing window size...')

num=1;
im=[f.base sprintf('%04d',num) f.end];
I=imread(im);


if (manual==1)
figure(1)
imagesc(I);
colormap(gray)

disp('Select two points and then <ENTER> to choose what area');
[x y]=getpts(1);

if ~(numel(x) == 2)
  x(1)=1; 
  y(1)=1;
  x(2)=size(I,2);
  y(2)=size(I,1);
end


wx=round(x);
wy=round(y);

else

  p=(1-1/sqrt(2))*size(I,1)/2;
  q=(1-1/sqrt(2))*size(I,2)/2;
  
  wy=round([p size(I,1)-p]);
  wx=round([q size(I,2)-q]);
  
end

disp(['Image size is:' num2str(size(I))]);
disp(['Window size is:' num2str(wy(1)) ':' num2str(wy(2)) 'x' num2str(wx(1)) ':' num2str(wx(2))]);

I=I(wy(1):wy(2), wx(1):wx(2));

% Choose how to convert to 8 bit - or work with 16 bit?
disp('Setting cut offs for the binarization...');
if(manual==1)
figure(1)
h=subplot(1,2,1);
hist(double(I(:)),1000);

subplot(1,2,2)
imagesc(I);
axis image
colormap(gray)

[x y]=getpts(h);
mini=x(1); maxi=x(2);

else
  % Assuming more matrix than fibre material.
  mini=percentile(dip_image(I),20); 
  maxi=percentile(dip_image(I),97);
end

figure(1)

I=double(I);
I=256*(I-mini)/(maxi-mini);
I=uint8(I);
h=subplot(1,2,1)
hist(double(I(:)),256);
title('Histogram');
subplot(1,2,2);
imagesc(double(I));
colormap(gray)
axis image
title('Result for one slice of the suggested 8-bitization');

disp(['Using the interval ' num2str(mini) ' to ' num2str(maxi) ' in the original 16-bit data']);


disp('Estimating distributions, i.e. means and variances')
if(manual==1)
  [a b]=getpts(h)
  
  class1.mean=a(1)
  class2.mean=a(2)
else
  hg=histo8(I);
  hg(1)=0;
  hg(end)=0;
  
  % The intensity value at the largest peak
  class1.mean=find(hg==max(hg)); class1.mean=class1.mean(1);
  class2.mean=percentile(dip_image(I),95)
%  class2.mean=class1.mean+0.90*(256-class1.mean);
end


disp('Summary:')
disp(['Using intensities in original image from ' num2str(mini) ' to ' num2str(maxi)])
disp(['Window: X: ' num2str(wx(1)) '--' num2str(wx(2)) ', Y: '  num2str(wy(1)) '--' num2str(wy(2)) ])


disp(['First image: ' f.base sprintf('%04d',first) f.end]);

disp(['Last image: ' f.base sprintf('%04d',last) f.end]);

disp(['class1.mean: ' num2str(class1.mean) ' class2.mean: ' num2str(class2.mean)]);

disp('Ready to convert to 8-bit. Will save to vol8bit.mat');

if ~(force==1)
  pause
end

vol=uint8(zeros([size(I) (last-first+1)]));

for i=first:last
  filename=[f.base sprintf('%04d',i) f.end];
  disp(['Reading: ' filename]);
  I=imread(filename);
  I=I(wy(1):wy(2), wx(1):wx(2));
  I=double(I);
  I=256*(I-mini)/(maxi-mini);
  I=uint8(I);  
  vol(:,:,i)=I;
end




eval(['save ' pth 'vol8bit.mat vol class1 class2']);


