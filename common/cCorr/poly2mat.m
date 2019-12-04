function M = poly2mat(V, order)
% Returns the 1st, 2nd or 3rd order polynomial matrix of v
% containing two-dimensional points.
%
% I.e, if v = [[x1,y1], [x2,y2], ...]
% return [1 x y xx xy yy]
%

if order == 3
M= [ones(size(V,1),1), ...
        ...
        V(:,1), V(:,2),  ...
        ...
        V(:,1).*V(:,1), V(:,1).*V(:,2), ...
        V(:,2).*V(:,2), ...
        ...
        V(:,1).*V(:,1).*V(:,1), V(:,1).*V(:,1).*V(:,2), ...
        V(:,1).*V(:,2).*V(:,2), ...
        V(:,2).*V(:,2).*V(:,2)];
end


if order == 2
M= [ones(size(V,1),1), ...
        ...
        V(:,1), V(:,2), ...
        ...
        V(:,1).*V(:,1), V(:,1).*V(:,2), ...
        V(:,2).*V(:,2)];
end

if order == 1
M= [ones(size(V,1),1), ...
        V(:,1), V(:,2)];    
end

    