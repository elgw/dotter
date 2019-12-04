function sh = shortestEuclideanDistSets(A, B)
% Reurns the shortest distance between each dot in A and all dots in B
% d(kk) = min ||A(kk,:) - B(ll,:)||_2, for all ll

assert(size(A,2)==size(B,2));

sh = zeros(size(A,1),1);
for kk = 1:size(A,1) % For each point, find closest point from the other channel
    d = (repmat(A(kk,:), [size(B,1),1])-B(:,:));
    d = d.^2;
    s = sum(d,2);
    s = s.^(1/2);
    sh(kk)=min(s);    
end

