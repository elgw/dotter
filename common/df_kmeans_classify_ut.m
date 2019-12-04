function df_kmeans_classify()

disp('>> One mean');
m = [0,0,0];
P = rand(21, 3);
L = df_kmeans_classify(m , P);
assert(size(L,1) == size(P,1));
assert(size(L,2) == 1);
assert(sum(L-ones(size(L)))==0);

disp('>> One mean, with maxdist');
m = [0,0,0];
P = rand(21, 3);
P(end,:) = P(end,:) + 10;
s.maxDist = 2;
s.maxDots = inf;
L = df_kmeans_classify(m , P, s);
assert(size(L,1) == size(P,1));
assert(size(L,2) == 1);
assert(sum(L) == size(P,1)-1);

disp('>> One mean, with maxdots');
s.maxDots = 1;
s.maxDist = inf;

m = [0,0,0];

P = linspace(-2,2, 10)';
P = repmat(P, [1, 3]);

for kk = 1:10
    m = P(kk,:);
    L = df_kmeans_classify(m , P, s);
    assert(L(kk) == 1);
    assert(sum(L) == 1);
end

disp('>> Two means');
m = rand(2,3);
P = rand(21, 3);
L = df_kmeans_classify(m , P);
assert(size(L,1) == size(P,1));
assert(size(L,2) == 1);
assert(min(L(:))>=1);
assert(max(L(:))<=2);

disp('>> Two means, with maxdist');
s.maxDist = 2;
s.maxDots = inf;

m = rand(2,3);
P = rand(21, 3);
P(end,:) = P(end,:)+10;
L = df_kmeans_classify(m , P, s);
assert(size(L,1) == size(P,1));
assert(size(L,2) == 1);
assert(min(L(:))==0);
assert(sum(L(:)==0)==1);
assert(max(L(:))<=2);

disp('>> Two means, with maxdots');
s.maxDist = inf;
s.maxDots = 3;

m = rand(2,3);
P = rand(21, 3);
P(end,:) = P(end,:)+10;
L = df_kmeans_classify(m , P, s);
assert(min(L(:))==0);
assert(sum(L(:)==1)<=s.maxDots);
assert(sum(L(:)==2)<=s.maxDots);
assert(max(L(:))<=2);

disp('>> N means');
for N = 3:7
    s.maxDist = inf;
    s.maxDots = inf;
    m = rand(N,3);
    P = rand(21, 3);
    P(end,:) = P(end,:)+10;
    L = df_kmeans_classify(m , P, s);
    assert(min(L(:))>=1);
    assert(max(L(:))<=N);
end

disp('>> N means, with maxDots');
for N = 3:7
    s.maxDist = inf;
    s.maxDots = 2;
    m = rand(N,3);
    P = rand(21, 3);
    P(end,:) = P(end,:)+10;
    L = df_kmeans_classify(m , P, s);
    assert(min(L(:))==0); %
    assert(max(L(:))<=N);
    assert(sum(L==N)<=s.maxDots);
end

disp('>> N means, with maxDots and maxDist');
for N = 3:7
    s.maxDist = 2;
    s.maxDots = 2;    
    P = rand(21, 3);
    m = P(2:N+1,:);
    P(end,:) = P(end,:)+10;
    L = df_kmeans_classify(m , P, s);
    assert(min(L(:))==0); %
    assert(max(L(:))==N);
    assert(sum(L==N)<=s.maxDots);
    assert(L(end) == 0);
end

end