% Needed: an objective way to evaluate the mappings. 
% Eyes are attracted to the largest deviations.

% Look at smaller regions first to see that it works. Might happen that
% really high order corrections only do the work.

close all

if 0
V1 = df_readTif('/Users/erikw/data/iJC60_071015_003/a594_quim_001.tif');
S1 = max(V1,[],3);
D = dotCandidates(V1);

V2 = df_readTif('/Users/erikw/data/iJC60_071015_003/cy5_quim_001.tif');
S2 = max(V2,[],3);

V3 = df_readTif('/Users/erikw/data/iJC60_071015_003/tmr_quim_001.tif');
S3 = max(V3,[],3);
channels = {'a594_quim', 'cy5_quim', 'tmr_quim'};
corrFile = 'cc_20151019.mat';
mul = [1,1,1];
end

if 0
    %% MIT data, 111212
    % Works when a594 is reference channel since that is between the
    % extremes. 
    
    V1 = df_readTif('/Users/erikw/Desktop/111212/beads/a594_001.tif');
    S1 = max(V1,[],3);
    D = dotCandidates(V1);

    V2 = df_readTif('/Users/erikw/Desktop/111212/beads/cy5_001.tif');
    S2 = max(V2,[],3);

    V3 = df_readTif('/Users/erikw/Desktop/111212/beads/dapi_001.tif');
    S3 = max(V3,[],3);
    
    channels = {'a594', 'cy5', 'dapi'};
    corrFile = 'cc_111212.mat';
    
    prefix = '111212';
    mul = [3.5,1,3.5]; % multipliers for the channels when visualizing
end

if 0
    %% MIT data, 200912
    % Works when a594 is reference channel since that is between the
    % extremes. 
    
    V1 = df_readTif('/Users/erikw/Desktop/200912/200912_beads/a594_001.tif');
    S1 = max(V1,[],3);
    D = dotCandidates(V1);

    V2 = df_readTif('/Users/erikw/Desktop/200912/200912_beads/cy5_001.tif');
    S2 = max(V2,[],3);

    V3 = df_readTif('/Users/erikw/Desktop/200912/200912_beads/dapi_001.tif');
    S3 = max(V3,[],3);
    
    channels = {'a594', 'cy5', 'dapi'};
    corrFile = 'cc_200912.mat';
    
    prefix = '200912';
    mul = [1,1,1]; % multipliers for the channels when visualizing
end

if 1
     V1 = df_readTif('/data/current_images/iJC154_091215_004/a594_001.tif');
    S1 = max(V1,[],3);
    D = dotCandidates(V1);

    V2 = df_readTif('/data/current_images/iJC154_091215_004/cy5_001.tif');
    S2 = max(V2,[],3);

    V3 = df_readTif('/data/current_images/iJC154_091215_004/tmr_001.tif');
    S3 = max(V3,[],3);
    
    channels = {'a594', 'cy5', 'tmr'};
    corrFile = 'cc_20151216.mat';
    
    prefix = '20151216';
    mul = [1,1,1.5]; % multipliers for the channels when visualizing
    
end
RGB = cat(3, mul(1)*normalisera(S1), mul(2)*normalisera(S2), mul(3)*normalisera(S3));
figure, imshow(RGB)
title('Original')

pause
%% Now, correction

%C1 = cCorrI(S1, 'a594_quim', 'cy5_quim', 'cc_20151019.mat');
C1 = cCorrI(S1, channels{1},  channels{2}, corrFile);
C2 = cCorrI(S2, channels{2},  channels{2}, corrFile);
C3 = cCorrI(S3, channels{3},  channels{2}, corrFile);
%C3 = cCorrI(S3, 'cy5_quim', 'a594_quim', 'cc_20151019.mat');
%C3 = 0*C1;

%C1 = C1-min(C1(:)); C1 =C1/max(C1(:));
%C2 = C2-min(C2(:)); C2 =C2/max(C2(:));
%C3 = C3-min(C3(:)); C3 =C3/max(C3(:));

cRGB = cat(3, mul(1)*normalisera(C1), mul(2)*normalisera(C2), mul(3)*normalisera(C3));
%cRGB = cRGB-min(cRGB(:)); 
figure, 
imshow(cRGB)
hold on
%plot(D(1:200,2), D(1:200,1), 'ro')
%D1 = cCorrI(D(:,1:3), 'a594_quim', 'cy5_quim', 'cc_20151019.mat');
hold on
%plot(D1(1:200,2), D1(1:200,1), 'go')
title('Corrected')

imwrite(RGB, [prefix '_ref.png']);
imwrite(cRGB, [prefix '_corr.png']);