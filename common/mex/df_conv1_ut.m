function df_conv1_ut()
%% df_conv1(V, K, dimension)
% Convolve V, 1D, 2D or 3D by K (1D)

disp('--> Testing df_conv1');

if ~exist('doCompile', 'var')
    doCompile = 0;
end

if ~exist('doPlot', 'var')
    doPlot = 0;
end

if doCompile
    cd ~/code/dotter/common/mex/
    
    mex df_conv1.c conv1.c CFLAGS='$CFLAGS -O3 -std=c99 -march=native -flto -Dverbose=0' ...
        COPTIMFLAGS='$COPTIMFLAGS -O3 -flto' 
        
end

disp('--> too small kernel');
gotError = 0;
try
    df_conv1(ones(3,3,3), 1:3,1:3,1:3)
catch e
    gotError = 1;
end
assert(gotError ==1);

%details_x()
%details_z()

disp('--> all kernels used');
K1 = 2*ones(3,1);
K2 = 3*ones(3,1);
K3 = 5*ones(3,1);
T = zeros(21,21,21);
T(11,11,11) = 1;
T2 = df_conv1(T, K1, K2, K3);
assert(T2(11,11,11) == 2*3*5);
assert(sum(abs(T2(:))) == 2*3*5*27);



disp('--> Verifying correctness')
t = rand(101,102,103);
k = rand(7,1);

fprintf('z... ');
t1 = convn(t, reshape(k,[1,1,7]),'same');
t2 = df_conv1(t, [], [], flipud(k));
diff = max(abs(t1(:) - t2(:)));
assert(diff<10e-8)


fprintf('y... ');
t1 = convn(t, reshape(k,[1,7,1]),'same');
t2 = df_conv1(t, [], flipud(k), []);
diff = max(abs(t1(:) - t2(:)));
assert(diff<10e-8);

fprintf('x... ');
t1 = convn(t, reshape(k,[7,1,1]),'same');
t2 = df_conv1(t, flipud(k), [], []);

assert(max(abs(t1(:) - t2(:)))<10e-9);
fprintf('\n');

verify_xyz(356, 354, 31, 11);

if 0
disp('--> timings');
% some timings of matlab

timing_typical_image_size(356, 356, 31, 11);
timing_typical_image_size(512, 512, 31, 11);
timing_typical_image_size(1024, 1024, 31, 11);
timing_typical_image_size(2*1024, 2*1024, 31, 11);
time_vs_size()
end

end

function time_vs_size()
NS = 100:50:550;
for kk = 1:numel(NS)
    N = NS(kk);
    V = rand(N,N,31);
    K1 = rand(11,1);
    clear W
    tic
    W = convn(V,reshape(K1, [11,1,1]), 'same');
    t_mat(kk) = toc;
    clear W
    tic
    W = df_conv1(V,fliplr(K1),[],[]);
    t_df(kk) = toc;
end
figure,
plot(NS, t_df)
hold on
plot(NS, t_mat)
legend({'df', 'matlab'}, 'location', 'nw');
end
        
function details_x()

V = rand(1024,3,3)/11;
K = ones(7,1);
V(512,2,2) = 1;
C = df_conv1(V, K, [], []);
C2 = convn(V, K, 'same');
figure,
plot(2+squeeze(V(:,2,2)), 'r--')
hold on
c1 = C(:,2,2);
plot(1+c1, 'b:', 'lineWidth', 2)
hold on
c2 = squeeze(C2(:,2,2));
plot(c2, 'k')
legend({'V', 'df', 'mat'})
axis([512-10,512+10,0,3])

figure,
plot(c1-c2)
hold on
plot(c1)
plot(c2)
legend({'diff', 'df', 'matlab'})
assert(1==0)

end

function details_z()

V = .1*rand(3,3,1024)/11;
K = ones(7,1);
V(2,2, 512) = 1;
V(2,2, 495) = 1;
C = df_conv1(V, [], [], K);
C2 = convn(V, reshape(K, [1,1,numel(K)]), 'same');
figure,
subplot(2,1,1)
v = squeeze(V(2,2, :));
plot(2+squeeze(v), 'r--')
hold on
c1 = squeeze(C(2,2,:));
plot(1+c1, 'b:', 'lineWidth', 2)
hold on
c2 = squeeze(C2(2,2, :))
plot(c2, 'k')
legend({'V', 'df', 'mat'})
%axis([512-10,512+10,0,3])

