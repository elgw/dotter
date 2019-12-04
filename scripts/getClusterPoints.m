function CP = getClusterPoints(C, n)
% Finds the other points which belongs to the same cluster as the point n.
% The cluster is defined by C

% n = kk

p = find(C==n);
assert(numel(p)==1);

pstart = p;
if pstart > 0 && C(pstart)~=0
    pstart = pstart -1;
end
pstart = pstart+1;

pend = p;
while pend <= size(C,1) && C(pend)>0
    pend = pend +1;
end    
pend=pend-1;

CP = C(pstart:pend);

end


