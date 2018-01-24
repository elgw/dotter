function df_volumeSpheres_ut()

disp('-> df_volumeSpheres')

disp('Float input')
S = [1, 1.1, 1.2, 1.4];
V = df_volumeSpheres(S);
assert(abs(V-1.4^3*4/3*pi)<0.1);

disp('One sphere');
S = [1,1,1,1];
V = df_volumeSpheres(S);
assert(abs(V-4/3*pi)<0.01);

S = [1,1,1,2];
V = df_volumeSpheres(S);
assert(abs(V-8*4/3*pi)<0.1);

disp('Two spheres');
S = [1,1,1,1; 1, 1, 1, 1];
V = df_volumeSpheres(S);
assert(abs(V-4/3*pi)<0.01);

S = [1,1,1,1; 1.5, 1.5, 1.5, 1];
V = df_volumeSpheres(S);
assert(V> 4/3*pi);
assert(V<8/3*pi);

disp('>> One sphere, correct volume');
T = [0,0,0, 1]; % sphere centered at [0,0,0] with radius 1
V = df_volumeSpheres(T, 'npoints', 20000);
assert(abs(V-4/3*pi)< 0.1);

disp('>> One sphere, shifted, correct volume');
T = [100,0,0, 1]; % sphere centered at [0,0,0] with radius 1
V = df_volumeSpheres(T, 'npoints', 20000);
assert(abs(V-4/3*pi)< 0.1);


disp('>> One sphere, correct volume, changing radius');
r = 2;
T = [0,0,0, r]; % sphere centered at [0,0,0];
V = df_volumeSpheres(T, 'npoints', 20000);
assert(abs(V-4/3*pi*r^3)< 0.4);

disp('>> Two overlapping spheres, correct volume, changing radius');
r = 2;
T = [0,0,0, r]; % sphere centered at [0,0,0];
T = [T;T];
V = df_volumeSpheres(T, 'npoints', 20000);
assert(abs(V-4/3*pi*r^3)< 0.4);

end