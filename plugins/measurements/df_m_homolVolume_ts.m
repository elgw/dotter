function varargout = df_m_homolVolume_ts(varargin)
% Find the closest path connecting the dots (the travelling salesman
% problem) and then dilating the path by a certain radius.
% Then calculate the volume of the dot cloud based on this.

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        t.string = 'Cluster Volumes - connected spheres';
        t.selChan = 1;
        t.features = 'alone';
        s.radius = 130*5;
        t.s = s;
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
    
    for aa = 1:2
        dots = [];
        
        for cc = chan
            cdots = N{nn}.clusters{aa}.dots{cc};
            dots = [dots ; cdots];
            
        end
        
        if size(dots,1)>1
            for kk = 1:3
                dots(:,kk) = dots(:,kk)*res(kk)/1000;
            end
            
            T = getMST(dots(:,1:3));
            
            MM = [MM; [size(dots,1), df_volumeTubes('data', T, 'radius', s.radius/1000, 'npoints', 100000, 'verbose')]];
        end
    end
    waitbar(nn/numel(N), w);
end
close(w);

if nargout == 0
df_histogramPlot('Data', MM(:,2), ...
    'title', '(connected) Sphere covering', ...
    'xlabel', 'Volume {μm}^3');
end
D = D(:);
if nargout == 0
figure
scatter(MM(:,1), MM(:,2))
xlabel('Number of dots')
ylabel('Volume, μm^3');
tString = sprintf('r=%d nm', s.radius);
if numel(chan) == 1
    tString = [M{1}.channels(chan(1)) tString];
end
grid on
title(tString);
end

if nargout == 1
    varargout{1} = MM(:,2);
end

end