subplot(2,1,2)
plot(c1-c2)
hold on
plot(c1)
plot(c2+0.01)
legend({'diff', 'df', 'matlab'})
title(sprintf('Details Z, max abs diff: %f', max(abs(c1-c2))))
assert(1==0)

end
    


function timing_typical_image_size(M, N, P, nK)
doPlot = 0;
nK = 11;
fprintf('Image: [%d, %d, %d], x,y,z-kernels: [%d]\n', M, N, P, nK);
V = rand(M, N, P);
K = fspecial('gaussian', [nK,1], 1);

K1 = linspace(1,2,11);
K2 = linspace(1,2,11);
K3 = linspace(1,2,11);

tic
W = convn(V,reshape(K1, [11,1,1]), 'same');
tmx = toc;

tic
W = convn(W,reshape(K2, [1,11,1]), 'same');
tmy = toc;

tic
W = convn(W,reshape(K3, [1,1,11]), 'same');
tmz = toc;

tm = tmx + tmy + tmz;


tic
W2 = df_conv1(V,fliplr(K1),[],[]);
tdx = toc;
tic
W2 = df_conv1(W2,[],fliplr(K2),[]);
tdy = toc;
tic
W2 = df_conv1(W2,[],[],fliplr(K3));
tdz = toc;

td = tdx+tdy+tdz;

diff = max(abs(W(:)-W2(:)));

% Convolve/Shift approach
clear W2
tic
W2 = df_conv1(V,K1,[],[]);
W2 = shiftdim(W2);
W2 = df_conv1(W2,K2,[],[]);
W2 = shiftdim(W2);
W2 = df_conv1(W2,K3,[],[]);
W2 = shiftdim(W2);
tdsz = toc;

clear W2
tic
W2 = df_conv1(V,K1,K2,K3);
tdxyz = toc;

fprintf('Matlab: (%.2f, %.2f, %.2f) %.2f s\n', ...
    tmx, tmy, tmz, tm);
fprintf('DOTTER: (%.2f, %.2f, %.2f) %.2f s (%.2f s using one call)\n', ...
    tdx, tdy, tdz, td, tdxyz);
fprintf('DOTTER/shiftdim: %.2f\n', tdsz);
assert(diff<1e-5);

if doPlot
    figure, imagesc([W(:,:,30) W2(:,:,30); W(:,:,31) W2(:,:,31)])
end
end

function verify_xyz(M, N, P, nK)
doPlot = 0;
nK = 11;
fprintf('Image: [%d, %d, %d], x,y,z-kernels: [%d]\n', M, N, P, nK);
V = rand(M, N, P);
K = fspecial('gaussian', [nK,1], 1);

K1 = linspace(1,2,11);
K2 = linspace(1,2,11);
K3 = linspace(1,2,11);

tic
W = convn(V,reshape(K1, [11,1,1]), 'same');
tmx = toc;

tic
W = convn(W,reshape(K2, [1,11,1]), 'same');
tmy = toc;

tic
W = convn(W,reshape(K3, [1,1,11]), 'same');
tmz = toc;

tm = tmx + tmy + tmz;


tic
W2 = df_conv1(V,fliplr(K1),[],[]);
tdx = toc;
tic
W2 = df_conv1(W2,[],fliplr(K2),[]);
tdy = toc;
tic
W2 = df_conv1(W2,[],[],fliplr(K3));
tdz = toc;

td = tdx+tdy+tdz;

diff = max(abs(W(:)-W2(:)));

% Convolve/Shift approach
clear W2
tic
W2 = df_conv1(V,K1,[],[]);
W2 = shiftdim(W2);
W2 = df_conv1(W2,K2,[],[]);
W2 = shiftdim(W2);
W2 = df_conv1(W2,K3,[],[]);
W2 = shiftdim(W2);
tdsz = toc;

clear W2
tic
W2 = df_conv1(V,K1,K2,K3);
tdxyz = toc;

fprintf('Matlab: (%.2f, %.2f, %.2f) %.2f s\n', ...
    tmx, tmy, tmz, tm);
fprintf('DOTTER: (%.2f, %.2f, %.2f) %.2f s (%.2f s using one call)\n', ...
    tdx, tdy, tdz, td, tdxyz);
fprintf('DOTTER/shiftdim: %.2f\n', tdsz);
assert(diff<1e-5);

end