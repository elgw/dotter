disp('--> Testing df_mlfit1sn')
if(0)
cd /home/erikw/code/dotter_matlab/common/mex
mex df_mlfit1sn.c CFLAGS='$CFLAGS -std=c99 ' COPTIMFLAGS='-DNDEBUG -O3 -D verbose=2' LINKLIBS='$LINKLIBS -lgsl -lgslcblas' mlfit.o
end

% Not working with sub pixel locations.
% Crashing for locations close to the edge.

% also tested in df_blit3_ut.m

% Status values
%               -3  /* Too close to the boundary */
% GSL_SUCCESS  = 0, 
% GSL_FAILURE  = -1,
% GSL_CONTINUE = -2, /* iteration has not converged */
%

disp('  no input')
error = false;
try
    df_mlfit1sn();
catch e
    %disp('  the expected error generated for no input')
    error = true;
end
assert(error)

disp('  wrong input type')
error = false;
try
    df_mlfit1sn(double(1));
catch e
    %disp('expected error generated for wrong type of input')
    error = true;
end
assert(error)

disp('  Correct sigma');
P = [6.51,7,7];
sigma0 = 1.3;
bg = 1000;
V = bg+df_blit3(0*ones(13,13,13), [], [P , 10000, sigma0*ones(1,3)]');
nphot0 = sum(sum(V(:,:,7)-bg));
F = df_mlfit1sn(V, P');
sigma = F(1); nphot = F(2);
fprintf('Input: s: %f n: %f\n', sigma0, nphot0);
fprintf('Out  : s: %f n: %f\n', sigma, nphot);

assert((sigma0-F(1))<1e-2);

disp('  timing in a realistic case')
nD = 1000;
V = 1000+zeros(1024,1024,60);
D0 = [(size(V,1)-6)*rand(nD,1), (size(V,2)-6)*rand(nD,1), size(V,3)*rand(nD,1)];
D0 = round(D0);
D0(D0<10) = 10;
D0 = [D0, 7000+3000*rand(size(D0,1),1), repmat((1.2+1*rand(size(D0,1),1)), 1, 3)];
V = df_blit3(V, [], D0');

tic
F = df_mlfit1sn(V, D0(:,[1,2,3])'); 
F = F';
tval = toc;
fprintf('  --> df_mlfit1sn took %.3f s for a %dx%dx%d image and %d dots\n', tval, size(V,1), size(V,2), size(V,3), size(D0,1));

% Only counts in the plane are given by mlfit1sn, calculate
% a correction factor
t = df_blit3(zeros(13,13,13), [], [7,7,7,1,1,1,1]');
fa = sum(sum(t(:,:,7)));

if 0
figure,
[~, idx] = sort(F(:,1), 'descend');
dotterSlide(V, [D0(idx,1:3), F(idx,1)]);
end

if 0
    figure, 
    subplot(1,2,1)
    scatter(F(:,1), D0(:,5));
    corr2(D0(:,5), F(:,1))
    title('sigma')
    mi = min(D0(:,5)); ma = max(D0(:,5));
    axis([mi,ma,mi,ma]);
    ylabel('simulated'); xlabel('Measured');
    subplot(1,2,2)
    minf = min([F(:,1) ; D0(:,4)]);
    maxf = max([F(:,1) ; D0(:,4)]);
    
    scatter(F(:,2), D0(:,4));
    title('nphot')
    ylabel('simulated'); xlabel('Measured');
    axis([minf,maxf,minf,maxf])
end

disp('  -- done');
