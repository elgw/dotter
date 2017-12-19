function N = df_ud_clusters_vhie(varargin)
% function N = df_ud_clusters_vhie(varargin)
% Hierarchical clustering
%

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        N.string = 'Hierarchical clustering';
        N.channels_base = 1;
        N.channels_apply = 1;
        N.param(1).String = 'Number of clusters';
        N.param(1).Value = 2;
        N.param(2).String = 'Outlier distance';
        N.param(2).Value = 10;
        N.param(3).String = 'Linkage';
        N.param(3).Value = 'single';
        return
    end
end

N = varargin{1};
s = varargin{2};

s.nClusters = str2num(s.param(1).Value);
s.outlierDistance = str2num(s.param(2).Value);
s.linkageMethod = s.param(3).Value;
s
% Load dots from base channels into nucDots
nucDots = [];
for cc = s.channels_base %numel(N{nn}.userDots)
    nucDots = [nucDots ; N.userDots{cc}];
end

if size(nucDots,1)>1
    
    d = pdist(nucDots(:,1:3));
    Z = linkage(d, s.linkageMethod);
    
    if s.nClusters == 0
        c = cluster(Z, ...%'maxclust', s.nClusters, ... % Maximum number of clusters
            'cutoff', s.outlierDistance, ... % Max distance between dots
            'criterion', 'distance');
    else
        c = cluster(Z, 'maxclust', s.nClusters);
    end           
    
    % Assign cluster number to all userDots based on the clusters
    for cc = s.channels_apply
        if size(N.userDots{cc},1)>0
            t = classify_dots(nucDots, c, N.userDots{cc}(:,1:3), s.outlierDistance);
            assert(size(t,1) == size(N.userDots{cc},1));
            N.userDotsLabels{cc} = t;
        end
    end
    
    % Note that label 0 is given dots that were excluded based
    % on their distance to the cluster means
end

end

function t = classify_dots(cDots, cLabels, D, outlierDistance)
% Classify dots depending on closest dot among the already classified

t = zeros(size(D,1),1);

for kk = 1:size(D,1)
    d = D(kk,:);
    dist = eudist(d, cDots(:,1:3));
    idx = find(dist==min(dist(:)));
    idx = idx(1);
    t(kk) = cLabels(idx);
end
t
end