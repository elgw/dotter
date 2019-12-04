function msRegistrationShow(msFile)
%% function msRegistrationShow(msFile)
% Visualize the result of an image registration



t = load(msFile);
s = t.s;

s

%% Load target image

T = imread(s.targetImage);

T = double(T);
if s.scaling ~= 1
    T = imresize(T, s.scaling);
end

if s.invertTarget 
    disp('Inverting target image')
    T = max(T(:)) - T;
end

close all

targetFig = figure(1);
targetFig.Name = 'Target';
imagesc(T)
axis image
hold on
colormap gray

p = [];

for kk = 1:numel(s.subImages);    
    subImage = s.subImages{kk};    
    fprintf('%d/%d : %s\n', kk, numel(s.subImages),  subImage);
    
    try
        S = df_readTif(subImage);
    catch e
        disp('Could not read with df_readTif, trying imread');
        S = imread(subImage);
    end
            
    
    S = double(S);
    S = sum(S,3);
    
    S = imresize(S, s.scaling*s.targetResolution/s.subimageResolution);
    
    if s.flipVert
        S = flipud(S);
    end
    
    
    subimageFig = figure(2);
    subimageFig.Name = sprintf('Sub image %d, nxc: %02f\n', kk, s.match{kk}(3));
    clf
    imagesc(S)    
    colormap(gray);
    axis image
    
    if numel(p)>0
        delete(p)
    end
    
    figure(1)
    bx = s.match{kk}(1);
    by = s.match{kk}(2);
    
    width = size(S, 1);
    height = size(S, 2);
    bx = [bx, bx, bx+height, bx+height, bx];
    by = [by+width, by, by, by+width, by+width];
    
    p = plot(bx, by, 'r');
    
    disp('Press enter to show next');
    pause
    
    
end

end