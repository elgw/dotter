function df_mlfit1_ut()
disp('--> Testing df_mlfit1')
%{
cd /home/erikw/code/dotter_matlab/common/mex
mex df_mlfit1.c CFLAGS='$CFLAGS -std=c99 ' COPTIMFLAGS='-DNDEBUG -O3 -D verbose=0' LINKLIBS='$LINKLIBS -lgsl -lgslcblas'
%}

disp('  no input')
error = false;
try
    df_mlfit1();
catch e
    %disp('  the expected error generated for no input')
    error = true;
end
assert(error)

disp('  wrong input type')
error = false;
try
    df_mlfit1(double(1));
catch e
    %disp('expected error generated for wrong type of input')
    error = true;
end
assert(error)

disp('  Correct localization');
P = [8,8,8];
V = df_blit3(zeros(15,15,15), [], [P , 1, 1, 1, 1]');
F = df_mlfit1(V, P');
assert(eudist(P, F')<1e-3);

F = df_mlfit1(V+1000, P');
assert(eudist(P, F')<1e-3);

disp('  right size of output')


disp('  timing in a realistic case')
nD = 5000;
V = zeros(1024,1024,60);
D0 = round([(size(V,1)-6)*rand(nD,1), (size(V,2)-6)*rand(nD,1), size(V,3)*rand(nD,1)]);
D0(D0<7) = 7;
D = round(D0);
T = 0*V;
T(sub2ind(size(V),D(:,1), D(:,2), D(:,3))) = 1;
T = gsmooth(T, 1.6);
V = poissrnd(100000*T);
tic
F = df_mlfit1(V, D'); F = F';
tval = toc;
fprintf('  --> df_mlfit1 took %.3f s for a %dx%dx%d image and %d dots\n', tval, size(V,1), size(V,2), size(V,3), size(D,1));

if 0
    % About 30x faster, no z-fitting or clustering
    tic
    dotFitting(V,D);
    tval2 = toc;
end

if 0
    % This test might not be a fair comparison between ML and COM since COM
    % favors the distince positions of the grid.
    C3 = df_com3(V, D'); C3 = C3';
    %C4 = dotFitting(V, D);
    figure
    imagesc(sum(V,3)); colormap gray; axis image; hold on
    plot(D(:,2), D(:,1), 'rs');
    plot(F(:,2), F(:,1), 'gx');
    plot(C3(:,2), C3(:,1), 'b.');
    legend({'Inital positions', 'Fitted-ML', 'Fitted-COM'})
    figure, subplot(1,2,1)
    eml = eudist(D(:,1:2), F(:,1:2));
    %eml_old = eudist(D(:,1:2), C4(:,1:2));
    %fprintf('mean(eml_old): %f\n', mean(eml_old));
    histogram(eml)
    a = axis; a(1) = 0; a(2) = 1;
    axis(a)
    title('ML')
    subplot(1,2,2)
    ecom = eudist(D(:,1:2), C3(:,1:2));
    histogram(ecom)
    a = axis; a(1) = 0; a(2) = 1;
    axis(a)
    title('COM')
    fprintf('Means errors: ML: %.3f COM: %.3f\n', mean(eml), mean(ecom));
    figure, scatter(eml, ecom), xlabel('E ML'), ylabel('E COM'), axis equal, grid on
    title('Errors are correlated')
end

disp('  -- done');
end