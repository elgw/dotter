% To be run in a folder with csv files
% Calculates per cell:
% the correlation between physical and genomic distances
% the correlation between physical distances and HiC data
% plots alleles and saves them in the alleles3d/ folder with correlation to
% HiC as filename


mkdir('alleles3d')

close all
clear all

%% Settings
s.normalize = 0; % Normalize by DAPI diameter

if s.normalize
    normstring = 'n';
else
    normstring = 'd';
end

res = [131.08, 131.08, 200]; % Resolution in x, y, z

%% Set up conversions between channel
% name and probe number and probe name

%      Chan   Probe  order/number
%             name
% Q1   AF594   2       2
% T7   TMR     3       5
% O72  GFP     1       1
% Q2   Cy5    13       3
% O71  Cy7    14       4

% Q1   AF594   8       10
% T7   TMR     7       9
% O72  GFP     4       6
% Q2   Cy5     5       7
% O71  Cy7     6       8

% Q1   AF594   12      14
% T7   TMR     11      13
% O72  GFP     -
% Q2   Cy5     9       11
% O71  Cy7     10      12

Chan = {'a594', 'tmr', 'gfp', 'cy5', 'cy7'};

% Define the names of the probes
probenames = [1 2 13 14 3 4 5 6 7 8 9 10 11 12];
cprobenames = num2cell(probenames);
for kk=1:numel(cprobenames)
    cprobenames{kk} = ['p' num2str(cprobenames{kk})];
end

%% Set up measurements of euclidean vs genomic distances
% Position along DNA
probePos = [26454882.5
    27015657
    28214887.5
    28695441.5
    29455632
    29520921.5
    30298116
    32804382
    33387551.5
    34556685.5
    35185039.5
    36167821
    27102949.5
    27747137];
probePos = probePos*0.34; % Conversion to nm

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


%% Prepare some outputs
Cf = []; % Correlation between genomic and physical per allele
Ch = []; % Correlation between physical and HiC per allele

PM = []; % Matrix of pairwise distances, one allele per row
jj = 0;

%% Read data from csv and calculate pairwise distances
files = dir('i*.csv');

