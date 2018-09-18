function df_imresize_ut()

disp('Unit resize')
T = rand(21,21,21);
R = df_imresize(T, [1,1,1]);
assert(isequal(size(T), size(R)));

disp('Integer rescaling')
T = rand(21,21,21);
R = df_imresize(T, [.5,.5,.5]);


end