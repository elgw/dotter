function m = df_maxEdge3(V)
% function m = df_maxEdge3(V)
% return the largest value of V at the edge.
% Used to figure out if padding is needed when performing distance
% transforms.

assert(~isvector(V));
assert(numel(size(V)) == 3);

s = zeros(6,1); % 6 sides
s(1) = max(max(max( V(:,:,1) ))); % top
s(2) = max(max(max( V(:,:,end) ))); % bottom

s(3) = max(max(max( V(:,1,:) ))); % front
s(4) = max(max(max( V(:,end,:) ))); % back

s(5) = max(max(max( V(1,:,:) ))); % left
s(6) = max(max(max( V(end,:,:) ))); % right

m = max(s);
end