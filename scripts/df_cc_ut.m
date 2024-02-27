function df_cc_ut()

s.plot = 0;

test_df_cc_cluster();

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


    
end

function test_df_cc_cluster()
disp('>>> df_cc_cluster')

N = 100; % Number of dots
NX = 20; % Number of co-localized dots
sigma1 = 0.5; % Gaussian additive to the pixel locations
maxDisplacement = [5, 5, 10]; % Max displacement per dimension

% A: First set of dots
A = [1024*rand(N,2), 60*rand(N,1)];
B = [1024*rand(N,2), 60*rand(N,1)];
B(1:NX, :) = A(1:NX, :); % NX dots are the same
% Make sure that the order is different
idx = randperm(size(B,1));
B = B(idx,:);
%idx2 = dsearchn(A, B);

% Make sure that we dont assume same size of A and B
if rand(1) > 0.5
B = B(1:end-5, :);
else
A = A(1:end-5, :);
end

%keyboard
% Add a shift
delta0 = maxDisplacement.*(2*(rand(1,3)-0.5));
for kk = 1:3
    B(:,kk) = B(:,kk) + delta0(kk);
end

% Additive Gaussian noise
% Just so that the poistions are not identical
B = B + sigma1*randn(size(B));

if 0
    figure,
    scatter3(A(:,2), A(:,1), A(:,3));
    hold on
    scatter3(B(:,2), B(:,1), B(:,3), 'x');
    legend({'A, original', 'B, distorted'})
end

D = cell(1,1);
D{1} = A;
D{2} = B;

t = df_cc_cluster('getDefaults');
[C, Delta] = df_cc_cluster('dots', D, 'settings', t);

% The displacement vector should be found with reasonable precision
assert(norm(delta0 + Delta{1,2}) < 1)

% At least 80% of the matching dots should be found
assert(size(C{1,2},1) >= 0.8*NX);
assert(size(C{2,1},1) >= 0.8*NX);

end