function df_cc_ut()

s.plot = 0;

disp('>>> df_cc_create');
disp('>> Random displacement in X and Y')

% Testing the cc utilities
N = 100; % Number of dots
channels = {'apples', 'bananas'};

for kk = 1:10
    P{1} = 1024*rand(N,3);
    d = 10*[rand(1), rand(1), 0];
    P{2} = P{1} + [d(1)*ones(N,1),  d(2)*ones(N,1), d(3)*ones(N,1)];
    
    for aa = 1:numel(P)
        for bb = 1:numel(P)
            D{aa,bb} = [P{aa} P{bb}];
        end
    end
    
    
    t = df_cc_create('getDefaults');
    t.filename = [tempdir() 'test.cc'];
    channels = {'apples', 'bananas'};
    df_cc_create('dots', D, 'settings', t, 'channels', channels);
    cc = load(t.filename, '-mat');
    
    assert(max(cc.E(:))<10e-6);
    
    % No displacement in Z
    for aa = 1:size(D,1)
        for bb = 1:size(D,2)
            if aa ~= bb                
                assert(abs(cc.dz{aa,bb} - 0) < 10e-9);
            end
        end
    end
    
    C = df_cc_apply_dots('dots', D{2}, 'from', 'bananas', 'to', 'apples', 'ccFile', t.filename);
    assert(max(sum( (C-D{1}).^2, 2).^(1/2)) < 10e-6)
end

if s.plot
    figure,
    plot(D{1}(:,1), D{1}(:,2), 'ro');
    hold on
    plot(D{2}(:,1), D{2}(:,2), 'k.');
    plot(C(:,1), C(:,2), 'kx');
    
    legend({'D{1}', 'D{2}', 'C(D{2})'})
end

disp('>> Displacement in Z')

P{1} = 1024*rand(N,3);
d = [0, 0, 1];
P{2} = P{1} + [d(1)*ones(N,1),  d(2)*ones(N,1), d(3)*ones(N,1)];

for aa = 1:numel(P)
    for bb = 1:numel(P)
        D{aa,bb} = [P{aa} P{bb}];
    end
end


df_cc_create('dots', D, 'settings', t, 'channels', channels);
C = df_cc_apply_dots('dots', D{2}, 'from', 'bananas', 'to', 'apples', 'ccFile', t.filename);
fprintf('mean(D{1}(:,3)): %f\nmean(D{2}(:,3)): %f\nmean(C(:,3)):    %f\n', mean(D{1}(:,3)), mean(D{2}(:,3)), mean(C(:,3)));
cc = load(t.filename, '-mat');
assert(abs(mean(C(:,3))-mean(D{1}(:,3))) < 10e-6)
assert(max(cc.E(:))<10e-6);

disp('>>> df_cc_cluster')

% N    dots with some noise
% N-NX colocalized dots
% NX   non-colocalized dots

N = 300;
NX = 50;
sigma1 = 1.5;
sigma2 = 30;

A = 1024*rand(N,3);
B = A;
dxy = 10*rand(1,2);
B(:,1) = B(:,1) + dxy(1);
B(:,2) = B(:,2) + dxy(2);
B = B + sigma1*rand(size(B));
B(1:NX,:) = B(1:NX,:) + sigma2*rand(NX,3);
B = B(randperm(size(B,1)),:);
D = cell(1,1);
D{1} = A;
D{2} = B;

t = df_cc_cluster('getDefaults');
C = df_cc_cluster('dots', D, 'settings', t);

assert(size(C{1,2},1) >= N-NX);
assert(size(C{2,1},1) >= N-NX);

end