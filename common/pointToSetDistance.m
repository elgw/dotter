function d = pointToSetDistance(p,S)
%% function d = pointToSetDistance(p,S)
% distance from p to all points in s

d = repmat(p(1,1:3), [size(S,1),1])-S(:,1:3);
d = d.^2;
d = sum(d,2);
d = d.^2;
