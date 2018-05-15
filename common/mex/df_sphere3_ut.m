function df_sphere3_ut()
mex df_sphere3.c
T = inf(1024,1024,60);
tic
d = [51,51,51];
S = df_sphere3(T, d');
assert( S(d(1), d(2), d(3))== 0 )
assert(max(S(:))>0)
toc

d = [51,51,51; 100, 120, 10];
S = df_sphere3(T, d');
for kk = 1:size(d,1)
assert(S(d(kk,1), d(kk,2), d(kk,3)) == 0)
end

tic
S = df_sphere3(T, [51,51,51], 10);
toc

T = inf(101,101,101);
S = df_sphere3(T, [51,51,51], 3);

end