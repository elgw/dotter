% Extract consequtive dots from alleles and do whatever can be done with
% them

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

s.normalize = 0; % Normalize by DAPI diameter

if s.normalize 
    normstring = 'n';
else
    normstring = 'd';
end

Chan = {'a594', 'tmr', 'gfp', 'cy5', 'cy7'};

% Define the names of the probes
probenames = [1 2 13 14 3 4 5 6 7 8 9 10 11 12];
cprobenames = num2cell(probenames);
for kk=1:numel(cprobenames)
    cprobenames{kk} = ['p' num2str(cprobenames{kk})];
end

D = cell(14,14); % summed distances
Dm = zeros(numel(probenames));
Ds = zeros(numel(probenames));
H = zeros(5,1);
PT = [];

res = [131.08, 131.08, 200];

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
jj = 0;
de = []; % Euclidean
dg = []; % Genomic

%% Read data from csv and calculate pairwise distances
files = dir('i*.csv');

nAllele = 0; % Number of current allele (only used counted).
    angles = [];
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
        
        if numel(P)>0 && size(P,1)<= numel(H)
            H(size(P,1)) = H(size(P,1))+1;
        end
        
        if numel(P(:,4))==numel(unique(P(:,4)))
            nAllele = nAllele+1;
            
            aCoord = cell2mat(P(:,6:8));
            aProbeNr = zeros(size(aCoord,1),1);
            for kk = 1:size(P,1)
                aProbeNr(kk) = chan2probe(find(strcmp(P{kk, 4}, Chan)==1));
                aCoord(kk,:) = aCoord(kk,:).*res;
            end
            
            % Order the dots
            sProbes = sort(chan2probe); % possible probes
            
 %           [~,ind] = sort(aChan);
  %          aChan = aChan(ind);
   %         aCoord = aCoord(ind);
            
            T=getTriplets(aProbeNr, aCoord, sProbes);
            
            for kk=1:numel(T)                         
                d1 = T{kk}.q-T{kk}.p; d1 = d1/norm(d1);
                d2 = T{kk}.r-T{kk}.q; d2 = d2/norm(d2);
                angles = [angles; T{kk}.probes acos(d1*d2')];
            end
        end
        P = getAllele(t, startPos);
    end
end

figure
subplot(3,3,1)
edges = linspace(0,pi, 10);
histogram(angles(:,4), edges)
ax = axis;
ax(1) = 0; ax(2) = pi;
axis(ax)
set(gca, 'XTick', [0, pi/2, pi])
set(gca, 'XTickLabel', {'0', '\pi/2', '\pi'})
title('All')
upaths = unique(angles(:,1));
for kk = 1:numel(upaths)
    subplot(3,3,kk+1)
    histogram(angles(angles(:,1)==upaths(kk), 4), edges)
    title(sprintf('%d-%d-%d', probenames(upaths(kk):upaths(kk)+2)))
    ax = axis;
    ax(1) = 0; ax(2) = pi;
    axis(ax)
    set(gca, 'XTick', [0, pi/2, pi])
    set(gca, 'XTickLabel', {'0', '\pi/2', '\pi'})
end
dprintpdf(sprintf('directions_%s.pdf', normstring))



