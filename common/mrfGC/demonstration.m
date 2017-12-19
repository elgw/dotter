mex mrfGC.cpp %kompilera
img = imread('testbild.bmp'); %ladda bild
whos


% skala om så att klasserna liknar ct-bildernas
img=64*uint8(img)+105;

% lägg tille ett lutande plan


k=5*sin(linspace(1,30,600));
l=5*sin(linspace(1,30,600))';
img2=uint8(double(img)+l*k);

img3=uint8(double(img2)+5*randn(size(img2))); %lägg till brus


%plot(histo8(img3));

seg=mrfGC(img3,[105 10],[169 10],1); %segmentera

 figure(2) % visa resultat
 subplot(1,3,1)
 imagesc(img)
 
 subplot(1,3,2)
 imagesc(img3)
 
 subplot(1,3,3)
 imagesc(seg);
 
 colormap(gray);
