function df_volumeSpheres_ut()

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