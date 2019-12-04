%% Figure out what cut-off distance that gives the highest correlation to
% HiC
%
% Requires: D, cell structure with pairwise distances

normstring = '';

hiC = [ ...
    0   73	150	66	55	14	5	7	20	14	14	6	2	1
    0   0   402	189	38	52	34	23	9	9	2	1	1	0
    0   0   0   959	121	42	21	17	14	6	6	1	5	2
    0   0   0   0   136	98	36	33	9	8	1	4	2	0
    0   0   0   0   0   93	23	38	33	21	3	3	1	0
    0   0   0   0   0   0   210	176	30	14	4	0	0	0
    0   0   0   0   0   0   0   2296 29	23	1	0	3	1
    0   0   0   0   0   0   0   0   40	30	1	4	0	0
    0   0   0   0   0   0   0   0   0   47	32	13	9	2
    0   0   0   0   0   0   0   0   0   0   68	6	7	2
    0   0   0   0   0   0   0   0   0   0   0   61	48	3
    0   0   0   0   0   0   0   0   0   0   0   0   337	5
    0   0   0   0   0   0   0   0   0   0   0   0   0   17
    0   0   0   0   0   0   0   0   0   0   0   0   0   0];


%fish = D;
%hicd = hiC;
% Mean distance
Dm = nan(size(D))
for kk = 1:numel(D)
    Dm(kk) = mean(D{kk});
end

cutoffs = linspace(0,1000, 2000);
correlsS = nan(numel(cutoffs),1);
correlsP = nan(numel(cutoffs),1);
C = zeros(size(D));

for cc = 1:numel(cutoffs)
    cutoff = cutoffs(cc);
    for kk = 1:size(D,1)
        for ll = 1:size(D,2)
            C(kk,ll) = sum(D{kk,ll}<cutoff)/numel(D{kk,ll});
        end
    end
    fish = C(~isnan(Dm));
    hicd = hiC(~isnan(Dm)');
    correlsS(cc) = corr(fish, hicd, 'type', 'spearman');
    correlsP(cc) = corr(fish, hicd);
end

figure
plot(cutoffs, correlsS, 'k')
hold on
%plot(cutoffs, correlsP, 'r', 'LineWidth', 1.2)
%legend({'Spearman', 'Pearson'})
%legend({'Spearman'})
xlabel('distance threshold [nm]')
ylabel('correlation to HiC (Spearman)')
ax = axis;
ax(1)=100;
ax(2)=600;
%ax(3)=-.35; ax(4)=.15;
grid on
axis(ax)
dprintpdf(sprintf('FISH_distance_-_HiC_%s.pdf', normstring))

pause

%% Figure out what soft cut-off distance that gives the highest correlation to
% HiC

maxdist = 10000;
cutoffs = linspace(0,1000, 2000);
correlsS = nan(numel(cutoffs),1);
correlsP = nan(numel(cutoffs),1);
C = zeros(size(D));
for cc = 1:numel(cutoffs)
    cutoff = cutoffs(cc);
    for kk = 1:size(D,1)
        for ll = 1:size(D,2)
            data = D{kk,ll};
            if numel(data)>0
                data = data(data<maxdist);
                erffun = 1-erf((linspace(0, max(data), ceil(max(data)))-cutoff)/12); % 25 ~ 100 nm wide
                const = ones(ceil(max(data)), 1);
                C(kk,ll) = sum(interp1(erffun, data))/sum(interp1(const, data));
            end
        end
    end
    fish = C(~isnan(W));
    correlsS(cc) = corr(fish, hicd, 'type', 'spearman');
end

figure
plot(cutoffs, correlsS, 'k')
hold on
%plot(cutoffs, correlsP, 'r', 'LineWidth', 1.2)
%legend({'Spearman', 'Pearson'})
%legend({'Spearman'})
xlabel('distance threshold [nm]')
ylabel('correlation to HiC (Spearman)')
ax = axis;
ax(1)=100;
ax(2)=400;
%ax(3)=-.45; ax(4)=.15;
grid on
axis(ax)
dprintpdf(sprintf('FISH_soft_distance_-_HiC_%s.pdf', normstring))

