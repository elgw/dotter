function ggaussian_ut()

g1 = ggaussian(15, 1);

disp('  Normalization');
assert(abs(1-sum(abs(g1)))<1e-9)
g2 = fspecial('gaussian', [15,1],1);
D = -7:7;
g3 = normpdf(D, 0, 1);
oversampling = 100;
g10 = normpdf(linspace(-7.5, 7.5, 15*oversampling));
g4 = imresize(g10, 1/10); 
g4 = g4/sum(g4);
g5 = reshape(g10, [oversampling,15]);
g5 = sum(g5,1);
g5 = g5/sum(g5);

disp('  Vs alternative way to calculate')
assert(sum(abs(g1-g5))<1e-3)

if(0)
    figure,
    plot(g1, 'k')
    hold on
    plot(g2, '--g')
    plot(g3, ':r')
    plot(g5, 'ro')
    legend({'ggaussian', 'fspecial', 'normpdf', 'resized normpdf'})
    dprintpdf('gaussians.pdf')
end

end