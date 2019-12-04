function dPointsToLines_ut()

disp('Border cases')

% Zero length
L = [0,0,0,0,0,0];
P = [1,0,0];
d = dPointsToLines(L, P);
assert(d == norm(P));

L = [1,0,0,1,0,0];
P = [1,0,0];
d = dPointsToLines(L, P);
assert(d == 0);

% Should be the point distance
L = [1,0,0,2,0,0];
P = [3,0,0];
d = dPointsToLines(L, P);
assert(d==1);
P = [0,0,0];
d = dPointsToLines(L, P);
assert(d==1);

% Should be distance to the line
for d0 = [0,1,100];
    L = [1,0,0,2,0,0];
    P = [1.5,d0,0];
    d = dPointsToLines(L, P);
    assert(d==d0);
end

M = makehgtform('xrotate', 2*pi*rand(1), 'yrotate', 2*pi*rand(1), 'zrotate', 2*pi*rand(1));
M = M(1:3,1:3);
norm(M);

disp('Affine Invariance')
for kk = 1:1000
    P = rand(1,3);
    L = rand(1,6);
    d1 = dPointsToLines(L, P);
    d2 = dPointsToLines([(M*L(1:3)')', (M*L(4:6)')'], (M*P')');
    assert(abs(d1-d2)<10e-6);
end

end