nAllele = 0; % Number of current allele (only used counted).
for ff = 1:numel(files)
    fprintf('Loading %s\n', files(ff).name);
    
    switch files(ff).name(6)
        case '2'
            chan2probe=[2 5 1 3 4];
        case '3'
            chan2probe=[2 5 1 3 4];
        case '4'
            chan2probe=[10 9 6 7 8];
        case '5'
            chan2probe=[10 9 6 7 8];
        case '6'
            chan2probe=[14 13 NaN 11 12];
        case '7'
            chan2probe=[14 13 NaN 11 12];
    end
    
    t = readtable(files(ff).name);
    t = table2cell(t);
    
    startPos = 1;
    P = getAllele(t, startPos);
    
    while numel(P)>0
        startPos = startPos+size(P,1);
        
        % calculate all pairwise distances
        if numel(P(:,4))==numel(unique(P(:,4))) % assure only one per probe
            if size(P,1)==5
                DD = zeros(5,5);
                nAllele = nAllele+1;
                Dp = []; Dg = []; Dh = [];
                for kk = 1:size(P,1)
                    for ll = kk+1:size(P,1)
                        p = [P{kk, 5:7}].*res;
                        fp = find(strcmp(P{kk, 4}, Chan)==1);
                        pn = chan2probe(fp);
                        
                        q = [P{ll, 5:7}].*res;
                        fq = find(strcmp(P{ll, 4}, Chan)==1);
                        qn = chan2probe(fq);
                        
                        temp = [qn, pn];
                        qn = max(temp);
                        pn = min(temp);
                        
                        qName = probenames(qn);
                        pName = probenames(pn);
                        
                        if pName == qName
                            pause
                        end
                        
                        d = norm(p-q);
                        if s.normalize
                            d = d*116/(2*(P{1,20}/pi)^(1/2));
                        end
                        
                        DD(max(fp, fq)-min(chan2probe)+1, min(fp, fq)-min(chan2probe)+1)=d;
                        
                        Dp = [Dp; d];
                        dg = abs(probePos(qName)-probePos(pName));
                        Dg = [Dg; dg];
                        Dh = [Dh; hiC(pn, qn)];
                    end
                end
                
                jj = jj+1;
                PM(jj,:) = DD(tril(ones(size(DD))-eye(size(DD))==1))
                
                %% Correlate to HiC
                Cf = [Cf, corr(Dp, Dg, 'type', 'Spearman')];
                Ch = [Ch, corr(Dp, Dh, 'type', 'Spearman')];
                
                %% Visualize
                [X,Y,Z] = sphere(10);
                FColors = jet(5);
                
                PP = cell2mat(P(:,5:7)); % Not the CA-corrected
                %P = P-repmat(P(1,:), size(P,1),1);
                PP(:,1) = PP(:,1)*res(1);
                PP(:,2) = PP(:,2)*res(2);
                PP(:,3) = PP(:,3)*res(3);
                
                c = (P(:,4));
                for kk=1:numel(c)
                    c{kk} = find(strcmp(Chan, c{kk})==1);
                end
                c = cell2mat(c);
                
                %PP = PP-repmat(min(P)+(max(P)-min(P))/2, size(P,1),1);
                
                PT = PP;
                order = chan2probe(c);
                order = order-min(order)+1;
                figure(1)
                clf
                hold on
                % Plot the backbone
                for kk = 1:4
                    from = PT(order==kk, :);
                    to = PT(order==kk+1, :);
                    plot3([from(1), to(1)], [from(2), to(2)], [from(3), to(3)], 'k', 'LineWidth', 1.5);
                end
                
                % Plot the spheres
                r = 50;
                for kk = 1:size(PP,1)
                    su(kk)=surf('XData', r*X+PT(kk,1), 'YData', r*Y+PT(kk,2), 'ZData', r*Z+PT(kk,3), 'EdgeColor', 'None', 'FaceColor', FColors(c(kk),:));
                end
                
                view(3)
                axis equal
                grid on
                camproj('perspective')
                lighting phong
                camlight
                
                dprintpdf(sprintf('alleles3d/%.2f.pdf', Ch(end)));
                
            end
        end
        P = getAllele(t, startPos);
    end
    
    
end


[coeff,score,latent,tsquared,explained,mu] = pca(PM');

figure
plot(cumsum(explained), 'LineWidth', 1.2)
axis([1,10,0,100])
xlabel('Number of components')
ylabel('Total variance explained')
dprintpdf('pcaVariance.pdf')



T = ones(10,10);
%Q = 
%[Y, stress] = mdsscale(, 3);


figure,
plot3(score(:,1), score(:,2), score(:,3), 'o')
xlabel('c1')
ylabel('c2')
zlabel('c3')
hold on
text(score(:,1)+250, score(:,2)+250, score(:,3)+250, cellfun(@(x) num2str(x), num2cell(1:size(score,1)), 'UniformOutput', false))
dprintpdf('c2-c3.pdf')


figure,
histogram(Cf, linspace(-1,1, 12));
hold on
ax = axis;
plot(mean(Cf)*[1,1], [0, ax(4)], 'r', 'LineWidth', 2);
plot(corr(mean(PM,1)', Dg, 'type', 'Spearman')*[1,1],  [0, ax(4)], 'b', 'LineWidth', 2);
legend({'Histogram', 'Mean correlation', 'Mean shape correlation'}, 'location', 'northwest')
title('Physical to Genomic')
xlabel('rank correlation')
dprintpdf('genomic_physical_perAllele.pdf');

figure,
histogram(Ch, linspace(-1,1, 12));
hold on
ax = axis;
plot(mean(Ch)*[1,1], [0, ax(4)], 'r', 'LineWidth', 2);
plot(corr(mean(PM,1)', Dh, 'type', 'Spearman')*[1,1],  [0, ax(4)], 'b', 'LineWidth', 2);
legend({'Histogram', 'Mean correlation', 'Mean shape correlation'})

title('Physical to HiC')
xlabel('rank correlation')
dprintpdf('physical_HiC_perAllele.pdf');
