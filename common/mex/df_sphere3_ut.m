function df_sphere3_ut()

T = inf(1024,1024,60);
tic
S = df_sphere3(T, [51,51,51]);
toc

tic
S = df_sphere3(T, [51,51,51], 10);
toc

T = inf(101,101,101);
S = df_sphere3(T, [51,51,51], 3);

end