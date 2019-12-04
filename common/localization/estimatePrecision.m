%% Estimate the localization precision by comparing pairwise distances in 
% two images, of the same dots, which are slighly shifted between the
% acquisitions

sample = 'iJC249_280216_002';
channel = 'a594';
channel = 'cy5';
channel = 'cy7';
channel = 'gfp';
channel = 'tmr';

I  = df_readTif(['/data/current_images/iJC249_280216_002/' channel '_001.tif']);
II = df_readTif(['/data/current_images/iJC249_280216_002/' channel '_002.tif']);

res = [131.08, 131.08, 200];

d1 = dotCandidates(I);
d2 = dotCandidates(II);

d1 = dotFitting(I, d1(1:250,1:3));
d2 = dotFitting(II, d2(1:250,1:3));

volumeSlide(I)
volumeSlide(II)

% Translate the data so that it will be easier to register the points

d2(:,2)=d2(:,2)-15;
d1(:,3)=d1(:,3)-mean(d1(:,3));
d2(:,3)=d2(:,3)-mean(d2(:,3));


figure,
plot(d1(1:250,1), d1(1:250,2), 'o')
hold on
plot(d2(1:250,1), d2(1:250,2), 'x')


P1 = zeros(size(d1,1), 3);
P2 = zeros(size(d1,1), 3);
nn = 0;
for kk = 1:250
    p = d1(kk,:);
    D = pointToSetDistance(p,d2);
    minD = min(D);
    if minD<2
        nn=nn+1;
        P1(nn,:)=p(1:3);
        P2(nn,:)=d2(D==minD, 1:3);
    end
end

P1 = P1(1:nn,:);
P2 = P2(1:nn,:);

figure,
plot(P1(:,1), P1(:,2), 'o')
hold on
plot(P2(:,1), P2(:,2), 'x')


pd1 = zeros(size(P1,1)^2/2+size(P1,1)/2,1);
pd2 = zeros(size(P1,1)^2/2+size(P1,1)/2,1);

%% Pairwise distances
dd = 0;
for kk=1:size(P1,1)
    for ll = kk+1:size(P1,1)
        dd = dd+1;
        pd1(dd) = sum(((P1(kk,:)-P1(ll,:)).*res).^2).^(1/2);
        pd2(dd) = sum(((P2(kk,:)-P2(ll,:)).*res).^2).^(1/2);
    end
end

%% Difference between pairwise distances
figure
histogram(abs(pd1-pd2))
meanerror=mean(abs(pd1-pd2));
xlabel('Errors (all distances), [nm]');
ylabel('# distances')
title([sample ', ' channel], 'interpreter', 'none')
legend({sprintf('mean: %.1f nm', meanerror)})
dprintpdf(['errors_full_' sample '_' channel '.pdf'])

figure
d0 = 100000;
histogram(abs(pd1(pd1<d0)-pd2(pd1<d0)))
meanerror=mean(abs(pd1(pd1<d0)-pd2(pd1<d0)));
xlabel('Errors (up to 10 um), [nm]');
ylabel('# distances')
title([sample ', ' channel], 'interpreter', 'none')
legend({sprintf('mean: %.1f nm', meanerror)})
dprintpdf(['errors_region_' sample '_' channel '.pdf'])

