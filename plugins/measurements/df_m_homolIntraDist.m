function D = df_m_homolIntraDist(varargin)
% Returns all pairwise distances from all alleles

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        t.string = 'Cluster Inter Distances';
        t.selChan = 1;
        t.features = 'alone';
        D = t;
        return
    end
end

M = varargin{1};
N = varargin{2};
chan = varargin{3};
s = varargin{5};

if ~isfield(M{1}, 'voxelSize')
    warning('Pixel size not specified!')
    res = [130,130,300];
else
    res = M{1}.voxelSize;
end

D = [];
ND = []; % number of dots
MM = []; % Number of dots, Volume ; ...
for nn = 1:numel(N)

    for aa = 1:2
        dots = [];

        for cc = chan
            cdots = N{nn}.clusters{aa}.dots{cc};
            dots = [dots ; cdots];

        end

        if size(dots,1)>1
            for kk = 1:3
                dots(:,kk) = dots(:,kk)*res(kk);
            end

            D{end+1} = pdist(dots);
            ND = [size(dots,1), ND];

        end
    end

end


if numel(chan) == 1
    tString = M{1}.channels(chan(1));
else
    tString = '';
end

figure
hold on
for kk = 1:numel(ND)
    scatter(ND(kk)*ones(numel(D{kk}), 1), D{kk}, 'k');
    hold on
end
xlabel('Number of dots')
ylabel('Distances')
grid on
title(tString);

%% Group by number of dots and get mean value for each group
mea = nan(max(ND),1);
stdv = mea;
for kk = 1:max(ND)
   idx = find(ND==kk);
   T = [];
   for ll = 1:numel(idx)
       T = [T, D{idx}];
   end
   mea(kk) = mean(T(:));
   stdv(kk) = std(T(:));
end

figure
plot(1:max(ND), mea, 'k', 'LineWidth', 2)
hold on
plot(1:max(ND), mea+stdv, 'k--', 'LineWidth', 1.5)
hold on
plot(1:max(ND), mea-stdv, 'k--', 'LineWidth', 1.5)
xlabel('Number of dots')
ylabel('intra allele distance');
legend({'mean', 'mean\pmstd'});
grid on
title(tString);


end
