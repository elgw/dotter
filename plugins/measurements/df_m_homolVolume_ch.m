function varargout = df_m_homolVolume_ch(varargin)
% Returns all pairwise distances from all alleles

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        t.string = 'Cluster: Volume - convex hull';
        t.selChan = 1;
        t.features = 'C';        
        if nargout == 1
            varargout{1} = t;
        end
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
    
    for aa = 1:numel(N{nn}.clusters)
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
            MM = [MM; v];            
        else
            MM = [MM; NaN];
        end
    end
    waitbar(nn/numel(N), w);
end
close(w);

if nargout == 0
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

if nargout>0
    varargout{1} = MM;
end

end