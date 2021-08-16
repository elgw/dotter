function df_imshift_ut()
%% df_imshift(I, delta, method)
% shift image I by delta, one per dimension
% delta has to be less than a pixel, i.e., abs(max(delta))<1
% method: 'Linear' or 'Cubic'
%
% Notes:
%  - falls back to Linear if the method name is not recognized
%  - Border pixels set to 0
%
% See the code for df_imshift_ut for examples


disp('--> Testing df_imshift');

if ~exist('doPlot', 'var')
    doPlot = 0;
end
if ~exist('doCompile', 'var')
    doCompile = 0;
end

if doCompile
    cd([getenv('DOTTER_PATH') 'common/mex/'])
    
    mex  imshift.c CFLAGS='-g $CFLAGS -std=c99 `pkg-config gsl --cflags --libs`' COPTIMFLAGS='-g -O3 -D verbose=0' ...
        LINKLIBS='$LINKLIBS -lgsl -lgslcblas' -c
    
    mex  df_imshift.c CFLAGS='-g $CFLAGS -std=c99 `pkg-config gsl --cflags --libs`' COPTIMFLAGS='-g -O3 -D verbose=0' ...
        LINKLIBS='$LINKLIBS -lgsl -lgslcblas' imshift.o conv1.o
end

disp('--> Invalid input')
disp('  no input')
gotError = 0;
try
    df_imshift()
catch e
    gotError = 1;
end
assert(gotError == 1)

disp('  wrong type')
gotError = 0;
try
    df_imshift('ad');
catch e
    gotError = 1;
end
assert(gotError == 1)

disp('  wrong number of deltas')
gotError = 0;
try
    df_imshift(zeros(10,10), [])
catch e
    gotError = 1;
end
assert(gotError == 1)

disp('  too large delta')
gotError = 0;
try
    df_imshift(zeros(10,1), [.6]);
catch e
    gotError =1;
end
assert(gotError == 1);

gotError = 0;
try
    df_imshift(zeros(10,10), [.6,0]);
catch e
    gotError =1;
end
assert(gotError == 1);

gotError = 0;
try
    df_imshift(zeros(10,10,10), [0,.6,0]);
catch e
    gotError =1;
end
assert(gotError == 1);

if 0 % does not accept 1D input
disp('--> 1D');
disp('  runs with no errors')
T = rand(100,1);
T = gsmooth(T,1);
S = df_imshift(T,-.5);
S = df_imshift(T,-.5, 'Linear');
S = df_imshift(T,-.5, 'Cubic');
getError = 0;

disp('  only accepts 1D input along first dimension')
try
    S = df_imshift(T',-.5);
catch e
    gotError = 1;
end
assert(gotError == 1);

T = zeros(100,1);
T(11) = 1;
S = df_imshift(T, .5);

T = zeros(50,50);
T(25:26,25:26) = 1;
S1 = df_imshift(T, [.4,.4], 'cubic');
S2 = imtranslate(T, [.4,.4], 'cubic');


if 0
    figure
    plot(T)
    hold on
    plot(S);
    legend({'input', 'output'})
end
end

disp('--> 2D');
if doPlot
    fig = figure;
    drawnow
end

T = imread('cameraman.tif');
T = double(T);
disp('  comparing with imshift')
S1 = df_imshift(T, [.2, .2], 'cubic');
S2 = imtranslate(T, [.2, .2], 'cubic');

diff = max(abs(S1(:)-S2(:)));
assert(diff<10e-9);
fprintf('  Max difference: %f -- ok\n', diff);

if doPlot
    figure
    imagesc([S1 S2; S1-S2, 0*S1])
    axis image
    colorbar
    title('S1 S2; S1-S2 0')
end

T = zeros(11,11);
T(6,6) = 1;

if doPlot
    figure
    drawnow
    img = imagesc(T(2:end-1,2:end-1));
    %colormap([1,0,0; 0,0,0; 0,1,0])
    %colormap([flipud(gray(100)); 0,0,0; (gray(100))])
    set(gca, 'Clim', [-1,1]);
    hold on
    p = plot(5,5,'rx');
end

thetas = linspace(0,2*pi, 1000);
t1 = 0; t2 = 0;
for kk = 1:numel(thetas)
    theta = thetas(kk);
    tic
    S = df_imshift(T, .5*[cos(theta),sin(theta)], 'Cubic');
    t1 = t1+toc;
    tic
    S2 = imtranslate(T, .5*[sin(theta),cos(theta)], 'cubic');
    t2 = t2 + toc;
    assert(max(abs(S(:)-S2(:)))<10e-9);
    D = cat(3, S, S2, 0*S);
    %D = S;
    D = D(2:end-1,2:end-1, :);
    if doPlot
        img.CData = D;
        title(num2str([cos(theta),sin(theta)]))
        p.XData = sin(theta)+5;
        p.YData = cos(theta)+5;
        drawnow
    end
end

fprintf('  df_imshift:  %.2f s\n', t2);
fprintf('  imtranslate: %.2f s\n', t2);

if doPlot
    title('T-S')
end

disp('-->3D');
T = zeros(121,121,121);
T(61,61,61) = 1;

tic
for kk = 1:100
    S = df_imshift(T, [0,0,.49], 'Quadratic');
end
t1 = toc;

tic
for kk = 1:100
    S2 = imtranslate(T, [0,0,.49]);
end
t2 = toc;

fprintf('  df_imshift:  %.2f s\n', t1);
fprintf('  imtranslate: %.2f s\n', t2);

assert(S(61,61,61) == max(S(:)));
assert(max(abs(S(:)-S2(:)))<10e-9)

end