function D = df_m_homolVolume_ch(varargin)
% Returns all pairwise distances from all alleles

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        t.string = 'Cluster Volumes - convex hull';
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

if ~isfield(M{1}, 'pixelSize')
    warning('Pixel size not specified!')
    res = [130,130,300];
else
    res = M{1}.pixelSize;
end

D = [];
MM = []; % Number of dots, Volume ; ...
w = waitbar(0, 'Calculating');
for nn = 1:numel(N)
    
    for aa = 1:2
        dots = [];
        
        for cc = chan
            cdots = N{nn}.clusters{aa}.dots{cc};
            dots = [dots ; cdots];
            
        end
        
        if size(dots,1)>3
            for kk = 1:3
                dots(:,kk) = dots(:,kk)*res(kk);
            end
            dots(:,1:3) = dots(:, 1:3)/1000;
            [~, v] = convhull(dots(:,1:3));
            MM = [MM; size(dots,1), v];            
        else
            MM = [MM; size(dots,1), NaN];
        end
    end
    waitbar(nn/numel(N), w);
end
close(w);

df_histogramPlot('Data', MM(:,2), ...
    'title', 'Convex hull', ...
    'xlabel', 'Volume {μm}^3');

D = D(:);
whos
figure
scatter(MM(:,1), MM(:,2))
xlabel('Number of dots')
ylabel('Volume, μm^3');
grid on

end