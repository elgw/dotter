

%% Count the number of pairs
Dm = zeros(size(D));
Dn = Dm; Ds = Dm; Dmed = Dm;

for kk=1:size(Dm,1)
    for ll=1:size(Dm,2)
        Dm(kk,ll) = mean(D{kk,ll});
        Ds(kk,ll) = std(D{kk,ll});
        Dmed(kk,ll) = median(D{kk,ll});
        Dn(kk,ll) = numel(D{kk,ll});
    end
end

npairs = sum(Dn(:))
nPairTypes = sum(sum(Dn>0))


%% Fit weibul distributions and put the mode in W
W = nan(size(D));
for kk = 1:size(D,1)
    for ll = 1:size(D,2)
        data = D{kk,ll}
        data = data(data>0);
        if numel(data)>0
            [parmhat, parmci] = wblfit(data);
            lambda = parmhat(1);
            k = parmhat(2);
            % Mode:
            W(kk,ll) = lambda*((k-1)/k)^(1/k);
            
            if 0
                figure,
                [hy, hx] = hist(data);
                hist(data)
                hold on
                dom = linspace(0,max(data));
                y = wblpdf(dom, lambda, k);
                plot(dom, y/max(y)*max(hy))
            end
        end
    end
end


%% HiC (log) - Fish (Weibul)
fish = W';
%fish = Dm';
fish = fish(~isnan(W'));
hicd = hiC(~isnan(W'));

figure,
plot(fish, log(hicd), 'o')
xlabel('FISH (Weibul mode)')
ylabel('log(HiC)')
title( sprintf('CR: %f', ...
    corr(fish, log(hicd), 'type', 'spearman') ));
dprintpdf(sprintf('logHiC-Weibul_%s.pdf', normstring))




%% Do a non-parametric fitting with a KDE and put the mode in MO
MO = nan(size(D));
for kk = 1:size(D,1)
    for ll = 1:size(D,2)
        data = D{kk,ll};
        if numel(data)>0
            [K, Dom] = kdeParzen(data, [], [0, max(data)], []);
            MO(kk,ll) = Dom(find(K==max(K)));
        end
    end
end


Dm
Ds

%% Plot genomic vs euclidean distances
figure,
plot(dg, de, 'o')
xlabel('Genomic distance [nm]')
ylabel('Physical distance [nm]')
dprintpdf(sprintf('ge_-_ph_%s.pdf', normstring));

%% Figure out what exponent that explains the data best

figure(67)
plot(dg, de, 'o')
hold on
ax = axis;

dg0 = 0; dg1 = max(dg); % all
%dg0 = 8*10^5; dg1 = max(dg); % end-short
%dg0 = 4.5*10^5; dg1 = max(dg); % end-wide
%dg0 = 1.5*10^5; dg1 = 4.5*10^5; % mid
%dg0 = 0; dg1 = 6*10^4; % first

des = de(dg>dg0 & dg<dg1);
dgs = dg(dg>dg0 & dg<dg1);

exponents = linspace(0,1,1000);
ss2 = nan(size(exponents));
for kk = 1:numel(exponents)
    k0(kk) = (dgs.^exponents(kk))'\des';
    ss2(kk) = sum((des-k0(kk)*dgs.^exponents(kk)).^2);
end

figure,
subplot(1,2,1)
plot(exponents, ss2)
xlabel('Exponent')
ylabel('sum of squares of residuals')
title(sprintf('dg: %f to %f', dg0, dg1));

figure(67)
ind = find(ss2==min(ss2));
dom = linspace(dg0, dg1);
plot(dom, k0(ind)*dom.^exponents(ind), 'r', 'LineWidth', 2);
axis(ax);



figure,
hold on
k0 = (dg.^(1/2))'\de';
k1 = (dg.^(1/3))'\de';
dom = linspace(0,1.05*max(dg), 1000);
plot(dom, k0*dom.^(1/2),'g', 'LineWidth', 1.25)
plot(dom, k0*dom.^(1/2),'--r', 'LineWidth', 1.25)
plot(dom, k1*dom.^(1/3),':b', 'LineWidth', 1.25)
legend({'Random coil, d^{1/2}', 'Eq. glob., d^{1/2}', 'Frac. glob., d^{1/3}'})

boxplot(de, dg, 'positions', unique(dg))
ax = axis;
ax(1)=0;
axis(ax)
set(gca, 'XTick', linspace(0, max(dom), 5));
set(gca, 'XTickLabelMode', 'auto')
xlabel('Genomic distance [nm]')
ylabel('Physical distance [nm]')
title('End to end distance')
dprintpdf(sprintf('end-to-end_%s.pdf', normstring));

figure,
%[LAMBDAHAT, LAMBDACI]=poissfit([dg dg]);
%[MUHAT,SIGMAHAT]=normfit([dg dg])
hold on
dom = linspace(0,max(dg), 1000);
%fun = normpdf(dom, MUHAT, SIGMAHAT);
%fun = poisspdf(dom, LAMBDAHAT); % Zero!
plot(dom, dom.^(1/2),'r')

figure,
plot(dg, de./dg, 'o')
xlabel('Genomic distance [nm]');
ylabel('Physical distance/Genomic distance [-]');
hold on
%plot([0, max(dg)], [1,1]);
dprintpdf(sprintf('ge_-_ph-ge_%s.pdf', normstring));


%% Write to disk
if 0
    % All pairs
    PTx = num2cell(PT);
    PTx = cell2table(PTx);
    PTx.Properties.VariableNames = {'Probe_A', 'Probe_B', 'N_distance_nm'};
    disp('Writing to ../pairsNorm_X.csv');
    writetable(PTx, sprintf('../pairs_%s.csv', normstring));
    
    % Mean distance matrix
    Dmx = num2cell(Dm);
    Dmx = cell2table(Dmx);
    Dmx.Properties.VariableNames = cprobenames;
    writetable(Dmx, sprintf('../meanDist_%s.csv', normstring));
end

%% Plot the data in D
%plotPairs

%% Correlation between consequitive distances?
conDist1 = conDist(sum(conDist(:,1:4),2)>0,1:4);
conDist2 = conDist(sum(conDist(:,6:9),2)>0,6:9);
conDist3 = conDist(sum(conDist(:,11:13),2)>0,11:13);

if conDistNorm == 1
    condistnormstring = 'normg';
else
    condistnormstring = 'none';
end

if numel(conDist1)>0
    figure
    [S,AX,BigAx,H,HAx]=plotmatrix(conDist1);
    title(BigAx, 'Probe 1-2, 2-13, 13-14, 14-3')
    corr(conDist1)
    ma = max(conDist1(:));
    for kk = 1:numel(AX)
        axis(AX(kk), [0, ma, 0, ma]);
    end
    dprintpdf(sprintf('conDist1_%s_%s.pdf', normstring, condistnormstring))
end

if numel(conDist2)>0
    figure
    [S,AX,BigAx,H,HAx]=plotmatrix(conDist2);
    title(BigAx, 'Probe 4-5, 5-6, 6-7, 7-8')
    corr(conDist2)
    ma = max(conDist2(:));
    for kk = 1:numel(AX)
        axis(AX(kk), [0, ma, 0, ma]);
    end
    dprintpdf(sprintf('conDist2_%s_%s.pdf', normstring, condistnormstring))
end

if numel(conDist3)>0
    figure
    [S,AX,BigAx,H,HAx]=plotmatrix(conDist3);
    title(BigAx, 'Probe 9-10, 10-11, 11-12')
    corr(conDist3)
    ma = max(conDist3(:));
    for kk = 1:numel(AX)
        axis(AX(kk), [0, ma, 0, ma]);
    end
    dprintpdf(sprintf('conDist3_%s_%s.pdf', normstring, condistnormstring))
end


mofish = MO';
%fish = Dm';
mofish = mofish(~isnan(MO'));
hicd = hiC(~isnan(MO'));

figure,
plot(mofish, log(hicd), 'o')
xlabel('FISH (KDE mode)')
ylabel('log(HiC)')
title( sprintf('CR: %f', ...
    corr(mofish, log(hicd), 'type', 'spearman') ));
dprintpdf(sprintf('logHiC-Mode_%s.pdf', normstring))



%% HiC (log) - Fish (Gauss)
fish = Dm';
fish = fish(~isnan(W'));
hicd = hiC(~isnan(W'));

figure,
plot(fish, log(hicd), 'o')
xlabel('FISH (Mean)')
ylabel('log(HiC)')
title( sprintf('CR: %f', ...
    corr(fish, log(hicd), 'type', 'spearman') ));
dprintpdf(sprintf('logHiC-Mean_s.pdf', normstring));

%% HiC (log) - Fish (Median)
fish = Dmed';
fish = fish(~isnan(W'));
hicd = hiC(~isnan(W'));

figure,
plot(fish, log(hicd), 'o')
xlabel('FISH (Median)')
ylabel('HiC')
title( sprintf('CR: %f', ...
    corr(fish, hicd, 'type', 'spearman') ));
dprintpdf(sprintf('logHiC-Median_%s.pdf', normstring))



% plotPairs