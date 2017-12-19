function N = df_ud_clusters_xmeans(varargin)
% function N = df_ud_clusters_kmeans(varargin)
% K means clustering of the dots
%
% SETTINGS:
% baseChannels:    Channel(s) to find cluster means in
% channels:        Channels to apply the clustering to, the other channels
%                  are left untouched
% nClusters:       Number of clusters to look for
% outlierDistance: Max distance from cluster mean dots further away than 
%                  this will be assigned to label 0
%
% NOTES:
% A random initialization is used so this method can give different
% results for the same input data.
% Only nClusters = 1 or 2 is supported
% OutlierDistance given in pixels, this function does assume isotropic
% pixels (can obviously be improved on that point)

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        N.string = 'TODO: auto-means clustering';
        N.channels_base = 1;
        N.channels_apply = 1;
        N.param(1).String = 'Outlier distance';
        N.param(1).Value = 10;
        N.param(2).String = 'Threshold';
        N.param(2).Value = 10;                
        return
    end
end

N = varargin{1};
s = varargin{2};


s.outlierDistance = s.param(1).Value;
s.threshold = s.param(2).Value;

% Load dots from base channels into nucDots
nucDots = [];
for cc = s.channels_base %numel(N{nn}.userDots)
    nucDots = [nucDots ; N.userDots{cc}];
end

if size(nucDots,1)>1
    
    % Get cluster means based on nucDots
    [~, m] = twomeans(nucDots(:,1:3), s.nClusters);
    
    % Assign cluster number to all userDots based on the clusters
    for cc = s.channels_apply
        if size(N.userDots{cc},1)>0
            t = twomeans_classify(m, N.userDots{cc}(:,1:3), s.outlierDistance);
            assert(size(t,1) == size(N.userDots{cc},1));
            N.userDotsLabels{cc} = t;
        end
    end
    
    % Note that label 0 is given dots that were excluded based
    % on their distance to the cluster means
end

end