function dotCandidates_ut()

disp('-> dotCandidates')
s = dotCandidates('getDefaults', 'lambda', 600, 'voxelSize', [130,130,200]);
t = zeros(124,124,60);
t(14,15,16) = 1;
d = dotCandidates('image', t, 'settings', s);
assert(size(d,1)==1);
t(41,51,2) = 1;

disp(' - All combinations of ranking and detection methods in 3D')
for aa = 1:numel(s.localizationMethods)
    for bb = 1:numel(s.rankingMethods)
        s.localizationMethod = s.localizationMethods{aa};
        s.rankingMethod = s.rankingMethods{bb};
        d = dotCandidates('image', t, 'settings', s);
        assert(numel(d(:,4)>0) == 1); % The dot on plane 60 should be found
    end
end

t = sum(t,3);
disp(' - All combinations of ranking and detection methods in 2D')
for aa = 1:numel(s.localizationMethods)
    for bb = 1:numel(s.rankingMethods)
        s.localizationMethod = s.localizationMethods{aa};
        s.rankingMethod = s.rankingMethods{bb};
        d = dotCandidates('image', t, 'settings', s);
        assert(numel(d(:,4)>0) == 2); % Both dots should be found
    end
end



%% Test/figure out sigma vs dot size

if 1
    disp(' - not running: Detection vs sigma')
else
    
    s = dotCandidates('getDefaults', 'lambda', 600, 'voxelSize', [130,130,200]);
    s.ranking = 'gaussian';
    dotSigmas = linspace(.75,2.5,5);
    sigmas = linspace(0.75,3,20);
    
    
    figure('Name', s.ranking);
    for ss = 1:numel(dotSigmas)
        dotSigma = dotSigmas(ss);
        subplot(numel(dotSigmas), 1, ss);
        
        r = 15;
        for kk = 1:numel(sigmas)
            
            sigma = sigmas(kk);
            s.sigmadog = sigma*[1,1,1];
            I = df_gaussianInt3([0,0,0], dotSigma*[1,1,1], r);
            I = I/sum(I(:));
            D = dotCandidates(I, s);
            v(kk) = D(1,4);
        end
        
        plot(sigmas, v)
        ax = axis;
        hold on
        plot([dotSigma, dotSigma], ax(3:4), 'k');
        xlabel('Detection sigma');
        ylabel('Strength')
        legend({sprintf('Dot sigma: %f', dotSigma')})
    end
    
    dprintpdf(sprintf('detection_%s.pdf',s.ranking), 'h', 30, 'w', 10)
    
end

end