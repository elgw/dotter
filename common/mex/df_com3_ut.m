function df_com3_ut()
% Tests df_com3
%
% df_com3 can be called with two or three arguments
% if the third argument is 1, weighting will be used to try to resolve
% situations when dots are partially overlapping. That is usually a good
% thing to use.
%
% C = df_com3(V, P');    % Centre of mass for each [x,y,z] in P
% Cw = df_com3(V, P',1); % Weighted
%
% Dots too close to the boundary are not considered.
% Note: not resolution independent, uses fixed padding.

disp('--> Testing df_com3')
% mex CFLAGS='$CFLAGS -std=c99 -Wall `pkg-config gsl --cflags --libs`' df_com3.c

disp('  Handles zero input')
error = 0;
try
    df_com3()
catch e
    error = 1;
end
assert(error==1);

disp('  Don''t do anything at flat locations')
V = zeros(100,100,100);
disp('  Flat images')
P = [51,51,51];
C = df_com3(V, P');
Cw = df_com3(V, P',1 );
assert(sum(P(:)==C(:)) == numel(P));
assert(sum(P(:)==Cw(:)) == numel(P));
C = df_com3(1+V, P');
Cw = df_com3(1+V, P', 1);
assert(sum(P(:)==C(:)) == numel(P));
assert(sum(P(:)==Cw(:)) == numel(P));

disp('  Locate at the right position')
V = zeros(100,100,100);
P = [51,52,53];
V(P(1), P(2), P(3))=1;
for w = 0:1
C = df_com3(V, P', w);
assert(sum(P(:)==C(:)) == numel(P));
end

disp('  Invalid input')
% Should not crash
for w=0:1
    q = df_com3(V, [10e6, -10e6, 0]', w);
end


disp('  Shifts in the right directions')
for w = 0:1
V = zeros(25,25,25);
P = [10,10,10];
V(P(1), P(2), P(3))=2;
P1 = [11,10,10];
V(P1(1), P1(2), P1(3))=2;
C = df_com3(V, P', w);
assert(C(1)>P(1))
assert(C(1)<P1(1))
end

disp('  Don''t crash for random input and give reasonable answers')
for w = 0:1
for kk = 1:10
    V = rand(100,200,300);
    V = V+min(V(:));
    N = 100;
    P = [size(V,1)*rand(N,1), size(V,2)*rand(N,1), size(V,3)*rand(N,1)];
    C = df_com3(V, P', w)';
    d = eudist(P,C);
    assert(max(d(:))<2)
end
end

if 0
    figure,
    histogram(d)
    figure
    plot3(C(:,1), C(:,2), C(:,3), 'o')
    hold on
    plot3(P(:,1), P(:,2), P(:,3), 'x')
end

disp('  Timings for a realistic case');
for w = 0:1
V = rand(1024,1024,60);
N = 100000;
P = [size(V,1)*rand(N,1), size(V,2)*rand(N,1), size(V,3)*rand(N,1)];
tic
C = df_com3(V, P',w)';
t = toc;
fprintf('  -> Took %.1f sec for an image of size %dx%dx%d and %d dots, w=%d\n',...
    t, size(V,1), size(V,2), size(V,3), N, w);
end

disp('  Localization of small 2D gaussians')
P = P(1:5000, :);
P(:,3) = 30;
V = 0*V;
V(:,:,30) = blitGauss(V(:,:,30), P(:,1:2), 1);
tic
C = df_com3(V, P',0)';
toc
%assert(max(eudist(P,C))<1)
tic
C1 = df_com3(V, P',1)';
toc
%assert(max(eudist(P,C))<1)
d = eudist(P,C);
d1 = eudist(P,C1);
    
if(0)
    figure, 
    ax1 = subplot(1,2,1);
    imagesc(V(:,:,30)); 
    colormap gray, axis image
    hold on
    plot(C(:,2), C(:,1), 'ro');
    hold on
    plot(P(:,2), P(:,1), 'g+');
    title('com3')
    ax2 = subplot(1,2,2);
    imagesc(V(:,:,30)); 
    colormap gray, axis image
    hold on
    plot(C1(:,2), C1(:,1), 'ro');
    hold on
    plot(P(:,2), P(:,1), 'g+');
    linkaxes([ax1, ax2], 'xy');
    title('com3 - weighted');
    
    figure,
    ax1 = subplot(1,2,1);
    
     histogram(d);
         title('com3')
    ax2 = subplot(1,2,2);
    
     histogram(d1);
     linkaxes([ax1, ax2], 'xy');
         title('com3 - weighted');
end

fprintf('com:   Mean error: %0.2f pixels\n', mean(d(:)));
fprintf('com+w: Mean error: %0.2f pixels\n', mean(d1(:)));

test_speed()

disp('  -- done')
end

function test_speed()

disp('Some timing ...')
I = rand(1024, 1024, 60);
N = 1000;
D = [randi(size(I,1), N, 1), randi(size(I,2), N, 1), randi(size(I,3), N, 1)];
I(sub2ind(size(I), D(:,1), D(:,2), D(:,3))) = 2;
tic
C = df_com3(I, D',1)';
t = toc;
fprintf(' -> %.2f dots per second\n', N/t);
end