function V = blit(V, S, L)
% Blit S in V at L

d = size(S);

for kk = 1:size(L,1)
    if(min(L(:))>0)
        if sum( (L(kk,1:3)+d)<size(V))==3
    V(L(kk,1):L(kk,1)+d(1)-1, ...
      L(kk,2):L(kk,2)+d(2)-1, ... 
      L(kk,3):L(kk,3)+d(3)-1) = ...
      V(L(kk,1):L(kk,1)+d(1)-1, ...
      L(kk,2):L(kk,2)+d(2)-1, ... 
      L(kk,3):L(kk,3)+d(3)-1) + S;
        end
    end
end
end
