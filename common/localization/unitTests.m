% Tests for the components involved in the dotFitting

verbose = 0;

testno = 0;


%% LL2PG
% Test that the likelihood is increasing towards perfect match

% 1 Still target
sigma = 1;
side = 5;
bg = 0;
nphot = 1;

patch = df_gaussianInt2([0, 0], [sigma, sigma], side);

X = linspace(5,6);
Y = linspace(5,6);

for kk = 1:numel(X)
    x = X(kk); y = Y(kk);
    ML(kk) = LL2PG(patch, sigma, [x-(side+1),y-(side+1), bg, nphot]);
    if kk>1
       assert(ML(kk)<=ML(kk-1)); % decreasing -likelihood
    end
end
if verbose
plot(ML)
title('test 1')
end
disp('Increasing likelihood as the guess approaches the target')
testno = testno+1;
fprintf('Test %d passed\n', testno);


% Moving target
% Learned: The convergence radius is quite small, less than .5 pixels for
% sigma = 1;
sigma = 1;
side = 5;
bg = 0;
nphot = 1;

X = linspace(5.6,6);
Y = linspace(5.6,6);

for kk = 1:numel(X)
    x = X(kk); y = Y(kk);
    patch = df_gaussianInt2([6-x, 6-y], [sigma, sigma], side);
    ML(kk) = LL2PG(patch, sigma, [0,0, bg, nphot,]);
    if kk>1
       assert(ML(kk)<=ML(kk-1)); % decreasing -likelihood
    end
end
%plot(ML)
disp('Increasing likelihood as the target approaches the guess')
testno = testno+1;
fprintf('Test %d passed\n', testno);

% Background converging
clear ML
BG = linspace(100,0, 10);
for kk = 1:numel(BG)
    bg = BG(kk);
    patch = df_gaussianInt2([6-x, 6-y], [sigma, sigma], side);
    ML(kk) = LL2PG(patch, sigma, [0,0,bg, nphot]);
    if kk>1
       assert(ML(kk)<=ML(kk-1)); % decreasing -likelihood
    end
end
if verbose
figure, plot(ML)
end
bg = 1;
disp('Increasing likelihood as the background approaches the guess')
testno = testno+1;
fprintf('Test %d passed\n', testno);

% Photon count converging
clear ML
NPHOT = linspace(100,1);
for kk = 1:numel(BG)
    nphot = NPHOT(kk);
    patch = df_gaussianInt2([6-x, 6-y], [sigma, sigma], side);
    ML(kk) = LL2PG(patch, sigma, [0,0, bg, nphot]);
    if kk>1
       assert(ML(kk)<=ML(kk-1)); % increasing likelihood
    end
end
if verbose
figure, plot(ML)
end
disp('Increasing likelihood as the number of photons in the signal approaches the model')
testno = testno+1;
fprintf('Test %d passed\n', testno);

% 
[X,Y] = meshgrid(linspace(-.5,.5,11), linspace(-.5,.5,11));
L = 0*X;
side = 5;
sigma = 1;
for kk=1:size(X,1)
    for ll = 1:size(X,2)
        patch = 0+10*df_gaussianInt2([X(kk,ll), Y(kk,ll)], [sigma, sigma], side);
        L(kk,ll) = LL2PG(patch, sigma, [0,0, 0, 10]);
    end
end

if verbose
figure, imagesc(L)
title('test 5. L')
end
assert(L(6,6)==min(L(:)))

disp('Coordinate 0,0 was the most probable');
testno = testno+1;
fprintf('Test %d passed\n', testno);

%% LH2G
side = 5;
x0 = [0,0];
patch = df_gaussianInt2(x0, [sigma, sigma], side);
[x] = LH2G(patch, sigma, 0);
assert(norm(x(1:2)-x0-[side+1,side+1])<0.02)

testno = testno+1;
fprintf('Test %d passed\n', testno);

side = 5;
x0 = [.2,0];
patch = 1+1000*df_gaussianInt2(x0, [sigma, sigma], side);
[x] = LH2G(patch, sigma, 0);
if verbose
figure, imagesc([patch , 1+1000*1*df_gaussianInt2(x(1:2)-[side+1, side+1], sigma, side)])
end
assert(norm(x(1:2)-x0-[side+1,side+1])<0.02)
testno = testno+1;
fprintf('Test %d passed\n', testno);

side = 5;
x0 = [0,-.2];
patch = 1+1000*df_gaussianInt2(x0, [sigma, sigma], side);
[x] = LH2G(patch, sigma, 0);
if verbose
figure, imagesc([patch , 1+1000*1*df_gaussianInt2(x(1:2)-[side+1, side+1], [sigma, sigma], side)])
end
assert(norm(x(1:2)-x0-[side+1,side+1])<0.02)
testno = testno+1;
fprintf('Test %d passed\n', testno);
