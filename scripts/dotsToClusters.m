function cdots = dotsToClusters(dots, cluster1, cluster2, distance)
%% function cdots = dotsToClusters(dots, cluster1, cluster2)

cdots = zeros(size(dots,1),1);
for kk = 1:size(dots,1)
    if distance22([dots(kk,1:2); cluster1])<distance
        cdots(kk)=1;
    end
    if distance22([dots(kk,1:2); cluster2])<distance
        cdots(kk)=2;
    end
end