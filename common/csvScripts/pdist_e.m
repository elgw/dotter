function D = pdist_e(A, B)


for kk=1:size(A,1)
    for ll = 1:size(B,1)
        D(kk,ll) = norm(A(kk,:)-B(ll,:));
    end
end
