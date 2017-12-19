function [  ] = cluster3e_show( P, C )
%
%  

nView = 3;

%plot3(P(:,1), P(:,2), P(:,3), 'wo', 'MarkerFaceColor', 'r')
hold on
%plot3(P(1,1), P(1,2), P(1,3), 'rx');
for kk = 1:max(C(:))
    mC = mean(P(C==kk,:),1);
    ind = find(C==kk);
    disp('')
    for ll = 1:numel(ind)
       % fprintf('%d\n', ind(ll))
        plot3([mC(1), P(ind(ll),1)], ...
            [mC(2), P(ind(ll),2)], ...
            [mC(3), P(ind(ll),3)], 'r:', 'LineWidth', 1);
    end
end
view(nView)
axis equal

end

