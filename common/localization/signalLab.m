% Try different filters for dot localization
% and especially for relevance ordering

close all
addpath('../df_gaussianInt2')

TG = [];
gsigma = .9:.1:2;
for ll = 1:numel(gsigma)
    tg = 10000*df_gaussianInt2([0,0], gsigma(ll)*[1, 1], 11);
    tg = [tg; 10000*df_gaussianInt2([.5,.5], gsigma(ll)*[1, 1], 11)];
    TG = [TG, tg];
end

figure
subplot(4,1,1)
imagesc(TG), axis image
subplot(4,1,2)
plot(sum(TG, 1));
ax = axis();
ax(1) = 1; ax(2)=size(TG,2)
axis(ax)

dog1 = gsmooth(TG, .9)-gsmooth(TG, .9+0.01);
dog2 = gsmooth(TG, 1.2)-gsmooth(TG, 1.2+0.01);

subplot(4,1,3)
imagesc(dog2-dog1), axis image

subplot(4,1,4)
imagesc(TG + gsmooth(TG,1)), axis image

PP = [];
for kk = 1:numel(gsigma)
    PP = [PP; [0*23+12, (kk-1)*23+12, 1]];
end

TG2 = 5000+TG; %+50*randn(size(TG,1), size(TG,2));
sigmaerror = gaussianSize(TG2, PP, gsigma);
figure, imagesc(sqrt(sigmaerror))
figure, imshow2((TG2))

% Movie, a dot moves 200 nm, 1 nm per frame

vidObj = VideoWriter('1nm_per_frame.avi', 'Grayscale AVI');
vidObj.FrameRate = 20;
open(vidObj);

fig = figure
img = imagesc()

clear M
axis image
axis off
colormap(gray)

theta = linspace(-pi,pi, 1258);
xpos = cos(theta);
ypos = sin(theta);
d = ((xpos(2)-xpos(1)).^2+(ypos(2)-ypos(1)).^2).^(1/2);

for kk=1:numel(xpos)
    gint = df_gaussianInt2([ypos(kk),xpos(kk)], [1.2, 1.2], 11);
    set(img, 'CData', gint);
    %drawnow()
    currFrame = getframe;
    currFrame.cdata = currFrame.cdata(:,:,1);
    writeVideo(vidObj,currFrame);
end
close(vidObj);

