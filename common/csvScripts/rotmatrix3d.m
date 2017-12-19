function [R]=rotmatrix3d(angles)
%% function [R]=rotmatrix3d(angles)
% Builds a 3D rotation matrix.
% Rotate around xyx-axes by [az, ay, ax] (radians)
%
% Erik Wernersson

% Rotation around the z-axis
t=angles(1);
R2=[cos(t) -sin(t); sin(t) cos(t)]; % rotationsmatris
RXY=eye(3); RXY(1:2,1:2)=R2;

% Rotation around the y-axis
t=angles(2);
RXZ=[cos(t) 0 sin(t); 0 1 0;  -sin(t) 0 cos(t)]; % rotationsmatris

%rotation around the x-axis
t=angles(3);
R2=[cos(t) -sin(t); sin(t) cos(t)]; % rotationsmatris
RYZ=eye(3); RYZ(2:3,2:3)=R2;

% And the combined rotation matrix:
R=RXY*RXZ*RYZ;



