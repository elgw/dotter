function df_gaussianInt3_ut()

disp('--> df_gaussianInt3');

disp('  Symmetric output')
A = df_gaussianInt3([0,0, 0], [1, 2,1],5);
assert(max(max(max(A-flipud(A))))<10^-9)
assert(max(max(max(A-fliplr(A))))<10^-9)

disp('  Correct sum')
assert(abs(sum(A(:))-1)<10^9) % sums to 1

disp('  Invariant shifting, 1')
B = df_gaussianInt3([0,  .1,0], [1,1,1], 5);
C = df_gaussianInt3([0, -.1,0], [1,1,1], 5);
assert(max(max(max(fliplr(B)-C)))<10^-9)


disp('  -- done');

%{
// Equation system to find the integral combination
M = [1 0 1 0 0 0 0 0
     1 1 1 1 0 0 0 0 
     0 0 1 0 0 0 0 0
     0 0 1 1 0 0 0 0
     1 0 1 0 1 0 1 0
     1 1 1 1 1 1 1 1
     0 0 1 0 0 0 1 0
     0 0 1 1 0 0 1 1];
 inv(M')*[0 0 0 0 0 1 0 0]'
%}
 
end