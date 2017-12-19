function d = eudist(P,Q)
% Euclidean distance between the vectors in P and Q
% one vector per row

if numel(Q) == 0
    d = [];
    return
end

if size(P,1)==1
    P = repmat(P, [size(Q,1),1]);
end

d = P-Q;
d = d.^2;
d = sum(d,2);
d = d.^(1/2);

end
