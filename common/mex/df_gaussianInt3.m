%% V = df_gaussianInt3(P, S, R)
% P: position
% S: sigma
% R: radius, V has side length 2*R+1
%
% compilation: mex CFLAGS='$CFLAGS -std=c99' COPTIMFLAGS='-DNDEBUG -O3' df_gaussianInt3.c        
%
% Example:
%  create a centered gaussian (P=0) with sigma 1.1 in all directions:
%
%   K = df_gaussianInt3([0,0,0], [1.1,1.1,1.1], 2);
