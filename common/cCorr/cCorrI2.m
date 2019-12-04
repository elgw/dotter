function [C] = cCorrI2(I, Cx, Cy, dz)
%% function [C] = cCorrI2(I, Cx, Cy, dz)

% Dense representation
[X,Y, Z] = ndgrid(1:size(I,1),1:size(I,2), 1:size(I,3));

polyorder = 2;
PD = [X(:) Y(:), Z(:)];
QD(:,1) = poly3mat(PD, polyorder)*Cx;
QD(:,2) = poly3mat(PD, polyorder)*Cy;
QD(:,3) = PD(:,3)+dz;


if size(I,3) > 1 % 3D
    C = interpn(double(I), ...
    reshape(QD(:,1), size(I)), ...
    reshape(QD(:,2), size(I)), ...
    reshape(QD(:,3), size(I)), 'cubic' );
end

if size(I,3) == 1 % 2D
    C = interpn(double(I), ...
    reshape(QD(:,1), size(I)), ...
    reshape(QD(:,2), size(I)), 'cubic' );
end

end
