function IAD = df_m_cluster_min_dist(varargin)
% For each cluster
%  For each point, kk
%   Calculate the distance to the closest point, dm_kk
%  Return the mean of all dm_kk


if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        t.string = 'Cluster: compaction, mean smallest distance';
        t.selChan = 1;
        t.features = 'C';
        IAD = t;
        return
    end
end

M = varargin{1};
N = varargin{2};
chan = varargin{3};

d.resolution = M{1}.voxelSize;

disp(M{1}.channels(chan))

% Strings for the channels
channelsS = '';

for kk = 1:numel(chan)
    channelsS = [channelsS '-' M{1}.channels{chan(kk)}];
end

IAD = [];

for kk = 1:numel(N)
    for ll = 1:numel(N{kk}.clusters)
        A = [];
        for cc = chan
            D = N{kk}.clusters{ll}.dots{cc};
            A = [A; D];
        end

        if size(A,1) == 0
            fprintf('No dots in %s\n', channelsS)
            md = NaN;
        else
            for cc = 1:3
                A(:,cc) = A(:,cc)*d.resolution(cc);
            end

            md = pdist(A(:,1:3));
            md = squareform(md);
            md(1:(size(md,1)+1):end) = inf;
            md = mean(min(md));

        end
        IAD = [IAD; md];
    end
end

end
