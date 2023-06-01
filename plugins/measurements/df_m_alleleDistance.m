function D = df_m_alleleDistance(varargin)
% For each nuclei
%  For each cluster
%   Grab all pairwise distances

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        t.string = 'Cluster: mean intercluster distance';
        t.selChan = 1;
        t.features = 'C';
        D = t;
        return
    end
end

M = varargin{1};
N = varargin{2};
chan = varargin{3};

if ~isfield(M{1}, 'voxelSize')
    warning('Pixel size not specified!')
    res = [130,130,300];
else
    res = M{1}.voxelSize;
end

D = [];

for nn = 1:numel(N)

    for aa = 1:numel(N{nn}.clusters)
        dots = [];

        for cc = chan
            cdots = N{nn}.clusters{aa}.dots{cc};
            dots = [dots ; cdots];
        end

        if size(dots,1)>1
            % Convert pixels to metric distance
            dots(:,1)=dots(:,1)*res(1);
            dots(:,2)=dots(:,2)*res(2);
            dots(:,3)=dots(:,3)*res(3);
            % Distance matrix between dots
            DM = pdist(dots(:,1:3), 'euclidean');

            % All pairwise distances
            D = [D; mean(DM(:))];
        else
            D = [D; NaN];
        end

    end


end
