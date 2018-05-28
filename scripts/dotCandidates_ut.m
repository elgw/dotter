function dotCandidates_ut()

disp('-> dotCandidates')
s = dotCandidates('getDefaults', 'lambda', 600, 'voxelSize', [130,130,200]);
t = zeros(124,124,60);
t(14,15,16) = 1;
d = dotCandidates('image', t, 'settings', s);
assert(size(d,1)==1);
t(14,15,2) = 1;



%% Test/figure out sigma vs dot size

if 0
    
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

dprintpdf('detection_gaussian.pdf', 'h', 30, 'w', 10)

end

end