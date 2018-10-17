function df_mlfit1_ut()
% Fitting of dots in volumetric image

disp('--> Testing df_mlfit1')

% compile()

test_invalid_input()
test_correct_localization()
test_behaviour_wrong_init()
test_realistic_timing()
test_noise()

% Produce a plot with error vs sigma.
% test_sigma()

% To do: 
% Noise!

% compile()

disp('  -- done');
end

function compile()

mex  CFLAGS='$CFLAGS -std=c99 -march=native -Wall `pkg-config gsl --cflags --libs`' gaussianInt2.c COPTIMFLAGS='-DNDEBUG -O3' -c
mex  mlfit.c gaussianInt2.o CFLAGS='$CFLAGS -std=c99 -march=native `pkg-config gsl --cflags --libs`' COPTIMFLAGS='-O3 -D verbose=0' ...
    LINKLIBS='$LINKLIBS -lgsl -lgslcblas -v' -c
mex  df_mlfit1.c CFLAGS='$CFLAGS -std=c99 -march=native `pkg-config gsl --cflags --libs`' COPTIMFLAGS='-O3 -D verbose=0' ...
    LINKLIBS='$LINKLIBS -lgsl -lgslcblas' mlfit.o blit3.o gaussianInt2.o

end

function test_sigma()

sigmas = linspace(0.5,2);
P = [8,8,8]+.2*(1-rand(1,3));
for kk = 1:numel(sigmas)
    sigma = sigmas(kk);        
    V = 1000+1000*df_blit3(zeros(15,15,15), [], [P , 1, sigma*[1, 1, 1]]');
    F = df_mlfit1(V, P', sigma);
    err(kk) = norm(F'-P);
    xerr(kk) = abs(F(1)-P(1));
    zerr(kk) = abs(F(3)-P(3));
end

% plot(R, 'r'), hold on, plot(G, 'g')

figure()
clf
subplot(2,2,1), plot(squeeze(V(:, 8,8))), title('x')
subplot(2,2,2), plot(squeeze(V(8,:,8))), title('y')
subplot(2,2,3), plot(squeeze(V(8,8,:))), title('z')
subplot(2,2,4), 
plot(sigmas, err, 'x')
hold on
plot(sigmas, xerr, 's')
plot(sigmas, zerr, 'o')
xlabel('Sigma')
ylabel('Error')
legend({'xyz', 'x', 'z'})

end

function test_invalid_input()
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

% border case:
gotError =0;
try
    df_mlfit1(zeros(101,101,101), [51,51,51]');
catch e
    gotError = 1;
end
assert(gotError==1);
end


function test_realistic_timing()
disp('  > worst case timings -- no convergence')
nD = 1000;
V = 1000+1000*rand(1024,1024,60);
D0 = round([(size(V,1)-6)*rand(nD,1), (size(V,2)-6)*rand(nD,1), size(V,3)*rand(nD,1)]);
D0(D0<7) = 7;
D = round(D0);
T = 0*V;
T(sub2ind(size(V),D(:,1), D(:,2), D(:,3))) = 1;
T = gsmooth(T, 1.6);
V = 1+poissrnd(100000*T);
tic
F = df_mlfit1(V, D'); F = F';
tval = toc;
fprintf('  --> df_mlfit1 took %.3f s for a %dx%dx%d image and %d dots\n', tval, size(V,1), size(V,2), size(V,3), size(D,1));
fprintf('      i.e., %d dots/s\n', round(size(D,1)/tval));

if 0
    % About 30x faster
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
end


function test_noise()
disp('  > Random input (better that it crashes here than in a sharp situation)');

for kk = 1:100
    V = rand(round(125*rand([3,1]))'); % Input volume of random size
    P = 200*rand(randi(100),randi(4)); % Dots that might be outside of V
    try
        F = df_mlfit1(V, P');
    catch e
        % Ok if some errors are generated since the input
        % isn't always valid
    end
end

end

function test_behaviour_wrong_init()
disp('  > Testing initial positions far from dot')

for delta = 0:5
    P0 = [8,8,8];
    P = [8,8,8]+delta;
    V = 1+df_blit3(zeros(15,15,15), [], [P , 1, 1, 1, 1]');
    F = df_mlfit1(V, P');
end

% When it does not converge, F is set to [0,0,0]

end

function test_correct_localization()
disp('  > Correct localization');

% Basic integer case
P = [8,8,8];
V = 100+1000*df_blit3(zeros(15,15,15), [], [P , 1, 1, 1, 1]');
F = df_mlfit1(V, P');
assert(eudist(P, F')<1e-3);

% +0.1 from integer
P = [8.1,8.2,8.3];
V = 100+10000*df_blit3(zeros(15,15,15), [], [P , 1, 1, 1, 1]');
F = df_mlfit1(V, round(P'));
assert(eudist(P, F')<1e-2);

% Random offset -- correct initial position
for kk = 1:1000
    P = [8,8,8] + .5*(1-rand(1,3));
    V = 1000+100000*df_blit3(zeros(15,15,15), [], [P , 1, 1, 1, 1]');
    F = df_mlfit1(V, P');    
    assert(eudist(P, F')<2e-2);
end

% Random offset -- rounded initial position
for kk = 1:1000
    P = [8,8,8] + .5*(1-rand(1,3));
    V = 10+10000*df_blit3(zeros(15,15,15), [], [P , 1, 1, 1, 1]');
    F = df_mlfit1(V, round(P'));
    assert(eudist(P, F')<1e-2);
end


end
