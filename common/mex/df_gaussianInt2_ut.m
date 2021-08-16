function df_gaussianInt2_ut(varargin)
% df_gaussianInt2(pos, sigma, w)
% Create a 2D Gaussian by integrating a Gaussian over a grid
%
% TODO: The function only uses the first sigma parameter, i.e.,
%       can only generate symmetric gaussians.
doBuild = 0;

for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'build')
        doBuild = 1;
    end
end

if doBuild
    mex CFLAGS='$CFLAGS -std=c99 -Wall' COPTIMFLAGS='-DNDEBUG -O3' df_gaussianInt2.c        
end

disp('  Symmetric output')
A = df_gaussianInt2([0,0], [1,1] ,5);
assert(max(max(A-A'))<10^-9)

disp('  Correct sum')
assert(abs(sum(sum(A))-1)<10^9) % sums to 1

disp('  Invariant shifting, 1')
B = df_gaussianInt2([.1,0], [1,1],5);
C = df_gaussianInt2([0,.1], [1,1],5);
assert(max(max(B'-C))<10^-9)

disp('  Invariant shifting, 2')
D = df_gaussianInt2([-.1,0], [1,1],5);
assert(max(max(B-flipud(D)))<10^-9)

disp('  Invariant shifting, 3')
E = df_gaussianInt2([0,-.1], [1,1],5);
assert(max(max(C-fliplr(E)))<10^-9)

disp('  Invalid arguments')
% Empy arguments
error = 0;
try
E = df_gaussianInt2([], [], []);
catch e
    error = 1;
end
assert(error == 1)
% Only sigma set
error = 0;
try
E = df_gaussianInt2([], [1,1], []);
catch e
    error = 1;
end
assert(error == 1)

% No size
error = 0;
try
E = df_gaussianInt2([0,0], [1,1], []);
catch e
    error = 1;
end
assert(error == 1)

% Empty size
error = 0;
try
E = df_gaussianInt2([0,0], [1,1], 0);
catch e
    error = 1;
end
assert(error == 1)

% Wrong data type
error = 0;
try
E = df_gaussianInt2([0,0], uint16([1,1]), 3);
catch e
    error = 1;
end
assert(error == 1)


% Random input
for kk = 1:1000
    E = df_gaussianInt2(rand(1, 2), rand(1, 2), 5);
end

disp('  -- done');
end