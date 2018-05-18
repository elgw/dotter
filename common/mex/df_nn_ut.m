function df_nn_ut()
disp(' -> Testing df_nn');

%{
Speed depends on the number of buckets that can be used, which in term is
determined by the distance vs the domain size.

Speedup scales with the number of bins.
Memory scales with the number of bins.

Example, dots from image of size 1024x1024x60, produces 3D coordinates in
the domain [0,130*1024]x[0,130*1024]x[0,300*1024] nm. Using a distance
threshold of 200 nm yields about 665x665x153 ~ 67 M buckets.


%}

disp('  Don''t filter out dots that are close withing the same channel');
D = [1, 1, 1, 1
    1, 1, 1, 1
    2, 2, 2, 2
    3, 3, 3, 3];

X = df_nn(D', 0.5);

assert(sum(X)==0);

disp('  Find dots that are equal in two different channels');
D = [1, 1, 1, 1
    1, 1, 1, 2
    2, 2, 2, 3
    3, 3, 3, 4];

X = df_nn(D', 0.5);

assert(X(1)==X(2)==1)

disp('  Random points to verify that the close are found')
t_nn = 0;
t_matlab = 0;
for kk = 1:1

dist = 0.01;
N = 5000;
D = rand(N,4);
D(:,4) = 1:size(D,1); % each point a unique class
tic
X = df_nn(D', dist);
t_nn = t_nn+toc;

tic
close = 0;
for kk = 1:N
    d = eudist(D(kk,1:3), D(:,1:3));
    if  sum(d<dist) > 1
        close = close + 1;
    end
end
t_matlab = t_matlab+toc;

assert(sum(X) == close);
end

fprintf('t_nn: %f, t_matlab: %f\n', t_nn, t_matlab);

if 0 % bechmark

    dist = 1;
NN = 2.^(1:22);
T = 0*NN;
for kk = 1:numel(NN)
    N = NN(kk);
D = 1024*rand(N,4);

tic
for ll = 1:1
X = df_nn(D', dist);
end
T(kk) = toc/11;
end

figure,
semilogx(NN, T)
plot(NN, T)
hold on
plot(NN, T, 'o')
xlabel('Size')
ylabel('Time (s)')

end

end