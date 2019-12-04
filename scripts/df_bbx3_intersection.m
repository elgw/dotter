function [v, bbx] = df_bbx3_intersection(BBX)
% function [v, bbx] = df_bbx3_intersection(BBX)
% v: volume
% bbx: intersection
% BBX is a Nx6 matrix
%
% Create intersection between 3D bounding boxes
% BBXes are encoded as [x0, x1, y0, y1, z0, z1]

% If only one bbx, return it.
if size(BBX,1) == 1       
    v = (BBX(2)-BBX(1))*(BBX(4)-BBX(3))*(BBX(6)-BBX(5));
    bbx = BBX;
    return;
end 

% If more than one, recursive call
% Intersection of the last two bbxes in varargin


BBX(end-1,:) = intersect_pair(BBX(end,:), BBX(end-1,:));
BBX = BBX(1:end-1, :);
[v, bbx] = df_bbx3_intersection(BBX);
    
end

function [bbx] = intersect_pair(A, B)

for kk = 0:2
    ind = 2*kk+(1:2);
    bbx(ind) = getRangeIntersection(A(ind), B(ind));
end

end

function range = getRangeIntersection(A, B)
% Get intersection of 1D line

% Identify no overlap
if(max(A) <= min(B))
    range = [0,0];
    return;
end

if(max(B) <= min(A))
    range = [0,0];
    return;
end

% Identify if one interval contains the other
if(min(A)<min(B) && max(A)>max(B))
    range = B;
    return
end

if(min(B)<min(A) && max(B)>max(A))
    range = A;
    return
end

% Identify partial overlap
if(max(A)>=min(B) && min(B) <= min(A))
    range = [ min(A), max(B)];
    return;
end

if(max(B)>=min(A) && min(A) <= min(B))
    range = [ min(B), max(A)];
    return;
end

error('This should not happen');

end