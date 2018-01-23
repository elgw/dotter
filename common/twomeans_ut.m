disp('Testing twomeans')

doPlot = 0;

if(doPlot)
    P = randn(70,3);
    P = [P; randn(70,3)+repmat(2*[1,1,1], [70,1])];
    P = P(randperm(140), :);
    P(:,3) = 0;
    [L1, m] = twomeans(P, 2);
    
    s.maxDots = 5;
    s.maxDist = 1;
    L2 = twomeans_classify(m, P, s);
    
    
    
    if sum(abs(L1-L2)) > sum(abs(L1-(mod(5*L2,3))))
        L2 = mod(5*L2, 3);
    end
    
    [L1, L2]
    
    figure
    plot(P(L1==1, 1), P(L1==1, 2), 'ro')
    hold on
    plot(P(L1==2, 1), P(L1==2, 2), 'rs')
    
    plot(P(L2==1, 1), P(L2==1, 2), 'ko', 'MarkerSize', 15)
    hold on
    plot(P(L2==2, 1), P(L2==2, 2), 'ks', 'MarkerSize', 15)
    
    for kk = 1:size(m,1)
        plot(m(kk,1), m(kk,2), 'kh', 'MarkerFaceColor', 'g');
    end
    
    axis equal
end

D = rand(71,3);
for kk = 1:50
    [P, m] = twomeans(D,kk);
    assert(min(P)==1)
    assert(max(P)==kk)
    assert(size(m,1) == kk)
end
