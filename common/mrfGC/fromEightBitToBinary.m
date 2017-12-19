% load vol (that is created with toEightBit.m
%clear all 
%close all

eval(['load ' pth 'vol8bit.mat']);
whos

class1.variance=50;
class2.variance=35;

class1
class2

beta=1

cube=100; % Size of cube at each step.
ol=2; % Pixel overlap

seg=uint8(zeros(size(vol)));

disp(['Cube size is: ' num2str(cube) ', beta=' num2str(beta)]);
disp(['Using overlap of ' num2str(ol) ' pizels']);
disp('Ready to binarize, will save to segmented.mat');
if ~(force==1)
  pause
end

tic
h=waitbar(0, 'Binarizing');



for i=-ol:cube-2*ol:size(vol,1)+ol  
  for j=-ol:cube-2*ol:size(vol,2)+ol
    for k=-ol:cube-2*ol:size(vol,3)+ol

%      ystart=(i-1)*cube+1; yend=min(size(seg,1), cube*i+1);
%      xstart=(j-1)*cube+1; xend=min(size(seg,2), cube*j+1);
%      zstart=(j-1)*cube+1; zend=min(size(seg,3), cube*k+1); 
      
      ystart=max(1,i); yend=min(size(seg,1), i+cube);
      xstart=max(1,j); xend=min(size(seg,2), j+cube);
      zstart=max(1,k); zend=min(size(seg,3), k+cube);
      
      waitbar(i / size(vol,1),h);
      
      disp(num2str(i));
      if(exist('block')) 
        clear block;
      end
      
block=      mrfGC(vol(ystart:yend, xstart:xend,zstart:zend), [class1.mean,class1.variance], [class2.mean,class2.variance], beta);
      seg(ystart+ol:yend-ol , xstart+ol:xend-ol , zstart+ol:zend-ol) = block(1+ol:end-ol,1+ol:end-ol,1+ol:end-ol);

    end
  end  
end


close(h);
toc

seg=seg(ol+1:end-ol, ol+1:end-ol, ol+1:end-ol);

eval(['save ' pth 'segmented.mat seg']);
