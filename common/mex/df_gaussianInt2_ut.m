function df_gaussianInt2_ut(varargin)

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

disp('  -- done');
end