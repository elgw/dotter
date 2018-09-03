function df_eudist_ut()

compile()

test_correct_2D()
test_speed_image()

test_speed_2D()
dprintpdf('timings_2D', 'w', 20, 'h', 10)
test_speed_3D()
dprintpdf('timings_3D', 'w', 20, 'h', 10)
end

function test_correct_2D()

for kk = 1:1000
    M = zeros(randi(100)+10, randi(100)+10);
    M(randi(size(M,1)), randi(size(M,2))) = 1;
    D1 = df_eudist(M);
    D2 = bwdist(M);
    
    err = max(abs(D1(:)-D2(:)));
    if(err>10e-3)
        whos
        error('Too large error')
    end
end

fprintf('%d 2D tests ok!\n', kk);

end

function compile()
mex CFLAGS='$CFLAGS -std=c11 -march=native' LDFLAGS="$LDFLAGS -lpthread" COPTIMFLAGS='-O3 -flto' df_eudist.c
%mex -g -lpthread df_eudist.c
end

function test_speed_image()

B = zeros(1024, 1024, 60);
fprintf('Timings for an isotropic %dx%dx%d image\n', size(B,1), size(B,2), size(B,3));
for kk = 1:50
    B(randi(size(B,1)), randi(size(B,2)), randi(size(B,3))) = 1;
end

tic
D1 = bwdistsc(B, [1, 1, 1]);
t_bwdistsc = toc;

tic
D2 = bwdist(B);
t_matlab = toc;

tic
D3 = df_eudist(B);
t_eudist = toc;


fprintf('bwdist: %f, df_eudist: %f, bwdistsc %f\n', t_matlab, t_eudist, t_bwdistsc);

end

function test_speed_2D()

N = linspace(100,10e7, 50);
N = round(sqrt(N));
K = 5; % number of trials
t_matlab = zeros(numel(N),1);
t_df = zeros(numel(N),1);

for nn = 1:numel(N)
    % progressbar(nn, numel(N));
    B = zeros(N(nn),N(nn));
    for kk = 1:10
        B(randi(size(B,1)), randi(size(B,2))) = 1;
    end
    D = zeros(size(B));
    
    tic
    for kk = 1:K
        D = bwdist(B);
    end
    t_matlab(nn) = toc/K;
    
    tic
    for kk = 1:K
        D = df_eudist(B);
    end
    t_df(nn) = toc/K;
end

figure
subplot(1,2,1)
plot(N.^2, t_matlab, 'k')
hold on
plot(N.^2, t_df, 'r');
legend({'bwdist', 'eudist'});

xlabel('Number of voxels')
ylabel('Time (s)');
title('2D timings')
subplot(1,2,2)
plot(N.^2, t_df./t_matlab, 'o');
xlabel('Number of voxels')
legend({'eudist/bwdist'}, 'interpreter', 'none');
title('2D timings')
end

function test_speed_3D()

N = linspace(1000,10e7, 50);
N = round(N.^(1/3));
K = 5; % number of trials
t_matlab = zeros(numel(N),1);
t_df = zeros(numel(N),1);

for nn = 1:numel(N)
    % progressbar(nn, numel(N));
    B = zeros(N(nn),N(nn), N(nn));
    for kk = 1:10
        B(randi(size(B,1)), randi(size(B,2)), randi(size(B,2))) = 1;
    end
    D = zeros(size(B));
    tic
    for kk = 1:K
        D = bwdist(B);
    end
    t_matlab(nn) = toc/K;
    
    tic
    for kk = 1:K
        D = df_eudist(B);
    end
    
    t_df(nn) = toc/K;
end

figure
subplot(1,2,1)
plot(N.^2, t_matlab, 'k')
hold on
plot(N.^2, t_df, 'r');
legend({'bwdist', 'eudist'});

xlabel('Number of voxels')
ylabel('Time (s)');
title('3D timings')
subplot(1,2,2)
plot(N.^2, t_df./t_matlab, 'o');
xlabel('Number of voxels')
legend({'eudist/bwdist'}, 'interpreter', 'none');
title('3D timings')
end