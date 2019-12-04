function Q=showDotsInCluster(P, C, d, varargin)

color = 'r';
show = 1;
for kk = 1:numel(varargin)
        if strcmp(varargin(kk), 'noshow')
            show = 0;
        end
    if strcmp(varargin(kk), 'color')
        color = varargin{kk+1};
    end
end


Q = [];

for kk = 1:size(P,1)
   p = P(kk,1:3);   
   for ll = 1:size(C,1)       
       if norm(p-C(ll,1:3))< d;           
           Q = [Q;p];
           break % only add a point once
       end       
   end
end

if show
if size(Q,1)>0
    plot3(Q(:,2), Q(:,1), Q(:,3), 'wo', 'MarkerFaceColor', color);
end
end

end