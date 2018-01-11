function df_volumeTubes_ut()

disp('>> One sphere, correct volume');
T = [0,0,0,0,0,0]; % sphere centered at [0,0,0];
V = df_volumeTubes('data', T, 'npoints', 20000, 'radius', 1);
assert(abs(V-4/3*pi)< 0.1);

disp('>> One sphere, shifted, correct volume');
T = [100,0,0,100,0,0]; % sphere centered at [0,0,0];
V = df_volumeTubes('data', T, 'npoints', 20000, 'radius', 1);
assert(abs(V-4/3*pi)< 0.1);

disp('>> One sphere, correct volume, changing radius');
T = [0,0,0,0,0,0]; % sphere centered at [0,0,0];
r = 2;
V = df_volumeTubes('data', T, 'npoints', 20000, 'radius', r);
assert(abs(V-4/3*pi*r^3)< 0.4);

disp('>> Tube of length 2, correct volume');
T = [0,0,0,1,0,0]; % sphere centered at [0,0,0] and [1,0,0] and joining cylinder
V = df_volumeTubes('data', T, 'npoints', 20000, 'radius', 1);
assert(abs(V-(4/3*pi+pi))< 0.1);

disp('>> Tube with 3 dots')
T = [[0,0,0,1,0,0];
     [1,0,0,2,0,0]]; % sphere centered at [0,0,0] and [1,0,0] and joining cylinder
V = df_volumeTubes('data', T, 'npoints', 20000, 'radius', 1);
assert(abs(V-(4/3*pi+2*pi))< 0.1);

end