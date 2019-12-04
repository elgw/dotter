function df_blit3_ut()
%% W = df_blit3(V, K, P)
%
% Compilation:
%mex df_blit3.c CFLAGS='$CFLAGS -std=c99 -Wall -g' COPTIMFLAGS='-DNDEBUG -O3 -D verbose=1' ...
%       LINKLIBS='$LINKLIBS -lgsl -lgslcblas'
%   mex df_blit3.c CFLAGS='$CFLAGS -std=c99 -Wall' COPTIMFLAGS='-DNDEBUG -O3 -D verbose=0' ...
%       LINKLIBS='$LINKLIBS -lgsl -lgslcblas'
% blit3 paints or blits to a volumetric image.
% An image to blit with can be given as the second argument. If K==[]
% a gaussian image image will be drawn.
%
% P is either a 3xN list of N dots or a 7xN list where the rows are:
% x,y,y location,
% the number of photons
% sigmax, sigmay, sigmaz: sigma of the gaussian
%
% For given K, the positions in P are rounded to nearest int
% Gaussians are placed with sub pixel precision
%

disp('--> Testing df_blit3')

disp('  Handles zero input')
error = 0;
try
    df_blit3()
catch e
    error = 1;
end
assert(error==1);

disp('  Is able to draw to the whole volume')
V = zeros(101,101,101);
K = ones(size(V));
W = df_blit3(V, padarray(K, [2,2,2]), [51,51,51]');
assert(sum(W(:) == K(:)) == numel(W));

disp('  Blits at the right positions')
V = zeros(10,10,10);
for mm=1:10    
    for nn = 1:10
        for pp = 1:10
            V = 0*V;
            W = df_blit3(V, padarray(1, [2,2,2]), [mm,nn,pp]');
            assert(W(mm, nn, pp)==1);
        end
    end
end

disp('  Shifts correctly')
K = zeros(7,7,7);
K(4,4,4) = 1;
V = zeros(11,11,11);
delta = [0.1, .0, .0];
V2 = V; V2(6,6,6) = 1;
V2 = df_imshift(V2, delta, 'Cubic');
V3 = df_blit3(V, padarray(K,[1,1,1]), ([6, 6, 6]+delta)');
assert(sum(abs(V2(:)-V3(:))>10e-9) == 0)

disp('  Is additive')
V = ones(10,10,10);
W = df_blit3(V, 1, [4,4,4]');
assert(W(4,4,4)==2);

disp('  Correct number of photons with Gaussian kernel -- in volume')
V1 = df_blit3(zeros(11,11,11), [], [6,6,6, 1, 1,1,1]', 0);
assert(abs(sum(V1(:)) - 1)<1e-6);
disp('  Correct number of photons with Gaussian kernel -- in plane')
V2 = df_blit3(zeros(11,11,11), [], [6,6,6, 1, 1,1,1]', 1);
assert(abs(sum(sum(V2(:,:,6))) - 1)<1e-6);
disp('  Correct number of photons with Gaussian kernel -- in dot')
V3 = df_blit3(zeros(11,11,11), [], [6,6,6, 1, 1,1,1]', 2);
assert(abs(sum(V3(6,6,6)) - 1)<1e-6);

       
disp('  Timings for a realistic case');
N = 10000;
V = zeros(1024,1024,60);
P = [size(V,1)*rand(N, 1), size(V,2)*rand(N, 1), size(V,3)*rand(N, 1)];
P = P';
%P = int64(P');

K = df_gaussianInt2([0,0], [1.5,1.5], 5);
K = repmat(K, 1, 1, 11);

tic
W= df_blit3(V, K, P);
t = toc;

fprintf('  -> Took %.1f sec for an image of size %dx%dx%d and %d locations\n',...
    t, size(V,1), size(V,2), size(V,3), N);
fprintf('     Kernel size was: %dx%dx%d\n', size(K,1), size(K,2), size(K,3));

if 0
    figure, imagesc(sum(W,3)), axis image, colormap gray
end


disp('  Timings for a realistic case: Sub pixel shifted gaussians.');
  
N = 1000;
V = zeros(512,512,60);
% P: x, y, z, #photons, sigmax, sigmay, sigmaz
P = [size(V,1)*rand(N, 1), size(V,2)*rand(N, 1), size(V,3)*rand(N, 1), 10000*ones(N,1) , 1.6*ones(N,1), 1.6*ones(N,1), 2*ones(N,1)];
P = P';

K = [];

tic
W= df_blit3(V, K, P);
t = toc;
fprintf('     w. gaussianInt3\n');
fprintf('  -> Took %.1f sec for an image of size %dx%dx%d and %d locations\n',...
    t, size(V,1), size(V,2), size(V,3), N);


K = padarray(df_gaussianInt3([0,0,0], [1.1, 1.1, 1.1], 3), [2,2,2]);

tic
W2= df_blit3(V, K, P(1:3,:));
t = toc;
fprintf('     w. imshift\n');
fprintf('  -> Took %.1f sec for an image of size %dx%dx%d and %d locations\n',...
    t, size(V,1), size(V,2), size(V,3), N);

% volumeSlideRGB(W, 10000*W2, 0*W)

if 0
    figure, imagesc(sum(W,3)), axis image, colormap gray
end

if 0
    vidObj = VideoWriter('ml_vs_com.avi', 'Grayscale AVI');
    vidObj.FrameRate = 20;
    open(vidObj);


    % This should look smooth
   s = linspace(0,2*pi, 200);
   r = 2;
   x = 7+r*cos(s);
   y = 7+r*sin(s);
   E = []; S = [];
   
   figure
   im = imagesc(zeros(13,13));
    colormap gray, axis image
    hold on
    pref = plot(0,0,'go');
    pml = plot(0,0,'bs');
    p = plot(0,0,'rx');         
    legend({'ref', 'ml', 'com'})
    G = df_gaussianInt3([0,0,0], [1.1, 1.1, 1.1], 1);
    G = padarray(G, [2,2,2]);
   for kk = 1:numel(s)
       % Integrate gaussian
       V = 1000+1000*df_blit3(zeros(13,13,13), [], [x(kk), y(kk), 7, 1, 1, 1, 1]');
       % To see how it looks when a gaussian is shifted:
       %V = df_blit3(zeros(13,13,13),  G, [x(kk), y(kk), 7, 1, 1, 1, 1]');
       
       Dml = df_mlfit1(V, [x(kk), y(kk), 7]');
       D = df_com3(V, [x(kk), y(kk), 7]');
       sn = df_mlfit1sn(V, [x(kk), y(kk), 7]');
       
       pref.YData = x(kk); pref.XData = y(kk);
          p.YData = D(1);     p.XData = D(2);
        pml.YData = Dml(1); pml.XData = Dml(2);
       im.CData = V(:,:,7);
       drawnow
       
       E(kk,1) = eudist([x(kk), y(kk)], [D(1), D(2)]);
       E(kk,2) = eudist([x(kk), y(kk)], [Dml(1), Dml(2)]);
       S(kk) = sn(1);
        currFrame = getframe;
    currFrame.cdata = currFrame.cdata(:,:,1);
    writeVideo(vidObj,currFrame);
   end
   
   close(vidObj);
    
   figure,
   subplot(1,2,1)
   
   plot(s, E(:,1)*120, 'r');
   hold on
   plot(s, E(:,2)*120, 'k');
   title('Theoretical localization')
   legend({'COM', 'ML'});
   ylabel('Error [nm]');
   xlabel('Position')
   axis equal
   
   subplot(1,2,2)
   plot(S)
   title('Estimated sigma')
    
end


disp('  -- done')
end