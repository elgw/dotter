function df_fwhm1d_ut(varargin)

doBuild = 0;
doPlot = 0;

for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'build')
        doBuild = 1;
    end
    if strcmpi(varargin{kk}, 'plot')
        doPlot = 1;
    end
end

if doBuild
    mex CFLAGS='$CFLAGS -std=c99 -march=native -Wall `pkg-config gsl --cflags --libs`' COPTIMFLAGS='-DNDEBUG -O3' LINKLIBS='$LINKLIBS -lgsl -lgslcblas' df_fwhm1d.c
end

if exist('df_fwhm1d') ~= 3
    error('df_fwhm1d does not exist, probably not compiled')
end

disp('Wrong arguments')

% No argument
gotError = false;
try
    df_fwhm1d();
catch e
    gotError=true;
end
assert(gotError);

% Empy argument -- and too short arguments
for kk = 0:6
gotError = false;
try
    df_fwhm1d(zeros(kk,1));
catch e
    gotError=true;
end
assert(gotError);
end

gotError = false;
try
    df_fwhm1d(uint8(1));
catch e
    gotError = true;
end
assert(gotError);


% Even size of signal -- should only accept odd
for kk = 4:2:22
gotError = false;
try
    df_fwhm1d(zeros(kk,1));
catch e
    gotError = true;
end
assert(gotError);
end


disp('Border cases');
% Constant/flat signals
for kk = -1:1
    t = ones(11,1);
    df_fwhm1d(kk*t);
end

disp('Random input')
for kk = 1:100000
    t = rand(randi(29)*2+5,1);
    df_fwhm1d(t);
end

disp('NaN and inf')
w = df_fwhm1d([1 1 1 nan 1 1 1]);
assert(w == -1);
w = df_fwhm1d([1 1 1 Inf 1 1 1]);
assert(w == -1);

for kk = 1:7
    df_fwhm1d(circshift([1, 1, 1, -1e9, 1, 1, 1], kk));
    df_fwhm1d(circshift([1, 1, 1, 1e9, 1, 1, 1], kk));
end

disp('Precision')
sigmas = linspace(1,2)';
w = 0*sigmas;
for kk = 1:numel(sigmas)
    t = df_fwhm1d(fspecial('gaussian', [15, 1], sigmas(kk)));
    if t == -1
        keyboard
    end
    w(kk) = t(1);
end

T = [sigmas, w, 2*sqrt(2*log(2))*sigmas ];

assert(max(abs(1-T(:,2)./T(:,3))) < 0.05);

if doPlot
    figure
    plot(T(:,1), T(:,2))
    hold on
    plot(T(:,1), T(:,3))
    title('Performance')
    xlabel('Input sigma')
    ylabel('FWHM')
    legend({'Detected', 'Theoretical'}, 'Location', 'NorthWest');
end

disp('Constant offset')
sigmas = linspace(1,2)';
w2 = 0*sigmas;
for kk = 1:numel(sigmas)
    t = df_fwhm1d(fspecial('gaussian', [11, 1], sigmas(kk))+7);
    w2(kk) = t(1);
end

assert(max(abs(w-w2))<10^6);

w3 = 0*sigmas;
w4 = 0*sigmas;


% Compare to getw
for kk = 1:numel(sigmas)
    signal = fspecial('gaussian', [15, 1], sigmas(kk));
    w3(kk) = df_fwhm1d(signal);
    w4(kk) = getw(signal, 0);
end

theo = 2*sqrt(2*log(2))*sigmas;

if doPlot
    figure,    
    plot(sigmas, theo );
    hold on
    plot(sigmas, w3)
    plot(sigmas, w4)
    xlabel('Sigma')
    ylabel('FWHM')
    legend({'Theoreticalm', 'df_fwhm1d', 'getw'}, 'interpreter', 'none', 'location', 'northwest')
end

e1=theo-w3;
e2 = theo-w4;
mm = max(abs( [e1(:) ; e2(:)]));

if doPlot
    figure,
    subplot(1,2,1)
    D = linspace(-mm, mm, 31);
    histogram(e1, D)
    title('df_fwhm1d', 'interpreter', 'none')
    subplot(1,2,2)
    
    histogram(e2, D)
    title('getw')
    fprintf('Errors:    mean, std\n')
    fprintf('df_fwhm1d  %f, %f\n', mean(e1), std(e1));
    fprintf('getw       %f, %f\n', mean(e2), std(e2));
end

if exist('getw') == 2
    signal = fspecial('gaussian', [21, 1], 1.5);
    N = 100;
    tic;
    for kk = 1:N
        getw(signal, 0);
    end
    t0 = toc;
    tic;
    for kk = 1:N
        df_fwhm1d(signal);
    end
    t1 = toc;
    
    fprintf('Timings:\n')
    fprintf('getw:      %.2d /s\n', N/t0);
    fprintf('df_fwhm1d: %.2d /s\n', N/t1);
    
end

end