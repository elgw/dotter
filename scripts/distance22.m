function d = distance22(P)
%% function d = distance22(P)
% euclidean distance between P(1,:) and P(2,:)

dd = P(1,:)-P(2,:);
dd = dd.^2;
dd = sum(dd);
d = sqrt(dd);