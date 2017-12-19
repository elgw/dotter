function d = dPointsToLines(L, P)
% Returns the shortest path from the line SEGMENT L (x,y,z to x,y,z) to P (x,y,z)
%
% Distance to an Infinite Line:
% http://mathworld.wolfram.com/Point-LineDistance3-Dimensional.html
%
% Here, when the point is projected outside the line, the shortest distance to
% the end points is returned.

A = L(1,1:3); B = L(1,4:6);
% Coordinate of P projected on (A,B) Proj(P) = A+t(B-A)
% I.e., if 0<t<1 the shortest distance is given by projection to the
% line, otherwise the shortest distance is the euclidean distance from
% A to P or from B to P

normAB = norm(A-B);
dL = inf(size(P,1),1);
t = inf(size(P,1),1);
for kk  = 1:size(P,1)
    t(kk) = -(A-P(kk,:))*(B-A)'/normAB^2;
    dL(kk) = norm(cross((P(kk,:)-A),(P(kk,:)-B)))/normAB;
end

dA = eudist(L(1,1:3), P);
dB = eudist(L(1,4:6), P);

dL(t<0) = inf;
dL(t>1) = inf;

d = min(dA,min(dB, dL));
end