function df_volumeSpheres_ut()

disp('-> df_volumeSpheres')

disp('Float input')
S = [1, 1.1, 1.2, 1.4];
V = df_volumeSpheres(S);
assert(abs(V-1.4^3*4/3*pi)<0.1); % Correct volume
rel_error = abs(V-1.4^3*4/3*pi)/1.4^3*4/3*pi;
assert(rel_error<10e-4);
fprintf('Relative error (%f) is ok\n', rel_error);

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

disp('>> Random number of spheres, mex vs matlab')
N = 10;
radius = 5;
v1 = nan(N,1); v2 = v1;
for kk = 1:N
    P = rand(2+randi(8), 3);    
    P = P*50;
    P = [P, radius*ones(size(P,1),1)]; % add radius
    v1(kk) = df_volumeSpheres(P);
    v2(kk) = df_volumeSpheres(P, 'disable_mex');
    if(abs(v1(kk)-v2(kk))/(v1(kk)+v2(kk)) > .01)
        warning('big difference')
        kk = N;
    end
end

if 0
    max_vol = max(max(v1), max(v2));
    % show the results for the two methods
    scatter(v1, v2), axis([0, max_vol, 0, max_vol]), grid on, xlabel('mex'), ylabel('matlab')
    % Show where non-overlapping spheres are
    for nn = 1:10
        v0 = 4/3*pi*5^3;
        hold on
        plot(nn*v0,nn*v0, 'rx')
    end
end

end
