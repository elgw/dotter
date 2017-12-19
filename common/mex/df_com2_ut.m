disp('--> Testing df_com2')
% mex CFLAGS='$CFLAGS -std=c99 -Wall' df_com2.c

disp('  Handles zero input')
error = 0;
try
    df_com2()
catch e
    error = 1;
end
assert(error==1);

disp('  Don''t do anything at flat locations')
V = zeros(100,100);
disp('  Flat images')
P = [51,51];
C = df_com2(V, P');
assert(sum(P(:)==C(:)) == numel(P));
C = df_com2(1+V, P');
assert(sum(P(:)==C(:)) == numel(P));

disp('  Locate at the right position')
V = zeros(100,100);
P = [51,52];
V(P(1), P(2))=1;
C = df_com2(V, P');
assert(sum(P(:)==C(:)) == numel(P));

disp('  Shifts in the right directions')
V = zeros(25,25);
P = [10,10];
V(P(1), P(2))=2;
P1 = [11,10];
V(P1(1), P1(2))=2;
C = df_com2(V, P');
assert(C(1)>P(1))
assert(C(1)<P1(1))

disp('  Don''t crash for random input and give reasonable answers')
for kk = 1:10
    V = rand(100,200);
    V = V+min(V(:));
    N = 100;
    P = [size(V,1)*rand(N,1), size(V,2)*rand(N,1)];
    C = df_com2(V, P')';
    d = eudist(P,C);
    assert(max(d(:))<1.5)
end

if 0
    figure,
    histogram(d)
    figure
    plot(C(:,1), C(:,2), 'o')
    hold on
    plot(P(:,1), P(:,2), 'x')
end

disp('  Timings for a realistic case');
V = rand(1024,1024);
N = 100000;
P = [size(V,1)*rand(N,1), size(V,2)*rand(N,1)];
tic
C = df_com2(V, P')';
t = toc;
fprintf('  -> Took %.1f sec for an image of size %dx%dx and %d dots\n',...
    t, size(V,1), size(V,2), N);

disp('  Localization of small 2D gaussians')
P = P(1:100, :);
V = 0*V;
V = blitGauss(V, P(:,1:2), 1);
C = df_com2(V, P')';
assert(max(eudist(P,C))<1)

if(0)
    figure, imagesc(V(:,:,30)); 
    colormap gray, axis image
    hold on
    plot(C(:,2), C(:,1), 'ro');
    hold on
    plot(P(:,2), P(:,1), 'g+');
    d = eudist(P,C);
    figure, histogram(d);
    fprintf('Mean error: %0.2f pixels', mean(d(:)));
end

disp('  -- done')