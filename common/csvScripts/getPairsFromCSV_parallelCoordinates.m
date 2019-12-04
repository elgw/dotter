% This script is for iJC202 -- iJC207
% To be run in the folder with all csv files
% Loads full alleles with all 5 dots

close all
clear all

%% Settings
s.normalize = 0; % Normalize by DAPI diameter
res = [131.08, 131.08, 200]; % Resolution in x, y, z
cmap = jet(100);

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


%% Prepare some outputs
D = cell(14,14); % summed distances
A = {};
Dm = zeros(numel(probenames));
Ds = zeros(numel(probenames));
H = zeros(5,1);
PT = [];

jj = 0;


%% Read data from csv and calculate pairwise distances
files = dir('i*.csv');

nAllele = 0; % Number of current allele (only used counted).
for ff = 1:numel(files)
    fprintf('Loading %s\n', files(ff).name);
    
    switch files(ff).name(6)
        case '2'
            chan2probe=[2 5 1 3 4];
            dset = 1;
        case '3'
            chan2probe=[2 5 1 3 4];
            dset = 1;
        case '4'
            chan2probe=[10 9 6 7 8];
            dset = 2;
        case '5'
            chan2probe=[10 9 6 7 8];
            dset = 2;
        case '6'
            chan2probe=[14 13 NaN 11 12];
            dset = 3;
        case '7'
            chan2probe=[14 13 NaN 11 12];
            dset = 3;
    end
    
    t = readtable(files(ff).name);
    t = table2cell(t);
    
    startPos = 1;
    P = getAllele(t, startPos);
    
    while numel(P)>0
        startPos = startPos+size(P,1);
        
        if numel(P)>0 && size(P,1)<= numel(H)
            H(size(P,1)) = H(size(P,1))+1;
        end
        % calculate all pairwise distances
        
        % If all dots are there
        if numel(P(:,4))==numel(unique(P(:,4)))
            if numel(P(:,4))==numel(chan2probe)
                
                nAllele = nAllele+1;
                jj = 0;
                de = []; % Euclidean
                dg = []; % Genomic
                DA = [];
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
                        DA(qn,pn) = d;
                        DA(pn,qn) = d;
                        
                        D{qn, pn} = [D{qn, pn}; d];
                        jj = jj+1;
                        de(jj)=d;
                        dG = abs(probePos(qName)-probePos(pName));
                        dg(jj)=dG;
                        
                        if qn==pn+1
                            conDist(nAllele, pn) = d;
                        end
                        
                        PT = [PT; [pName qName d]];
                    end
                end
                A{nAllele} = DA;
                
                if dset==2
                    if numel(de)>1
                        figure(1)
                        hold on
                        [~, order] = sort(dg);
                        dg = dg(order); de = de(order);
                        c = interp1(dg, de, 7*10^5); % 3, 7, 4.5
                        plot(dg, de, 'Color', cmap(ceil(min(c*size(cmap,1)/2000,size(cmap,1))), :) )
                        plot(dg, de, 'ko')
                        xlabel('Genomic distance')
                        ylabel('Physical distance')
                        if dset==1
                            title('Pairs from probe 1, 2, 13, 14, 3');
                        end
                        if dset==2
                            title('Pairs from probe 4, 5, 6, 7, 8');
                        end
                        if dset==3
                            title('Pairs from probe 9, 10, 11, 12');
                        end
                    end
                end
                
            end
        end
            P = getAllele(t, startPos);        
    end
end


%% MDS of distances between the alleles
dA = zeros(numel(A), numel(A));
for kk = 1:numel(A)
    for ll = 1:numel(A)
        dA(kk,ll) = sqrt(sum(sum((A{kk}-A{ll}).^2)));
    end
end

s = statset;
s.MaxIter = 2000;
[Y,STRESS,DISPARITIES] = mdscale(dA,3, 'Options', s);
figure,
plot3(Y(:,1), Y(:,2), Y(:,3), 'o');
xlabel('D1')
ylabel('D2')
zlabel('D3')
title('MDS of alleles')
dprintpdf('mds3.pdf')

%% Length of the regions
Lt = zeros(numel(A),1); % Total length
Le = zeros(numel(A),1); % End to end length
for kk = 1:numel(A)
    Lt(kk) = sum(diag(A{kk},1));
    Le(kk) = A{kk}(min(chan2probe),max(chan2probe));
end

figure,
[y,d] = kdeParzen(Lt);
plot(d,y);
hold on
plot(Lt, 0*Lt, 'ko')
xlabel('Total Length')
ylabel('Density')
title(num2str(unique(chan2probe(chan2probe>0))))

figure,
plot(Lt, Le, 'ko')
xlabel('Total Length')
ylabel('End to End Length')
title(num2str(unique(chan2probe(chan2probe>0))))
dprintpdf('lengths.pdf');
