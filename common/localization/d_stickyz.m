function D2 = d_stickyz(D2, D1, deltaz)
% z-values in the third column

DZ = (D1(:,3)-D2(:,3)).^2; % squared distance
ZP = DZ>deltaz^2;
D2(ZP,3)=D1(ZP,3);