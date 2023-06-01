function IAD = df_m_nucpDallelesInter(varargin)
% Distance between cluster 1 and 2 in each nuclei for selected channel(s)
%
% Geometric means are used to define the location of the clusters,
% hence the distance between these are returned

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        t.string = 'ClusterP: Distance between centroids [NM]';
        t.selChan = 1;
        t.features = 'CP';
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

IAD = zeros(numel(N),1);


for kk = 1:numel(N)
    A1 = [];
    A2 = [];

    for cc = chan
        d1 = N{kk}.clusters{1}.dots{cc};
        A1 = [A1; d1];
    end
    for cc = chan
        d2 = N{kk}.clusters{2}.dots{cc};
        A2 = [A2; d2];
    end

    if size(A1,1) == 0 || size(A2,1) == 0
        if(size(A1,1) ==0)
            fprintf('No dots in cluster 1 for %s\n', channelsS)
        end
        if(size(A2,1) ==0)
            fprintf('No dots in cluster 2 for %s\n', channelsS)
        end
        IAD(kk) = nan;
    else
        if kk==27
            %keyboard
        end
        mA1 = mean(A1(:,1:3),1);
        mA2 = mean(A2(:,1:3),1);
        whos

        IAD(kk) = norm(d.resolution.*(mA1-mA2));
    end

end

IAD = IAD';
IAD = IAD(:);

end
