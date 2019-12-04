function N = df_ud_clusters_setConstant(varargin)
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
        N.string = 'Set to Label';
        N.channels_base = 0;
        N.channels_apply = 1;
        N.param(1).String = 'Label';
        N.param(1).Value = 2;
        return
    end
end

N = varargin{1};
s = varargin{2};

s.Label = str2num(s.param(1).Value);

% Load dots from base channels into nucDots
nucDots = [];
for cc = s.channels_base %numel(N{nn}.userDots)
    nucDots = [nucDots ; N.userDots{cc}];
end

if size(nucDots,1)>1
    % Assign cluster number to all userDots based on the clusters
    for cc = s.channels_apply
        if size(N.userDots{cc},1)>0
            N.userDotsLabels{cc} = s.Label*ones(size(N.userDotsLabels{cc}));
        end
    end
end

end