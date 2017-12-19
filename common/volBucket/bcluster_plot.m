function df_bcluster_plot(C, X)
%% function df_bcluster_plot(C, P)
%  Plots clustering result of df_bcluster
%
%  Usage:
%  C = df_bcluster(X, d);
%  df_bcluster_plot(C, X);

hold on
kk=1;
while(kk < numel(C))
    kk0 = kk;
    while(C(kk)>0 && kk<numel(C))
        kk = kk+1;
    end
    
    if (kk>kk0)
        P=C(kk0:kk-1);
        xx = X(P, 2);
        yy = X(P, 1);
        zz = X(P, 3);
        mx = mean(xx); my = mean(yy); mz=mean(zz);
        %plot(mx, my, 'ro')
        for ll = 1:size(xx,1)
            %plot3([xx(1), xx(ll)],[yy(1), yy(ll)],[zz(1), zz(ll)]);
            plot([mx, xx(ll)],[my, yy(ll)], 'r');
        end
    end
    kk = kk+1;
end
