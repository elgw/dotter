function df_bcluster_ut()
% bcluster(Dots, distance)
%
% dots is a [Nx3] matrix
% distance is a double
%

disp('--> Testing df_bcluster')
% mex CFLAGS='$CFLAGS -std=c99' COPTIMFLAGS='-DNDEBUG -O3' df_bcluster.c volBucket.c

disp('  Random input ... ')
N = 100000;
verbosive = 0;

for r = linspace(.5, 2, 5)
    X = 124*rand(N,3);
    tic
    df_bcluster(X, r);
    t = toc;
end
clear X

fprintf(' Realistic case with %d dots took %.2f seconds \n', size(N,1), t);

disp(' Does not crash with no inputs')
error = 0;
try
    df_bcluster()
catch e
    error = 1;
end
assert(error == 1);

disp('  Does not accept coordinate lists with wrong dimensions')
error = 0;
try
    df_bcluster([0,0,0,0],1)
catch e
    error =1;
end
assert(error ==1);

error = 0;
try
    df_bcluster([0,0],1)
catch e
    error =1;
end
assert(error ==1);

error = 0;
try
    df_bcluster(0,1)
catch e
    error =1;
end
assert(error ==1);

error = 0;
try
    df_bcluster([],1)
catch e
    error =1;
end
assert(error ==1);

error = 0;
try
    df_bcluster([[1,2,3], [3,4,5]], 1);
catch e
    error =1;
end
assert(error ==1);


disp('  Only one point')
c = df_bcluster([0,0,0],1.1);
assert(c==0)

disp('  Two separated points')
c = df_bcluster([[1,2,3]; [3,4,5]], 1);
assert(c==0);

disp('  Two clustered points')
c = df_bcluster([[1,2,3]; [3,4,5]], 10);
assert(sum(c==[1;2])==2)

if(0)
    disp('  Testing a data set that caused a crash previously')
    load bclustertest.mat
    c = df_bcluster(D, 1);
    assert(sum(c==0) == 2);
end

if verbosive
    r=4;
    
    N = 1200;
    X = 124*rand(N,2);
    %theta = linspace(0, 2*pi, 100)';
    %X(:,1) = 500 + 40*sin(theta);
    %X(:,2) = 500 + 40*cos(theta);
    X(:,3)=1; %51*rand(N,1);
    
    if 0
        for kk=1:100
            for ll=1:100
                D2(kk,ll)= sum((X(kk,:)-X(ll,:)).^2);
            end
        end
    end
    
    %figure,
    %imagesc(D2.^(1/2))
    
    
    tic
    C = df_bcluster(X, r);
    t1 = toc
    
    
    %tic
    %C2 = cluster(linkage(X, 'single'), 'cutoff', r);
    %t2 = toc
    
    
    figure,
    subplot('position', [0,0,1,1])
    %plot3(X(:,2), X(:,1), X(:,3), '.')
    plot(X(:,2), X(:,1), 'k.')
    
    axis equal
    %view(3)
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
    
    
    axis off
    set(gcf, 'color', 'black')
end

disp(' -- done');
end