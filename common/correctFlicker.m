function V=correctFlicker(V)

figure,
subplot(1,2,1)
zMean = mean(mean(V,1),2);
zMean = squeeze(zMean);
plot(zMean)
xlabel('z')


zFlick = zMean - gsmooth(zMean, 1, 'normalized');

zFlick = (zMean+zFlick)./zMean;

subplot(1,2,2);
plot(zFlick, 'r')

xlabel('z')
ylabel('Estimated flicker coefficient')


for kk = 1:size(V,3)
    V(:,:,kk) = V(:,:,kk)*zFlick(kk);
end

subplot(1,2,1)
hold on
plot(zMean./zFlick, 'r')
legend({'Before', 'After'})

end
