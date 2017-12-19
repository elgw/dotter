%Depends on dip image for: 
%  percentile


% Settings
manual=0;
verbose=0;
force=1; % Do not pause


% File names and numbers
dsk='1';

vlms={'K11002_','K11003_', 'K14002_','T11002_','T13004_','T31005_','K11004_','T11003_','T1400101_','T33001_','K13001_','T11004_','T14002_','T33002_','K13002_','T1100101_','T13001_','T14003_','T33003_','K11001_','K13003_','T1100102_','T13002_','T31001_','T3400101_','K11002_','K1400101_','T1100103_','T13003_','T31004_','T34002_'};

%vlms=vlms(12:end)

for vlm=vlms
    
pth=['/data/fiber/WoodWisdom/SLS_FEB09/disk' dsk '/' cell2mat(vlm) '/rec_16bit_cbazp/'];
f.base=[pth cell2mat(vlm)];

f.end='.rec.16bit.tif';
first=1; % Number of first file.
last=1024; % Number of last file.

  figure(4)
  subplot(1,1,1)
  title(pth);
  
  figure(1)


% Do conversion to 8 bit
toEightBit
% And binarize
fromEightBitToBinary % Markov random field

% Inspect the binarization

%vtkIso(seg)
figure(1)
subplot(1,1,1);

imagesc(vol(ol+1:end-ol,ol+1:end-ol,14));
colormap(gray)
title('Slice 14 of the 8bit version');
figure(2)
subplot(1,1,1);
imagesc(seg(:,:,14-ol));
colormap(gray);
title('Slice 14 of the segmentation');

clear vol
clear seg

end
