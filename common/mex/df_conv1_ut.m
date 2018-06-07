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
cd ~/code/dotter_matlab/common/mex/
mex  conv1.c CFLAGS='$CFLAGS -g -std=c99 -march=native `pkg-config gsl --cflags --libs`' COPTIMFLAGS=' -O3 -D verbose=0' ...
    LINKLIBS='$LINKLIBS -lgsl -lgslcblas -lpthread' -c
mex  df_conv1.c CFLAGS='$CFLAGS -g -std=c99 -march=native `pkg-config gsl --cflags --libs`' COPTIMFLAGS=' -O3 -D verbose=0' ...
    LINKLIBS='$LINKLIBS -lgsl -lgslcblas' conv1.o
end

disp('--> too small kernel');
gotError = 0;
try
    df_conv1(ones(3,3,3), 1:3,1:3,1:3)
catch e
    gotError = 1;
end
assert(gotError ==1);

disp('--> timings');
% some timings of matlab

M = 1024; N = 1024; P = 31;
nK = 11;
fprintf('     Image: [%d, %d, %d], x,y,z-kernels: [%d]\n', M, N, P, nK);
V = rand(M, N, P);
V(50,50,30) = 1;
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
W2 = df_conv1(V,K1,[],[]);
tdx = toc;
tic
W2 = df_conv1(W2,[],K2,[]);
tdy = toc;
tic
W2 = df_conv1(W2,[],[],K3);
tdz = toc;

td = tdx+tdy+tdz;

% Convolve/Shift approach
tic
W2 = df_conv1(V,K1,[],[]);
W2 = shiftdim(W2);
W2 = df_conv1(W2,K2,[],[]);
W2 = shiftdim(W2);
W2 = df_conv1(W2,K3,[],[]);
W2 = shiftdim(W2);
tdsz = toc;

tic
W2 = df_conv1(V,K1,K2,K3);
tdxyz = toc;

fprintf('Matlab: (%.2f, %.2f, %.2f) %.2f s, \nDOTTER: (%.2f, %.2f, %.2f) %.2f s (%.1f s using one call)\n', ...
    tmx, tmy, tmz, tm, ...
    tdx, tdy, tdz, td, tdxyz);

fprintf('DOTTER/shiftdim: %.2f\n', tdsz);

if doPlot
    figure, imagesc([W(:,:,30) W2(:,:,30); W(:,:,31) W2(:,:,31)])
end

disp('--> all kernels used');
K1 = 2*ones(3,1);
K2 = 3*ones(3,1);
K3 = 5*ones(3,1);
T = zeros(21,21,21);
T(11,11,11) = 1;
T2 = df_conv1(T, K1, K2, K3);


disp('--> Verifying correctness')
t = rand(101,102,103);
k = rand(7,1);
disp('-->x');
t1 = convn(t, reshape(k,[7,1,1]),'same');
t2 = df_conv1(t, flipud(k), [], []);
assert(sum(t1(:) - t2(:))<10e-9);
disp('-->y');
t1 = convn(t, reshape(k,[1,7,1]),'same');
t2 = df_conv1(t, [], flipud(k), []);
assert(sum(t1(:) - t2(:))<10e-9);
disp('-->z');
t1 = convn(t, reshape(k,[7,1,1]),'same');
t2 = df_conv1(t, [], [], flipud(k));
assert(sum(t1(:) - t2(:))<10e-9);

end